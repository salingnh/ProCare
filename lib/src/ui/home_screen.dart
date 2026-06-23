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

part 'home_screen_support.dart';
part 'home_screen_startup.dart';
part 'home_screen_actions.dart';
part 'home_screen_form_shell.dart';
part 'home_screen_patient_list.dart';
part 'home_screen_dashboard.dart';
part 'home_screen_quick_form.dart';
part 'home_screen_detailed_form.dart';
part 'home_screen_form_support.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
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

  // Wrapper so helper methods defined in part files (extensions) can
  // request a rebuild without tripping invalid_use_of_protected_member.
  void _rebuild(VoidCallback fn) {
    setState(fn);
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
}
