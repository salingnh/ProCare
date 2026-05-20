import 'package:flutter_test/flutter_test.dart';
import 'package:news2_l/src/domain/clinical_assessment.dart';
import 'package:news2_l/src/domain/clinical_value_parser.dart';
import 'package:news2_l/src/domain/scoring.dart';
import 'package:news2_l/src/export/crf_exporter.dart';

void main() {
  test('parser accepts comma decimal and strips unit text', () {
    expect(ClinicalValueParser.parseDouble('38,5 °C'), 38.5);
    expect(ClinicalValueParser.parseInteger('110 mmHg'), 110);
  });

  test('NEWS2 scoring calculates expected total', () {
    final assessment = ClinicalAssessment(
      news2RespirationMeasured: '25',
      news2Spo2Measured: '95',
      news2OxygenMeasured: 'Có',
      news2TemperatureMeasured: '39.2',
      news2SystolicBpMeasured: '88',
      news2HeartRateMeasured: '120',
      news2ConsciousnessMeasured: 'V',
    );

    recalculateClinicalAssessment(assessment);

    expect(assessment.news2Respiration, 3);
    expect(assessment.news2Spo2, 1);
    expect(assessment.news2Oxygen, 2);
    expect(assessment.news2Temperature, 2);
    expect(assessment.news2SystolicBp, 3);
    expect(assessment.news2HeartRate, 2);
    expect(assessment.news2Consciousness, 3);
    expect(assessment.news2Total, 16);
    expect(assessment.qsofaTotal, 3);
  });

  test('NEWS2 boundary scores match clinical thresholds', () {
    expect(News2Scoring.scoreRespiration(8, 0), 3);
    expect(News2Scoring.scoreRespiration(9, 0), 1);
    expect(News2Scoring.scoreRespiration(12, 3), 0);
    expect(News2Scoring.scoreRespiration(21, 0), 2);
    expect(News2Scoring.scoreRespiration(25, 0), 3);

    expect(News2Scoring.scoreSpo2Scale1(91, 0), 3);
    expect(News2Scoring.scoreSpo2Scale1(92, 0), 2);
    expect(News2Scoring.scoreSpo2Scale1(94, 0), 1);
    expect(News2Scoring.scoreSpo2Scale1(96, 3), 0);

    expect(News2Scoring.scoreSpo2Scale2(83, 0), 3);
    expect(News2Scoring.scoreSpo2Scale2(84, 0), 2);
    expect(News2Scoring.scoreSpo2Scale2(86, 0), 1);
    expect(News2Scoring.scoreSpo2Scale2(88, 3), 0);
    expect(News2Scoring.scoreSpo2Scale2(93, 0), 1);
    expect(News2Scoring.scoreSpo2Scale2(95, 0), 2);
    expect(News2Scoring.scoreSpo2Scale2(97, 0), 3);

    expect(News2Scoring.scoreTemperature(35.0, 0), 3);
    expect(News2Scoring.scoreTemperature(35.1, 0), 1);
    expect(News2Scoring.scoreTemperature(36.1, 3), 0);
    expect(News2Scoring.scoreTemperature(38.1, 0), 1);
    expect(News2Scoring.scoreTemperature(39.1, 0), 2);

    expect(News2Scoring.scoreSystolicBp(90, 0), 3);
    expect(News2Scoring.scoreSystolicBp(91, 0), 2);
    expect(News2Scoring.scoreSystolicBp(101, 0), 1);
    expect(News2Scoring.scoreSystolicBp(111, 3), 0);
    expect(News2Scoring.scoreSystolicBp(220, 0), 3);

    expect(News2Scoring.scoreHeartRate(40, 0), 3);
    expect(News2Scoring.scoreHeartRate(41, 0), 1);
    expect(News2Scoring.scoreHeartRate(51, 3), 0);
    expect(News2Scoring.scoreHeartRate(91, 0), 1);
    expect(News2Scoring.scoreHeartRate(111, 0), 2);
    expect(News2Scoring.scoreHeartRate(131, 0), 3);

    expect(News2Scoring.scoreConsciousness('A', 3), 0);
    expect(News2Scoring.scoreConsciousness('Tỉnh', 3), 0);
    expect(News2Scoring.scoreConsciousness('C', 0), 3);
    expect(News2Scoring.scoreConsciousness('V', 0), 3);
  });

  test('qSOFA and Sepsis-3 diagnosis match clinical rules', () {
    final assessment = ClinicalAssessment(
      news2RespirationMeasured: '22',
      news2SystolicBpMeasured: '100',
      news2ConsciousnessMeasured: 'P',
      sofaNeurologicMeasured: '13',
    );
    recalculateClinicalAssessment(assessment);

    expect(assessment.qsofaRespiration, isTrue);
    expect(assessment.qsofaSystolicBp, isTrue);
    expect(assessment.qsofaConsciousness, isTrue);
    expect(assessment.qsofaTotal, 3);
    expect(assessment.sofaTotal, 1);
    expect(assessment.sepsisDiagnosis, 'Không Nhiễm khuẩn huyết');
    expect(
      sofaThresholdText(assessment),
      'SOFA < 2: chưa đủ ngưỡng rối loạn cơ quan theo Sepsis-3',
    );

    assessment.sofaRenalMeasured = '2.0';
    recalculateClinicalAssessment(assessment);
    expect(assessment.sofaTotal, 3);
    expect(assessment.sepsisDiagnosis, 'Có Nhiễm khuẩn huyết');
    expect(
      sofaThresholdText(assessment),
      'SOFA ≥ 2: đạt ngưỡng rối loạn cơ quan theo Sepsis-3',
    );

    assessment.vasopressor = true;
    assessment.sofaCardiovascularMeasured = 'MAP 65';
    assessment.lactateLevel = '≥ 2 mmol/L';
    recalculateClinicalAssessment(assessment);
    expect(assessment.sepsisDiagnosis, 'Sốc nhiễm khuẩn');
  });

  test('qSOFA altered consciousness is checked for AVPU C V P U values', () {
    for (final value in ['C', 'V', 'P', 'U', 'C/V/P/U - Lú lẫn']) {
      final assessment = ClinicalAssessment(news2ConsciousnessMeasured: value);
      recalculateClinicalAssessment(assessment);
      expect(
        assessment.qsofaConsciousness,
        isTrue,
        reason: '$value should count as altered consciousness',
      );
      expect(assessment.qsofaTotal, 1);
    }

    final alert = ClinicalAssessment(news2ConsciousnessMeasured: 'A');
    recalculateClinicalAssessment(alert);
    expect(alert.qsofaConsciousness, isFalse);
    expect(alert.qsofaTotal, 0);
  });

  test('SOFA boundary scores and risk groups match clinical thresholds', () {
    expect(SofaScoring.scoreRespiration('399', 0), 1);
    expect(SofaScoring.scoreRespiration('299', 0), 2);
    expect(SofaScoring.scoreRespiration('199 thở oxy', 0), 3);
    expect(SofaScoring.scoreRespiration('99 vent', 0), 4);

    expect(SofaScoring.scoreCoagulation('149', 0), 1);
    expect(SofaScoring.scoreCoagulation('99', 0), 2);
    expect(SofaScoring.scoreCoagulation('49', 0), 3);
    expect(SofaScoring.scoreCoagulation('19', 0), 4);

    expect(SofaScoring.scoreLiver('1.2 mg/dL', 0), 1);
    expect(SofaScoring.scoreLiver('2.0 mg/dL', 0), 2);
    expect(SofaScoring.scoreLiver('6.0 mg/dL', 0), 3);
    expect(SofaScoring.scoreLiver('12.0 mg/dL', 0), 4);
    expect(SofaScoring.scoreLiver('34.2 µmol/L', 0), 2);
    expect(SofaScoring.scoreLiver('34.2', 0, unit: 'µmol/L'), 2);

    expect(SofaScoring.scoreCardiovascular('69', false, 0), 1);
    expect(SofaScoring.scoreCardiovascular('', true, 0), 2);
    expect(SofaScoring.scoreCardiovascular('dopamine 6', false, 0), 3);
    expect(SofaScoring.scoreCardiovascular('norepi 0.2', false, 0), 4);

    expect(SofaScoring.scoreNeurologic('14', 0), 1);
    expect(SofaScoring.scoreNeurologic('12', 0), 2);
    expect(SofaScoring.scoreNeurologic('9', 0), 3);
    expect(SofaScoring.scoreNeurologic('5', 0), 4);

    expect(SofaScoring.scoreRenal('1.2 mg/dL', 0), 1);
    expect(SofaScoring.scoreRenal('2.0 mg/dL', 0), 2);
    expect(SofaScoring.scoreRenal('3.5 mg/dL', 0), 3);
    expect(SofaScoring.scoreRenal('5.0 mg/dL', 0), 4);
    expect(
      SofaScoring.scoreRenal('177', 0, creatinineUnit: 'µmol/L'),
      2,
    );
    expect(SofaScoring.scoreRenal('400 ml nước tiểu', 0), 3);
    expect(SofaScoring.scoreRenal('100 ml nước tiểu', 0), 4);
    expect(
      SofaScoring.scoreRenal('400 ml nước tiểu', 0, creatinineUnit: 'µmol/L'),
      3,
    );
    expect(
      SofaScoring.scoreRenal('Creatinin 2.0 mg/dL, nước tiểu 400 ml', 0),
      3,
    );

    expect(SofaScoring.riskGroup(8), SofaScoring.riskLow);
    expect(SofaScoring.riskGroup(9), SofaScoring.riskIntermediate);
    expect(SofaScoring.riskGroup(12), SofaScoring.riskHigh);
  });

  test('SOFA bilirubin and creatinine use persisted unit fields', () {
    final assessment = ClinicalAssessment(
      sofaLiverMeasured: '34.2',
      sofaLiverUnit: 'µmol/L',
      sofaRenalMeasured: '177',
      sofaRenalUnit: 'µmol/L',
    );

    recalculateClinicalAssessment(assessment);

    expect(assessment.sofaLiver, 2);
    expect(assessment.sofaRenal, 2);
  });

  test('ClinicalAssessment persists SOFA unit selections', () {
    final assessment = ClinicalAssessment(
      sofaLiverUnit: 'µmol/L',
      sofaRenalUnit: 'µmol/L',
    );

    final restored = ClinicalAssessment.fromJson(assessment.toJson());

    expect(restored.sofaLiverUnit, 'µmol/L');
    expect(restored.sofaRenalUnit, 'µmol/L');
  });

  test('SOFA sepsis helpers set diagnosis', () {
    final assessment = ClinicalAssessment(
      lactate: '4.2',
      vasopressor: true,
      sofaCardiovascularMeasured: 'MAP 66',
      sofaNeurologicMeasured: '13',
    );

    recalculateClinicalAssessment(assessment);

    expect(assessment.sofaNeurologic, 1);
    expect(assessment.sepsisDiagnosis, 'Sốc nhiễm khuẩn');
  });

  test('septic shock requires vasopressor, MAP at least 65, and lactate >= 2',
      () {
    final assessment = ClinicalAssessment(
      lactate: '2.1',
      vasopressor: true,
      sofaCardiovascularMeasured: 'MAP 64',
    );
    recalculateClinicalAssessment(assessment);
    expect(SofaScoring.hasSepticShock(assessment), isFalse);
    expect(assessment.sepsisDiagnosis, isNot('Sốc nhiễm khuẩn'));

    assessment.sofaCardiovascularMeasured = 'MAP 65';
    recalculateClinicalAssessment(assessment);
    expect(SofaScoring.hasSepticShock(assessment), isTrue);
    expect(assessment.sepsisDiagnosis, 'Sốc nhiễm khuẩn');

    assessment.lactate = '1.9';
    assessment.lactateLevel = '';
    recalculateClinicalAssessment(assessment);
    expect(SofaScoring.hasSepticShock(assessment), isFalse);
  });

  test('NEWS2 scores reset when measured inputs are cleared', () {
    final assessment = ClinicalAssessment(
      news2RespirationMeasured: '25',
      news2Spo2Measured: '91',
      news2OxygenMeasured: 'Có',
      news2TemperatureMeasured: '39.2',
      news2SystolicBpMeasured: '88',
      news2HeartRateMeasured: '140',
      news2ConsciousnessMeasured: 'V',
    );
    recalculateClinicalAssessment(assessment);
    expect(assessment.news2Total, greaterThan(0));

    assessment.news2RespirationMeasured = '';
    assessment.news2Spo2Measured = '';
    assessment.news2OxygenMeasured = '';
    assessment.news2TemperatureMeasured = '';
    assessment.news2SystolicBpMeasured = '';
    assessment.news2HeartRateMeasured = '';
    assessment.news2ConsciousnessMeasured = '';
    recalculateClinicalAssessment(assessment);

    expect(assessment.news2Total, 0);
    expect(assessment.qsofaTotal, 0);
  });

  test('SOFA scores reset when measured inputs and vasopressor are cleared',
      () {
    final assessment = ClinicalAssessment(
      lactate: '4.2',
      vasopressor: true,
      sofaCardiovascularMeasured: 'MAP 70 noradrenaline 0.2',
      sofaNeurologicMeasured: '9',
      sofaRenalMeasured: '5.0',
    );
    recalculateClinicalAssessment(assessment);
    expect(assessment.sofaTotal, greaterThan(0));
    expect(assessment.sepsisDiagnosis, 'Sốc nhiễm khuẩn');

    assessment.lactate = '';
    assessment.vasopressor = false;
    assessment.sofaCardiovascularMeasured = '';
    assessment.sofaNeurologicMeasured = '';
    assessment.sofaRenalMeasured = '';
    recalculateClinicalAssessment(assessment);

    expect(assessment.sofaTotal, 0);
    expect(assessment.sofaCardiovascular, 0);
    expect(assessment.sepsisDiagnosis, 'Không Nhiễm khuẩn huyết');
  });

  test('export filename sanitizes Vietnamese names', () {
    expect(
      CrfExporter.sanitizeFileName('Nguyễn Văn A / 01'),
      'Nguyễn-Văn-A-01',
    );
  });
}
