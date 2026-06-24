import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/assessment_display.dart';
import '../domain/clinical_assessment.dart';
import '../domain/clinical_value_parser.dart';
import '../domain/scoring.dart';
import '../export/assessment_exporter.dart';
import '../export/export_action.dart';
import '../services/update_controller.dart';
import 'app_settings_dialog.dart';
import 'assessment_controller.dart';
import 'clinical_components.dart' as clinical_ui;
import 'clinical_display_helpers.dart';
import 'clinical_theme.dart';
import 'export_action_menu.dart';
import 'update_banner.dart';

part 'assessment_form_shell.dart';
part 'assessment_form_dashboard.dart';
part 'assessment_form_quick.dart';
part 'assessment_form_detailed.dart';
part 'assessment_form_support.dart';

/// Full-screen editor for a single assessment, pushed as a route. Owns the
/// form-UI state (scroll, accordion, focus, unit pickers) and reads/writes the
/// assessment through the shared [AssessmentController]. Pops itself on save or
/// confirmed leave.
class AssessmentFormScreen extends StatefulWidget {
  final AssessmentController controller;
  final UpdateController updateController;

  const AssessmentFormScreen({
    super.key,
    required this.controller,
    required this.updateController,
  });

  @override
  State<AssessmentFormScreen> createState() => _AssessmentFormScreenState();
}

class _AssessmentFormScreenState extends State<AssessmentFormScreen> {
  AssessmentController get _assessmentController => widget.controller;

  final _assessmentExporter = const AssessmentExporter();
  final ScrollController _formScrollController = ScrollController();
  final Map<String, GlobalKey> _sectionKeys = {};
  final Map<String, GlobalKey> _fieldKeys = {};
  final Map<String, FocusNode> _fieldFocusNodes = {};
  final Map<String, String> _fieldUnitSelections = {};
  final Set<String> _expandedSections = {};
  int _formVersion = 0;
  bool _exporting = false;

  ClinicalAssessment get _assessment => _assessmentController.assessment;
  int? get _openedSavedAssessmentId =>
      _assessmentController.openedSavedAssessmentId;
  String get _preferredAssessmentMode =>
      _assessmentController.preferredAssessmentMode;
  SaveState get _saveState => _assessmentController.saveState;
  String? get _saveError => _assessmentController.saveError;
  int get _lastSavedAtMillis => _assessmentController.lastSavedAtMillis;
  bool get _saving => _assessmentController.saving;
  bool get _formDirty => _assessmentController.formDirty;

  ClinicalTones get _clinicalTones =>
      Theme.of(context).extension<ClinicalTones>()!;

  @override
  void initState() {
    super.initState();
    _expandedSections.add(_defaultOpenSection(_assessment));
    _assessmentController.addListener(_onControllerChanged);
    _assessmentController.canAutoSave = () => mounted;
  }

  @override
  void dispose() {
    _assessmentController.removeListener(_onControllerChanged);
    _assessmentController.canAutoSave = () => false;
    _assessmentController.cancelAutoSave();
    _formScrollController.dispose();
    for (final node in _fieldFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      _rebuild(() {});
    }
  }

  void _rebuild(VoidCallback fn) {
    setState(fn);
  }

  void _mutate(void Function(ClinicalAssessment assessment) change) {
    _assessmentController.mutate(change);
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleExportAction(
    ClinicalAssessment source,
    ExportAction action,
  ) async {
    if (_exporting) {
      return;
    }
    _rebuild(() => _exporting = true);
    try {
      final message = await _assessmentExporter.run(source, action);
      if (message != null && mounted) {
        _showMessage(message);
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Không thực hiện được tác vụ. Vui lòng thử lại.');
      }
    } finally {
      if (mounted) {
        _rebuild(() => _exporting = false);
      }
    }
  }

  Future<void> _savePatient() async {
    final outcome = await _assessmentController.save();
    if (outcome == null || !mounted) {
      return;
    }
    switch (outcome) {
      case SaveOutcome.empty:
        _showMessage('Chưa có dữ liệu để lưu phiếu.');
      case SaveOutcome.saved:
        _showMessage('Đã lưu bệnh nhân.');
        Navigator.of(context).pop();
      case SaveOutcome.updated:
        _showMessage('Đã cập nhật bệnh nhân.');
        Navigator.of(context).pop();
    }
  }

  void _setAssessmentMode(String mode) {
    final normalized = ClinicalAssessment.normalizeAssessmentMode(mode);
    if (_assessment.assessmentMode == normalized &&
        _preferredAssessmentMode == normalized) {
      return;
    }
    _assessmentController.setPreferredAssessmentMode(normalized);
    _mutate((assessment) {
      assessment.assessmentMode = normalized;
    });
  }

  void _showAppSettings() {
    showAppSettingsDialog(
      context: context,
      updateController: widget.updateController,
      assessmentMode: _preferredAssessmentMode,
      onAssessmentModeChanged: _setAssessmentMode,
      showMessage: _showMessage,
    );
  }

  Future<void> _leaveForm() async {
    _assessmentController.cancelAutoSave();
    if (_formDirty && _saveState != SaveState.error) {
      await _assessmentController.autoSave();
    }
    if (_saveState == SaveState.error) {
      final leave = await _confirmLeaveAfterSaveError();
      if (!leave || !mounted) {
        return;
      }
    } else if (_formDirty) {
      final discardChanges = await _confirmDiscardChanges();
      if (!discardChanges || !mounted) {
        return;
      }
    }
    await _assessmentController.restoreBaseline();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  Future<bool> _confirmLeaveAfterSaveError() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Lỗi lưu phiếu'),
          content: Text(
            _saveError == null
                ? 'Phiếu chưa được lưu thành công. Bạn vẫn muốn rời màn hình?'
                : 'Phiếu chưa được lưu thành công. Chi tiết: $_saveError',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Ở lại'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Rời màn hình'),
            ),
          ],
        );
      },
    );
    return leave ?? false;
  }

  Future<bool> _confirmDiscardChanges() async {
    final discardChanges = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Bỏ thay đổi?'),
          content: const Text(
            'Phiếu hiện tại có thay đổi chưa lưu. Bạn muốn quay lại danh sách và bỏ các thay đổi này?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Tiếp tục sửa'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Bỏ thay đổi'),
            ),
          ],
        );
      },
    );
    return discardChanges ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final assessment = _assessment;
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              return;
            }
            _leaveForm();
          },
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                tooltip: 'Quay lại danh sách',
                onPressed: _leaveForm,
                icon: const Icon(Icons.arrow_back),
              ),
              title: Text(_formAppBarTitle()),
              actions: _appBarActions(constraints.maxWidth),
            ),
            body: LayoutBuilder(
              builder: (context, bodyConstraints) {
                // Keep the dashboard a fixed header on normal screens, but let
                // it scroll internally on very short viewports so the body
                // column never overflows (the missing-data panel can be tall).
                final dashboardMaxHeight =
                    (bodyConstraints.maxHeight - 140).clamp(0.0, double.infinity);
                return Column(
                  children: [
                    UpdateBanner(controller: widget.updateController),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: dashboardMaxHeight),
                      child: SingleChildScrollView(
                        child: _clinicalDashboard(assessment),
                      ),
                    ),
                    Expanded(
                      child: KeyedSubtree(
                        key: ValueKey(_formVersion),
                        child: assessment.isQuickMode
                            ? _buildQuickAssessmentForm()
                            : _buildAssessmentForm(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

final _integerInputFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.digitsOnly,
];
final _decimalInputFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
];
final _dateInputFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.allow(RegExp(r'[0-9/-]')),
];
final _timeInputFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
];

String _lactateLevel(String value) {
  final lactate = ClinicalValueParser.parseDouble(value);
  if (lactate == null) {
    return '';
  }
  if (lactate < 2) {
    return '< 2 mmol/L';
  }
  if (lactate < 4) {
    return '2 - 3.9 mmol/L';
  }
  return '≥ 4 mmol/L';
}

String _two(int value) => value.toString().padLeft(2, '0');

class _FullWidth extends StatelessWidget {
  final Widget child;

  const _FullWidth({required this.child});

  @override
  Widget build(BuildContext context) => child;
}

class _ScoreItem {
  final String label;
  final int score;
  final bool completed;

  const _ScoreItem(
    this.label,
    this.score, {
    required this.completed,
  });
}

class _QuickScoreOption {
  final String label;
  final int score;

  const _QuickScoreOption(this.label, this.score);
}

class _QuickChoiceOption {
  final String label;
  final String value;
  final String helper;

  const _QuickChoiceOption(this.label, this.value, this.helper);
}
