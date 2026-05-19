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
}
