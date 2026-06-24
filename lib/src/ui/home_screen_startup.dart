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
    var includePrereleaseUpdates = _updateController.includePrereleaseUpdates;
    var assessmentMode = ClinicalAssessment.normalizeAssessmentMode(
      _preferredAssessmentMode,
    );
    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Cài đặt app'),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _assessmentModeSettingsCard(
                        assessmentMode: assessmentMode,
                        onChanged: (mode) {
                          setDialogState(() => assessmentMode = mode);
                          _setAssessmentMode(mode);
                        },
                      ),
                      const SizedBox(height: 12),
                      clinical_ui.ClinicalSurfaceCard(
                        padding: EdgeInsets.zero,
                        child: SwitchListTile(
                          value: includePrereleaseUpdates,
                          onChanged: (value) {
                            setDialogState(
                                () => includePrereleaseUpdates = value);
                            _updateController.setIncludePrerelease(value);
                          },
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          title: const Text('Cài bản prerelease'),
                          subtitle: const Text(
                            'Mặc định tắt, chỉ bật khi cần thử nghiệm',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      clinical_ui.ClinicalInfoBanner(
                        icon: Icons.system_update_alt,
                        title: 'Cập nhật ứng dụng',
                        message:
                            'Kiểm tra bản phát hành mới từ GitHub Releases.',
                        status: ClinicalStatus.missing,
                        trailing: OutlinedButton.icon(
                          onPressed: () {
                            _updateController.checkForUpdate(force: true);
                            _showMessage('Đang kiểm tra cập nhật...');
                          },
                          icon: const Icon(Icons.sync, size: 18),
                          label: const Text('Kiểm tra ngay'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _assessmentModeSettingsCard({
    required String assessmentMode,
    required ValueChanged<String> onChanged,
  }) {
    final theme = Theme.of(context);
    final selectedMode = ClinicalAssessment.parseAssessmentInputMode(
      assessmentMode,
    );
    return clinical_ui.ClinicalSurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mode đánh giá',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Áp dụng cho phiếu mới và phiếu mở chỉnh sửa.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<ClinicalAssessmentInputMode>(
              showSelectedIcon: false,
              selected: {selectedMode},
              segments: const [
                ButtonSegment(
                  value: ClinicalAssessmentInputMode.detailed,
                  icon: Icon(Icons.monitor_heart_outlined),
                  label: Text('Chi tiết'),
                ),
                ButtonSegment(
                  value: ClinicalAssessmentInputMode.quick,
                  icon: Icon(Icons.touch_app_outlined),
                  label: Text('Nhanh'),
                ),
              ],
              onSelectionChanged: (selection) {
                onChanged(
                  ClinicalAssessment.assessmentModeValue(selection.first),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadUpdate() async {
    if (_updateController.downloadingUpdate ||
        _updateController.availableUpdate == null) {
      return;
    }
    final ok = await _updateController.downloadAndInstall();
    if (!ok && mounted) {
      _showMessage('Không tải hoặc mở được bản cập nhật.');
    }
  }
}
