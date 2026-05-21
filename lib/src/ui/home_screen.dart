import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../data/assessment_repository.dart';
import '../domain/assessment_display.dart';
import '../domain/clinical_assessment.dart';
import '../domain/clinical_value_parser.dart';
import '../domain/scale_guidance_config.dart';
import '../domain/scoring.dart';
import '../export/crf_exporter.dart';
import '../services/update_service.dart';
import 'clinical_components.dart' as clinical_ui;
import 'clinical_theme.dart';
import 'export_action_menu.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum _HomeMode {
  list,
  form,
}

enum _PatientFilter {
  all,
  incomplete,
  highRisk,
  septicShock,
}

enum _SaveState {
  clean,
  dirty,
  saving,
  error,
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const _initialHistoryPageSize = 50;
  static const _historyPageSize = 50;
  static const _updateCheckInterval = Duration(hours: 6);
  static const _resumeUpdateCheckCooldown = Duration(minutes: 15);
  static const _androidFileChannel = MethodChannel('news2_l/android_files');
  static final _integerInputFormatters = <TextInputFormatter>[
    FilteringTextInputFormatter.digitsOnly,
  ];
  static final _decimalInputFormatters = <TextInputFormatter>[
    FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
  ];
  static final _dateInputFormatters = <TextInputFormatter>[
    FilteringTextInputFormatter.allow(RegExp(r'[0-9/-]')),
  ];
  static final _timeInputFormatters = <TextInputFormatter>[
    FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
  ];

  final _repository = AssessmentRepository();
  final _exporter = const CrfExporter();
  final _updateService = const UpdateService();
  ScrollController? _patientScrollController;
  final ScrollController _formScrollController = ScrollController();
  final ValueNotifier<_PatientScrollBubbleState> _patientScrollBubble =
      ValueNotifier(const _PatientScrollBubbleState.hidden());

  ClinicalAssessment _assessment = _newAssessment();
  List<SavedAssessment> _history = [];
  List<SavedAssessment> _filteredHistory = [];
  _PatientSummary _patientSummary = const _PatientSummary.empty();
  final Map<String, GlobalKey> _sectionKeys = {};
  final Map<String, GlobalKey> _fieldKeys = {};
  final Map<String, FocusNode> _fieldFocusNodes = {};
  final Map<String, String> _fieldUnitSelections = {};
  final Set<String> _expandedSections = {};
  PatientSortMode _sortMode = PatientSortMode.updatedAt;
  _PatientFilter _patientFilter = _PatientFilter.all;
  String _searchQuery = '';
  String _preferredAssessmentMode = ClinicalAssessment.assessmentModeDetailed;
  int? _openedSavedAssessmentId;
  _HomeMode _homeMode = _HomeMode.list;
  ClinicalAssessment? _formBaseline;
  int _formVersion = 0;
  _SaveState _saveState = _SaveState.clean;
  Timer? _autoSaveTimer;
  int _lastSavedAtMillis = 0;
  String? _saveError;
  bool _loading = true;
  bool _saving = false;
  bool _formDirty = false;
  bool _exporting = false;
  bool _downloadingUpdate = false;
  bool _checkingUpdate = false;
  bool _pendingUpdateCheck = false;
  bool _historyLoading = false;
  bool _historyLoadedAll = true;
  bool _includePrereleaseUpdates = false;
  double _downloadProgress = 0;
  int _historyLoadGeneration = 0;
  int _lastUpdateCheckAtMillis = 0;
  UpdateInfo? _availableUpdate;
  Timer? _patientScrollBubbleTimer;
  Timer? _updateCheckTimer;

  ClinicalTones get _clinicalTones =>
      Theme.of(context).extension<ClinicalTones>()!;

  ScrollController get _patientScrollControllerOrCreate {
    return _patientScrollController ??= ScrollController();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _updateCheckTimer?.cancel();
    _patientScrollBubbleTimer?.cancel();
    _patientScrollBubble.dispose();
    _patientScrollController?.dispose();
    _formScrollController.dispose();
    for (final node in _fieldFocusNodes.values) {
      node.dispose();
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkUpdateAfterResume();
    }
  }

  Future<void> _load() async {
    final startupWatch = Stopwatch()..start();
    _logStartup('start', startupWatch);
    if (kIsWeb) {
      final preferredAssessmentMode = await _repository.loadAssessmentMode();
      if (!mounted) {
        return;
      }
      setState(() {
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
    recalculateClinicalAssessment(draft);
    final activeAssessment = _hasAnyClinicalData(draft)
        ? draft
        : _newAssessment(assessmentMode: preferredAssessmentMode);
    if (!mounted) {
      return;
    }
    setState(() {
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
      setState(() {
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
      setState(() {
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
        setState(() {
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
      setState(() {
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
        setState(() {
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
    setState(() => _historyLoading = true);
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
      setState(() {
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
        setState(() {
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
      setState(() => _availableUpdate = update);
    } finally {
      _checkingUpdate = false;
      if (_pendingUpdateCheck && mounted) {
        _pendingUpdateCheck = false;
        _checkUpdate(force: true);
      }
    }
  }

  Future<void> _setIncludePrereleaseUpdates(bool enabled) async {
    setState(() {
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
    setState(() {
      _downloadingUpdate = true;
      _downloadProgress = 0;
    });
    try {
      final apk = await _updateService.downloadApk(update, (progress) {
        if (mounted) {
          setState(() => _downloadProgress = progress);
        }
      });
      await _updateService.openAndroidInstaller(apk);
    } catch (_) {
      if (mounted) {
        _showMessage('Không tải hoặc mở được bản cập nhật.');
      }
    } finally {
      if (mounted) {
        setState(() => _downloadingUpdate = false);
      }
    }
  }

  void _mutate(void Function(ClinicalAssessment assessment) change) {
    setState(() {
      change(_assessment);
      _assessment.admissionDateTime = _buildAdmissionDateTime(_assessment);
      _assessment.modifiedAtMillis = DateTime.now().millisecondsSinceEpoch;
      _formDirty = true;
      _saveState = _SaveState.dirty;
      _saveError = null;
      recalculateClinicalAssessment(_assessment);
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
        setState(() {
          _formDirty = false;
          _saveState = _SaveState.clean;
        });
        _showMessage('Chưa có dữ liệu để lưu phiếu.');
      }
      return;
    }
    setState(() => _saving = true);
    try {
      final wasEditingSavedAssessment = _openedSavedAssessmentId != null;
      recalculateClinicalAssessment(_assessment);
      final savedId = await _repository.saveAssessmentHistory(
        _assessment,
        id: _openedSavedAssessmentId,
      );
      await _repository.saveCurrentAssessment(_assessment);
      await _refreshHistory();
      if (!mounted) {
        return;
      }
      setState(() {
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
        setState(() => _saving = false);
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
    setState(() {
      _saving = true;
      _saveState = _SaveState.saving;
      _saveError = null;
    });
    try {
      recalculateClinicalAssessment(_assessment);
      final savedId = await _repository.saveAssessmentHistory(
        _assessment,
        id: _openedSavedAssessmentId,
      );
      await _repository.saveCurrentAssessment(_assessment);
      await _refreshHistory();
      if (!mounted) {
        return;
      }
      setState(() {
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
      setState(() {
        _saveState = _SaveState.error;
        _saveError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _saving = false);
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
    setState(() => _exporting = true);
    try {
      final assessment = source.clone();
      recalculateClinicalAssessment(assessment);
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
        setState(() => _exporting = false);
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
    recalculateClinicalAssessment(assessment);
    final preferredAssessmentMode = _preferredAssessmentMode;
    final keepQuickScores =
        preferredAssessmentMode == ClinicalAssessment.assessmentModeDetailed &&
            assessment.isQuickMode &&
            _hasQuickScoreData(assessment);
    if (!keepQuickScores &&
        assessment.assessmentMode != preferredAssessmentMode) {
      assessment.assessmentMode = preferredAssessmentMode;
      recalculateClinicalAssessment(assessment);
    }
    setState(() {
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
    setState(() {
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
      setState(() => _preferredAssessmentMode = normalized);
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
      recalculateClinicalAssessment(baseline);
    }
    setState(() {
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isForm = _homeMode == _HomeMode.form;
        final content = _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (_availableUpdate != null) _buildUpdateBanner(),
                  if (isForm) _clinicalDashboard(_assessment),
                  Expanded(
                    child: isForm
                        ? KeyedSubtree(
                            key: ValueKey(_formVersion),
                            child: _assessment.isQuickMode
                                ? _buildQuickAssessmentForm()
                                : _buildAssessmentForm(),
                          )
                        : _buildPatientList(),
                  ),
                ],
              );

        return PopScope(
          canPop: !isForm,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop || _homeMode != _HomeMode.form) {
              return;
            }
            _leaveForm();
          },
          child: Scaffold(
            appBar: AppBar(
              leading: isForm
                  ? IconButton(
                      tooltip: 'Quay lại danh sách',
                      onPressed: _leaveForm,
                      icon: const Icon(Icons.arrow_back),
                    )
                  : null,
              title: Text(isForm ? _formAppBarTitle() : 'NEWS2-L'),
              actions: _appBarActions(constraints.maxWidth),
            ),
            body: content,
            floatingActionButton:
                !_loading && !isForm && _filteredHistory.isNotEmpty
                    ? FloatingActionButton.extended(
                        onPressed: _startNew,
                        icon: const Icon(Icons.add),
                        label: const Text('Phiếu mới'),
                      )
                    : null,
          ),
        );
      },
    );
  }

  String _formAppBarTitle() {
    final fullName = _assessment.fullName.trim();
    if (fullName.isNotEmpty) {
      return fullName;
    }
    final patientId = _assessment.patientId.trim();
    if (patientId.isNotEmpty) {
      return patientId;
    }
    return _openedSavedAssessmentId == null ? 'Phiếu mới' : 'Chỉnh sửa phiếu';
  }

  List<Widget> _appBarActions(double width) {
    if (_homeMode == _HomeMode.list) {
      return [
        IconButton(
          tooltip: 'Cài đặt app',
          onPressed: _showUpdateSettings,
          icon: const Icon(Icons.settings_outlined),
        ),
        const SizedBox(width: 4),
      ];
    }
    if (width >= 520) {
      return [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Center(child: _saveStatusIndicator()),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: FilledButton.icon(
            onPressed: _saving ? null : _savePatient,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Lưu'),
          ),
        ),
        _formExportMenu(),
        IconButton(
          tooltip: 'Cài đặt app',
          onPressed: _showUpdateSettings,
          icon: const Icon(Icons.settings_outlined),
        ),
        const SizedBox(width: 4),
      ];
    }
    return [
      Center(child: _saveStatusIndicator(compact: true)),
      IconButton.filledTonal(
        tooltip: 'Lưu bệnh nhân',
        onPressed: _saving ? null : _savePatient,
        icon: const Icon(Icons.save_outlined),
      ),
      _formExportMenu(),
      IconButton(
        tooltip: 'Cài đặt app',
        onPressed: _showUpdateSettings,
        icon: const Icon(Icons.settings_outlined),
      ),
      const SizedBox(width: 4),
    ];
  }

  Widget _saveStatusIndicator({bool compact = false}) {
    final label = switch (_saveState) {
      _SaveState.clean => _lastSavedAtMillis > 0
          ? 'Đã lưu ${_formatClock(_lastSavedAtMillis)}'
          : 'Đã lưu nháp',
      _SaveState.dirty => 'Chưa lưu',
      _SaveState.saving => 'Đang lưu...',
      _SaveState.error => 'Lỗi lưu',
    };
    final status = switch (_saveState) {
      _SaveState.clean => ClinicalStatus.normal,
      _SaveState.dirty => ClinicalStatus.watch,
      _SaveState.saving => ClinicalStatus.watch,
      _SaveState.error => ClinicalStatus.danger,
    };
    return Padding(
      padding: EdgeInsets.only(right: compact ? 4 : 0),
      child: clinical_ui.SaveStatusIndicator(label: label, status: status),
    );
  }

  Widget _formExportMenu() {
    return ExportActionMenu(
      enabled: !_exporting,
      onSelected: (action) => _handleExportAction(_assessment, action),
    );
  }

  Widget _buildUpdateBanner() {
    final update = _availableUpdate!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: clinical_ui.ClinicalInfoBanner(
        icon: Icons.system_update_alt,
        title: 'Có bản cập nhật NEWS2-L ${update.version}'
            '${update.prerelease ? ' (thử nghiệm)' : ''}',
        message: 'Tải APK mới để cập nhật ứng dụng trên thiết bị này.',
        status: ClinicalStatus.watch,
        progress: _downloadingUpdate
            ? LinearProgressIndicator(value: _downloadProgress)
            : null,
        trailing: FilledButton.icon(
          onPressed: _downloadingUpdate ? null : _downloadUpdate,
          icon: const Icon(Icons.download),
          label: Text(_downloadingUpdate ? 'Đang tải' : 'Tải'),
        ),
      ),
    );
  }

  Widget _buildAssessmentForm() {
    final assessment = _assessment;
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 720;
        return ListView(
          controller: _formScrollController,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          children: [
            _section(
              'Thông tin bệnh nhân',
              sectionId: AssessmentSections.patient,
              progress: _patientProgress(assessment),
              twoColumns: twoColumns,
              children: [
                _field('Mã bệnh nhân', assessment.patientId, (value) {
                  assessment.patientId = value;
                }, fieldId: AssessmentFields.patientId),
                _field('Họ và tên', assessment.fullName, (value) {
                  assessment.fullName = value;
                }, fieldId: AssessmentFields.fullName),
                _field('Ngày nhập viện', assessment.admissionDate, (value) {
                  assessment.admissionDate = value;
                },
                    fieldId: AssessmentFields.admissionDate,
                    hint: 'yyyy-MM-dd',
                    keyboardType: TextInputType.datetime,
                    inputFormatters: _dateInputFormatters),
                _field('Giờ nhập viện', assessment.admissionTime, (value) {
                  assessment.admissionTime = value;
                },
                    fieldId: AssessmentFields.admissionTime,
                    hint: 'HH:mm',
                    keyboardType: TextInputType.datetime,
                    inputFormatters: _timeInputFormatters),
                _field('Tuổi', assessment.age, (value) {
                  assessment.age = value;
                },
                    unitOptions: const ['năm'],
                    hint: 'VD: 65',
                    keyboardType: TextInputType.number,
                    inputFormatters: _integerInputFormatters),
                _fullWidth(
                  _field('Lý do nhập viện', assessment.admissionReason,
                      (value) {
                    assessment.admissionReason = value;
                  }, maxLines: 3),
                ),
                _fullWidth(
                  _field('Cơ quan nhiễm trùng', assessment.infectionOrgan,
                      (value) {
                    assessment.infectionOrgan = value;
                  }),
                ),
              ],
            ),
            _section(
              '2. Sinh hiệu NEWS2',
              sectionId: AssessmentSections.news2,
              progress: AssessmentDisplay.news2Progress(assessment),
              twoColumns: twoColumns,
              children: [
                _field('Nhịp thở', assessment.news2RespirationMeasured,
                    (value) {
                  assessment.news2RespirationMeasured = value;
                },
                    fieldId: AssessmentFields.respiration,
                    unitOptions: const ['lần/phút'],
                    scoreText: _scoreText(
                      assessment.news2RespirationMeasured,
                      'Điểm NEWS2: ${assessment.news2Respiration}',
                    ),
                    scoreStatus: _scoreStatus(assessment.news2Respiration),
                    warningText: _rangeWarning(
                      assessment.news2RespirationMeasured,
                      min: 4,
                      max: 40,
                      label: 'Nhịp thở',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: _integerInputFormatters),
                _field('Huyết áp tâm thu', assessment.news2SystolicBpMeasured,
                    (value) {
                  assessment.news2SystolicBpMeasured = value;
                },
                    fieldId: AssessmentFields.systolicBp,
                    unitOptions: const ['mmHg'],
                    scoreText: _scoreText(
                      assessment.news2SystolicBpMeasured,
                      'Điểm NEWS2: ${assessment.news2SystolicBp}',
                    ),
                    scoreStatus: _scoreStatus(assessment.news2SystolicBp),
                    warningText: _rangeWarning(
                      assessment.news2SystolicBpMeasured,
                      min: 60,
                      max: 240,
                      label: 'Huyết áp tâm thu',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: _integerInputFormatters),
                DropdownButtonFormField<String>(
                  initialValue: assessment.news2ConsciousnessMeasured.isEmpty
                      ? null
                      : assessment.news2ConsciousnessMeasured,
                  isExpanded: true,
                  decoration:
                      const InputDecoration(labelText: 'Tri giác (AVPU)'),
                  items: const [
                    DropdownMenuItem(value: 'A', child: Text('A - Tỉnh táo')),
                    DropdownMenuItem(value: 'C', child: Text('C - Lú lẫn mới')),
                    DropdownMenuItem(
                        value: 'V', child: Text('V - Đáp ứng lời nói')),
                    DropdownMenuItem(
                        value: 'P', child: Text('P - Đáp ứng đau')),
                    DropdownMenuItem(
                        value: 'U', child: Text('U - Không đáp ứng')),
                  ],
                  onChanged: (value) => _mutate((a) {
                    a.news2ConsciousnessMeasured = value ?? '';
                  }),
                ),
                _fullWidth(
                  Column(
                    children: [
                      _qsofaChecklist(assessment),
                      const SizedBox(height: 8),
                      _readOnlyLine(
                        'Kết luận qSOFA',
                        _qsofaConclusionText(assessment),
                        tone: _qsofaTone(assessment),
                        maxLines: 5,
                      ),
                    ],
                  ),
                ),
                _field('SpO2', assessment.news2Spo2Measured, (value) {
                  assessment.news2Spo2Measured = value;
                },
                    fieldId: AssessmentFields.spo2,
                    unitOptions: const ['%'],
                    scoreText: _scoreText(
                      assessment.news2Spo2Measured,
                      'Điểm NEWS2: ${assessment.news2Spo2}',
                    ),
                    scoreStatus: _scoreStatus(assessment.news2Spo2),
                    warningText: _rangeWarning(
                      assessment.news2Spo2Measured,
                      min: 50,
                      max: 100,
                      label: 'SpO2',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: _integerInputFormatters),
                _toggleTile(
                  'Nguy cơ hô hấp tăng CO2',
                  assessment.news2Spo2Scale2,
                  (value) => _mutate((a) => a.news2Spo2Scale2 = value),
                ),
                _toggleTile(
                  'Đang thở oxy',
                  assessment.news2OxygenMeasured == 'Có',
                  (value) => _mutate((a) {
                    a.news2OxygenMeasured = value ? 'Có' : 'Không';
                  }),
                ),
                _field('Nhiệt độ', assessment.news2TemperatureMeasured,
                    (value) {
                  assessment.news2TemperatureMeasured = value;
                },
                    fieldId: AssessmentFields.temperature,
                    unitOptions: const ['°C'],
                    scoreText: _scoreText(
                      assessment.news2TemperatureMeasured,
                      'Điểm NEWS2: ${assessment.news2Temperature}',
                    ),
                    scoreStatus: _scoreStatus(assessment.news2Temperature),
                    warningText: _rangeWarning(
                      assessment.news2TemperatureMeasured,
                      min: 30,
                      max: 43,
                      label: 'Nhiệt độ',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: _decimalInputFormatters),
                _field('Nhịp tim', assessment.news2HeartRateMeasured, (value) {
                  assessment.news2HeartRateMeasured = value;
                },
                    fieldId: AssessmentFields.heartRate,
                    unitOptions: const ['lần/phút'],
                    scoreText: _scoreText(
                      assessment.news2HeartRateMeasured,
                      'Điểm NEWS2: ${assessment.news2HeartRate}',
                    ),
                    scoreStatus: _scoreStatus(assessment.news2HeartRate),
                    warningText: _rangeWarning(
                      assessment.news2HeartRateMeasured,
                      min: 30,
                      max: 220,
                      label: 'Nhịp tim',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: _integerInputFormatters),
                _fullWidth(
                  _miniScores([
                    _ScoreItem(
                      'Nhịp thở',
                      assessment.news2Respiration,
                      completed: ClinicalValueParser.hasText(
                        assessment.news2RespirationMeasured,
                      ),
                    ),
                    _ScoreItem(
                      'HA',
                      assessment.news2SystolicBp,
                      completed: ClinicalValueParser.hasText(
                        assessment.news2SystolicBpMeasured,
                      ),
                    ),
                    _ScoreItem(
                      'Tri giác',
                      assessment.news2Consciousness,
                      completed: ClinicalValueParser.hasText(
                        assessment.news2ConsciousnessMeasured,
                      ),
                    ),
                    _ScoreItem(
                      'SpO2',
                      assessment.news2Spo2,
                      completed: ClinicalValueParser.hasText(
                        assessment.news2Spo2Measured,
                      ),
                    ),
                    _ScoreItem(
                      'Oxy',
                      assessment.news2Oxygen,
                      completed: ClinicalValueParser.hasText(
                        assessment.news2OxygenMeasured,
                      ),
                    ),
                    _ScoreItem(
                      'Nhiệt',
                      assessment.news2Temperature,
                      completed: ClinicalValueParser.hasText(
                        assessment.news2TemperatureMeasured,
                      ),
                    ),
                    _ScoreItem(
                      'Mạch',
                      assessment.news2HeartRate,
                      completed: ClinicalValueParser.hasText(
                        assessment.news2HeartRateMeasured,
                      ),
                    ),
                  ]),
                ),
                _fullWidth(
                  _readOnlyLine(
                    'Kết luận NEWS2',
                    _news2ConclusionText(assessment),
                    tone: _news2Tone(assessment),
                    maxLines: 9,
                  ),
                ),
              ],
            ),
            _section(
              '3. Lactate & huyết động',
              sectionId: AssessmentSections.lactate,
              progress: AssessmentDisplay.lactateProgress(assessment),
              twoColumns: twoColumns,
              children: [
                _field('Lactate tĩnh mạch', assessment.lactate, (value) {
                  assessment.lactate = value;
                  assessment.lactateLevel = _lactateLevel(value);
                },
                    fieldId: AssessmentFields.lactate,
                    unitOptions: const ['mmol/L'],
                    warningText: _lactateWarning(assessment.lactate),
                    hint: 'VD: 2.1',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: _decimalInputFormatters),
                _field(
                    'Thời gian lấy mẫu lactate', assessment.lactateSampleTime,
                    (value) {
                  assessment.lactateSampleTime = value;
                },
                    fieldId: AssessmentFields.lactateSampleTime,
                    hint: 'HH:mm',
                    keyboardType: TextInputType.datetime,
                    inputFormatters: _timeInputFormatters),
                _readOnlyLine(
                  'Phân mức Lactate',
                  assessment.lactateLevel.isEmpty
                      ? 'Chưa nhập lactate'
                      : assessment.lactateLevel,
                  tone: ClinicalValueParser.hasText(assessment.lactate)
                      ? null
                      : _clinicalTones.muted,
                ),
                _field('Tim mạch - MAP/Vận mạch (mmHg; thuốc/liều)',
                    assessment.sofaCardiovascularMeasured, (value) {
                  assessment.sofaCardiovascularMeasured = value;
                },
                    fieldId: AssessmentFields.cardiovascular,
                    scoreText: _scoreText(
                      assessment.sofaCardiovascularMeasured,
                      'Điểm SOFA tim mạch: ${assessment.sofaCardiovascular}',
                    ),
                    scoreStatus: _scoreStatus(assessment.sofaCardiovascular),
                    hint: 'VD: MAP 65 hoặc norepi 0.2'),
                _toggleTile(
                  'Có dùng vận mạch',
                  assessment.vasopressor,
                  (value) => _mutate((a) => a.vasopressor = value),
                ),
              ],
            ),
            _section(
              '4. SOFA 24 giờ',
              sectionId: AssessmentSections.sofa,
              progress: AssessmentDisplay.sofaProgress(assessment),
              twoColumns: twoColumns,
              children: [
                _fullWidth(
                  _readOnlyLine(
                    'Ngưỡng Sepsis-3',
                    _sofaComplete(assessment)
                        ? sofaThresholdText(assessment)
                        : _missingSentence(
                            AssessmentDisplay.sofaProgress(assessment),
                          ),
                    tone: _sofaThresholdTone(assessment),
                  ),
                ),
                _fullWidth(
                  _readOnlyLine(
                    'Kết luận SOFA',
                    _sofaConclusionText(assessment),
                    tone: _sofaTone(assessment),
                    maxLines: 5,
                  ),
                ),
                _field('Hô hấp - PaO2/FiO2', assessment.sofaRespirationMeasured,
                    (value) {
                  assessment.sofaRespirationMeasured = value;
                },
                    fieldId: AssessmentFields.sofaRespiration,
                    unitOptions: const ['mmHg'],
                    scoreText: _scoreText(
                      assessment.sofaRespirationMeasured,
                      'Điểm SOFA hô hấp: ${assessment.sofaRespiration}',
                    ),
                    scoreStatus: _scoreStatus(assessment.sofaRespiration),
                    hint: 'VD: 180 hoặc 180 thở máy'),
                _field(
                    'Đông máu - Tiểu cầu', assessment.sofaCoagulationMeasured,
                    (value) {
                  assessment.sofaCoagulationMeasured = value;
                },
                    fieldId: AssessmentFields.sofaCoagulation,
                    unitOptions: const ['10³/µL'],
                    scoreText: _scoreText(
                      assessment.sofaCoagulationMeasured,
                      'Điểm SOFA đông máu: ${assessment.sofaCoagulation}',
                    ),
                    scoreStatus: _scoreStatus(assessment.sofaCoagulation),
                    hint: 'VD: 120',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: _decimalInputFormatters),
                _field(
                    'Gan - Bilirubin',
                    assessment.sofaLiverMeasured,
                    (value) {
                      assessment.sofaLiverMeasured = value;
                      final unit = _selectedUnit(
                        value,
                        const ['mg/dL', 'µmol/L'],
                      );
                      if (unit != null) {
                        assessment.sofaLiverUnit = unit;
                      }
                    },
                    fieldId: AssessmentFields.sofaLiver,
                    scoreText: _scoreText(
                      assessment.sofaLiverMeasured,
                      'Điểm SOFA gan: ${assessment.sofaLiver}',
                    ),
                    scoreStatus: _scoreStatus(assessment.sofaLiver),
                    helperText: 'Đơn vị được lưu cùng chỉ số',
                    hint: 'VD: 2.0 hoặc 34 µmol/L',
                    unitOptions: const ['mg/dL', 'µmol/L'],
                    selectedUnit: _selectedFieldUnit(
                      AssessmentFields.sofaLiver,
                      assessment.sofaLiverMeasured,
                      const ['mg/dL', 'µmol/L'],
                      savedUnit: assessment.sofaLiverUnit,
                    ),
                    onUnitChanged: (value) {
                      _fieldUnitSelections[AssessmentFields.sofaLiver] = value;
                      assessment.sofaLiverUnit = value;
                      if (_selectedUnit(
                            assessment.sofaLiverMeasured,
                            const ['mg/dL', 'µmol/L'],
                          ) !=
                          null) {
                        assessment.sofaLiverMeasured = _replaceTrailingUnit(
                          assessment.sofaLiverMeasured,
                          value,
                        );
                      }
                    }),
                _field('Thần kinh - GCS', assessment.sofaNeurologicMeasured,
                    (value) {
                  assessment.sofaNeurologicMeasured = value;
                },
                    fieldId: AssessmentFields.sofaNeurologic,
                    scoreText: _scoreText(
                      assessment.sofaNeurologicMeasured,
                      'Điểm SOFA thần kinh: ${assessment.sofaNeurologic}',
                    ),
                    scoreStatus: _scoreStatus(assessment.sofaNeurologic),
                    unitOptions: const ['điểm'],
                    warningText: _rangeWarning(
                      assessment.sofaNeurologicMeasured,
                      min: 3,
                      max: 15,
                      label: 'GCS',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: _integerInputFormatters),
                _field(
                    'Thận - Creatinin/nước tiểu',
                    assessment.sofaRenalMeasured,
                    (value) {
                      assessment.sofaRenalMeasured = value;
                      final unit = _selectedUnit(
                        value,
                        const ['mg/dL', 'µmol/L'],
                      );
                      if (unit != null) {
                        assessment.sofaRenalUnit = unit;
                      }
                    },
                    fieldId: AssessmentFields.sofaRenal,
                    scoreText: _scoreText(
                      assessment.sofaRenalMeasured,
                      'Điểm SOFA thận: ${assessment.sofaRenal}',
                    ),
                    scoreStatus: _scoreStatus(assessment.sofaRenal),
                    helperText: 'Đơn vị được lưu cùng chỉ số',
                    hint: 'VD: creatinin 2.0 mg/dL, nước tiểu 400 mL',
                    unitOptions: const ['mg/dL', 'µmol/L'],
                    selectedUnit: _selectedFieldUnit(
                      AssessmentFields.sofaRenal,
                      assessment.sofaRenalMeasured,
                      const ['mg/dL', 'µmol/L'],
                      savedUnit: assessment.sofaRenalUnit,
                    ),
                    onUnitChanged: (value) {
                      _fieldUnitSelections[AssessmentFields.sofaRenal] = value;
                      assessment.sofaRenalUnit = value;
                      if (_selectedUnit(
                            assessment.sofaRenalMeasured,
                            const ['mg/dL', 'µmol/L'],
                          ) !=
                          null) {
                        assessment.sofaRenalMeasured = _replaceTrailingUnit(
                          assessment.sofaRenalMeasured,
                          value,
                        );
                      }
                    }),
                _fullWidth(
                  _miniScores([
                    _ScoreItem(
                      'Hô hấp',
                      assessment.sofaRespiration,
                      completed: ClinicalValueParser.hasText(
                        assessment.sofaRespirationMeasured,
                      ),
                    ),
                    _ScoreItem(
                      'Đông máu',
                      assessment.sofaCoagulation,
                      completed: ClinicalValueParser.hasText(
                        assessment.sofaCoagulationMeasured,
                      ),
                    ),
                    _ScoreItem(
                      'Gan',
                      assessment.sofaLiver,
                      completed: ClinicalValueParser.hasText(
                        assessment.sofaLiverMeasured,
                      ),
                    ),
                    _ScoreItem(
                      'Tim mạch',
                      assessment.sofaCardiovascular,
                      completed: _sofaCardiovascularComplete(assessment),
                    ),
                    _ScoreItem(
                      'Thần kinh',
                      assessment.sofaNeurologic,
                      completed: ClinicalValueParser.hasText(
                        assessment.sofaNeurologicMeasured,
                      ),
                    ),
                    _ScoreItem(
                      'Thận',
                      assessment.sofaRenal,
                      completed: ClinicalValueParser.hasText(
                        assessment.sofaRenalMeasured,
                      ),
                    ),
                  ]),
                ),
              ],
            ),
            _diagnosisOutcomeCard(assessment, twoColumns: twoColumns),
          ],
        );
      },
    );
  }

  Widget _buildQuickAssessmentForm() {
    final assessment = _assessment;
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 720;
        return ListView(
          controller: _formScrollController,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          children: [
            _quickSectionCard(
              'Thông tin bệnh nhân',
              sectionId: AssessmentSections.patient,
              progress: _patientProgress(assessment),
              children: [
                _quickFieldGrid(
                  twoColumns: twoColumns,
                  children: [
                    _field('Mã bệnh nhân', assessment.patientId, (value) {
                      assessment.patientId = value;
                    }, fieldId: AssessmentFields.patientId),
                    _field('Họ và tên', assessment.fullName, (value) {
                      assessment.fullName = value;
                    }, fieldId: AssessmentFields.fullName),
                    _field('Ngày nhập viện', assessment.admissionDate, (value) {
                      assessment.admissionDate = value;
                    },
                        fieldId: AssessmentFields.admissionDate,
                        hint: 'yyyy-MM-dd',
                        keyboardType: TextInputType.datetime,
                        inputFormatters: _dateInputFormatters),
                    _field('Giờ nhập viện', assessment.admissionTime, (value) {
                      assessment.admissionTime = value;
                    },
                        fieldId: AssessmentFields.admissionTime,
                        hint: 'HH:mm',
                        keyboardType: TextInputType.datetime,
                        inputFormatters: _timeInputFormatters),
                    _field('Tuổi', assessment.age, (value) {
                      assessment.age = value;
                    },
                        unitOptions: const ['năm'],
                        hint: 'VD: 65',
                        keyboardType: TextInputType.number,
                        inputFormatters: _integerInputFormatters),
                    _field('Cơ quan nhiễm trùng', assessment.infectionOrgan,
                        (value) {
                      assessment.infectionOrgan = value;
                    }),
                    _fullWidth(
                      _field('Lý do nhập viện', assessment.admissionReason,
                          (value) {
                        assessment.admissionReason = value;
                      }, maxLines: 3),
                    ),
                  ],
                ),
              ],
            ),
            _quickNews2Section(assessment),
            _quickHemodynamicsSection(
              assessment,
              twoColumns: twoColumns,
            ),
            _quickSofaSection(assessment),
            _diagnosisOutcomeCard(assessment, twoColumns: twoColumns),
          ],
        );
      },
    );
  }

  Widget _buildPatientList() {
    final patients = _filteredHistory;
    final showHeader = _history.isNotEmpty ||
        _searchQuery.trim().isNotEmpty ||
        _patientFilter != _PatientFilter.all;
    return Column(
      children: [
        if (showHeader)
          Padding(
            padding: EdgeInsets.fromLTRB(
              12,
              patients.isEmpty ? 8 : 12,
              12,
              patients.isEmpty ? 6 : 10,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 620;
                final searchField = TextField(
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Tìm theo mã BN hoặc họ tên',
                    prefixIcon: Icon(Icons.search),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (value) {
                    _searchQuery = value;
                    _refreshHistory();
                  },
                );
                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      searchField,
                      if (_history.isNotEmpty ||
                          _patientFilter != _PatientFilter.all) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _patientSortControl(compact: true),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: _patientFilterMenu()),
                          ],
                        ),
                      ],
                      if (patients.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _patientSummaryStrip(_patientSummary, compact: true),
                      ],
                    ],
                  );
                }
                final sortControl = _patientSortControl();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(child: searchField),
                        const SizedBox(width: 12),
                        sortControl,
                      ],
                    ),
                    if (patients.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        runSpacing: 8,
                        children: [
                          _patientFilterChips(),
                          _patientSummaryStrip(_patientSummary),
                        ],
                      ),
                    ] else if (_history.isNotEmpty ||
                        _patientFilter != _PatientFilter.all) ...[
                      const SizedBox(height: 10),
                      _patientFilterChips(),
                    ],
                  ],
                );
              },
            ),
          ),
        Expanded(
          child: patients.isEmpty
              ? (_historyLoading
                  ? _patientListLoadingState()
                  : _emptyPatientState())
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        NotificationListener<ScrollNotification>(
                          onNotification: (notification) =>
                              _handlePatientScroll(notification, patients),
                          child: MasonryGridView.count(
                            controller: _patientScrollControllerOrCreate,
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                            crossAxisCount:
                                _patientGridColumns(constraints.maxWidth),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            itemCount:
                                patients.length + (_historyLoading ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == patients.length) {
                                return _patientPageLoadingTile();
                              }
                              if (index < 0 || index >= patients.length) {
                                return const SizedBox.shrink();
                              }
                              return _patientCard(patients[index]);
                            },
                          ),
                        ),
                        ValueListenableBuilder<_PatientScrollBubbleState>(
                          valueListenable: _patientScrollBubble,
                          builder: (context, bubble, child) {
                            if (!bubble.visible || bubble.label.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return Positioned(
                              top: _patientScrollBubbleTop(
                                constraints,
                                bubble.fraction,
                              ),
                              right: 12,
                              child: _patientScrollBubbleWidget(bubble.label),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _patientSortControl({bool compact = false}) {
    if (compact) {
      return PopupMenuButton<PatientSortMode>(
        initialValue: _sortMode,
        tooltip: 'Sắp xếp',
        onSelected: _selectPatientSort,
        itemBuilder: (context) => [
          _patientSortMenuItem(PatientSortMode.name),
          _patientSortMenuItem(PatientSortMode.createdAt),
          _patientSortMenuItem(PatientSortMode.updatedAt),
        ],
        child: _patientListMenuButton(
          icon: Icons.sort,
          label: _patientSortLabel(_sortMode, compact: true),
        ),
      );
    }
    return SegmentedButton<PatientSortMode>(
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        visualDensity: VisualDensity.compact,
      ),
      selected: {_sortMode},
      segments: const [
        ButtonSegment(
          value: PatientSortMode.name,
          label: Text('Tên'),
          icon: Icon(Icons.sort_by_alpha),
        ),
        ButtonSegment(
          value: PatientSortMode.createdAt,
          label: Text('Ngày tạo'),
          icon: Icon(Icons.event_available),
        ),
        ButtonSegment(
          value: PatientSortMode.updatedAt,
          label: Text('Ngày cập nhật'),
          icon: Icon(Icons.update),
        ),
      ],
      onSelectionChanged: (selection) {
        _selectPatientSort(selection.first);
      },
    );
  }

  PopupMenuItem<PatientSortMode> _patientSortMenuItem(PatientSortMode mode) {
    final selected = _sortMode == mode;
    return PopupMenuItem(
      value: mode,
      child: Row(
        children: [
          Icon(selected ? Icons.check : null, size: 18),
          const SizedBox(width: 8),
          Text(_patientSortLabel(mode)),
        ],
      ),
    );
  }

  String _patientSortLabel(PatientSortMode mode, {bool compact = false}) {
    return switch (mode) {
      PatientSortMode.name => 'Tên',
      PatientSortMode.createdAt => compact ? 'Ngày tạo' : 'Ngày tạo',
      PatientSortMode.updatedAt => compact ? 'Cập nhật' : 'Ngày cập nhật',
    };
  }

  void _selectPatientSort(PatientSortMode next) {
    if (next == _sortMode) {
      return;
    }
    setState(() {
      _sortMode = next;
      _patientScrollBubble.value = const _PatientScrollBubbleState.hidden();
    });
    if (_patientScrollControllerOrCreate.hasClients) {
      _patientScrollControllerOrCreate.jumpTo(0);
    }
    _refreshHistory();
  }

  List<SavedAssessment> _filteredPatients(List<SavedAssessment> source) {
    return source.where((saved) {
      final assessment = saved.assessment;
      return switch (_patientFilter) {
        _PatientFilter.all => true,
        _PatientFilter.incomplete =>
          AssessmentDisplay.isIncompletePatient(assessment),
        _PatientFilter.highRisk =>
          AssessmentDisplay.isHighRiskPatient(assessment),
        _PatientFilter.septicShock =>
          AssessmentDisplay.isSepticShockPatient(assessment),
      };
    }).toList();
  }

  void _rebuildPatientCaches() {
    _filteredHistory = _filteredPatients(_history);
    _patientSummary = _PatientSummary.from(_history);
  }

  Widget _patientFilterChips() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _patientFilterChip(_PatientFilter.all, 'Tất cả'),
        _patientFilterChip(_PatientFilter.incomplete, 'Chưa đủ dữ liệu'),
        _patientFilterChip(_PatientFilter.highRisk, 'Nguy cơ cao'),
        _patientFilterChip(_PatientFilter.septicShock, 'Sốc NK'),
      ],
    );
  }

  Widget _patientFilterMenu() {
    return PopupMenuButton<_PatientFilter>(
      initialValue: _patientFilter,
      tooltip: 'Lọc danh sách',
      onSelected: _selectPatientFilter,
      itemBuilder: (context) => [
        _patientFilterMenuItem(_PatientFilter.all),
        _patientFilterMenuItem(_PatientFilter.incomplete),
        _patientFilterMenuItem(_PatientFilter.highRisk),
        _patientFilterMenuItem(_PatientFilter.septicShock),
      ],
      child: _patientListMenuButton(
        icon: Icons.filter_list,
        label: _patientFilterLabel(_patientFilter, compact: true),
      ),
    );
  }

  PopupMenuItem<_PatientFilter> _patientFilterMenuItem(_PatientFilter filter) {
    final selected = _patientFilter == filter;
    return PopupMenuItem(
      value: filter,
      child: Row(
        children: [
          Icon(selected ? Icons.check : null, size: 18),
          const SizedBox(width: 8),
          Text(_patientFilterLabel(filter)),
        ],
      ),
    );
  }

  Widget _patientListMenuButton({
    required IconData icon,
    required String label,
  }) {
    final theme = Theme.of(context);
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: ShapeDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.arrow_drop_down,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  String _patientFilterLabel(_PatientFilter filter, {bool compact = false}) {
    return switch (filter) {
      _PatientFilter.all => 'Tất cả',
      _PatientFilter.incomplete => compact ? 'Chưa đủ' : 'Chưa đủ dữ liệu',
      _PatientFilter.highRisk => 'Nguy cơ cao',
      _PatientFilter.septicShock => 'Sốc NK',
    };
  }

  Widget _patientFilterChip(_PatientFilter filter, String label) {
    final theme = Theme.of(context);
    final selected = _patientFilter == filter;
    final status = switch (filter) {
      _PatientFilter.all => ClinicalStatus.normal,
      _PatientFilter.incomplete => ClinicalStatus.missing,
      _PatientFilter.highRisk => ClinicalStatus.warning,
      _PatientFilter.septicShock => ClinicalStatus.danger,
    };
    final style = clinical_ui.clinicalStatusStyle(context, status);
    return FilterChip(
      selected: selected,
      label: Text(label),
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      selectedColor: style.background,
      checkmarkColor: style.foreground,
      side: BorderSide(
        color: selected ? style.border : theme.colorScheme.outlineVariant,
      ),
      labelStyle: theme.textTheme.labelMedium?.copyWith(
        color: selected ? style.foreground : theme.colorScheme.onSurfaceVariant,
        fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
      ),
      onSelected: (_) {
        _selectPatientFilter(filter);
      },
    );
  }

  void _selectPatientFilter(_PatientFilter filter) {
    if (filter == _patientFilter) {
      return;
    }
    setState(() {
      _patientFilter = filter;
      _patientScrollBubble.value = const _PatientScrollBubbleState.hidden();
      _rebuildPatientCaches();
    });
    if (_patientScrollControllerOrCreate.hasClients) {
      _patientScrollControllerOrCreate.jumpTo(0);
    }
  }

  Widget _patientSummaryStrip(
    _PatientSummary summary, {
    bool compact = false,
  }) {
    final badges = [
      _summaryBadge('Tổng', summary.total, ClinicalStatus.normal),
      _summaryBadge('Chưa đủ', summary.incomplete, ClinicalStatus.missing),
      _summaryBadge('Nguy cơ cao', summary.highRisk, ClinicalStatus.warning),
      _summaryBadge('Sốc NK', summary.shock, ClinicalStatus.danger),
    ];
    if (compact) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < badges.length; i++) ...[
              badges[i],
              if (i < badges.length - 1) const SizedBox(width: 6),
            ],
          ],
        ),
      );
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: badges,
    );
  }

  Widget _summaryBadge(String label, int count, ClinicalStatus status) {
    return clinical_ui.StatusBadge(
      status: status,
      label: '$label: $count',
      dense: true,
    );
  }

  Widget _patientListLoadingState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox.square(
            dimension: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Đang tải danh sách...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _patientPageLoadingTile() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      ),
    );
  }

  Widget _emptyPatientState() {
    final theme = Theme.of(context);
    final activeFilter =
        _searchQuery.trim().isNotEmpty || _patientFilter != _PatientFilter.all;
    return Center(
      child: clinical_ui.ClinicalSurfaceCard(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 42,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              activeFilter
                  ? 'Không có phiếu phù hợp'
                  : 'Chưa có phiếu theo dõi',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              activeFilter
                  ? 'Thử đổi bộ lọc hoặc từ khóa tìm kiếm.'
                  : 'Tạo phiếu đầu tiên để ghi nhận NEWS2, lactate và SOFA.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _startNew,
              icon: const Icon(Icons.add),
              label: const Text('Phiếu mới'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _patientCard(SavedAssessment saved) {
    final assessment = saved.assessment;
    final treatmentOutcome = assessment.treatmentOutcome.trim();
    final badges = <Widget>[
      _scoreBadge(AssessmentDisplay.news2ScoreDisplay(assessment)),
      _scoreBadge(AssessmentDisplay.qsofaScoreDisplay(assessment)),
      _scoreBadge(AssessmentDisplay.sofaScoreDisplay(assessment)),
      if (ClinicalValueParser.hasText(assessment.lactate))
        clinical_ui.StatusBadge(
          status: SofaScoring.lactateAtLeastTwo(assessment)
              ? ClinicalStatus.warning
              : ClinicalStatus.normal,
          label: 'Lactate: ${assessment.lactate.trim()}',
          dense: true,
        ),
      if (AssessmentDisplay.isSepticShockPatient(assessment))
        const clinical_ui.StatusBadge(
          status: ClinicalStatus.danger,
          label: 'Sốc NK',
          dense: true,
        ),
    ];
    return clinical_ui.PatientCard(
      name: assessment.fullName.trim().isEmpty
          ? 'Chưa nhập tên bệnh nhân'
          : assessment.fullName.trim(),
      identityLine: _patientIdentityLine(assessment),
      admissionLine: _patientAdmissionLine(assessment),
      updatedText: _patientSortTimestampText(assessment),
      badges: badges,
      treatmentOutcomeLine: treatmentOutcome.isEmpty
          ? null
          : 'Kết quả điều trị: $treatmentOutcome',
      treatmentOutcomeStatus: _treatmentOutcomeStatus(treatmentOutcome),
      actionMenu: _patientActionMenu(assessment),
      onTap: () => _openSaved(saved),
    );
  }

  Widget _scoreBadge(ScoreDisplay display) {
    final value = display.scoreText == '-' ? '' : ' ${display.scoreText}';
    return clinical_ui.StatusBadge(
      status: display.status,
      label: '${display.title}:$value ${display.statusLabel}',
      dense: true,
    );
  }

  Widget _patientActionMenu(ClinicalAssessment assessment) {
    return ExportActionMenu(
      enabled: !_exporting,
      onSelected: (action) => _handleExportAction(assessment, action),
    );
  }

  ClinicalStatus _treatmentOutcomeStatus(String value) {
    final normalized = value.toLowerCase();
    if (normalized.contains('tử vong') ||
        normalized.contains('tu vong') ||
        normalized.contains('nặng') ||
        normalized.contains('nang')) {
      return ClinicalStatus.danger;
    }
    if (normalized.contains('chuyển') || normalized.contains('chuyen')) {
      return ClinicalStatus.watch;
    }
    return ClinicalStatus.normal;
  }

  String _patientAdmissionLine(ClinicalAssessment assessment) {
    final date = _compactDateText(assessment.admissionDate.trim());
    final time = assessment.admissionTime.trim();
    if (date.isEmpty && time.isEmpty) {
      return 'Chưa nhập thời gian nhập viện';
    }
    if (date.isEmpty) {
      return 'Nhập viện: $time';
    }
    if (time.isEmpty) {
      return 'Nhập viện: $date';
    }
    return 'Nhập viện: $time · $date';
  }

  String _patientIdentityLine(ClinicalAssessment assessment) {
    final patientId = assessment.patientId.trim();
    final age = assessment.age.trim();
    if (patientId.isEmpty && age.isEmpty) {
      return '';
    }
    if (age.isEmpty) {
      return 'Mã BN: $patientId';
    }
    if (patientId.isEmpty) {
      return 'Tuổi: $age';
    }
    return 'Mã BN: $patientId · Tuổi: $age';
  }

  String _patientSortTimestampText(ClinicalAssessment assessment) {
    final millis = _sortMode == PatientSortMode.createdAt
        ? assessment.createdAtMillis
        : assessment.modifiedAtMillis;
    return _formatRelativeTime(millis);
  }

  String _formatRelativeTime(int millis) {
    if (millis <= 0) {
      return 'Chưa cập nhật';
    }
    final value = DateTime.fromMillisecondsSinceEpoch(millis);
    final diff = DateTime.now().difference(value);
    if (diff.isNegative || diff.inSeconds < 60) {
      return 'Vừa cập nhật';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    }
    if (diff.inDays < 30) {
      return '${diff.inDays} ngày trước';
    }
    return '${_two(value.day)}/${_two(value.month)}/${value.year}';
  }

  String _compactDateText(String value) {
    if (value.isEmpty) {
      return '';
    }
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match != null) {
      final year = match.group(1);
      final month = match.group(2);
      final day = match.group(3);
      if (year != null && month != null && day != null) {
        return '$day/$month/$year';
      }
    }
    return value;
  }

  int _patientGridColumns(double width) {
    if (width >= 1100) {
      return 3;
    }
    if (width >= 680) {
      return 2;
    }
    return 1;
  }

  bool _handlePatientScroll(
    ScrollNotification notification,
    List<SavedAssessment> patients,
  ) {
    if (notification.metrics.axis != Axis.vertical) {
      return false;
    }
    if (notification.metrics.extentAfter < 720) {
      unawaited(_loadMoreHistory());
    }
    final label = _patientScrollLabel(notification.metrics, patients);
    final fraction = _patientScrollFraction(notification.metrics);
    _patientScrollBubbleTimer?.cancel();
    _patientScrollBubble.value = _PatientScrollBubbleState(
      visible: label.isNotEmpty,
      label: label,
      fraction: fraction,
    );
    _patientScrollBubbleTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) {
        return;
      }
      _patientScrollBubble.value = const _PatientScrollBubbleState.hidden();
    });
    return false;
  }

  double _patientScrollFraction(ScrollMetrics metrics) {
    final maxScrollExtent = metrics.maxScrollExtent;
    if (maxScrollExtent <= 0) {
      return 0;
    }
    final fraction =
        (metrics.pixels / maxScrollExtent).clamp(0.0, 1.0).toDouble();
    return (fraction * 100).round() / 100;
  }

  String _patientScrollLabel(
    ScrollMetrics metrics,
    List<SavedAssessment> patients,
  ) {
    if (patients.isEmpty) {
      return '';
    }
    final maxScrollExtent = metrics.maxScrollExtent;
    final fraction = maxScrollExtent <= 0
        ? 0.0
        : (metrics.pixels / maxScrollExtent).clamp(0.0, 1.0);
    final index = (fraction * (patients.length - 1))
        .round()
        .clamp(0, patients.length - 1);
    final assessment = patients[index].assessment;
    if (_sortMode == PatientSortMode.name) {
      return _patientNameIndex(assessment);
    }
    final millis = _sortMode == PatientSortMode.createdAt
        ? assessment.createdAtMillis
        : assessment.modifiedAtMillis;
    return _formatPatientDate(millis);
  }

  double _patientScrollBubbleTop(
    BoxConstraints constraints,
    double scrollFraction,
  ) {
    final maxTop = constraints.maxHeight - 56;
    final availableTop = (maxTop - 12).clamp(0.0, double.infinity).toDouble();
    final fraction = scrollFraction.clamp(0.0, 1.0).toDouble();
    return 12 + (availableTop * fraction);
  }

  Widget _patientScrollBubbleWidget(String label) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.primaryContainer,
      elevation: 1,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  String _patientNameIndex(ClinicalAssessment assessment) {
    final source = assessment.fullName.trim().isNotEmpty
        ? assessment.fullName.trim()
        : assessment.patientId.trim();
    if (source.isEmpty) {
      return '#';
    }
    final first = source.characters.first.toUpperCase();
    return RegExp(r'[A-ZÀ-Ỹ]').hasMatch(first) ? first : '#';
  }

  String _formatPatientDate(int millis) {
    if (millis <= 0) {
      return '--/--';
    }
    final value = DateTime.fromMillisecondsSinceEpoch(millis);
    return '${_two(value.day)}/${_two(value.month)}';
  }

  RiskTone _news2Tone(ClinicalAssessment assessment) {
    final tones = _clinicalTones;
    if (!_news2Complete(assessment)) {
      return tones.muted;
    }
    if (assessment.news2Total >= 7) {
      return tones.danger;
    }
    if (assessment.news2Total >= 5) {
      return tones.warning;
    }
    if (News2Scoring.hasSingleThreeScore(assessment)) {
      return tones.attention;
    }
    return tones.success;
  }

  RiskTone _qsofaTone(ClinicalAssessment assessment) {
    final tones = _clinicalTones;
    if (!_qsofaComplete(assessment)) {
      return tones.muted;
    }
    return assessment.qsofaTotal >= 2 ? tones.danger : tones.success;
  }

  RiskTone _sofaTone(ClinicalAssessment assessment) {
    final tones = _clinicalTones;
    if (SofaScoring.hasSepticShock(assessment) ||
        SofaScoring.riskGroup(assessment.sofaTotal) == SofaScoring.riskHigh) {
      return tones.danger;
    }
    if (!_sofaComplete(assessment)) {
      return tones.muted;
    }
    if (SofaScoring.riskGroup(assessment.sofaTotal) ==
        SofaScoring.riskIntermediate) {
      return tones.warning;
    }
    if (SofaScoring.hasSepsisBySofa(assessment)) {
      return tones.attention;
    }
    return tones.success;
  }

  RiskTone _sofaThresholdTone(ClinicalAssessment assessment) {
    final tones = _clinicalTones;
    if (!_sofaComplete(assessment)) {
      return tones.muted;
    }
    return SofaScoring.hasSepsisBySofa(assessment)
        ? tones.warning
        : tones.success;
  }

  RiskTone _diagnosisTone(ClinicalAssessment assessment) {
    final tones = _clinicalTones;
    if (_shockInputsIncomplete(assessment)) {
      return tones.muted;
    }
    if (SofaScoring.hasSepticShock(assessment)) {
      return tones.danger;
    }
    if (!_sofaComplete(assessment)) {
      return tones.muted;
    }
    if (SofaScoring.hasSepsisBySofa(assessment)) {
      return tones.warning;
    }
    return tones.success;
  }

  RiskTone _componentScoreTone(int score) {
    final tones = _clinicalTones;
    if (score >= 3) {
      return tones.danger;
    }
    if (score >= 2) {
      return tones.warning;
    }
    if (score == 1) {
      return tones.attention;
    }
    return tones.success;
  }

  bool _news2Complete(ClinicalAssessment assessment) {
    if (assessment.isQuickMode) {
      return assessment.news2RespirationSelected &&
          assessment.news2Spo2Selected &&
          assessment.news2OxygenSelected &&
          assessment.news2TemperatureSelected &&
          assessment.news2SystolicBpSelected &&
          assessment.news2HeartRateSelected &&
          assessment.news2ConsciousnessSelected;
    }
    return ClinicalValueParser.hasText(assessment.news2RespirationMeasured) &&
        ClinicalValueParser.hasText(assessment.news2Spo2Measured) &&
        ClinicalValueParser.hasText(assessment.news2OxygenMeasured) &&
        ClinicalValueParser.hasText(assessment.news2TemperatureMeasured) &&
        ClinicalValueParser.hasText(assessment.news2SystolicBpMeasured) &&
        ClinicalValueParser.hasText(assessment.news2HeartRateMeasured) &&
        ClinicalValueParser.hasText(assessment.news2ConsciousnessMeasured);
  }

  bool _qsofaComplete(ClinicalAssessment assessment) {
    if (assessment.isQuickMode) {
      return assessment.qsofaRespirationSelected &&
          assessment.qsofaSystolicBpSelected &&
          assessment.qsofaConsciousnessSelected;
    }
    return ClinicalValueParser.hasText(assessment.news2RespirationMeasured) &&
        ClinicalValueParser.hasText(assessment.news2SystolicBpMeasured) &&
        ClinicalValueParser.hasText(assessment.news2ConsciousnessMeasured);
  }

  bool _lactateComplete(ClinicalAssessment assessment) {
    return ClinicalValueParser.hasText(assessment.lactate) ||
        (assessment.isQuickMode &&
            ClinicalValueParser.hasText(assessment.lactateLevel));
  }

  bool _shockInputsIncomplete(ClinicalAssessment assessment) {
    if (!assessment.vasopressor) {
      return false;
    }
    return !_lactateComplete(assessment) ||
        !ClinicalValueParser.hasText(assessment.sofaCardiovascularMeasured);
  }

  bool _sofaCardiovascularComplete(ClinicalAssessment assessment) {
    if (assessment.isQuickMode) {
      return assessment.sofaCardiovascularSelected;
    }
    return ClinicalValueParser.hasText(assessment.sofaCardiovascularMeasured) ||
        assessment.vasopressor;
  }

  bool _sofaComplete(ClinicalAssessment assessment) {
    if (assessment.isQuickMode) {
      return assessment.sofaRespirationSelected &&
          assessment.sofaCoagulationSelected &&
          assessment.sofaLiverSelected &&
          assessment.sofaCardiovascularSelected &&
          assessment.sofaNeurologicSelected &&
          assessment.sofaRenalSelected;
    }
    return ClinicalValueParser.hasText(assessment.sofaRespirationMeasured) &&
        ClinicalValueParser.hasText(assessment.sofaCoagulationMeasured) &&
        ClinicalValueParser.hasText(assessment.sofaLiverMeasured) &&
        _sofaCardiovascularComplete(assessment) &&
        ClinicalValueParser.hasText(assessment.sofaNeurologicMeasured) &&
        ClinicalValueParser.hasText(assessment.sofaRenalMeasured);
  }

  String? _diagnosisRequirementText(ClinicalAssessment assessment) {
    if (_shockInputsIncomplete(assessment)) {
      return 'Cần nhập MAP và lactate để đánh giá sốc nhiễm khuẩn';
    }
    if (!_sofaComplete(assessment)) {
      return 'Cần nhập đủ 6 hệ cơ quan để hoàn tất SOFA';
    }
    return null;
  }

  String _news2ConclusionText(ClinicalAssessment assessment) {
    if (!_news2Complete(assessment)) {
      return 'Cần nhập đủ 7 tiêu chí NEWS2 để hoàn tất tính điểm';
    }
    final guidance = ScaleGuidanceConfig.news2(assessment);
    return 'Điểm: NEWS2 ${assessment.news2Total}\nNguy cơ: ${guidance.risk}\nPhản ứng: ${guidance.response}';
  }

  String _qsofaConclusionText(ClinicalAssessment assessment) {
    if (!_qsofaComplete(assessment)) {
      return 'Cần nhập nhịp thở, huyết áp tâm thu và tri giác để hoàn tất qSOFA';
    }
    final guidance = ScaleGuidanceConfig.qsofa(assessment);
    return 'Điểm: qSOFA ${assessment.qsofaTotal}/3\nNguy cơ: ${guidance.risk}\nPhản ứng: ${guidance.response}';
  }

  String _sofaConclusionText(ClinicalAssessment assessment) {
    if (!_sofaComplete(assessment)) {
      return 'Cần nhập đủ 6 hệ cơ quan để hoàn tất SOFA';
    }
    final guidance = ScaleGuidanceConfig.sofa(assessment);
    return 'Điểm: SOFA ${assessment.sofaTotal}\nNguy cơ: ${guidance.risk}\nPhản ứng: ${guidance.response}';
  }

  Widget _clinicalDashboard(ClinicalAssessment assessment) {
    final theme = Theme.of(context);
    final displays = [
      AssessmentDisplay.news2ScoreDisplay(assessment),
      AssessmentDisplay.qsofaScoreDisplay(assessment),
      AssessmentDisplay.sofaScoreDisplay(assessment),
    ];
    final missingItems = AssessmentDisplay.allMissingItems(assessment);
    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            if (compact) {
              return _compactClinicalDashboard(displays, missingItems);
            }
            final cards = [
              for (final display in displays)
                SizedBox(
                  width: (constraints.maxWidth - 24) / 3,
                  child: clinical_ui.ClinicalSummaryCard(
                    display: display,
                    onTap: () => _scrollToSection(_sectionForDisplay(display)),
                  ),
                ),
            ];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < cards.length; i++) ...[
                        cards[i],
                        if (i < cards.length - 1) const SizedBox(width: 12),
                      ],
                    ],
                  ),
                ),
                if (missingItems.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  clinical_ui.MissingDataPanel(
                    items: missingItems,
                    onItemTap: _jumpToMissingItem,
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _compactClinicalDashboard(
    List<ScoreDisplay> displays,
    List<MissingDataItem> missingItems,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            for (var i = 0; i < displays.length; i++) ...[
              Expanded(child: _compactScoreTile(displays[i])),
              if (i < displays.length - 1) const SizedBox(width: 6),
            ],
          ],
        ),
        if (missingItems.isNotEmpty) ...[
          const SizedBox(height: 8),
          _compactMissingDataButton(missingItems),
        ],
      ],
    );
  }

  Widget _compactScoreTile(ScoreDisplay display) {
    final style = clinical_ui.clinicalStatusStyle(context, display.status);
    final theme = Theme.of(context);
    return Tooltip(
      message:
          '${display.title}: ${display.statusLabel}. ${display.helperText}',
      child: Material(
        color: style.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: style.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _scrollToSection(_sectionForDisplay(display)),
          child: SizedBox(
            height: 52,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(style.icon, size: 13, color: style.foreground),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          display.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: style.foreground,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    display.scoreText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: style.foreground,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _compactMissingDataButton(List<MissingDataItem> missingItems) {
    final theme = Theme.of(context);
    final style =
        clinical_ui.clinicalStatusStyle(context, ClinicalStatus.missing);
    return Material(
      color: style.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: style.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showMissingDataSheet(missingItems),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            children: [
              Icon(Icons.playlist_add_check_circle_outlined,
                  size: 18, color: style.foreground),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cần bổ sung ${missingItems.length} dữ liệu',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: style.foreground,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                'Xem',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMissingDataSheet(List<MissingDataItem> missingItems) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SingleChildScrollView(
              child: clinical_ui.MissingDataPanel(
                items: missingItems,
                onItemTap: (item) {
                  Navigator.of(context).pop();
                  _jumpToMissingItem(item);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _quickSectionCard(
    String title, {
    required List<Widget> children,
    String? subtitle,
    String? sectionId,
    SectionProgress? progress,
  }) {
    final theme = Theme.of(context);
    final card = clinical_ui.ClinicalSurfaceCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.18,
                  ),
                ),
              ),
              if (progress != null) ...[
                const SizedBox(width: 10),
                _quickProgressPill(progress),
              ],
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.25,
              ),
            ),
          ],
          const SizedBox(height: 14),
          ..._withVerticalSpacing(children, spacing: 14),
        ],
      ),
    );
    if (sectionId == null) {
      return card;
    }
    return KeyedSubtree(
      key: _sectionKey(sectionId),
      child: card,
    );
  }

  List<Widget> _withVerticalSpacing(
    List<Widget> children, {
    required double spacing,
  }) {
    final spaced = <Widget>[];
    for (final child in children) {
      if (spaced.isNotEmpty) {
        spaced.add(SizedBox(height: spacing));
      }
      spaced.add(child);
    }
    return spaced;
  }

  Widget _quickProgressPill(SectionProgress progress) {
    final theme = Theme.of(context);
    final tone =
        progress.complete ? _clinicalTones.success : _clinicalTones.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: tone.background,
        border: Border.all(color: tone.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${progress.completedCount}/${progress.totalCount}',
        style: theme.textTheme.labelSmall?.copyWith(
          color: tone.foreground,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _quickFieldGrid({
    required bool twoColumns,
    required List<Widget> children,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final availableWidth = constraints.maxWidth;
        final itemWidth =
            twoColumns ? (availableWidth - spacing) / 2 : availableWidth;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(
                width: child is _FullWidth || !twoColumns
                    ? availableWidth
                    : itemWidth,
                child: child is _FullWidth ? child.child : child,
              ),
          ],
        );
      },
    );
  }

  Widget _quickNews2Section(ClinicalAssessment assessment) {
    final spo2Options = assessment.news2Spo2Scale2
        ? const [
            _QuickScoreOption('88 - 92%', 0),
            _QuickScoreOption('86 - 87% hoặc 93 - 94%', 1),
            _QuickScoreOption('84 - 85% hoặc 95 - 96%', 2),
            _QuickScoreOption('≤ 83% hoặc ≥ 97%', 3),
          ]
        : const [
            _QuickScoreOption('≥ 96%', 0),
            _QuickScoreOption('94 - 95%', 1),
            _QuickScoreOption('92 - 93%', 2),
            _QuickScoreOption('≤ 91%', 3),
          ];
    return _quickSectionCard(
      '2. NEWS2/qSOFA - đánh giá nhanh',
      sectionId: AssessmentSections.news2,
      progress: AssessmentDisplay.news2Progress(assessment),
      children: [
        _quickSpo2ScaleCard(assessment),
        _quickScoreGroup(
          title: 'Nhịp thở (lần/phút)',
          selected: assessment.news2RespirationSelected,
          score: assessment.news2Respiration,
          fieldId: AssessmentFields.respiration,
          options: const [
            _QuickScoreOption('12 - 20', 0),
            _QuickScoreOption('9 - 11', 1),
            _QuickScoreOption('21 - 24', 2),
            _QuickScoreOption('≤ 8 hoặc ≥ 25', 3),
          ],
          onSelected: (score) => _mutate((a) {
            a.news2Respiration = score;
            a.news2RespirationSelected = true;
          }),
          onClear: () => _mutate((a) => a.news2RespirationSelected = false),
        ),
        _quickScoreGroup(
          title: assessment.news2Spo2Scale2
              ? 'SpO2 (%) - Thang 2'
              : 'SpO2 (%) - Thang 1',
          subtitle: assessment.news2Spo2Scale2
              ? 'Bệnh nhân có nguy cơ suy hô hấp tăng CO2'
              : 'Bệnh nhân không có nguy cơ suy hô hấp tăng CO2',
          selected: assessment.news2Spo2Selected,
          score: assessment.news2Spo2,
          fieldId: AssessmentFields.spo2,
          options: spo2Options,
          onSelected: (score) => _mutate((a) {
            a.news2Spo2 = score;
            a.news2Spo2Selected = true;
          }),
          onClear: () => _mutate((a) => a.news2Spo2Selected = false),
        ),
        _quickScoreGroup(
          title: 'Hỗ trợ hô hấp',
          selected: assessment.news2OxygenSelected,
          score: assessment.news2Oxygen,
          fieldId: AssessmentFields.oxygen,
          options: const [
            _QuickScoreOption('Thở khí phòng', 0),
            _QuickScoreOption('Thở Oxy', 2),
          ],
          onSelected: (score) => _mutate((a) {
            a.news2Oxygen = score;
            a.news2OxygenSelected = true;
          }),
          onClear: () => _mutate((a) => a.news2OxygenSelected = false),
        ),
        _quickScoreGroup(
          title: 'Huyết áp tâm thu (mmHg)',
          selected: assessment.news2SystolicBpSelected,
          score: assessment.news2SystolicBp,
          fieldId: AssessmentFields.systolicBp,
          options: const [
            _QuickScoreOption('111 - 219', 0),
            _QuickScoreOption('101 - 110', 1),
            _QuickScoreOption('91 - 100', 2),
            _QuickScoreOption('≤ 90 hoặc ≥ 220', 3),
          ],
          onSelected: (score) => _mutate((a) {
            a.news2SystolicBp = score;
            a.news2SystolicBpSelected = true;
          }),
          onClear: () => _mutate((a) => a.news2SystolicBpSelected = false),
        ),
        _quickScoreGroup(
          title: 'Nhịp tim (lần/phút)',
          selected: assessment.news2HeartRateSelected,
          score: assessment.news2HeartRate,
          fieldId: AssessmentFields.heartRate,
          options: const [
            _QuickScoreOption('51 - 90', 0),
            _QuickScoreOption('41 - 50 hoặc 91 - 110', 1),
            _QuickScoreOption('111 - 130', 2),
            _QuickScoreOption('≤ 40 hoặc ≥ 131', 3),
          ],
          onSelected: (score) => _mutate((a) {
            a.news2HeartRate = score;
            a.news2HeartRateSelected = true;
          }),
          onClear: () => _mutate((a) => a.news2HeartRateSelected = false),
        ),
        _quickScoreGroup(
          title: 'Nhiệt độ (°C)',
          selected: assessment.news2TemperatureSelected,
          score: assessment.news2Temperature,
          fieldId: AssessmentFields.temperature,
          options: const [
            _QuickScoreOption('36.1 - 38.0', 0),
            _QuickScoreOption('35.1 - 36.0 hoặc 38.1 - 39.0', 1),
            _QuickScoreOption('≥ 39.1', 2),
            _QuickScoreOption('≤ 35.0', 3),
          ],
          onSelected: (score) => _mutate((a) {
            a.news2Temperature = score;
            a.news2TemperatureSelected = true;
          }),
          onClear: () => _mutate((a) => a.news2TemperatureSelected = false),
        ),
        _quickScoreGroup(
          title: 'Tri giác (AVPU)',
          selected: assessment.news2ConsciousnessSelected,
          score: assessment.news2Consciousness,
          fieldId: AssessmentFields.consciousness,
          options: const [
            _QuickScoreOption('A - Tỉnh', 0),
            _QuickScoreOption('C / V / P / U', 3),
          ],
          onSelected: (score) => _mutate((a) {
            a.news2Consciousness = score;
            a.news2ConsciousnessSelected = true;
          }),
          onClear: () => _mutate((a) => a.news2ConsciousnessSelected = false),
        ),
        _quickSubheading('qSOFA'),
        _quickScoreGroup(
          title: 'Nhịp thở ≥ 22 lần/phút',
          selected: assessment.qsofaRespirationSelected,
          score: assessment.qsofaRespiration ? 1 : 0,
          fieldId: AssessmentFields.qsofaRespiration,
          options: const [
            _QuickScoreOption('Không', 0),
            _QuickScoreOption('Có', 1),
          ],
          onSelected: (score) => _mutate((a) {
            a.qsofaRespiration = score == 1;
            a.qsofaRespirationSelected = true;
          }),
          onClear: () => _mutate((a) => a.qsofaRespirationSelected = false),
        ),
        _quickScoreGroup(
          title: 'Huyết áp tâm thu ≤ 100 mmHg',
          selected: assessment.qsofaSystolicBpSelected,
          score: assessment.qsofaSystolicBp ? 1 : 0,
          fieldId: AssessmentFields.qsofaSystolicBp,
          options: const [
            _QuickScoreOption('Không', 0),
            _QuickScoreOption('Có', 1),
          ],
          onSelected: (score) => _mutate((a) {
            a.qsofaSystolicBp = score == 1;
            a.qsofaSystolicBpSelected = true;
          }),
          onClear: () => _mutate((a) => a.qsofaSystolicBpSelected = false),
        ),
        _quickScoreGroup(
          title: 'Rối loạn ý thức',
          selected: assessment.qsofaConsciousnessSelected,
          score: assessment.qsofaConsciousness ? 1 : 0,
          fieldId: AssessmentFields.qsofaConsciousness,
          options: const [
            _QuickScoreOption('Không', 0),
            _QuickScoreOption('Có', 1),
          ],
          onSelected: (score) => _mutate((a) {
            a.qsofaConsciousness = score == 1;
            a.qsofaConsciousnessSelected = true;
          }),
          onClear: () => _mutate((a) => a.qsofaConsciousnessSelected = false),
        ),
        _miniScores([
          _ScoreItem(
            'Nhịp thở',
            assessment.news2Respiration,
            completed: assessment.news2RespirationSelected,
          ),
          _ScoreItem(
            'HA',
            assessment.news2SystolicBp,
            completed: assessment.news2SystolicBpSelected,
          ),
          _ScoreItem(
            'Tri giác',
            assessment.news2Consciousness,
            completed: assessment.news2ConsciousnessSelected,
          ),
          _ScoreItem(
            'SpO2',
            assessment.news2Spo2,
            completed: assessment.news2Spo2Selected,
          ),
          _ScoreItem(
            'Oxy',
            assessment.news2Oxygen,
            completed: assessment.news2OxygenSelected,
          ),
          _ScoreItem(
            'Nhiệt',
            assessment.news2Temperature,
            completed: assessment.news2TemperatureSelected,
          ),
          _ScoreItem(
            'Mạch',
            assessment.news2HeartRate,
            completed: assessment.news2HeartRateSelected,
          ),
        ]),
        _readOnlyLine(
          'Kết luận NEWS2',
          _news2ConclusionText(assessment),
          tone: _news2Tone(assessment),
          maxLines: 9,
        ),
        _readOnlyLine(
          'Kết luận qSOFA',
          _qsofaConclusionText(assessment),
          tone: _qsofaTone(assessment),
          maxLines: 5,
        ),
      ],
    );
  }

  Widget _quickHemodynamicsSection(
    ClinicalAssessment assessment, {
    required bool twoColumns,
  }) {
    return _quickSectionCard(
      '3. Lactate & huyết động',
      sectionId: AssessmentSections.lactate,
      progress: AssessmentDisplay.lactateProgress(assessment),
      children: [
        _quickLactateLevelGroup(assessment),
        _quickFieldGrid(
          twoColumns: twoColumns,
          children: [
            _field('Thời gian lấy mẫu lactate', assessment.lactateSampleTime,
                (value) {
              assessment.lactateSampleTime = value;
            },
                fieldId: AssessmentFields.lactateSampleTime,
                hint: 'HH:mm',
                keyboardType: TextInputType.datetime,
                inputFormatters: _timeInputFormatters),
            _field('Tim mạch - MAP/Vận mạch (mmHg; thuốc/liều)',
                assessment.sofaCardiovascularMeasured, (value) {
              assessment.sofaCardiovascularMeasured = value;
            },
                fieldId: AssessmentFields.cardiovascular,
                scoreText: _scoreText(
                  assessment.sofaCardiovascularMeasured,
                  'Điểm SOFA tim mạch: ${assessment.sofaCardiovascular}',
                ),
                scoreStatus: _scoreStatus(assessment.sofaCardiovascular),
                hint: 'VD: MAP 65 hoặc norepi 0.2'),
            _toggleTile(
              'Có dùng vận mạch',
              assessment.vasopressor,
              (value) => _mutate((a) => a.vasopressor = value),
            ),
          ],
        ),
        _readOnlyLine(
          'Phân mức Lactate',
          assessment.lactateLevel.isEmpty
              ? 'Chưa nhập lactate'
              : assessment.lactateLevel,
          tone: _lactateComplete(assessment) ? null : _clinicalTones.muted,
        ),
      ],
    );
  }

  Widget _quickLactateLevelGroup(ClinicalAssessment assessment) {
    return _quickChoiceGroup(
      title: 'Lactate tĩnh mạch',
      subtitle: 'Chọn nhanh phân mức lactate lúc phân loại/giờ đầu',
      selectedValue: assessment.lactateLevel,
      fieldId: AssessmentFields.lactate,
      options: const [
        _QuickChoiceOption('< 2 mmol/L', '< 2 mmol/L', 'Bình thường'),
        _QuickChoiceOption('2 - 3.9 mmol/L', '2 - 3.9 mmol/L', 'Tăng'),
        _QuickChoiceOption('≥ 4 mmol/L', '≥ 4 mmol/L', 'Cao'),
      ],
      onSelected: (value) => _mutate((a) {
        a.lactate = '';
        a.lactateLevel = value;
      }),
      onClear: () => _mutate((a) {
        a.lactate = '';
        a.lactateLevel = '';
      }),
    );
  }

  Widget _quickSofaSection(ClinicalAssessment assessment) {
    const sofaRespirationOptions = [
      _QuickScoreOption('PaO2/FiO2 ≥ 400', 0),
      _QuickScoreOption('PaO2/FiO2 < 400', 1),
      _QuickScoreOption('PaO2/FiO2 < 300', 2),
      _QuickScoreOption('< 200 + hỗ trợ hô hấp', 3),
      _QuickScoreOption('< 100 + hỗ trợ hô hấp', 4),
    ];
    const sofaCoagulationOptions = [
      _QuickScoreOption('Tiểu cầu ≥ 150', 0),
      _QuickScoreOption('Tiểu cầu < 150', 1),
      _QuickScoreOption('Tiểu cầu < 100', 2),
      _QuickScoreOption('Tiểu cầu < 50', 3),
      _QuickScoreOption('Tiểu cầu < 20', 4),
    ];
    const sofaLiverOptions = [
      _QuickScoreOption('Bilirubin < 1.2', 0),
      _QuickScoreOption('Bilirubin 1.2 - 1.9', 1),
      _QuickScoreOption('Bilirubin 2.0 - 5.9', 2),
      _QuickScoreOption('Bilirubin 6.0 - 11.9', 3),
      _QuickScoreOption('Bilirubin ≥ 12.0', 4),
    ];
    const sofaCardiovascularOptions = [
      _QuickScoreOption('MAP ≥ 70', 0),
      _QuickScoreOption('MAP < 70', 1),
      _QuickScoreOption('Dopamine ≤ 5 hoặc dobutamine', 2),
      _QuickScoreOption('Dopamine > 5 hoặc norepi/epi ≤ 0.1', 3),
      _QuickScoreOption('Dopamine > 15 hoặc norepi/epi > 0.1', 4),
    ];
    const sofaNeurologicOptions = [
      _QuickScoreOption('GCS 15', 0),
      _QuickScoreOption('GCS 13 - 14', 1),
      _QuickScoreOption('GCS 10 - 12', 2),
      _QuickScoreOption('GCS 6 - 9', 3),
      _QuickScoreOption('GCS < 6', 4),
    ];
    const sofaRenalOptions = [
      _QuickScoreOption('Creatinin < 1.2', 0),
      _QuickScoreOption('Creatinin 1.2 - 1.9', 1),
      _QuickScoreOption('Creatinin 2.0 - 3.4', 2),
      _QuickScoreOption('Creatinin 3.5 - 4.9 hoặc nước tiểu < 500 mL', 3),
      _QuickScoreOption('Creatinin ≥ 5.0 hoặc nước tiểu < 200 mL', 4),
    ];
    return _quickSectionCard(
      '4. SOFA 24 giờ - chọn điểm nhanh',
      sectionId: AssessmentSections.sofa,
      progress: AssessmentDisplay.sofaProgress(assessment),
      children: [
        _quickScoreGroup(
          title: 'Hô hấp',
          selected: assessment.sofaRespirationSelected,
          score: assessment.sofaRespiration,
          fieldId: AssessmentFields.sofaRespiration,
          options: sofaRespirationOptions,
          minTileWidth: 132,
          onSelected: (score) => _mutate((a) {
            a.sofaRespiration = score;
            a.sofaRespirationSelected = true;
          }),
          onClear: () => _mutate((a) => a.sofaRespirationSelected = false),
        ),
        _quickScoreGroup(
          title: 'Đông máu',
          selected: assessment.sofaCoagulationSelected,
          score: assessment.sofaCoagulation,
          fieldId: AssessmentFields.sofaCoagulation,
          options: sofaCoagulationOptions,
          minTileWidth: 132,
          onSelected: (score) => _mutate((a) {
            a.sofaCoagulation = score;
            a.sofaCoagulationSelected = true;
          }),
          onClear: () => _mutate((a) => a.sofaCoagulationSelected = false),
        ),
        _quickScoreGroup(
          title: 'Gan',
          selected: assessment.sofaLiverSelected,
          score: assessment.sofaLiver,
          fieldId: AssessmentFields.sofaLiver,
          subtitle: 'Bilirubin theo mg/dL',
          options: sofaLiverOptions,
          minTileWidth: 132,
          onSelected: (score) => _mutate((a) {
            a.sofaLiver = score;
            a.sofaLiverSelected = true;
          }),
          onClear: () => _mutate((a) => a.sofaLiverSelected = false),
        ),
        _quickScoreGroup(
          title: 'Tim mạch',
          selected: assessment.sofaCardiovascularSelected,
          score: assessment.sofaCardiovascular,
          fieldId: AssessmentFields.sofaCardiovascularScore,
          subtitle: 'Liều vận mạch theo µg/kg/phút',
          options: sofaCardiovascularOptions,
          minTileWidth: 132,
          onSelected: (score) => _mutate((a) {
            a.sofaCardiovascular = score;
            a.sofaCardiovascularSelected = true;
          }),
          onClear: () => _mutate((a) => a.sofaCardiovascularSelected = false),
        ),
        _quickScoreGroup(
          title: 'Thần kinh',
          selected: assessment.sofaNeurologicSelected,
          score: assessment.sofaNeurologic,
          fieldId: AssessmentFields.sofaNeurologic,
          options: sofaNeurologicOptions,
          minTileWidth: 132,
          onSelected: (score) => _mutate((a) {
            a.sofaNeurologic = score;
            a.sofaNeurologicSelected = true;
          }),
          onClear: () => _mutate((a) => a.sofaNeurologicSelected = false),
        ),
        _quickScoreGroup(
          title: 'Thận',
          selected: assessment.sofaRenalSelected,
          score: assessment.sofaRenal,
          fieldId: AssessmentFields.sofaRenal,
          subtitle: 'Creatinin theo mg/dL hoặc nước tiểu/24 giờ',
          options: sofaRenalOptions,
          minTileWidth: 132,
          onSelected: (score) => _mutate((a) {
            a.sofaRenal = score;
            a.sofaRenalSelected = true;
          }),
          onClear: () => _mutate((a) => a.sofaRenalSelected = false),
        ),
        _miniScores([
          _ScoreItem(
            'Hô hấp',
            assessment.sofaRespiration,
            completed: assessment.sofaRespirationSelected,
          ),
          _ScoreItem(
            'Đông máu',
            assessment.sofaCoagulation,
            completed: assessment.sofaCoagulationSelected,
          ),
          _ScoreItem(
            'Gan',
            assessment.sofaLiver,
            completed: assessment.sofaLiverSelected,
          ),
          _ScoreItem(
            'Tim mạch',
            assessment.sofaCardiovascular,
            completed: assessment.sofaCardiovascularSelected,
          ),
          _ScoreItem(
            'Thần kinh',
            assessment.sofaNeurologic,
            completed: assessment.sofaNeurologicSelected,
          ),
          _ScoreItem(
            'Thận',
            assessment.sofaRenal,
            completed: assessment.sofaRenalSelected,
          ),
        ]),
        _readOnlyLine(
          'Ngưỡng Sepsis-3',
          _sofaComplete(assessment)
              ? sofaThresholdText(assessment)
              : _missingSentence(AssessmentDisplay.sofaProgress(assessment)),
          tone: _sofaThresholdTone(assessment),
        ),
        _readOnlyLine(
          'Kết luận SOFA',
          _sofaConclusionText(assessment),
          tone: _sofaTone(assessment),
          maxLines: 5,
        ),
      ],
    );
  }

  Widget _quickSpo2ScaleCard(ClinicalAssessment assessment) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return clinical_ui.ClinicalSurfaceCard(
      color: scheme.primaryContainer.withValues(alpha: 0.35),
      borderColor: scheme.primary.withValues(alpha: 0.18),
      radius: 16,
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Row(
        children: [
          Icon(
            Icons.air_outlined,
            color: scheme.primary,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bệnh nhân có suy hô hấp?',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Bật nếu bệnh nhân có tiền sử suy hô hấp do tăng CO2 máu.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onPrimaryContainer.withValues(alpha: 0.78),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: assessment.news2Spo2Scale2,
            onChanged: (value) => _mutate((a) => a.news2Spo2Scale2 = value),
          ),
        ],
      ),
    );
  }

  Widget _quickSubheading(String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _quickScoreGroup({
    required String title,
    required bool selected,
    required int score,
    required List<_QuickScoreOption> options,
    required ValueChanged<int> onSelected,
    required VoidCallback onClear,
    String? subtitle,
    String? fieldId,
    double minTileWidth = 112,
  }) {
    final theme = Theme.of(context);
    final selector = clinical_ui.ClinicalSurfaceCard(
      radius: 16,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.25,
              ),
            ),
          ],
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 10.0;
              final columns = _quickScoreColumnCount(
                constraints.maxWidth,
                options.length,
                minTileWidth: minTileWidth,
              );
              final tileWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final option in options)
                    SizedBox(
                      width: tileWidth,
                      child: _quickScoreTile(
                        option: option,
                        selected: selected && score == option.score,
                        onSelected: () => onSelected(option.score),
                        onClear: onClear,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
    if (fieldId == null) {
      return selector;
    }
    return KeyedSubtree(
      key: _fieldKey(fieldId),
      child: selector,
    );
  }

  Widget _quickChoiceGroup({
    required String title,
    required String selectedValue,
    required List<_QuickChoiceOption> options,
    required ValueChanged<String> onSelected,
    required VoidCallback onClear,
    String? subtitle,
    String? fieldId,
  }) {
    final theme = Theme.of(context);
    final selector = clinical_ui.ClinicalSurfaceCard(
      radius: 16,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.25,
              ),
            ),
          ],
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 10.0;
              final columns = _quickScoreColumnCount(
                constraints.maxWidth,
                options.length,
                minTileWidth: 112,
              );
              final tileWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final option in options)
                    SizedBox(
                      width: tileWidth,
                      child: _quickChoiceTile(
                        option: option,
                        selected: selectedValue == option.value,
                        onSelected: () => onSelected(option.value),
                        onClear: onClear,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
    if (fieldId == null) {
      return selector;
    }
    return KeyedSubtree(
      key: _fieldKey(fieldId),
      child: selector,
    );
  }

  Widget _quickChoiceTile({
    required _QuickChoiceOption option,
    required bool selected,
    required VoidCallback onSelected,
    required VoidCallback onClear,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tone = selected ? _clinicalTones.attention : null;
    return clinical_ui.ClinicalSurfaceCard(
      color: tone?.background ?? scheme.surfaceContainerLowest,
      borderColor: tone?.border ?? scheme.outlineVariant,
      radius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      onTap: selected ? onClear : onSelected,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 68),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              option.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tone?.foreground ?? scheme.onSurface,
                fontWeight: FontWeight.w900,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              option.helper,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: tone?.foreground ??
                    scheme.onSurfaceVariant.withValues(alpha: 0.72),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _quickScoreColumnCount(
    double width,
    int optionCount, {
    required double minTileWidth,
  }) {
    const spacing = 10.0;
    var columns = ((width + spacing) / (minTileWidth + spacing)).floor();
    if (columns < 1) {
      columns = 1;
    }
    final maxColumns = width >= 760
        ? 5
        : width >= 520
            ? 4
            : width >= 340
                ? 3
                : width >= 220
                    ? 2
                    : 1;
    if (columns > maxColumns) {
      columns = maxColumns;
    }
    return columns > optionCount ? optionCount : columns;
  }

  Widget _quickScoreTile({
    required _QuickScoreOption option,
    required bool selected,
    required VoidCallback onSelected,
    required VoidCallback onClear,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tone = selected ? _componentScoreTone(option.score) : null;
    return clinical_ui.ClinicalSurfaceCard(
      color: tone?.background ?? scheme.surfaceContainerLowest,
      borderColor: tone?.border ?? scheme.outlineVariant,
      radius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      onTap: selected ? onClear : onSelected,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 68),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              option.label,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tone?.foreground ?? scheme.onSurface,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '${option.score} điểm',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: tone?.foreground ??
                    scheme.onSurfaceVariant.withValues(alpha: 0.72),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(
    String title, {
    required String sectionId,
    required SectionProgress progress,
    required List<Widget> children,
    required bool twoColumns,
  }) {
    final expanded = _expandedSections.contains(sectionId);
    return KeyedSubtree(
      key: _sectionKey(sectionId),
      child: clinical_ui.FormSectionAccordion(
        key: ValueKey('$sectionId-$expanded-$_formVersion'),
        title: title,
        progress: progress,
        initiallyExpanded: expanded,
        onExpansionChanged: (value) {
          setState(() {
            if (value) {
              _expandedSections.add(sectionId);
            } else {
              _expandedSections.remove(sectionId);
            }
          });
        },
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 12.0;
              final availableWidth = constraints.maxWidth;
              final itemWidth =
                  twoColumns ? (availableWidth - spacing) / 2 : availableWidth;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final child in children)
                    SizedBox(
                      width: child is _FullWidth || !twoColumns
                          ? availableWidth
                          : itemWidth,
                      child: child is _FullWidth ? child.child : child,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _diagnosisOutcomeCard(
    ClinicalAssessment assessment, {
    required bool twoColumns,
  }) {
    final theme = Theme.of(context);
    final children = [
      _fullWidth(_sepsisDiagnosisOptions(assessment)),
      DropdownButtonFormField<String>(
        initialValue: assessment.treatmentOutcome.isEmpty
            ? null
            : assessment.treatmentOutcome,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Kết quả điều trị'),
        items: const [
          DropdownMenuItem(
            value: 'Khỏi / Đỡ ra viện',
            child: Text('Khỏi / Đỡ ra viện'),
          ),
          DropdownMenuItem(
            value: 'Chuyển viện',
            child: Text('Chuyển viện'),
          ),
          DropdownMenuItem(
            value: 'Nặng xin về / Tử vong',
            child: Text('Nặng xin về / Tử vong'),
          ),
        ],
        onChanged: (value) => _mutate((a) => a.treatmentOutcome = value ?? ''),
      ),
      _field('Số ngày điều trị', assessment.treatmentDays, (value) {
        assessment.treatmentDays = value;
      },
          unitOptions: const ['ngày'],
          keyboardType: TextInputType.number,
          inputFormatters: _integerInputFormatters),
    ];
    return KeyedSubtree(
      key: _sectionKey(AssessmentSections.diagnosis),
      child: clinical_ui.ClinicalSurfaceCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.assignment_turned_in_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '5. Chẩn đoán & kết cục',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 12.0;
                final availableWidth = constraints.maxWidth;
                final itemWidth = twoColumns
                    ? (availableWidth - spacing) / 2
                    : availableWidth;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final child in children)
                      SizedBox(
                        width: child is _FullWidth || !twoColumns
                            ? availableWidth
                            : itemWidth,
                        child: child is _FullWidth ? child.child : child,
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _fullWidth(Widget child) => _FullWidth(child: child);

  Widget _toggleTile(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final theme = Theme.of(context);
    return clinical_ui.ClinicalSurfaceCard(
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Icon(
            value ? Icons.check_circle : Icons.radio_button_unchecked,
            color: value
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    String value,
    void Function(String value) onChanged, {
    String? fieldId,
    String? unit,
    String? helperText,
    String? warningText,
    String? scoreText,
    ClinicalStatus scoreStatus = ClinicalStatus.normal,
    List<String>? unitOptions,
    String? selectedUnit,
    ValueChanged<String>? onUnitChanged,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    String? hint,
  }) {
    final field = clinical_ui.MedicalInputField(
      label: label,
      value: value,
      unit: unit,
      helperText: helperText,
      warningText: warningText,
      scoreText: scoreText,
      scoreStatus: scoreStatus,
      hintText: hint,
      unitOptions: unitOptions,
      selectedUnit: selectedUnit,
      onUnitChanged: onUnitChanged == null
          ? null
          : (unit) => _mutate((_) => onUnitChanged(unit)),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      focusNode: fieldId == null ? null : _focusNode(fieldId),
      onChanged: (newValue) => _mutate((_) => onChanged(newValue)),
    );
    if (fieldId == null) {
      return field;
    }
    return KeyedSubtree(
      key: _fieldKey(fieldId),
      child: field,
    );
  }

  Widget _sepsisDiagnosisOptions(ClinicalAssessment assessment) {
    final theme = Theme.of(context);
    final tone = _diagnosisTone(assessment);
    final sofaComplete = _sofaComplete(assessment);
    final hasSepsis = sofaComplete && SofaScoring.hasSepsisBySofa(assessment);
    final hasNoSepsis = sofaComplete && !hasSepsis;
    final hasShock = SofaScoring.hasSepticShock(assessment);
    final requirement = _diagnosisRequirementText(assessment);

    return clinical_ui.ClinicalSurfaceCard(
      color: tone.background,
      borderColor: tone.border,
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chẩn đoán xác định (Theo Sepsis-3)',
            style: theme.textTheme.labelMedium?.copyWith(
              color: tone.foreground,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          _diagnosisCheckboxRow(
            'Có Nhiễm khuẩn huyết (SOFA ≥ 2)',
            checked: hasSepsis,
            tone: tone,
          ),
          _diagnosisCheckboxRow(
            'Không Nhiễm khuẩn huyết (SOFA < 2)',
            checked: hasNoSepsis,
            tone: tone,
          ),
          _diagnosisCheckboxRow(
            'Sốc nhiễm khuẩn (Dùng vận mạch duy trì MAP ≥ 65 và Lactate ≥ 2 mmol/L dù đã bù dịch)',
            checked: hasShock,
            tone: tone,
          ),
          if (requirement != null) ...[
            const SizedBox(height: 8),
            Text(
              requirement,
              style: theme.textTheme.bodySmall?.copyWith(
                color: tone.foreground,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _diagnosisCheckboxRow(
    String label, {
    required bool checked,
    required RiskTone tone,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            checked ? Icons.check_box : Icons.check_box_outline_blank,
            size: 18,
            color: tone.foreground,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: tone.foreground,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _readOnlyLine(
    String label,
    String value, {
    RiskTone? tone,
    int maxLines = 2,
  }) {
    final theme = Theme.of(context);
    final lineTone = tone ?? _clinicalTones.neutral;
    return clinical_ui.ClinicalSurfaceCard(
      color: lineTone.background,
      borderColor: lineTone.border,
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(lineTone.icon, size: 17, color: lineTone.foreground),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: lineTone.foreground,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? 'Chưa nhập dữ liệu' : value,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: lineTone.foreground,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _qsofaChecklist(ClinicalAssessment assessment) {
    return Column(
      children: [
        _readonlyCheck(
          'Nhịp thở ≥ 22 lần/phút',
          assessment.qsofaRespiration,
          ClinicalValueParser.hasText(assessment.news2RespirationMeasured),
        ),
        const SizedBox(height: 6),
        _readonlyCheck(
          'Huyết áp tâm thu ≤ 100 mmHg',
          assessment.qsofaSystolicBp,
          ClinicalValueParser.hasText(assessment.news2SystolicBpMeasured),
        ),
        const SizedBox(height: 6),
        _readonlyCheck(
          'Rối loạn ý thức (GCS < 15 / AVPU khác A)',
          assessment.qsofaConsciousness,
          ClinicalValueParser.hasText(assessment.news2ConsciousnessMeasured),
        ),
      ],
    );
  }

  Widget _readonlyCheck(String label, bool checked, bool completed) {
    final theme = Theme.of(context);
    final tones = _clinicalTones;
    final tone = !completed
        ? tones.muted
        : checked
            ? tones.danger
            : tones.success;
    return clinical_ui.ClinicalSurfaceCard(
      color: tone.background,
      borderColor: tone.border,
      radius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Row(
        children: [
          Icon(
            !completed
                ? Icons.remove_circle_outline
                : checked
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
            color: tone.foreground,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: tone.foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            completed ? (checked ? '1' : '0') : '-',
            style: theme.textTheme.labelMedium?.copyWith(
              color: tone.foreground,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniScores(List<_ScoreItem> scores) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: scores.map(
        (score) {
          final tone = score.completed
              ? _componentScoreTone(score.score)
              : _clinicalTones.muted;
          return Chip(
            avatar: Icon(tone.icon, size: 16, color: tone.foreground),
            label: Text(
              score.completed
                  ? '${score.label} ${score.score}'
                  : '${score.label} -',
            ),
            backgroundColor: tone.background,
            side: BorderSide(color: tone.border),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            labelStyle: theme.textTheme.labelSmall?.copyWith(
              color: tone.foreground,
              fontWeight: FontWeight.w800,
            ),
          );
        },
      ).toList(),
    );
  }

  GlobalKey _sectionKey(String sectionId) {
    return _sectionKeys.putIfAbsent(sectionId, GlobalKey.new);
  }

  GlobalKey _fieldKey(String fieldId) {
    return _fieldKeys.putIfAbsent(fieldId, GlobalKey.new);
  }

  FocusNode _focusNode(String fieldId) {
    return _fieldFocusNodes.putIfAbsent(fieldId, FocusNode.new);
  }

  String _sectionForDisplay(ScoreDisplay display) {
    return switch (display.title) {
      'NEWS2' || 'qSOFA' => AssessmentSections.news2,
      'SOFA' => AssessmentSections.sofa,
      _ => AssessmentSections.diagnosis,
    };
  }

  void _jumpToMissingItem(MissingDataItem item) {
    setState(() {
      _expandedSections.add(item.sectionId);
      _formVersion++;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fieldContext = _fieldKeys[item.fieldId]?.currentContext;
      if (fieldContext != null) {
        Scrollable.ensureVisible(
          fieldContext,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: 0.18,
        );
        _fieldFocusNodes[item.fieldId]?.requestFocus();
        return;
      }
      _scrollToSection(item.sectionId);
    });
  }

  void _scrollToSection(String sectionId) {
    setState(() {
      _expandedSections.add(sectionId);
      _formVersion++;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sectionContext = _sectionKeys[sectionId]?.currentContext;
      if (sectionContext != null) {
        Scrollable.ensureVisible(
          sectionContext,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: 0.08,
        );
      }
    });
  }

  SectionProgress _patientProgress(ClinicalAssessment assessment) {
    final missing = <String>[
      if (!ClinicalValueParser.hasText(assessment.patientId)) 'Mã bệnh nhân',
      if (!ClinicalValueParser.hasText(assessment.fullName)) 'Họ và tên',
      if (!ClinicalValueParser.hasText(assessment.admissionDate))
        'Ngày nhập viện',
      if (!ClinicalValueParser.hasText(assessment.admissionTime))
        'Giờ nhập viện',
    ];
    return SectionProgress(
      sectionId: AssessmentSections.patient,
      completedCount: 4 - missing.length,
      totalCount: 4,
      missingLabels: missing,
    );
  }

  String _defaultOpenSection(ClinicalAssessment assessment) {
    final sections = [
      _patientProgress(assessment),
      AssessmentDisplay.news2Progress(assessment),
      AssessmentDisplay.lactateProgress(assessment),
      AssessmentDisplay.sofaProgress(assessment),
    ];
    return sections
        .firstWhere(
          (section) => !section.complete,
          orElse: () => sections.first,
        )
        .sectionId;
  }

  String? _scoreText(String value, String text) {
    return ClinicalValueParser.hasText(value) ? text : null;
  }

  ClinicalStatus _scoreStatus(int score) {
    if (score >= 3) {
      return ClinicalStatus.danger;
    }
    if (score >= 2) {
      return ClinicalStatus.warning;
    }
    if (score == 1) {
      return ClinicalStatus.watch;
    }
    return ClinicalStatus.normal;
  }

  String _missingSentence(SectionProgress progress) {
    if (progress.missingLabels.isEmpty) {
      return 'Đã đủ dữ liệu';
    }
    return 'Còn thiếu: ${progress.missingLabels.join(', ')}';
  }

  String? _rangeWarning(
    String value, {
    required double min,
    required double max,
    required String label,
  }) {
    final number = ClinicalValueParser.parseDouble(value);
    if (number == null) {
      return null;
    }
    if (number < min || number > max) {
      return '$label ngoài khoảng thường gặp, vui lòng kiểm tra lại';
    }
    return null;
  }

  String? _lactateWarning(String value) {
    final lactate = ClinicalValueParser.parseDouble(value);
    if (lactate == null) {
      return null;
    }
    if (lactate >= 4) {
      return 'Lactate cao, cần đánh giá tưới máu và sốc nhiễm khuẩn';
    }
    if (lactate >= 2) {
      return 'Lactate tăng, cần theo dõi sát';
    }
    return null;
  }

  String _selectedFieldUnit(
    String fieldId,
    String value,
    List<String> units, {
    String? savedUnit,
  }) {
    return _selectedUnit(value, units) ??
        _normalizeUnit(savedUnit, units) ??
        _fieldUnitSelections[fieldId] ??
        units.first;
  }

  String? _selectedUnit(String value, List<String> units) {
    final lower = value.toLowerCase();
    for (final unit in units) {
      if (lower.contains(unit.toLowerCase())) {
        return unit;
      }
      if (unit == 'µmol/L' && lower.contains('umol')) {
        return unit;
      }
    }
    return null;
  }

  String? _normalizeUnit(String? value, List<String> units) {
    if (value == null) {
      return null;
    }
    final lower = value.toLowerCase();
    for (final unit in units) {
      if (lower == unit.toLowerCase()) {
        return unit;
      }
      if (unit == 'µmol/L' && lower == 'umol/l') {
        return unit;
      }
    }
    return null;
  }

  String _replaceTrailingUnit(String value, String unit) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    final withoutUnit = trimmed
        .replaceAll(
            RegExp(r'\s*(mg/dl|µmol/l|umol/l)\s*$', caseSensitive: false), '')
        .trim();
    return '$withoutUnit $unit';
  }

  String _formatClock(int millis) {
    if (millis <= 0) {
      return '--:--';
    }
    final value = DateTime.fromMillisecondsSinceEpoch(millis);
    return '${_two(value.hour)}:${_two(value.minute)}';
  }

  bool _hasMeaningfulHistoryData(ClinicalAssessment assessment) {
    return _hasAnyClinicalData(assessment) ||
        _hasQuickScoreData(assessment) ||
        ClinicalValueParser.hasText(assessment.lactateLevel) ||
        ClinicalValueParser.hasText(assessment.news2RespirationMeasured) ||
        ClinicalValueParser.hasText(assessment.news2SystolicBpMeasured) ||
        ClinicalValueParser.hasText(assessment.news2HeartRateMeasured) ||
        ClinicalValueParser.hasText(assessment.lactate) ||
        ClinicalValueParser.hasText(assessment.sofaNeurologicMeasured) ||
        ClinicalValueParser.hasText(assessment.treatmentOutcome);
  }

  static ClinicalAssessment _newAssessment({
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

  static bool _hasAnyClinicalData(ClinicalAssessment assessment) {
    if (assessment.isQuickMode && _hasQuickScoreData(assessment)) {
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

  static bool _hasQuickScoreData(ClinicalAssessment assessment) {
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

  static String _buildAdmissionDateTime(ClinicalAssessment assessment) {
    return '${assessment.admissionTime}, ngày ${assessment.admissionDate}';
  }

  static String _lactateLevel(String value) {
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

  static String _dateText(DateTime value) {
    return '${value.year}-${_two(value.month)}-${_two(value.day)}';
  }

  static String _timeText(DateTime value) {
    return '${_two(value.hour)}:${_two(value.minute)}';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}

class _PatientSummary {
  final int total;
  final int incomplete;
  final int highRisk;
  final int shock;

  const _PatientSummary({
    required this.total,
    required this.incomplete,
    required this.highRisk,
    required this.shock,
  });

  const _PatientSummary.empty()
      : total = 0,
        incomplete = 0,
        highRisk = 0,
        shock = 0;

  factory _PatientSummary.from(List<SavedAssessment> patients) {
    var incomplete = 0;
    var highRisk = 0;
    var shock = 0;
    for (final saved in patients) {
      final assessment = saved.assessment;
      if (AssessmentDisplay.isIncompletePatient(assessment)) {
        incomplete++;
      }
      if (AssessmentDisplay.isHighRiskPatient(assessment)) {
        highRisk++;
      }
      if (AssessmentDisplay.isSepticShockPatient(assessment)) {
        shock++;
      }
    }
    return _PatientSummary(
      total: patients.length,
      incomplete: incomplete,
      highRisk: highRisk,
      shock: shock,
    );
  }
}

class _PatientScrollBubbleState {
  final bool visible;
  final String label;
  final double fraction;

  const _PatientScrollBubbleState({
    required this.visible,
    required this.label,
    required this.fraction,
  });

  const _PatientScrollBubbleState.hidden()
      : visible = false,
        label = '',
        fraction = 0;
}

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
