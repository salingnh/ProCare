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
      _rebuild(() {
        _assessment = _newAssessment(assessmentMode: preferredAssessmentMode);
        _formBaseline = _assessment.clone();
        _fieldUnitSelections.clear();
        _history = [];
        _filteredHistory = [];
        _patientSummary = const _PatientSummary.empty();
        _historyLoading = false;
        _historyLoadedAll = true;
        _preferredAssessmentMode = preferredAssessmentMode;
        _homeMode = _HomeMode.list;
        _formDirty = false;
        _saveState = _SaveState.clean;
        _lastSavedAtMillis = 0;
        _saveError = null;
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
    final activeAssessment = _hasAnyClinicalData(draft)
        ? draft
        : _newAssessment(assessmentMode: preferredAssessmentMode);
    if (!mounted) {
      return;
    }
    _rebuild(() {
      _assessment = activeAssessment;
      _history = [];
      _filteredHistory = [];
      _patientSummary = const _PatientSummary.empty();
      _preferredAssessmentMode = preferredAssessmentMode;
      _fieldUnitSelections.clear();
      _openedSavedAssessmentId = null;
      _formBaseline = activeAssessment.clone();
      _homeMode = _HomeMode.list;
      _formDirty = false;
      _saveState = _SaveState.clean;
      _lastSavedAtMillis = activeAssessment.savedAtMillis;
      _saveError = null;
      _historyLoading = true;
      _historyLoadedAll = false;
      _loading = false;
      _formVersion++;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logStartup('first frame after draft', startupWatch);
      unawaited(_loadDeferredStartupData(startupWatch));
    });
  }

  Future<void> _refreshHistory() async {
    final generation = ++_historyLoadGeneration;
    if (mounted) {
      _rebuild(() {
        _historyLoading = true;
        _historyLoadedAll = false;
      });
    }
    try {
      final history = await _repository.loadAssessmentHistory(
        query: _searchQuery,
        sortMode: _sortMode,
        limit: _initialHistoryPageSize,
      );
      if (!mounted || generation != _historyLoadGeneration) {
        return;
      }
      final hasMore = history.length >= _initialHistoryPageSize;
      _rebuild(() {
        _history = history;
        _historyLoadedAll = !hasMore;
        _historyLoading = false;
        _rebuildPatientCaches();
      });
      if (hasMore) {
        unawaited(_loadRemainingHistory(generation));
      }
    } catch (_) {
      if (mounted && generation == _historyLoadGeneration) {
        _rebuild(() {
          _historyLoading = false;
          _historyLoadedAll = true;
        });
      }
    }
  }

  Future<void> _loadDeferredStartupData(Stopwatch startupWatch) async {
    final generation = ++_historyLoadGeneration;
    try {
      final includePrereleaseFuture =
          _repository.loadIncludePrereleaseUpdates();
      final history = await _repository.loadAssessmentHistory(
        sortMode: _sortMode,
        limit: _initialHistoryPageSize,
      );
      _logStartup('initial history loaded (${history.length})', startupWatch);
      final includePrereleaseUpdates = await includePrereleaseFuture;
      _logStartup('update settings loaded', startupWatch);
      if (!mounted || generation != _historyLoadGeneration) {
        return;
      }
      final hasMore = history.length >= _initialHistoryPageSize;
      final openedSavedAssessmentId = _hasAnyClinicalData(_assessment)
          ? _savedIdForAssessment(_assessment, history)
          : null;
      _rebuild(() {
        _history = history;
        _includePrereleaseUpdates = includePrereleaseUpdates;
        _openedSavedAssessmentId = openedSavedAssessmentId;
        _historyLoadedAll = !hasMore;
        _historyLoading = false;
        _rebuildPatientCaches();
      });
      _logStartup('startup data committed', startupWatch);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _logStartup('initial history frame rendered', startupWatch);
      });
      _checkUpdate();
      _startUpdateCheckTimer();
      if (hasMore) {
        unawaited(_loadRemainingHistory(generation));
      }
    } catch (error) {
      _logStartup('deferred startup load failed: $error', startupWatch);
      if (mounted && generation == _historyLoadGeneration) {
        _rebuild(() {
          _historyLoading = false;
          _historyLoadedAll = true;
        });
      }
      _checkUpdate();
      _startUpdateCheckTimer();
    }
  }

  Future<void> _loadRemainingHistory(int generation) async {
    while (
        mounted && generation == _historyLoadGeneration && !_historyLoadedAll) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
      if (_historyLoading) {
        continue;
      }
      await _loadMoreHistory(expectedGeneration: generation);
    }
  }

  Future<void> _loadMoreHistory({int? expectedGeneration}) async {
    if (_historyLoading || _historyLoadedAll) {
      return;
    }
    final generation = expectedGeneration ?? _historyLoadGeneration;
    final offset = _history.length;
    _rebuild(() => _historyLoading = true);
    try {
      final nextPage = await _repository.loadAssessmentHistory(
        query: _searchQuery,
        sortMode: _sortMode,
        limit: _historyPageSize,
        offset: offset,
      );
      if (!mounted || generation != _historyLoadGeneration) {
        return;
      }
      _rebuild(() {
        final existingIds = _history.map((saved) => saved.id).toSet();
        _history = [
          ..._history,
          ...nextPage.where((saved) => existingIds.add(saved.id)),
        ];
        _historyLoadedAll = nextPage.length < _historyPageSize;
        _historyLoading = false;
        _rebuildPatientCaches();
      });
    } catch (_) {
      if (mounted && generation == _historyLoadGeneration) {
        _rebuild(() {
          _historyLoading = false;
          _historyLoadedAll = true;
        });
      }
    }
  }

  void _startUpdateCheckTimer() {
    if (kIsWeb) {
      return;
    }
    _updateCheckTimer?.cancel();
    _updateCheckTimer = Timer.periodic(
      _updateCheckInterval,
      (_) => _checkUpdate(),
    );
  }

  void _checkUpdateAfterResume() {
    if (kIsWeb) {
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final lastCheck = _lastUpdateCheckAtMillis;
    if (lastCheck == 0 ||
        now - lastCheck >= _resumeUpdateCheckCooldown.inMilliseconds) {
      _checkUpdate();
    }
  }

  Future<void> _checkUpdate({bool force = false}) async {
    if (kIsWeb) {
      return;
    }
    if (_checkingUpdate) {
      if (force) {
        _pendingUpdateCheck = true;
      }
      return;
    }
    _checkingUpdate = true;
    _lastUpdateCheckAtMillis = DateTime.now().millisecondsSinceEpoch;
    try {
      final update = await _updateService.checkForUpdate(
        includePrerelease: _includePrereleaseUpdates,
      );
      if (!mounted || update == null) {
        return;
      }
      _rebuild(() => _availableUpdate = update);
    } finally {
      _checkingUpdate = false;
      if (_pendingUpdateCheck && mounted) {
        _pendingUpdateCheck = false;
        _checkUpdate(force: true);
      }
    }
  }

  Future<void> _setIncludePrereleaseUpdates(bool enabled) async {
    _rebuild(() {
      _includePrereleaseUpdates = enabled;
      _availableUpdate = null;
    });
    await _repository.saveIncludePrereleaseUpdates(enabled);
    await _checkUpdate(force: true);
  }

  void _showUpdateSettings() {
    var includePrereleaseUpdates = _includePrereleaseUpdates;
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
                            _setIncludePrereleaseUpdates(value);
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
                            _checkUpdate(force: true);
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
    final update = _availableUpdate;
    if (update == null || _downloadingUpdate) {
      return;
    }
    _rebuild(() {
      _downloadingUpdate = true;
      _downloadProgress = 0;
    });
    try {
      final apk = await _updateService.downloadApk(update, (progress) {
        if (mounted) {
          _rebuild(() => _downloadProgress = progress);
        }
      });
      await _updateService.openAndroidInstaller(apk);
    } catch (_) {
      if (mounted) {
        _showMessage('Không tải hoặc mở được bản cập nhật.');
      }
    } finally {
      if (mounted) {
        _rebuild(() => _downloadingUpdate = false);
      }
    }
  }
}
