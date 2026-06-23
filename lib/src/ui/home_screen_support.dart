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

// Top-level constants lifted from _HomeScreenState.
const _initialHistoryPageSize = 50;
const _historyPageSize = 50;
const _updateCheckInterval = Duration(hours: 6);
const _resumeUpdateCheckCooldown = Duration(minutes: 15);
const _androidFileChannel = MethodChannel('news2_l/android_files');
final _integerInputFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.digitsOnly,
];
final _decimalInputFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
];
final _dateInputFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.allow(RegExp(r'[0-9/-]')),
];
final _timeInputFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
];

// Top-level helpers lifted from _HomeScreenState.
ClinicalAssessment _newAssessment({
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

bool _hasAnyClinicalData(ClinicalAssessment assessment) {
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

bool _hasQuickScoreData(ClinicalAssessment assessment) {
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

String _buildAdmissionDateTime(ClinicalAssessment assessment) {
  return '${assessment.admissionTime}, ngày ${assessment.admissionDate}';
}

String _lactateLevel(String value) {
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

String _dateText(DateTime value) {
  return '${value.year}-${_two(value.month)}-${_two(value.day)}';
}

String _timeText(DateTime value) {
  return '${_two(value.hour)}:${_two(value.minute)}';
}

String _two(int value) => value.toString().padLeft(2, '0');
