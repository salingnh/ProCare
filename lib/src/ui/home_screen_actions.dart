part of 'home_screen.dart';

extension _HsActions on _HomeScreenState {
  void _mutate(void Function(ClinicalAssessment assessment) change) {
    _rebuild(() {
      change(_assessment);
      _assessment.admissionDateTime = _buildAdmissionDateTime(_assessment);
      _assessment.modifiedAtMillis = DateTime.now().millisecondsSinceEpoch;
      _formDirty = true;
      _saveState = _SaveState.dirty;
      _saveError = null;
      recalculateClinicalAssessment(_assessment, preserveExistingScores: true);
    });
    _repository.saveCurrentAssessment(_assessment);
    _scheduleAutoSave();
  }

  Future<void> _savePatient() async {
    if (_saving) {
      return;
    }
    _autoSaveTimer?.cancel();
    if (!_hasMeaningfulHistoryData(_assessment)) {
      await _repository.saveCurrentAssessment(_assessment);
      if (mounted) {
        _rebuild(() {
          _formDirty = false;
          _saveState = _SaveState.clean;
        });
        _showMessage('Chưa có dữ liệu để lưu phiếu.');
      }
      return;
    }
    _rebuild(() => _saving = true);
    try {
      final wasEditingSavedAssessment = _openedSavedAssessmentId != null;
      recalculateClinicalAssessment(_assessment, preserveExistingScores: true);
      final savedId = await _repository.saveAssessmentHistory(
        _assessment,
        id: _openedSavedAssessmentId,
      );
      await _repository.saveCurrentAssessment(_assessment);
      await _refreshHistory();
      if (!mounted) {
        return;
      }
      _rebuild(() {
        _openedSavedAssessmentId = savedId;
        _formBaseline = _assessment.clone();
        _formDirty = false;
        _saveState = _SaveState.clean;
        _lastSavedAtMillis = _assessment.savedAtMillis;
        _saveError = null;
        _homeMode = _HomeMode.list;
      });
      _showMessage(
        wasEditingSavedAssessment
            ? 'Đã cập nhật bệnh nhân.'
            : 'Đã lưu bệnh nhân.',
      );
    } finally {
      if (mounted) {
        _rebuild(() => _saving = false);
      }
    }
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(
      const Duration(milliseconds: 800),
      () => _autoSaveAssessment(),
    );
  }

  Future<void> _autoSaveAssessment() async {
    if (_saving || _homeMode != _HomeMode.form || !_formDirty) {
      return;
    }
    if (!_hasMeaningfulHistoryData(_assessment)) {
      await _repository.saveCurrentAssessment(_assessment);
      return;
    }
    _rebuild(() {
      _saving = true;
      _saveState = _SaveState.saving;
      _saveError = null;
    });
    try {
      recalculateClinicalAssessment(_assessment, preserveExistingScores: true);
      final savedId = await _repository.saveAssessmentHistory(
        _assessment,
        id: _openedSavedAssessmentId,
      );
      await _repository.saveCurrentAssessment(_assessment);
      await _refreshHistory();
      if (!mounted) {
        return;
      }
      _rebuild(() {
        _openedSavedAssessmentId = savedId;
        _formBaseline = _assessment.clone();
        _formDirty = false;
        _saveState = _SaveState.clean;
        _lastSavedAtMillis = _assessment.savedAtMillis;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      _rebuild(() {
        _saveState = _SaveState.error;
        _saveError = error.toString();
      });
    } finally {
      if (mounted) {
        _rebuild(() => _saving = false);
      }
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
      final assessment = source.clone();
      recalculateClinicalAssessment(assessment, preserveExistingScores: true);
      switch (action) {
        case ExportAction.saveDocx:
          await _saveExportedAssessment(assessment, action.exportFormat);
          break;
        case ExportAction.shareDocx:
          await _shareExportedAssessment(assessment, action.exportFormat);
          break;
        case ExportAction.printPdf:
          await _printPdfAssessment(assessment);
          break;
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

  Future<void> _saveExportedAssessment(
    ClinicalAssessment assessment,
    CrfExportFormat format,
  ) async {
    final file = await _exporter.export(assessment, format);
    final fileName = file.uri.pathSegments.last;
    final savedToDownloads = await _saveExportToDownloads(
      sourcePath: file.path,
      fileName: fileName,
      mimeType: format.mimeType,
    );
    if (!mounted) {
      return;
    }
    _showMessage(
      savedToDownloads
          ? 'Đã lưu vào Downloads/NEWS2-L: $fileName'
          : 'Đã lưu trong thư mục xuất của app: $fileName',
    );
  }

  Future<void> _shareExportedAssessment(
    ClinicalAssessment assessment,
    CrfExportFormat format,
  ) async {
    final file = await _exporter.export(assessment, format);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: format.mimeType)],
        subject: 'NEWS2-L CRF',
        text: file.uri.pathSegments.last,
      ),
    );
  }

  Future<void> _printPdfAssessment(ClinicalAssessment assessment) async {
    final bytes = await _exporter.buildPdfBytes(assessment);
    final fileName = CrfExporter.buildFileName(assessment, CrfExportFormat.pdf);
    await Printing.layoutPdf(
      name: fileName,
      onLayout: (_) async => bytes,
    );
  }

  Future<bool> _saveExportToDownloads({
    required String sourcePath,
    required String fileName,
    required String mimeType,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      await _androidFileChannel.invokeMethod<String>('saveToDownloads', {
        'sourcePath': sourcePath,
        'fileName': fileName,
        'mimeType': mimeType,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  void _openSaved(SavedAssessment saved) {
    final assessment = saved.assessment.clone();
    recalculateClinicalAssessment(assessment, preserveExistingScores: true);
    if (assessment.assessmentMode != _preferredAssessmentMode) {
      assessment.assessmentMode = _preferredAssessmentMode;
      recalculateClinicalAssessment(assessment, preserveExistingScores: true);
    }
    _rebuild(() {
      _assessment = assessment;
      _openedSavedAssessmentId = saved.id;
      _fieldUnitSelections.clear();
      _formBaseline = assessment.clone();
      _formDirty = false;
      _saveState = _SaveState.clean;
      _lastSavedAtMillis = assessment.savedAtMillis;
      _saveError = null;
      _homeMode = _HomeMode.form;
      _expandedSections
        ..clear()
        ..add(_defaultOpenSection(assessment));
      _formVersion++;
    });
    _repository.saveCurrentAssessment(assessment);
  }

  void _startNew() {
    final assessment = _newAssessment(assessmentMode: _preferredAssessmentMode);
    _rebuild(() {
      _assessment = assessment;
      _openedSavedAssessmentId = null;
      _fieldUnitSelections.clear();
      _formBaseline = assessment.clone();
      _formDirty = false;
      _saveState = _SaveState.clean;
      _lastSavedAtMillis = 0;
      _saveError = null;
      _homeMode = _HomeMode.form;
      _expandedSections
        ..clear()
        ..add(_defaultOpenSection(assessment));
      _formVersion++;
    });
    _repository.saveCurrentAssessment(assessment);
  }

  void _setAssessmentMode(String mode) {
    final normalized = ClinicalAssessment.normalizeAssessmentMode(mode);
    if (_assessment.assessmentMode == normalized &&
        _preferredAssessmentMode == normalized) {
      return;
    }
    unawaited(_repository.saveAssessmentMode(normalized));
    if (_homeMode != _HomeMode.form) {
      _rebuild(() => _preferredAssessmentMode = normalized);
      return;
    }
    _preferredAssessmentMode = normalized;
    _mutate((assessment) {
      assessment.assessmentMode = normalized;
    });
  }

  Future<void> _leaveForm() async {
    if (_homeMode != _HomeMode.form) {
      return;
    }
    _autoSaveTimer?.cancel();
    if (_formDirty && _saveState != _SaveState.error) {
      await _autoSaveAssessment();
    }
    if (_saveState == _SaveState.error) {
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
    final baseline = _formBaseline?.clone();
    if (baseline != null) {
      recalculateClinicalAssessment(baseline, preserveExistingScores: true);
    }
    _rebuild(() {
      if (baseline != null) {
        _assessment = baseline;
        _fieldUnitSelections.clear();
        _formVersion++;
      }
      _formDirty = false;
      _saveState = _SaveState.clean;
      _homeMode = _HomeMode.list;
    });
    if (baseline != null) {
      await _repository.saveCurrentAssessment(baseline);
    }
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
