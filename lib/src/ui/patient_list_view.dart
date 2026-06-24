import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../data/assessment_repository.dart';
import '../domain/assessment_display.dart';
import '../domain/clinical_assessment.dart';
import '../domain/clinical_value_parser.dart';
import '../domain/scoring.dart';
import '../export/assessment_exporter.dart';
import '../export/export_action.dart';
import 'clinical_components.dart' as clinical_ui;
import 'clinical_theme.dart';
import 'export_action_menu.dart';
import 'patient_list_controller.dart';

part 'patient_list_body.dart';

/// The saved-patient list screen body. Owns its scroll/export UI state and
/// renders from a [PatientListController]; navigation to the form is delegated
/// to [onOpenForm]/[onNewForm] so this view stays decoupled from the shell.
class PatientListView extends StatefulWidget {
  final PatientListController listController;
  final ValueChanged<SavedAssessment> onOpenForm;
  final VoidCallback onNewForm;

  const PatientListView({
    super.key,
    required this.listController,
    required this.onOpenForm,
    required this.onNewForm,
  });

  @override
  State<PatientListView> createState() => _PatientListViewState();
}

class _PatientListViewState extends State<PatientListView> {
  PatientListController get _listController => widget.listController;

  final _assessmentExporter = const AssessmentExporter();
  ScrollController? _patientScrollController;
  Timer? _patientScrollBubbleTimer;
  final ValueNotifier<_PatientScrollBubbleState> _patientScrollBubble =
      ValueNotifier(const _PatientScrollBubbleState.hidden());
  bool _exporting = false;

  ScrollController get _patientScrollControllerOrCreate {
    return _patientScrollController ??= ScrollController();
  }

  ClinicalTones get _clinicalTones =>
      Theme.of(context).extension<ClinicalTones>()!;

  void _rebuild(VoidCallback fn) {
    setState(fn);
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _two(int value) => value.toString().padLeft(2, '0');

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

  @override
  void dispose() {
    _patientScrollBubbleTimer?.cancel();
    _patientScrollBubble.dispose();
    _patientScrollController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildPatientList();
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
