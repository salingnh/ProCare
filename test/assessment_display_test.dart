import 'package:flutter_test/flutter_test.dart';
import 'package:news2_l/src/domain/assessment_display.dart';
import 'package:news2_l/src/domain/clinical_assessment.dart';
import 'package:news2_l/src/domain/scoring.dart';

void main() {
  test('NEWS2 missing fields report concrete labels and progress', () {
    final assessment = ClinicalAssessment(
      news2RespirationMeasured: '22',
      news2Spo2Measured: '94',
    );

    final missing = AssessmentDisplay.news2MissingItems(assessment);
    final progress = AssessmentDisplay.news2Progress(assessment);

    expect(progress.completedCount, 2);
    expect(progress.totalCount, 7);
    expect(missing.map((item) => item.label), contains('HA tâm thu'));
    expect(missing.map((item) => item.label), contains('Tri giác'));
    expect(AssessmentDisplay.news2Status(assessment), ClinicalStatus.missing);
  });

  test('SOFA progress reports two of six completed systems', () {
    final assessment = ClinicalAssessment(
      sofaRespirationMeasured: '250',
      sofaNeurologicMeasured: '13',
    );

    final progress = AssessmentDisplay.sofaProgress(assessment);

    expect(progress.completedCount, 2);
    expect(progress.totalCount, 6);
    expect(progress.missingLabels, containsAll(['Đông máu', 'Gan', 'Thận']));
  });

  test('shock missing items require lactate and MAP when vasopressor is on',
      () {
    final assessment = ClinicalAssessment(vasopressor: true);

    final missing = AssessmentDisplay.shockMissingItems(assessment);

    expect(missing.map((item) => item.label),
        containsAll(['Lactate', 'MAP/vận mạch']));
  });

  test('high risk and septic shock predicates are mapped from scoring', () {
    final assessment = ClinicalAssessment(
      lactate: '2.1',
      vasopressor: true,
      sofaCardiovascularMeasured: 'MAP 65',
      news2RespirationMeasured: '25',
      news2Spo2Measured: '90',
      news2OxygenMeasured: 'Có',
      news2TemperatureMeasured: '39.2',
      news2SystolicBpMeasured: '88',
      news2HeartRateMeasured: '132',
      news2ConsciousnessMeasured: 'V',
      sofaRespirationMeasured: '180 thở máy',
      sofaCoagulationMeasured: '80',
      sofaLiverMeasured: '2.0 mg/dL',
      sofaNeurologicMeasured: '10',
      sofaRenalMeasured: '2.0 mg/dL',
    );
    recalculateClinicalAssessment(assessment);

    expect(AssessmentDisplay.isHighRiskPatient(assessment), isTrue);
    expect(AssessmentDisplay.isSepticShockPatient(assessment), isTrue);
    expect(AssessmentDisplay.isIncompletePatient(assessment), isFalse);
    expect(
        AssessmentDisplay.diagnosisStatus(assessment), ClinicalStatus.danger);
  });

  test('quick mode treats selected zero scores as completed data', () {
    final assessment = ClinicalAssessment(
      assessmentMode: ClinicalAssessment.assessmentModeQuick,
      news2Respiration: 0,
      news2RespirationSelected: true,
      news2Spo2: 0,
      news2Spo2Selected: true,
      news2Oxygen: 0,
      news2OxygenSelected: true,
      news2Temperature: 0,
      news2TemperatureSelected: true,
      news2SystolicBp: 0,
      news2SystolicBpSelected: true,
      news2HeartRate: 0,
      news2HeartRateSelected: true,
      news2Consciousness: 0,
      news2ConsciousnessSelected: true,
      qsofaRespiration: false,
      qsofaRespirationSelected: true,
      qsofaSystolicBp: false,
      qsofaSystolicBpSelected: true,
      qsofaConsciousness: false,
      qsofaConsciousnessSelected: true,
      sofaRespiration: 0,
      sofaRespirationSelected: true,
      sofaCoagulation: 0,
      sofaCoagulationSelected: true,
      sofaLiver: 0,
      sofaLiverSelected: true,
      sofaCardiovascular: 0,
      sofaCardiovascularSelected: true,
      sofaNeurologic: 0,
      sofaNeurologicSelected: true,
      sofaRenal: 0,
      sofaRenalSelected: true,
    );
    recalculateClinicalAssessment(assessment);

    expect(AssessmentDisplay.news2Progress(assessment).complete, isTrue);
    expect(AssessmentDisplay.qsofaProgress(assessment).complete, isTrue);
    expect(AssessmentDisplay.sofaProgress(assessment).complete, isTrue);
    expect(AssessmentDisplay.news2ScoreDisplay(assessment).scoreText, '0');
    expect(AssessmentDisplay.qsofaScoreDisplay(assessment).scoreText, '0');
    expect(AssessmentDisplay.sofaScoreDisplay(assessment).scoreText, '0');
    expect(AssessmentDisplay.isIncompletePatient(assessment), isFalse);
  });

  test('quick mode qSOFA missing items are included in patient completeness',
      () {
    final assessment = ClinicalAssessment(
      assessmentMode: ClinicalAssessment.assessmentModeQuick,
      news2RespirationSelected: true,
      news2Spo2Selected: true,
      news2OxygenSelected: true,
      news2TemperatureSelected: true,
      news2SystolicBpSelected: true,
      news2HeartRateSelected: true,
      news2ConsciousnessSelected: true,
      sofaRespirationSelected: true,
      sofaCoagulationSelected: true,
      sofaLiverSelected: true,
      sofaCardiovascularSelected: true,
      sofaNeurologicSelected: true,
      sofaRenalSelected: true,
    );

    final missing = AssessmentDisplay.allMissingItems(assessment);

    expect(
      missing.map((item) => item.id),
      containsAll([
        'qsofa_respiration',
        'qsofa_systolic_bp',
        'qsofa_consciousness',
      ]),
    );
    expect(AssessmentDisplay.isIncompletePatient(assessment), isTrue);
  });

  test('quick mode lactate level completes lactate progress', () {
    final assessment = ClinicalAssessment(
      assessmentMode: ClinicalAssessment.assessmentModeQuick,
      lactateLevel: '2 - 3.9 mmol/L',
    );

    final progress = AssessmentDisplay.lactateProgress(assessment);
    final shockMissing = AssessmentDisplay.shockMissingItems(
      ClinicalAssessment(
        assessmentMode: ClinicalAssessment.assessmentModeQuick,
        lactateLevel: '2 - 3.9 mmol/L',
        vasopressor: true,
      ),
    );

    expect(progress.complete, isTrue);
    expect(shockMissing.map((item) => item.label), isNot(contains('Lactate')));
    expect(shockMissing.map((item) => item.label), contains('MAP/vận mạch'));
  });
}
