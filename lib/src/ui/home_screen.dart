import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/assessment_repository.dart';
import '../domain/assessment_display.dart';
import '../domain/clinical_assessment.dart';
import '../domain/clinical_value_parser.dart';
import '../domain/scoring.dart';
import '../export/assessment_exporter.dart';
import '../export/export_action.dart';
import '../services/update_controller.dart';
import 'patient_list_controller.dart';
import 'patient_list_view.dart';
import 'update_banner.dart';
import 'assessment_controller.dart';
import 'app_settings_dialog.dart';
import 'clinical_display_helpers.dart';
import 'clinical_components.dart' as clinical_ui;
import 'clinical_theme.dart';
import 'export_action_menu.dart';

part 'home_screen_support.dart';
part 'home_screen_startup.dart';
part 'home_screen_actions.dart';
part 'home_screen_form_shell.dart';
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
  late final UpdateController _updateController;
  late final PatientListController _listController;
  late final AssessmentController _assessmentController;
  final _assessmentExporter = const AssessmentExporter();
  final ScrollController _formScrollController = ScrollController();

  final Map<String, GlobalKey> _sectionKeys = {};
  final Map<String, GlobalKey> _fieldKeys = {};
  final Map<String, FocusNode> _fieldFocusNodes = {};
  final Map<String, String> _fieldUnitSelections = {};
  final Set<String> _expandedSections = {};
  _HomeMode _homeMode = _HomeMode.list;
  int _formVersion = 0;
  bool _loading = true;
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

  // Wrapper so helper methods defined in part files (extensions) can
  // request a rebuild without tripping invalid_use_of_protected_member.
  void _rebuild(VoidCallback fn) {
    setState(fn);
  }

  void _onControllerChanged() {
    if (mounted) {
      _rebuild(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateController = UpdateController(repository: _repository)
      ..addListener(_onControllerChanged);
    _listController = PatientListController(repository: _repository)
      ..addListener(_onControllerChanged);
    _assessmentController = AssessmentController(repository: _repository)
      ..onPersisted = _listController.refresh
      ..canAutoSave = (() => _homeMode == _HomeMode.form)
      ..addListener(_onControllerChanged);
    _load();
  }

  @override
  void dispose() {
    _formScrollController.dispose();
    for (final node in _fieldFocusNodes.values) {
      node.dispose();
    }
    _updateController.removeListener(_onControllerChanged);
    _updateController.dispose();
    _listController.removeListener(_onControllerChanged);
    _listController.dispose();
    _assessmentController.removeListener(_onControllerChanged);
    _assessmentController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateController.checkAfterResume();
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
                  UpdateBanner(controller: _updateController),
                  if (isForm) _clinicalDashboard(_assessment),
                  Expanded(
                    child: isForm
                        ? KeyedSubtree(
                            key: ValueKey(_formVersion),
                            child: _assessment.isQuickMode
                                ? _buildQuickAssessmentForm()
                                : _buildAssessmentForm(),
                          )
                        : PatientListView(
                            listController: _listController,
                            onOpenForm: _openSaved,
                            onNewForm: _startNew,
                          ),
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
                !_loading && !isForm && _listController.filteredHistory.isNotEmpty
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
