import '../domain/clinical_assessment.dart';
import '../domain/clinical_value_parser.dart';
import '../domain/scale_guidance_config.dart';
import '../domain/scoring.dart';
import 'clinical_theme.dart';

/// Pure clinical-display helpers shared by the patient list and the
/// assessment form: section completeness, conclusion text and risk tones.
/// Tones take the resolved [ClinicalTones] so they stay free of BuildContext.

bool news2Complete(ClinicalAssessment assessment) {
  if (assessment.isQuickMode) {
    return assessment.news2RespirationSelected &&
        assessment.news2Spo2Selected &&
        assessment.news2OxygenSelected &&
        assessment.news2TemperatureSelected &&
        assessment.news2SystolicBpSelected &&
        assessment.news2HeartRateSelected &&
        assessment.news2ConsciousnessSelected;
  }
  return ClinicalValueParser.hasText(assessment.news2RespirationMeasured) &&
      ClinicalValueParser.hasText(assessment.news2Spo2Measured) &&
      ClinicalValueParser.hasText(assessment.news2OxygenMeasured) &&
      ClinicalValueParser.hasText(assessment.news2TemperatureMeasured) &&
      ClinicalValueParser.hasText(assessment.news2SystolicBpMeasured) &&
      ClinicalValueParser.hasText(assessment.news2HeartRateMeasured) &&
      ClinicalValueParser.hasText(assessment.news2ConsciousnessMeasured);
}

bool qsofaComplete(ClinicalAssessment assessment) {
  if (assessment.isQuickMode) {
    return assessment.qsofaRespirationSelected &&
        assessment.qsofaSystolicBpSelected &&
        assessment.qsofaConsciousnessSelected;
  }
  return ClinicalValueParser.hasText(assessment.news2RespirationMeasured) &&
      ClinicalValueParser.hasText(assessment.news2SystolicBpMeasured) &&
      ClinicalValueParser.hasText(assessment.news2ConsciousnessMeasured);
}

bool lactateComplete(ClinicalAssessment assessment) {
  return ClinicalValueParser.hasText(assessment.lactate) ||
      (assessment.isQuickMode &&
          ClinicalValueParser.hasText(assessment.lactateLevel));
}

bool shockInputsIncomplete(ClinicalAssessment assessment) {
  if (!assessment.vasopressor) {
    return false;
  }
  return !lactateComplete(assessment) ||
      !ClinicalValueParser.hasText(assessment.sofaCardiovascularMeasured);
}

bool sofaCardiovascularComplete(ClinicalAssessment assessment) {
  if (assessment.isQuickMode) {
    return assessment.sofaCardiovascularSelected;
  }
  return ClinicalValueParser.hasText(assessment.sofaCardiovascularMeasured) ||
      assessment.vasopressor;
}

bool sofaComplete(ClinicalAssessment assessment) {
  if (assessment.isQuickMode) {
    return assessment.sofaRespirationSelected &&
        assessment.sofaCoagulationSelected &&
        assessment.sofaLiverSelected &&
        assessment.sofaCardiovascularSelected &&
        assessment.sofaNeurologicSelected &&
        assessment.sofaRenalSelected;
  }
  return ClinicalValueParser.hasText(assessment.sofaRespirationMeasured) &&
      ClinicalValueParser.hasText(assessment.sofaCoagulationMeasured) &&
      ClinicalValueParser.hasText(assessment.sofaLiverMeasured) &&
      sofaCardiovascularComplete(assessment) &&
      ClinicalValueParser.hasText(assessment.sofaNeurologicMeasured) &&
      ClinicalValueParser.hasText(assessment.sofaRenalMeasured);
}

String? diagnosisRequirementText(ClinicalAssessment assessment) {
  if (shockInputsIncomplete(assessment)) {
    return 'Cần nhập MAP và lactate để đánh giá sốc nhiễm khuẩn';
  }
  if (!sofaComplete(assessment)) {
    return 'Cần nhập đủ 6 hệ cơ quan để hoàn tất SOFA';
  }
  return null;
}

String news2ConclusionText(ClinicalAssessment assessment) {
  if (!news2Complete(assessment)) {
    return 'Cần nhập đủ 7 tiêu chí NEWS2 để hoàn tất tính điểm';
  }
  final guidance = ScaleGuidanceConfig.news2(assessment);
  return 'Điểm: NEWS2 ${assessment.news2Total}\nNguy cơ: ${guidance.risk}\nPhản ứng: ${guidance.response}';
}

String qsofaConclusionText(ClinicalAssessment assessment) {
  if (!qsofaComplete(assessment)) {
    return 'Cần nhập nhịp thở, huyết áp tâm thu và tri giác để hoàn tất qSOFA';
  }
  final guidance = ScaleGuidanceConfig.qsofa(assessment);
  return 'Điểm: qSOFA ${assessment.qsofaTotal}/3\nNguy cơ: ${guidance.risk}\nPhản ứng: ${guidance.response}';
}

String sofaConclusionText(ClinicalAssessment assessment) {
  if (!sofaComplete(assessment)) {
    return 'Cần nhập đủ 6 hệ cơ quan để hoàn tất SOFA';
  }
  final guidance = ScaleGuidanceConfig.sofa(assessment);
  return 'Điểm: SOFA ${assessment.sofaTotal}\nNguy cơ: ${guidance.risk}\nPhản ứng: ${guidance.response}';
}

RiskTone news2Tone(ClinicalAssessment assessment, ClinicalTones tones) {
  if (!news2Complete(assessment)) {
    return tones.muted;
  }
  if (assessment.news2Total >= 7) {
    return tones.danger;
  }
  if (assessment.news2Total >= 5) {
    return tones.warning;
  }
  if (News2Scoring.hasSingleThreeScore(assessment)) {
    return tones.attention;
  }
  return tones.success;
}

RiskTone qsofaTone(ClinicalAssessment assessment, ClinicalTones tones) {
  if (!qsofaComplete(assessment)) {
    return tones.muted;
  }
  return assessment.qsofaTotal >= 2 ? tones.danger : tones.success;
}

RiskTone sofaTone(ClinicalAssessment assessment, ClinicalTones tones) {
  if (SofaScoring.hasSepticShock(assessment) ||
      SofaScoring.riskGroup(assessment.sofaTotal) == SofaScoring.riskHigh) {
    return tones.danger;
  }
  if (!sofaComplete(assessment)) {
    return tones.muted;
  }
  if (SofaScoring.riskGroup(assessment.sofaTotal) ==
      SofaScoring.riskIntermediate) {
    return tones.warning;
  }
  if (SofaScoring.hasSepsisBySofa(assessment)) {
    return tones.attention;
  }
  return tones.success;
}

RiskTone sofaThresholdTone(ClinicalAssessment assessment, ClinicalTones tones) {
  if (!sofaComplete(assessment)) {
    return tones.muted;
  }
  return SofaScoring.hasSepsisBySofa(assessment)
      ? tones.warning
      : tones.success;
}

RiskTone diagnosisTone(ClinicalAssessment assessment, ClinicalTones tones) {
  if (shockInputsIncomplete(assessment)) {
    return tones.muted;
  }
  if (SofaScoring.hasSepticShock(assessment)) {
    return tones.danger;
  }
  if (!sofaComplete(assessment)) {
    return tones.muted;
  }
  if (SofaScoring.hasSepsisBySofa(assessment)) {
    return tones.warning;
  }
  return tones.success;
}

RiskTone componentScoreTone(int score, ClinicalTones tones) {
  if (score >= 3) {
    return tones.danger;
  }
  if (score >= 2) {
    return tones.warning;
  }
  if (score == 1) {
    return tones.attention;
  }
  return tones.success;
}
