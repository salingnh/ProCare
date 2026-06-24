import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/assessment_repository.dart';
import '../domain/clinical_assessment.dart';
import '../domain/clinical_value_parser.dart';
import '../domain/scoring.dart';

/// Persistence state of the assessment currently being edited.
enum SaveState { clean, dirty, saving, error }

/// Result of an explicit [AssessmentController.save].
enum SaveOutcome { saved, updated, empty }

/// Owns the assessment being edited plus its draft/history persistence and
/// auto-save lifecycle. Pure `ChangeNotifier` (no `BuildContext`); the host
/// widget keeps form-UI state (navigation, accordion, focus) and wires the
/// [onPersisted] and [canAutoSave] callbacks.
class AssessmentController extends ChangeNotifier {
  AssessmentController({
    required AssessmentRepository repository,
    String preferredAssessmentMode = ClinicalAssessment.assessmentModeDetailed,
    Duration autoSaveDelay = const Duration(milliseconds: 800),
  })  : _repository = repository,
        _autoSaveDelay = autoSaveDelay,
        _preferredAssessmentMode =
            ClinicalAssessment.normalizeAssessmentMode(preferredAssessmentMode),
        _assessment = newAssessment(assessmentMode: preferredAssessmentMode);

  final AssessmentRepository _repository;
  final Duration _autoSaveDelay;

  /// Invoked after a successful history save so the host can refresh the list.
  Future<void> Function()? onPersisted;

  /// Returns whether an auto-save may run now (e.g. the form is on screen).
  bool Function()? canAutoSave;

  ClinicalAssessment _assessment;
  ClinicalAssessment? _formBaseline;
  int? _openedSavedAssessmentId;
  String _preferredAssessmentMode;
  SaveState _saveState = SaveState.clean;
  String? _saveError;
  int _lastSavedAtMillis = 0;
  bool _saving = false;
  bool _formDirty = false;
  Timer? _autoSaveTimer;
  bool _disposed = false;

  ClinicalAssessment get assessment => _assessment;
  ClinicalAssessment? get formBaseline => _formBaseline;
  int? get openedSavedAssessmentId => _openedSavedAssessmentId;
  String get preferredAssessmentMode => _preferredAssessmentMode;
  SaveState get saveState => _saveState;
  String? get saveError => _saveError;
  int get lastSavedAtMillis => _lastSavedAtMillis;
  bool get saving => _saving;
  bool get formDirty => _formDirty;

  void setPreferredAssessmentMode(String mode) {
    _preferredAssessmentMode = ClinicalAssessment.normalizeAssessmentMode(mode);
  }

  /// Installs an assessment (loaded draft or fresh) as the current one and
  /// resets the save state. Used by the startup flow.
  void adoptAssessment(
    ClinicalAssessment assessment, {
    int? openedSavedAssessmentId,
  }) {
    _assessment = assessment;
    _formBaseline = assessment.clone();
    _openedSavedAssessmentId = openedSavedAssessmentId;
    _formDirty = false;
    _saveState = SaveState.clean;
    _saveError = null;
    _lastSavedAtMillis = assessment.savedAtMillis;
    _notify();
  }

  void setOpenedSavedAssessmentId(int? id) {
    _openedSavedAssessmentId = id;
    _notify();
  }

  /// Applies an edit, recalculates scores, marks the form dirty, persists the
  /// draft and schedules an auto-save.
  void mutate(void Function(ClinicalAssessment assessment) change) {
    change(_assessment);
    _assessment.admissionDateTime = _buildAdmissionDateTime(_assessment);
    _assessment.modifiedAtMillis = DateTime.now().millisecondsSinceEpoch;
    _formDirty = true;
    _saveState = SaveState.dirty;
    _saveError = null;
    recalculateClinicalAssessment(_assessment, preserveExistingScores: true);
    _notify();
    _repository.saveCurrentAssessment(_assessment);
    _scheduleAutoSave();
  }

  /// Opens a saved record for editing, honouring the preferred input mode.
  ClinicalAssessment openSaved(SavedAssessment saved) {
    final assessment = saved.assessment.clone();
    recalculateClinicalAssessment(assessment, preserveExistingScores: true);
    if (assessment.assessmentMode != _preferredAssessmentMode) {
      assessment.assessmentMode = _preferredAssessmentMode;
      recalculateClinicalAssessment(assessment, preserveExistingScores: true);
    }
    _assessment = assessment;
    _openedSavedAssessmentId = saved.id;
    _formBaseline = assessment.clone();
    _formDirty = false;
    _saveState = SaveState.clean;
    _lastSavedAtMillis = assessment.savedAtMillis;
    _saveError = null;
    _notify();
    _repository.saveCurrentAssessment(assessment);
    return assessment;
  }

  /// Starts a brand new assessment using the preferred input mode.
  ClinicalAssessment startNew() {
    final assessment = newAssessment(assessmentMode: _preferredAssessmentMode);
    _assessment = assessment;
    _openedSavedAssessmentId = null;
    _formBaseline = assessment.clone();
    _formDirty = false;
    _saveState = SaveState.clean;
    _lastSavedAtMillis = 0;
    _saveError = null;
    _notify();
    _repository.saveCurrentAssessment(assessment);
    return assessment;
  }

  /// Restores the form baseline (discarding unsaved edits) and persists it as
  /// the current draft. Returns the restored assessment, or null if there was
  /// no baseline to restore.
  Future<ClinicalAssessment?> restoreBaseline() async {
    final baseline = _formBaseline?.clone();
    if (baseline != null) {
      recalculateClinicalAssessment(baseline, preserveExistingScores: true);
      _assessment = baseline;
    }
    _formDirty = false;
    _saveState = SaveState.clean;
    _notify();
    if (baseline != null) {
      await _repository.saveCurrentAssessment(baseline);
    }
    return baseline;
  }

  void cancelAutoSave() {
    _autoSaveTimer?.cancel();
  }

  /// Saves the current assessment to history. Returns null if a save is already
  /// in flight, [SaveOutcome.empty] when there is nothing meaningful to save,
  /// or saved/updated depending on whether it was a new or existing record.
  Future<SaveOutcome?> save() async {
    if (_saving) {
      return null;
    }
    _autoSaveTimer?.cancel();
    if (!hasMeaningfulHistoryData(_assessment)) {
      await _repository.saveCurrentAssessment(_assessment);
      _formDirty = false;
      _saveState = SaveState.clean;
      _notify();
      return SaveOutcome.empty;
    }
    final wasEditing = _openedSavedAssessmentId != null;
    _saving = true;
    _notify();
    try {
      recalculateClinicalAssessment(_assessment, preserveExistingScores: true);
      final savedId = await _repository.saveAssessmentHistory(
        _assessment,
        id: _openedSavedAssessmentId,
      );
      await _repository.saveCurrentAssessment(_assessment);
      await onPersisted?.call();
      if (!_disposed) {
        _openedSavedAssessmentId = savedId;
        _formBaseline = _assessment.clone();
        _formDirty = false;
        _saveState = SaveState.clean;
        _lastSavedAtMillis = _assessment.savedAtMillis;
        _saveError = null;
        _notify();
      }
      return wasEditing ? SaveOutcome.updated : SaveOutcome.saved;
    } finally {
      if (!_disposed) {
        _saving = false;
        _notify();
      }
    }
  }

  /// Debounced auto-save triggered after edits. No-ops while saving, when the
  /// host disallows it, or when there is nothing meaningful to save.
  Future<void> autoSave() async {
    if (_saving || !(canAutoSave?.call() ?? true) || !_formDirty) {
      return;
    }
    if (!hasMeaningfulHistoryData(_assessment)) {
      await _repository.saveCurrentAssessment(_assessment);
      return;
    }
    _saving = true;
    _saveState = SaveState.saving;
    _saveError = null;
    _notify();
    try {
      recalculateClinicalAssessment(_assessment, preserveExistingScores: true);
      final savedId = await _repository.saveAssessmentHistory(
        _assessment,
        id: _openedSavedAssessmentId,
      );
      await _repository.saveCurrentAssessment(_assessment);
      await onPersisted?.call();
      if (_disposed) {
        return;
      }
      _openedSavedAssessmentId = savedId;
      _formBaseline = _assessment.clone();
      _formDirty = false;
      _saveState = SaveState.clean;
      _lastSavedAtMillis = _assessment.savedAtMillis;
      _notify();
    } catch (error) {
      if (_disposed) {
        return;
      }
      _saveState = SaveState.error;
      _saveError = error.toString();
      _notify();
    } finally {
      if (!_disposed) {
        _saving = false;
        _notify();
      }
    }
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(_autoSaveDelay, autoSave);
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  // --- assessment helpers (moved from the home screen library) ---

  static ClinicalAssessment newAssessment({
    String assessmentMode = ClinicalAssessment.assessmentModeDetailed,
  }) {
    final now = DateTime.now();
    final assessment = ClinicalAssessment(
      assessmentMode: ClinicalAssessment.normalizeAssessmentMode(
        assessmentMode,
      ),
      admissionDate: _dateText(now),
      admissionTime: _timeText(now),
      admissionDateTime: '${_timeText(now)}, ngày ${_dateText(now)}',
      createdAtMillis: now.millisecondsSinceEpoch,
      modifiedAtMillis: now.millisecondsSinceEpoch,
    );
    recalculateClinicalAssessment(assessment);
    return assessment;
  }

  static bool hasAnyClinicalData(ClinicalAssessment assessment) {
    if (assessment.isQuickMode && hasQuickScoreData(assessment)) {
      return true;
    }
    return [
      assessment.patientId,
      assessment.fullName,
      assessment.age,
      assessment.admissionReason,
      assessment.infectionOrgan,
      assessment.lactateLevel,
      assessment.news2RespirationMeasured,
      assessment.news2Spo2Measured,
      assessment.sofaRespirationMeasured,
    ].any(ClinicalValueParser.hasText);
  }

  static bool hasQuickScoreData(ClinicalAssessment assessment) {
    return ClinicalValueParser.hasText(assessment.lactateLevel) ||
        assessment.news2RespirationSelected ||
        assessment.news2Spo2Selected ||
        assessment.news2OxygenSelected ||
        assessment.news2TemperatureSelected ||
        assessment.news2SystolicBpSelected ||
        assessment.news2HeartRateSelected ||
        assessment.news2ConsciousnessSelected ||
        assessment.qsofaRespirationSelected ||
        assessment.qsofaSystolicBpSelected ||
        assessment.qsofaConsciousnessSelected ||
        assessment.sofaRespirationSelected ||
        assessment.sofaCoagulationSelected ||
        assessment.sofaLiverSelected ||
        assessment.sofaCardiovascularSelected ||
        assessment.sofaNeurologicSelected ||
        assessment.sofaRenalSelected;
  }

  static bool hasMeaningfulHistoryData(ClinicalAssessment assessment) {
    return hasAnyClinicalData(assessment) ||
        hasQuickScoreData(assessment) ||
        ClinicalValueParser.hasText(assessment.lactateLevel) ||
        ClinicalValueParser.hasText(assessment.news2RespirationMeasured) ||
        ClinicalValueParser.hasText(assessment.news2SystolicBpMeasured) ||
        ClinicalValueParser.hasText(assessment.news2HeartRateMeasured) ||
        ClinicalValueParser.hasText(assessment.lactate) ||
        ClinicalValueParser.hasText(assessment.sofaNeurologicMeasured) ||
        ClinicalValueParser.hasText(assessment.treatmentOutcome);
  }
}

String _buildAdmissionDateTime(ClinicalAssessment assessment) {
  return '${assessment.admissionTime}, ngày ${assessment.admissionDate}';
}

String _dateText(DateTime value) {
  return '${value.year}-${_two(value.month)}-${_two(value.day)}';
}

String _timeText(DateTime value) {
  return '${_two(value.hour)}:${_two(value.minute)}';
}

String _two(int value) => value.toString().padLeft(2, '0');
