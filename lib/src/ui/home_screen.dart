import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/assessment_repository.dart';
import '../domain/clinical_assessment.dart';
import '../domain/scoring.dart';
import '../services/update_controller.dart';
import 'app_settings_dialog.dart';
import 'assessment_controller.dart';
import 'assessment_form_screen.dart';
import 'patient_list_controller.dart';
import 'patient_list_view.dart';
import 'update_banner.dart';

part 'home_screen_startup.dart';
part 'home_screen_actions.dart';

/// App shell: owns the long-lived controllers and the patient list, and pushes
/// the assessment form as a route. Form-UI state lives in the form screen.
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
  bool _loading = true;

  ClinicalAssessment get _assessment => _assessmentController.assessment;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateController = UpdateController(repository: _repository);
    _listController = PatientListController(repository: _repository)
      ..addListener(_onListChanged);
    _assessmentController = AssessmentController(repository: _repository)
      ..onPersisted = _listController.refresh
      ..canAutoSave = (() => false);
    _load();
  }

  @override
  void dispose() {
    _updateController.dispose();
    _listController.removeListener(_onListChanged);
    _listController.dispose();
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

  void _onListChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _rebuild(VoidCallback fn) {
    setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NEWS2-L'),
        actions: [
          IconButton(
            tooltip: 'Cài đặt app',
            onPressed: _showUpdateSettings,
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                UpdateBanner(controller: _updateController),
                Expanded(
                  child: PatientListView(
                    listController: _listController,
                    onOpenForm: _openSaved,
                    onNewForm: _startNew,
                  ),
                ),
              ],
            ),
      floatingActionButton:
          !_loading && _listController.filteredHistory.isNotEmpty
              ? FloatingActionButton.extended(
                  onPressed: _startNew,
                  icon: const Icon(Icons.add),
                  label: const Text('Phiếu mới'),
                )
              : null,
    );
  }
}
