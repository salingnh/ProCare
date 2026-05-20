import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:share_plus/share_plus.dart';

import 'src/data/assessment_repository.dart';
import 'src/domain/assessment_display.dart';
import 'src/domain/clinical_assessment.dart';
import 'src/domain/clinical_value_parser.dart';
import 'src/domain/scale_guidance_config.dart';
import 'src/domain/scoring.dart';
import 'src/export/crf_exporter.dart';
import 'src/services/update_service.dart';
import 'src/ui/clinical_components.dart' as clinical_ui;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const News2LApp());
}

class News2LApp extends StatelessWidget {
  const News2LApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF00796B),
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NEWS2-L',
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: colorScheme.surface,
        useMaterial3: true,
        extensions: [
          _ClinicalTones.fromColorScheme(colorScheme),
        ],
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.surface,
          centerTitle: false,
          scrolledUnderElevation: 1,
        ),
        cardTheme: CardThemeData(
          color: colorScheme.surfaceContainerLow,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: shape,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: colorScheme.surfaceContainerLowest,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
          ),
          labelStyle: const TextStyle(fontSize: 13),
          hintStyle: const TextStyle(fontSize: 13),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: colorScheme.surfaceContainerHighest,
          shape: const StadiumBorder(),
          labelStyle: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          secondaryLabelStyle: TextStyle(
            color: colorScheme.onSecondaryContainer,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: colorScheme.surfaceContainer,
          indicatorColor: colorScheme.secondaryContainer,
          elevation: 3,
        ),
        navigationRailTheme: NavigationRailThemeData(
          backgroundColor: colorScheme.surfaceContainerLow,
          indicatorColor: colorScheme.secondaryContainer,
          elevation: 1,
        ),
        switchTheme: SwitchThemeData(
          thumbIcon: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Icon(Icons.check, size: 16);
            }
            return null;
          }),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: const StadiumBorder(),
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: 18),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: const StadiumBorder(),
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: shape,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

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

class _HomeScreenState extends State<HomeScreen> {
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

  ClinicalAssessment _assessment = _newAssessment();
  List<SavedAssessment> _history = [];
  final Map<String, GlobalKey> _sectionKeys = {};
  final Map<String, GlobalKey> _fieldKeys = {};
  final Map<String, FocusNode> _fieldFocusNodes = {};
  final Set<String> _expandedSections = {};
  PatientSortMode _sortMode = PatientSortMode.updatedAt;
  _PatientFilter _patientFilter = _PatientFilter.all;
  String _searchQuery = '';
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
  bool _includePrereleaseUpdates = false;
  bool _showPatientScrollBubble = false;
  double _downloadProgress = 0;
  String _patientScrollBubbleLabel = '';
  UpdateInfo? _availableUpdate;
  Timer? _patientScrollBubbleTimer;

  _ClinicalTones get _clinicalTones =>
      Theme.of(context).extension<_ClinicalTones>()!;

  ScrollController get _patientScrollControllerOrCreate {
    return _patientScrollController ??= ScrollController();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _patientScrollBubbleTimer?.cancel();
    _patientScrollController?.dispose();
    _formScrollController.dispose();
    for (final node in _fieldFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    if (kIsWeb) {
      if (!mounted) {
        return;
      }
      setState(() {
        _assessment = _newAssessment();
        _formBaseline = _assessment.clone();
        _history = [];
        _homeMode = _HomeMode.list;
        _formDirty = false;
        _saveState = _SaveState.clean;
        _lastSavedAtMillis = 0;
        _saveError = null;
        _loading = false;
        _formVersion++;
      });
      return;
    }
    final draft = await _repository.loadCurrentAssessment();
    recalculateClinicalAssessment(draft);
    final history = await _repository.loadAssessmentHistory();
    final includePrereleaseUpdates =
        await _repository.loadIncludePrereleaseUpdates();
    final activeAssessment =
        _hasAnyClinicalData(draft) ? draft : _newAssessment();
    final openedSavedAssessmentId = _hasAnyClinicalData(draft)
        ? _savedIdForAssessment(draft, history)
        : null;
    if (!mounted) {
      return;
    }
    setState(() {
      _assessment = activeAssessment;
      _history = history;
      _openedSavedAssessmentId = openedSavedAssessmentId;
      _formBaseline = activeAssessment.clone();
      _homeMode = _HomeMode.list;
      _formDirty = false;
      _saveState = _SaveState.clean;
      _lastSavedAtMillis = activeAssessment.savedAtMillis;
      _saveError = null;
      _includePrereleaseUpdates = includePrereleaseUpdates;
      _loading = false;
      _formVersion++;
    });
    _checkUpdate();
  }

  Future<void> _refreshHistory() async {
    final history = await _repository.loadAssessmentHistory(
      query: _searchQuery,
      sortMode: _sortMode,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _history = history;
    });
  }

  Future<void> _checkUpdate() async {
    if (kIsWeb) {
      return;
    }
    final update = await _updateService.checkForUpdate(
      includePrerelease: _includePrereleaseUpdates,
    );
    if (!mounted || update == null) {
      return;
    }
    setState(() => _availableUpdate = update);
  }

  Future<void> _setIncludePrereleaseUpdates(bool enabled) async {
    setState(() {
      _includePrereleaseUpdates = enabled;
      _availableUpdate = null;
    });
    await _repository.saveIncludePrereleaseUpdates(enabled);
    await _checkUpdate();
  }

  void _showUpdateSettings() {
    var includePrereleaseUpdates = _includePrereleaseUpdates;
    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Cài đặt app'),
              content: SwitchListTile(
                value: includePrereleaseUpdates,
                onChanged: (value) {
                  setDialogState(() => includePrereleaseUpdates = value);
                  _setIncludePrereleaseUpdates(value);
                },
                contentPadding: EdgeInsets.zero,
                title: const Text('Cài bản prerelease'),
                subtitle:
                    const Text('Mặc định tắt, chỉ bật khi cần thử nghiệm'),
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

  Future<void> _exportAssessment(
    ClinicalAssessment source,
    CrfExportFormat format,
  ) async {
    if (_exporting) {
      return;
    }
    setState(() => _exporting = true);
    try {
      final assessment = source.clone();
      recalculateClinicalAssessment(assessment);
      final file = await _exporter.export(assessment, format);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: format.mimeType)],
          subject: 'NEWS2-L CRF',
          text: file.uri.pathSegments.last,
        ),
      );
    } catch (_) {
      if (mounted) {
        _showMessage('Không xuất được file. Vui lòng thử lại.');
      }
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  void _openSaved(SavedAssessment saved) {
    final assessment = saved.assessment.clone();
    recalculateClinicalAssessment(assessment);
    setState(() {
      _assessment = assessment;
      _openedSavedAssessmentId = saved.id;
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
    final assessment = _newAssessment();
    setState(() {
      _assessment = assessment;
      _openedSavedAssessmentId = null;
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
                            child: _buildAssessmentForm(),
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
                !_loading && !isForm && _filteredPatients(_history).isNotEmpty
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
    return PopupMenuButton<CrfExportFormat>(
      enabled: !_exporting,
      tooltip: 'Tác vụ',
      icon: const Icon(Icons.more_vert),
      onSelected: (format) => _exportAssessment(_assessment, format),
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: CrfExportFormat.pdf,
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf_outlined),
              SizedBox(width: 12),
              Text('Xuất PDF'),
            ],
          ),
        ),
        PopupMenuItem(
          value: CrfExportFormat.docx,
          child: Row(
            children: [
              Icon(Icons.description_outlined),
              SizedBox(width: 12),
              Text('Xuất DOCX'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateBanner() {
    final update = _availableUpdate!;
    return Material(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.system_update_alt),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Có bản cập nhật NEWS2-L ${update.version}'
                    '${update.prerelease ? ' (thử nghiệm)' : ''}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (_downloadingUpdate)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: LinearProgressIndicator(value: _downloadProgress),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _downloadingUpdate ? null : _downloadUpdate,
              icon: const Icon(Icons.download),
              label: Text(_downloadingUpdate ? 'Đang tải' : 'Tải'),
            ),
          ],
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
                _field('Tuổi (năm)', assessment.age, (value) {
                  assessment.age = value;
                },
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
                _field(
                    'Nhịp thở (lần/phút)', assessment.news2RespirationMeasured,
                    (value) {
                  assessment.news2RespirationMeasured = value;
                },
                    fieldId: AssessmentFields.respiration,
                    scoreText: _scoreText(
                      assessment.news2RespirationMeasured,
                      'Điểm NEWS2: ${assessment.news2Respiration}',
                    ),
                    warningText: _rangeWarning(
                      assessment.news2RespirationMeasured,
                      min: 4,
                      max: 40,
                      label: 'Nhịp thở',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: _integerInputFormatters),
                _field('Huyết áp tâm thu (mmHg)',
                    assessment.news2SystolicBpMeasured, (value) {
                  assessment.news2SystolicBpMeasured = value;
                },
                    fieldId: AssessmentFields.systolicBp,
                    scoreText: _scoreText(
                      assessment.news2SystolicBpMeasured,
                      'Điểm NEWS2: ${assessment.news2SystolicBp}',
                    ),
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
                _field('SpO2 (%)', assessment.news2Spo2Measured, (value) {
                  assessment.news2Spo2Measured = value;
                },
                    fieldId: AssessmentFields.spo2,
                    scoreText: _scoreText(
                      assessment.news2Spo2Measured,
                      'Điểm NEWS2: ${assessment.news2Spo2}',
                    ),
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
                _field('Nhiệt độ (°C)', assessment.news2TemperatureMeasured,
                    (value) {
                  assessment.news2TemperatureMeasured = value;
                },
                    fieldId: AssessmentFields.temperature,
                    scoreText: _scoreText(
                      assessment.news2TemperatureMeasured,
                      'Điểm NEWS2: ${assessment.news2Temperature}',
                    ),
                    warningText: _rangeWarning(
                      assessment.news2TemperatureMeasured,
                      min: 30,
                      max: 43,
                      label: 'Nhiệt độ',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: _decimalInputFormatters),
                _field('Nhịp tim (lần/phút)', assessment.news2HeartRateMeasured,
                    (value) {
                  assessment.news2HeartRateMeasured = value;
                },
                    fieldId: AssessmentFields.heartRate,
                    scoreText: _scoreText(
                      assessment.news2HeartRateMeasured,
                      'Điểm NEWS2: ${assessment.news2HeartRate}',
                    ),
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
                _field('Lactate tĩnh mạch (mmol/L)', assessment.lactate,
                    (value) {
                  assessment.lactate = value;
                  assessment.lactateLevel = _lactateLevel(value);
                },
                    fieldId: AssessmentFields.lactate,
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
                _field('Hô hấp - PaO2/FiO2 (mmHg)',
                    assessment.sofaRespirationMeasured, (value) {
                  assessment.sofaRespirationMeasured = value;
                },
                    fieldId: AssessmentFields.sofaRespiration,
                    scoreText: _scoreText(
                      assessment.sofaRespirationMeasured,
                      'Điểm SOFA hô hấp: ${assessment.sofaRespiration}',
                    ),
                    hint: 'VD: 180 hoặc 180 thở máy'),
                _field('Đông máu - Tiểu cầu (10³/µL)',
                    assessment.sofaCoagulationMeasured, (value) {
                  assessment.sofaCoagulationMeasured = value;
                },
                    fieldId: AssessmentFields.sofaCoagulation,
                    scoreText: _scoreText(
                      assessment.sofaCoagulationMeasured,
                      'Điểm SOFA đông máu: ${assessment.sofaCoagulation}',
                    ),
                    hint: 'VD: 120',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: _decimalInputFormatters),
                _field('Gan - Bilirubin (mg/dL hoặc µmol/L)',
                    assessment.sofaLiverMeasured, (value) {
                  assessment.sofaLiverMeasured = value;
                },
                    fieldId: AssessmentFields.sofaLiver,
                    scoreText: _scoreText(
                      assessment.sofaLiverMeasured,
                      'Điểm SOFA gan: ${assessment.sofaLiver}',
                    ),
                    hint: 'VD: 2.0 mg/dL hoặc 34 µmol/L'),
                _unitSwitcher(
                  label: 'Đơn vị bilirubin',
                  value: assessment.sofaLiverMeasured,
                  units: const ['mg/dL', 'µmol/L'],
                  onChanged: (value) {
                    assessment.sofaLiverMeasured = _replaceTrailingUnit(
                        assessment.sofaLiverMeasured, value);
                  },
                ),
                _field(
                    'Thần kinh - GCS (điểm)', assessment.sofaNeurologicMeasured,
                    (value) {
                  assessment.sofaNeurologicMeasured = value;
                },
                    fieldId: AssessmentFields.sofaNeurologic,
                    scoreText: _scoreText(
                      assessment.sofaNeurologicMeasured,
                      'Điểm SOFA thần kinh: ${assessment.sofaNeurologic}',
                    ),
                    warningText: _rangeWarning(
                      assessment.sofaNeurologicMeasured,
                      min: 3,
                      max: 15,
                      label: 'GCS',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: _integerInputFormatters),
                _field('Thận - Creatinin/nước tiểu (mg/dL, µmol/L, mL/ngày)',
                    assessment.sofaRenalMeasured, (value) {
                  assessment.sofaRenalMeasured = value;
                },
                    fieldId: AssessmentFields.sofaRenal,
                    scoreText: _scoreText(
                      assessment.sofaRenalMeasured,
                      'Điểm SOFA thận: ${assessment.sofaRenal}',
                    ),
                    hint: 'VD: creatinin 2.0 mg/dL, nước tiểu 400 mL'),
                _unitSwitcher(
                  label: 'Đơn vị creatinine',
                  value: assessment.sofaRenalMeasured,
                  units: const ['mg/dL', 'µmol/L'],
                  onChanged: (value) {
                    assessment.sofaRenalMeasured = _replaceTrailingUnit(
                        assessment.sofaRenalMeasured, value);
                  },
                ),
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
            _section(
              '5. Chẩn đoán & kết cục',
              sectionId: AssessmentSections.diagnosis,
              progress: _diagnosisProgress(assessment),
              twoColumns: twoColumns,
              children: [
                _fullWidth(_sepsisDiagnosisOptions(assessment)),
                DropdownButtonFormField<String>(
                  initialValue: assessment.treatmentOutcome.isEmpty
                      ? null
                      : assessment.treatmentOutcome,
                  isExpanded: true,
                  decoration:
                      const InputDecoration(labelText: 'Kết quả điều trị'),
                  items: const [
                    DropdownMenuItem(
                        value: 'Khỏi / Đỡ ra viện',
                        child: Text('Khỏi / Đỡ ra viện')),
                    DropdownMenuItem(
                        value: 'Chuyển viện', child: Text('Chuyển viện')),
                    DropdownMenuItem(
                        value: 'Nặng xin về / Tử vong',
                        child: Text('Nặng xin về / Tử vong')),
                  ],
                  onChanged: (value) =>
                      _mutate((a) => a.treatmentOutcome = value ?? ''),
                ),
                _field('Số ngày điều trị (ngày)', assessment.treatmentDays,
                    (value) {
                  assessment.treatmentDays = value;
                },
                    keyboardType: TextInputType.number,
                    inputFormatters: _integerInputFormatters),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildPatientList() {
    final patients = _filteredPatients(_history);
    final showHeader = _history.isNotEmpty ||
        _searchQuery.trim().isNotEmpty ||
        _patientFilter != _PatientFilter.all;
    return Column(
      children: [
        if (showHeader)
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              patients.isEmpty ? 8 : 12,
              16,
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
                        _patientSummaryStrip(_history, compact: true),
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
                          _patientSummaryStrip(_history),
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
              ? _emptyPatientState()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        NotificationListener<ScrollNotification>(
                          onNotification: (notification) =>
                              _handlePatientScroll(notification, patients),
                          child: MasonryGridView.count(
                            controller: _patientScrollControllerOrCreate,
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            crossAxisCount:
                                _patientGridColumns(constraints.maxWidth),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            itemCount: patients.length,
                            itemBuilder: (context, index) {
                              if (index < 0 || index >= patients.length) {
                                return const SizedBox.shrink();
                              }
                              return _patientCard(patients[index]);
                            },
                          ),
                        ),
                        if (_showPatientScrollBubble &&
                            _patientScrollBubbleLabel.isNotEmpty)
                          Positioned(
                            top: _patientScrollBubbleTop(constraints),
                            right: 12,
                            child: _patientScrollBubble(
                              _patientScrollBubbleLabel,
                            ),
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
      _patientScrollBubbleLabel = '';
      _showPatientScrollBubble = false;
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
        shape: StadiumBorder(
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
      _patientScrollBubbleLabel = '';
      _showPatientScrollBubble = false;
    });
    if (_patientScrollControllerOrCreate.hasClients) {
      _patientScrollControllerOrCreate.jumpTo(0);
    }
  }

  Widget _patientSummaryStrip(
    List<SavedAssessment> patients, {
    bool compact = false,
  }) {
    final total = patients.length;
    final incomplete = patients
        .where(
            (saved) => AssessmentDisplay.isIncompletePatient(saved.assessment))
        .length;
    final highRisk = patients
        .where((saved) => AssessmentDisplay.isHighRiskPatient(saved.assessment))
        .length;
    final shock = patients
        .where(
            (saved) => AssessmentDisplay.isSepticShockPatient(saved.assessment))
        .length;
    final badges = [
      _summaryBadge('Tổng', total, ClinicalStatus.normal),
      _summaryBadge('Chưa đủ', incomplete, ClinicalStatus.missing),
      _summaryBadge('Nguy cơ cao', highRisk, ClinicalStatus.warning),
      _summaryBadge('Sốc NK', shock, ClinicalStatus.danger),
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

  Widget _emptyPatientState() {
    final theme = Theme.of(context);
    final activeFilter =
        _searchQuery.trim().isNotEmpty || _patientFilter != _PatientFilter.all;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
    return PopupMenuButton<CrfExportFormat>(
      enabled: !_exporting,
      tooltip: 'Tác vụ',
      icon: const Icon(Icons.more_vert),
      onSelected: (format) => _exportAssessment(assessment, format),
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: CrfExportFormat.pdf,
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf_outlined),
              SizedBox(width: 12),
              Text('Xuất PDF'),
            ],
          ),
        ),
        PopupMenuItem(
          value: CrfExportFormat.docx,
          child: Row(
            children: [
              Icon(Icons.description_outlined),
              SizedBox(width: 12),
              Text('Xuất DOCX'),
            ],
          ),
        ),
      ],
    );
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
    final patientId = assessment.patientId.trim().isEmpty
        ? 'Chưa nhập mã BN'
        : assessment.patientId.trim();
    final age = assessment.age.trim();
    if (age.isEmpty) {
      return 'Mã BN: $patientId';
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
    final label = _patientScrollLabel(notification.metrics, patients);
    _patientScrollBubbleTimer?.cancel();
    if (mounted) {
      setState(() {
        _patientScrollBubbleLabel = label;
        _showPatientScrollBubble = label.isNotEmpty;
      });
    }
    _patientScrollBubbleTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() => _showPatientScrollBubble = false);
      }
    });
    return false;
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

  double _patientScrollBubbleTop(BoxConstraints constraints) {
    final maxTop = constraints.maxHeight - 56;
    final controller = _patientScrollControllerOrCreate;
    if (!controller.hasClients || controller.position.maxScrollExtent <= 0) {
      return 12;
    }
    final fraction = (controller.offset / controller.position.maxScrollExtent)
        .clamp(0.0, 1.0)
        .toDouble();
    final availableTop = (maxTop - 12).clamp(0.0, double.infinity).toDouble();
    return 12 + (availableTop * fraction);
  }

  Widget _patientScrollBubble(String label) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.inverseSurface,
      elevation: 3,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onInverseSurface,
            fontWeight: FontWeight.w800,
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

  _RiskTone _news2Tone(ClinicalAssessment assessment) {
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

  _RiskTone _qsofaTone(ClinicalAssessment assessment) {
    final tones = _clinicalTones;
    if (!_qsofaComplete(assessment)) {
      return tones.muted;
    }
    return assessment.qsofaTotal >= 2 ? tones.danger : tones.success;
  }

  _RiskTone _sofaTone(ClinicalAssessment assessment) {
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

  _RiskTone _sofaThresholdTone(ClinicalAssessment assessment) {
    final tones = _clinicalTones;
    if (!_sofaComplete(assessment)) {
      return tones.muted;
    }
    return SofaScoring.hasSepsisBySofa(assessment)
        ? tones.warning
        : tones.success;
  }

  _RiskTone _diagnosisTone(ClinicalAssessment assessment) {
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

  _RiskTone _componentScoreTone(int score) {
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
    return ClinicalValueParser.hasText(assessment.news2RespirationMeasured) &&
        ClinicalValueParser.hasText(assessment.news2Spo2Measured) &&
        ClinicalValueParser.hasText(assessment.news2OxygenMeasured) &&
        ClinicalValueParser.hasText(assessment.news2TemperatureMeasured) &&
        ClinicalValueParser.hasText(assessment.news2SystolicBpMeasured) &&
        ClinicalValueParser.hasText(assessment.news2HeartRateMeasured) &&
        ClinicalValueParser.hasText(assessment.news2ConsciousnessMeasured);
  }

  bool _qsofaComplete(ClinicalAssessment assessment) {
    return ClinicalValueParser.hasText(assessment.news2RespirationMeasured) &&
        ClinicalValueParser.hasText(assessment.news2SystolicBpMeasured) &&
        ClinicalValueParser.hasText(assessment.news2ConsciousnessMeasured);
  }

  bool _lactateComplete(ClinicalAssessment assessment) {
    return ClinicalValueParser.hasText(assessment.lactate);
  }

  bool _shockInputsIncomplete(ClinicalAssessment assessment) {
    if (!assessment.vasopressor) {
      return false;
    }
    return !_lactateComplete(assessment) ||
        !ClinicalValueParser.hasText(assessment.sofaCardiovascularMeasured);
  }

  bool _sofaCardiovascularComplete(ClinicalAssessment assessment) {
    return ClinicalValueParser.hasText(assessment.sofaCardiovascularMeasured) ||
        assessment.vasopressor;
  }

  bool _sofaComplete(ClinicalAssessment assessment) {
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
      AssessmentDisplay.diagnosisScoreDisplay(assessment),
    ];
    final missingItems = AssessmentDisplay.allMissingItems(assessment);
    return Material(
      color: theme.colorScheme.surface,
      elevation: 1,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            if (compact) {
              return _compactClinicalDashboard(displays, missingItems);
            }
            final cards = [
              for (final display in displays)
                SizedBox(
                  width: (constraints.maxWidth - 36) / 4,
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
            height: 58,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                    style: theme.textTheme.titleLarge?.copyWith(
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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

  Widget _fullWidth(Widget child) => _FullWidth(child: child);

  Widget _toggleTile(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final theme = Theme.of(context);
    return Card.outlined(
      color: theme.colorScheme.surfaceContainerLowest,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _unitSwitcher({
    required String label,
    required String value,
    required List<String> units,
    required ValueChanged<String> onChanged,
  }) {
    final selected = _selectedUnit(value, units);
    return DropdownButtonFormField<String>(
      initialValue: selected,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        helperText: 'Đơn vị sẽ được lưu kèm giá trị nhập',
      ),
      items: [
        for (final unit in units)
          DropdownMenuItem(
            value: unit,
            child: Text(unit),
          ),
      ],
      onChanged: (unit) {
        if (unit == null) {
          return;
        }
        _mutate((_) => onChanged(unit));
      },
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
      hintText: hint,
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

    return Card.filled(
      color: tone.background,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: tone.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chẩn đoán xác định (Theo Sepsis-3)',
              style: theme.textTheme.labelMedium?.copyWith(
                color: tone.foreground,
                fontWeight: FontWeight.w800,
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
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _diagnosisCheckboxRow(
    String label, {
    required bool checked,
    required _RiskTone tone,
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
    _RiskTone? tone,
    int maxLines = 2,
  }) {
    final theme = Theme.of(context);
    final lineTone = tone ?? _clinicalTones.neutral;
    return Card.filled(
      color: lineTone.background,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: lineTone.border),
      ),
      child: Padding(
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
                      fontWeight: FontWeight.w700,
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
    return Card.filled(
      color: tone.background,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: tone.border),
      ),
      child: Padding(
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
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              completed ? (checked ? '1' : '0') : '-',
              style: theme.textTheme.labelMedium?.copyWith(
                color: tone.foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
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

  SectionProgress _diagnosisProgress(ClinicalAssessment assessment) {
    final missing = [
      ...AssessmentDisplay.sofaMissingItems(assessment),
      ...AssessmentDisplay.shockMissingItems(assessment),
    ].map((item) => item.label).toList();
    return SectionProgress(
      sectionId: AssessmentSections.diagnosis,
      completedCount: missing.isEmpty ? 1 : 0,
      totalCount: 1,
      missingLabels: missing,
    );
  }

  String _defaultOpenSection(ClinicalAssessment assessment) {
    final sections = [
      _patientProgress(assessment),
      AssessmentDisplay.news2Progress(assessment),
      AssessmentDisplay.lactateProgress(assessment),
      AssessmentDisplay.sofaProgress(assessment),
      _diagnosisProgress(assessment),
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
    return units.first;
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
        ClinicalValueParser.hasText(assessment.news2RespirationMeasured) ||
        ClinicalValueParser.hasText(assessment.news2SystolicBpMeasured) ||
        ClinicalValueParser.hasText(assessment.news2HeartRateMeasured) ||
        ClinicalValueParser.hasText(assessment.lactate) ||
        ClinicalValueParser.hasText(assessment.sofaNeurologicMeasured) ||
        ClinicalValueParser.hasText(assessment.treatmentOutcome);
  }

  static ClinicalAssessment _newAssessment() {
    final now = DateTime.now();
    final assessment = ClinicalAssessment(
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
    return [
      assessment.patientId,
      assessment.fullName,
      assessment.age,
      assessment.admissionReason,
      assessment.infectionOrgan,
      assessment.news2RespirationMeasured,
      assessment.news2Spo2Measured,
      assessment.sofaRespirationMeasured,
    ].any(ClinicalValueParser.hasText);
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

class _ClinicalTones extends ThemeExtension<_ClinicalTones> {
  final _RiskTone success;
  final _RiskTone attention;
  final _RiskTone warning;
  final _RiskTone danger;
  final _RiskTone neutral;
  final _RiskTone muted;

  const _ClinicalTones({
    required this.success,
    required this.attention,
    required this.warning,
    required this.danger,
    required this.neutral,
    required this.muted,
  });

  factory _ClinicalTones.fromColorScheme(ColorScheme scheme) {
    return _ClinicalTones(
      success: const _RiskTone(
        background: Color(0xFFEAF7EE),
        border: Color(0xFFA8DDB8),
        foreground: Color(0xFF1B6B36),
        icon: Icons.check_circle,
        severity: 1,
      ),
      attention: const _RiskTone(
        background: Color(0xFFFFF8E1),
        border: Color(0xFFFFD978),
        foreground: Color(0xFF7A5A00),
        icon: Icons.info,
        severity: 2,
      ),
      warning: const _RiskTone(
        background: Color(0xFFFFF0E0),
        border: Color(0xFFFFBE7A),
        foreground: Color(0xFFAD4E00),
        icon: Icons.warning_amber,
        severity: 3,
      ),
      danger: _RiskTone(
        background: scheme.errorContainer,
        border: scheme.error.withValues(alpha: 0.36),
        foreground: scheme.onErrorContainer,
        icon: Icons.error,
        severity: 4,
      ),
      neutral: _RiskTone(
        background: scheme.surfaceContainerHighest,
        border: scheme.outlineVariant,
        foreground: scheme.onSurfaceVariant,
        icon: Icons.radio_button_unchecked,
        severity: 1,
      ),
      muted: _RiskTone(
        background: scheme.surfaceContainerHigh,
        border: scheme.outlineVariant,
        foreground: scheme.onSurfaceVariant.withValues(alpha: 0.72),
        icon: Icons.remove_circle_outline,
        severity: 0,
      ),
    );
  }

  @override
  _ClinicalTones copyWith({
    _RiskTone? success,
    _RiskTone? attention,
    _RiskTone? warning,
    _RiskTone? danger,
    _RiskTone? neutral,
    _RiskTone? muted,
  }) {
    return _ClinicalTones(
      success: success ?? this.success,
      attention: attention ?? this.attention,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      neutral: neutral ?? this.neutral,
      muted: muted ?? this.muted,
    );
  }

  @override
  _ClinicalTones lerp(ThemeExtension<_ClinicalTones>? other, double t) {
    if (other is! _ClinicalTones) {
      return this;
    }
    return _ClinicalTones(
      success: success.lerp(other.success, t),
      attention: attention.lerp(other.attention, t),
      warning: warning.lerp(other.warning, t),
      danger: danger.lerp(other.danger, t),
      neutral: neutral.lerp(other.neutral, t),
      muted: muted.lerp(other.muted, t),
    );
  }
}

class _RiskTone {
  final Color background;
  final Color border;
  final Color foreground;
  final IconData icon;
  final int severity;

  const _RiskTone({
    required this.background,
    required this.border,
    required this.foreground,
    required this.icon,
    required this.severity,
  });

  _RiskTone copyWith({
    Color? background,
    Color? border,
    Color? foreground,
    IconData? icon,
    int? severity,
  }) {
    return _RiskTone(
      background: background ?? this.background,
      border: border ?? this.border,
      foreground: foreground ?? this.foreground,
      icon: icon ?? this.icon,
      severity: severity ?? this.severity,
    );
  }

  _RiskTone lerp(_RiskTone other, double t) {
    return _RiskTone(
      background: Color.lerp(background, other.background, t)!,
      border: Color.lerp(border, other.border, t)!,
      foreground: Color.lerp(foreground, other.foreground, t)!,
      icon: t < 0.5 ? icon : other.icon,
      severity: t < 0.5 ? severity : other.severity,
    );
  }
}
