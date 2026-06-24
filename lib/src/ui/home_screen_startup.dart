part of 'home_screen.dart';

extension _HsStartup on _HomeScreenState {
  Future<void> _load() async {
    final startupWatch = Stopwatch()..start();
    _logStartup('start', startupWatch);
    if (kIsWeb) {
      final preferredAssessmentMode = await _repository.loadAssessmentMode();
      if (!mounted) {
        return;
      }
      _assessmentController.setPreferredAssessmentMode(preferredAssessmentMode);
      _assessmentController.adoptAssessment(
        AssessmentController.newAssessment(
          assessmentMode: preferredAssessmentMode,
        ),
      );
      _listController.resetEmpty();
      _rebuild(() {
        _fieldUnitSelections.clear();
        _homeMode = _HomeMode.list;
        _loading = false;
        _formVersion++;
      });
      _logStartup('web ready', startupWatch);
      return;
    }
    final draft = await _repository.loadCurrentAssessment();
    final preferredAssessmentMode = await _repository.loadAssessmentMode();
    _logStartup('draft loaded', startupWatch);
    recalculateClinicalAssessment(draft, preserveExistingScores: true);
    final activeAssessment = AssessmentController.hasAnyClinicalData(draft)
        ? draft
        : AssessmentController.newAssessment(
            assessmentMode: preferredAssessmentMode,
          );
    if (!mounted) {
      return;
    }
    _assessmentController.setPreferredAssessmentMode(preferredAssessmentMode);
    _assessmentController.adoptAssessment(activeAssessment);
    _listController.beginInitialLoad();
    _rebuild(() {
      _fieldUnitSelections.clear();
      _homeMode = _HomeMode.list;
      _loading = false;
      _formVersion++;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logStartup('first frame after draft', startupWatch);
      unawaited(_loadDeferredStartupData(startupWatch));
    });
  }

  Future<void> _loadDeferredStartupData(Stopwatch startupWatch) async {
    try {
      await _listController.refresh();
      _logStartup(
        'initial history loaded (${_listController.history.length})',
        startupWatch,
      );
      if (!mounted) {
        return;
      }
      final openedSavedAssessmentId =
          AssessmentController.hasAnyClinicalData(_assessment)
              ? _savedIdForAssessment(_assessment, _listController.history)
              : null;
      _assessmentController.setOpenedSavedAssessmentId(openedSavedAssessmentId);
      _logStartup('startup data committed', startupWatch);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _logStartup('initial history frame rendered', startupWatch);
      });
      unawaited(_updateController.start());
    } catch (error) {
      _logStartup('deferred startup load failed: $error', startupWatch);
      unawaited(_updateController.start());
    }
  }

  void _showUpdateSettings() {
    showAppSettingsDialog(
      context: context,
      updateController: _updateController,
      assessmentMode: _preferredAssessmentMode,
      onAssessmentModeChanged: _setAssessmentMode,
      showMessage: _showMessage,
    );
  }
}
