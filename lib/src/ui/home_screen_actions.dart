part of 'home_screen.dart';

extension _HsActions on _HomeScreenState {
  void _openSaved(SavedAssessment saved) {
    _assessmentController.openSaved(saved);
    _pushForm();
  }

  void _startNew() {
    _assessmentController.startNew();
    _pushForm();
  }

  void _pushForm() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AssessmentFormScreen(
          controller: _assessmentController,
          updateController: _updateController,
        ),
      ),
    );
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
