import 'package:flutter_test/flutter_test.dart';
import 'package:news2_l/src/domain/clinical_assessment.dart';
import 'package:news2_l/src/ui/clinical_display_helpers.dart';

ClinicalAssessment _news2Filled() => ClinicalAssessment(
      news2RespirationMeasured: '18',
      news2Spo2Measured: '97',
      news2OxygenMeasured: 'Không',
      news2TemperatureMeasured: '37',
      news2SystolicBpMeasured: '120',
      news2HeartRateMeasured: '80',
      news2ConsciousnessMeasured: 'A',
    );

ClinicalAssessment _sofaFilled() => ClinicalAssessment(
      sofaRespirationMeasured: '300',
      sofaCoagulationMeasured: '150',
      sofaLiverMeasured: '1.0',
      sofaCardiovascularMeasured: 'MAP 70',
      sofaNeurologicMeasured: '15',
      sofaRenalMeasured: '1.0',
    );

void main() {
  test('news2Complete requires all seven measured inputs', () {
    expect(news2Complete(ClinicalAssessment()), isFalse);
    final filled = _news2Filled();
    expect(news2Complete(filled), isTrue);
    filled.news2HeartRateMeasured = '';
    expect(news2Complete(filled), isFalse);
  });

  test('qsofaComplete requires respiration, systolic BP and consciousness', () {
    expect(qsofaComplete(ClinicalAssessment()), isFalse);
    expect(qsofaComplete(_news2Filled()), isTrue);
  });

  test('sofaComplete requires all six organ systems', () {
    expect(sofaComplete(ClinicalAssessment()), isFalse);
    final filled = _sofaFilled();
    expect(sofaComplete(filled), isTrue);
    filled.sofaRenalMeasured = '';
    expect(sofaComplete(filled), isFalse);
  });

  test('shockInputsIncomplete flags vasopressor without lactate/MAP', () {
    final a = ClinicalAssessment(vasopressor: true);
    expect(shockInputsIncomplete(a), isTrue);
    a.lactate = '2.5';
    a.sofaCardiovascularMeasured = 'MAP 65';
    expect(shockInputsIncomplete(a), isFalse);
  });

  test('lactateComplete accepts a quick-mode lactate level', () {
    expect(lactateComplete(ClinicalAssessment()), isFalse);
    expect(
      lactateComplete(ClinicalAssessment(lactate: '2.1')),
      isTrue,
    );
    expect(
      lactateComplete(ClinicalAssessment(
        assessmentMode: ClinicalAssessment.assessmentModeQuick,
        lactateLevel: '< 2 mmol/L',
      )),
      isTrue,
    );
  });
}
