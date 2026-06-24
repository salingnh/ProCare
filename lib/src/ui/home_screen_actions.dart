part of 'home_screen.dart';

extension _HsActions on _HomeScreenState {
  void _mutate(void Function(ClinicalAssessment assessment) change) {
    _assessmentController.mutate(change);
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
        _rebuild(() => _homeMode = _HomeMode.list);
        _showMessage('Đã lưu bệnh nhân.');
      case SaveOutcome.updated:
        _rebuild(() => _homeMode = _HomeMode.list);
        _showMessage('Đã cập nhật bệnh nhân.');
    }
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

  void _openSaved(SavedAssessment saved) {
    final assessment = _assessmentController.openSaved(saved);
    _rebuild(() {
      _fieldUnitSelections.clear();
      _homeMode = _HomeMode.form;
      _expandedSections
        ..clear()
        ..add(_defaultOpenSection(assessment));
      _formVersion++;
    });
  }

  void _startNew() {
    final assessment = _assessmentController.startNew();
    _rebuild(() {
      _fieldUnitSelections.clear();
      _homeMode = _HomeMode.form;
      _expandedSections
        ..clear()
        ..add(_defaultOpenSection(assessment));
      _formVersion++;
    });
  }

  void _setAssessmentMode(String mode) {
    final normalized = ClinicalAssessment.normalizeAssessmentMode(mode);
    if (_assessment.assessmentMode == normalized &&
        _preferredAssessmentMode == normalized) {
      return;
    }
    unawaited(_repository.saveAssessmentMode(normalized));
    if (_homeMode != _HomeMode.form) {
      _assessmentController.setPreferredAssessmentMode(normalized);
      _rebuild(() {});
      return;
    }
    _assessmentController.setPreferredAssessmentMode(normalized);
    _mutate((assessment) {
      assessment.assessmentMode = normalized;
    });
  }

  Future<void> _leaveForm() async {
    if (_homeMode != _HomeMode.form) {
      return;
    }
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
    final baseline = await _assessmentController.restoreBaseline();
    if (!mounted) {
      return;
    }
    _rebuild(() {
      if (baseline != null) {
        _fieldUnitSelections.clear();
        _formVersion++;
      }
      _homeMode = _HomeMode.list;
    });
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

  int? _savedIdForAssessment(
    ClinicalAssessment assessment,
    List<SavedAssessment> history,
  ) {
    if (assessment.createdAtMillis <= 0) {
      return null;
    }
    for (final saved in history) {
      final savedAssessment = saved.assessment;
      if (savedAssessment.createdAtMillis == assessment.createdAtMillis &&
          savedAssessment.savedAtMillis == assessment.savedAtMillis) {
        return saved.id;
      }
    }
    for (final saved in history) {
      if (saved.assessment.createdAtMillis == assessment.createdAtMillis) {
        return saved.id;
      }
    }
    return null;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _logStartup(String message, Stopwatch stopwatch) {
    if (kReleaseMode) {
      return;
    }
    debugPrint('[startup] ${stopwatch.elapsedMilliseconds}ms $message');
  }
}
