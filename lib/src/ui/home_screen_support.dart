part of 'home_screen.dart';

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
