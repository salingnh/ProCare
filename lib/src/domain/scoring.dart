import 'clinical_assessment.dart';
import 'clinical_value_parser.dart';

class News2Scoring {
  const News2Scoring._();

  static int total(ClinicalAssessment assessment) {
    return assessment.news2Respiration +
        assessment.news2Spo2 +
        assessment.news2Oxygen +
        assessment.news2Temperature +
        assessment.news2SystolicBp +
        assessment.news2HeartRate +
        assessment.news2Consciousness;
  }

  static bool hasSingleThreeScore(ClinicalAssessment assessment) {
    return assessment.news2Respiration == 3 ||
        assessment.news2Spo2 == 3 ||
        assessment.news2Temperature == 3 ||
        assessment.news2SystolicBp == 3 ||
        assessment.news2HeartRate == 3 ||
        assessment.news2Consciousness == 3;
  }

  static String riskLabel(ClinicalAssessment assessment) {
    if (assessment.news2Total >= 7) {
      return 'Nguy cơ cao';
    }
    if (assessment.news2Total >= 5) {
      return 'Nguy cơ trung bình';
    }
    if (hasSingleThreeScore(assessment)) {
      return 'Cần chú ý';
    }
    return 'Nguy cơ thấp';
  }

  static int scoreRespiration(int? value, int fallback) {
    if (value == null) {
      return fallback;
    }
    if (value <= 8) {
      return 3;
    }
    if (value <= 11) {
      return 1;
    }
    if (value <= 20) {
      return 0;
    }
    if (value <= 24) {
      return 2;
    }
    return 3;
  }

  static int scoreSpo2Scale1(int? value, int fallback) {
    if (value == null) {
      return fallback;
    }
    if (value <= 91) {
      return 3;
    }
    if (value <= 93) {
      return 2;
    }
    if (value <= 95) {
      return 1;
    }
    return 0;
  }

  static int scoreSpo2Scale2(int? value, int fallback) {
    if (value == null) {
      return fallback;
    }
    if (value <= 83) {
      return 3;
    }
    if (value <= 85) {
      return 2;
    }
    if (value <= 87) {
      return 1;
    }
    if (value <= 92) {
      return 0;
    }
    if (value <= 94) {
      return 1;
    }
    if (value <= 96) {
      return 2;
    }
    return 3;
  }

  static int scoreOxygenText(String? value, int fallback) {
    if (!ClinicalValueParser.hasText(value)) {
      return fallback;
    }
    final normalized = value!.trim().toLowerCase();
    if (normalized.contains('không') ||
        normalized.contains('khong') ||
        normalized.contains('room') ||
        normalized.contains('khí phòng') ||
        normalized.contains('khi phong')) {
      return 0;
    }
    if (normalized.contains('oxy') ||
        normalized.contains('oxygen') ||
        normalized.contains('có') ||
        normalized.contains('co')) {
      return 2;
    }
    return fallback;
  }

  static int scoreTemperature(double? value, int fallback) {
    if (value == null) {
      return fallback;
    }
    if (value <= 35.0) {
      return 3;
    }
    if (value <= 36.0) {
      return 1;
    }
    if (value <= 38.0) {
      return 0;
    }
    if (value <= 39.0) {
      return 1;
    }
    return 2;
  }

  static int scoreSystolicBp(int? value, int fallback) {
    if (value == null) {
      return fallback;
    }
    if (value <= 90) {
      return 3;
    }
    if (value <= 100) {
      return 2;
    }
    if (value <= 110) {
      return 1;
    }
    if (value <= 219) {
      return 0;
    }
    return 3;
  }

  static int scoreHeartRate(int? value, int fallback) {
    if (value == null) {
      return fallback;
    }
    if (value <= 40) {
      return 3;
    }
    if (value <= 50) {
      return 1;
    }
    if (value <= 90) {
      return 0;
    }
    if (value <= 110) {
      return 1;
    }
    if (value <= 130) {
      return 2;
    }
    return 3;
  }

  static int scoreConsciousness(String? value, int fallback) {
    if (!ClinicalValueParser.hasText(value)) {
      return fallback;
    }
    final normalized = value!.trim().toUpperCase();
    return normalized == 'A' ||
            normalized.contains('TINH') ||
            normalized.contains('TỈNH')
        ? 0
        : 3;
  }
}

class QsofaScoring {
  const QsofaScoring._();

  static int total(ClinicalAssessment assessment) {
    return (assessment.qsofaRespiration ? 1 : 0) +
        (assessment.qsofaSystolicBp ? 1 : 0) +
        (assessment.qsofaConsciousness ? 1 : 0);
  }
}

class SofaScoring {
  static const riskLow = 0;
  static const riskIntermediate = 1;
  static const riskHigh = 2;

  const SofaScoring._();

  static int total(ClinicalAssessment assessment) {
    return assessment.sofaRespiration +
        assessment.sofaCoagulation +
        assessment.sofaLiver +
        assessment.sofaCardiovascular +
        assessment.sofaNeurologic +
        assessment.sofaRenal;
  }

  static int riskGroup(int sofaTotal) {
    if (sofaTotal > 11) {
      return riskHigh;
    }
    if (sofaTotal >= 9) {
      return riskIntermediate;
    }
    return riskLow;
  }

  static bool hasSepsisBySofa(ClinicalAssessment assessment) {
    return assessment.sofaTotal >= 2;
  }

  static bool hasSepticShock(ClinicalAssessment assessment) {
    return assessment.vasopressor &&
        mapAtLeastSixtyFive(assessment) &&
        lactateAtLeastTwo(assessment);
  }

  static bool lactateAtLeastTwo(ClinicalAssessment assessment) {
    if (assessment.lactateLevel.isNotEmpty) {
      return !assessment.lactateLevel.startsWith('<');
    }
    final lactate = ClinicalValueParser.parseDouble(assessment.lactate);
    return lactate != null && lactate >= 2.0;
  }

  static bool mapAtLeastSixtyFive(ClinicalAssessment assessment) {
    final value = assessment.sofaCardiovascularMeasured.trim();
    if (!ClinicalValueParser.hasText(value)) {
      return false;
    }
    final map = ClinicalValueParser.parseDouble(value);
    return map != null && map >= 65.0;
  }

  static int scoreRespiration(String value, int fallback) {
    final ratio = ClinicalValueParser.parseDouble(value);
    if (ratio == null) {
      return fallback;
    }
    final lower = value.toLowerCase();
    final support = lower.contains('oxy') ||
        lower.contains('tho') ||
        lower.contains('thở') ||
        lower.contains('vent') ||
        lower.contains('hf') ||
        lower.contains('niv');
    if (ratio < 100 && support) {
      return 4;
    }
    if (ratio < 200 && support) {
      return 3;
    }
    if (ratio < 300) {
      return 2;
    }
    if (ratio < 400) {
      return 1;
    }
    return 0;
  }

  static int scoreCoagulation(String value, int fallback) {
    final platelet = ClinicalValueParser.parseDouble(value);
    if (platelet == null) {
      return fallback;
    }
    if (platelet < 20) {
      return 4;
    }
    if (platelet < 50) {
      return 3;
    }
    if (platelet < 100) {
      return 2;
    }
    if (platelet < 150) {
      return 1;
    }
    return 0;
  }

  static int scoreLiver(String value, int fallback) {
    var bilirubin = ClinicalValueParser.parseDouble(value);
    if (bilirubin == null) {
      return fallback;
    }
    final lower = value.toLowerCase();
    if (lower.contains('umol') || lower.contains('µmol')) {
      bilirubin = bilirubin / 17.1;
    }
    if (bilirubin >= 12.0) {
      return 4;
    }
    if (bilirubin >= 6.0) {
      return 3;
    }
    if (bilirubin >= 2.0) {
      return 2;
    }
    if (bilirubin >= 1.2) {
      return 1;
    }
    return 0;
  }

  static int scoreCardiovascular(
    String value,
    bool vasopressor,
    int fallback,
  ) {
    final lower = value.toLowerCase();
    final number = ClinicalValueParser.parseDouble(value);
    if (lower.contains('nor') || lower.contains('epi')) {
      if (number != null && number > 0.1) {
        return 4;
      }
      return 3;
    }
    if (lower.contains('dopamine')) {
      if (number != null && number > 15) {
        return 4;
      }
      if (number != null && number > 5) {
        return 3;
      }
      return 2;
    }
    if (lower.contains('dobutamine')) {
      return 2;
    }
    if (vasopressor) {
      return fallback > 2 ? fallback : 2;
    }
    if (number == null) {
      return fallback;
    }
    return number < 70 ? 1 : 0;
  }

  static int scoreNeurologic(String value, int fallback) {
    final gcs = ClinicalValueParser.parseInteger(value);
    if (gcs == null) {
      return fallback;
    }
    if (gcs < 6) {
      return 4;
    }
    if (gcs <= 9) {
      return 3;
    }
    if (gcs <= 12) {
      return 2;
    }
    if (gcs <= 14) {
      return 1;
    }
    return 0;
  }

  static int scoreRenal(String value, int fallback) {
    final urineOutput = _extractUrineOutput(value);
    var creatinine = _extractCreatinine(value);
    var creatinineScore = fallback;
    if (creatinine != null) {
      final lower = value.toLowerCase();
      if (lower.contains('umol') || lower.contains('µmol')) {
        creatinine = creatinine / 88.4;
      }
      if (creatinine >= 5.0) {
        creatinineScore = 4;
      } else if (creatinine >= 3.5) {
        creatinineScore = 3;
      } else if (creatinine >= 2.0) {
        creatinineScore = 2;
      } else if (creatinine >= 1.2) {
        creatinineScore = 1;
      } else {
        creatinineScore = 0;
      }
    }
    var urineScore = 0;
    if (urineOutput != null) {
      if (urineOutput < 200) {
        urineScore = 4;
      } else if (urineOutput < 500) {
        urineScore = 3;
      }
    }
    return creatinineScore > urineScore ? creatinineScore : urineScore;
  }

  static double? _extractCreatinine(String value) {
    if (!ClinicalValueParser.hasText(value)) {
      return null;
    }
    final lower = value.toLowerCase();
    final hasCreatinineHint = lower.contains('creatinin') ||
        lower.contains('creatinine') ||
        lower.contains('mg/dl') ||
        lower.contains('umol') ||
        lower.contains('µmol');
    final hasUrineHint = lower.contains('ml') ||
        lower.contains('nước tiểu') ||
        lower.contains('nuoc tieu');
    if (!hasCreatinineHint && hasUrineHint) {
      return null;
    }

    final labeledMatch = RegExp(
      r'(?:creatinin|creatinine)[^\d-]*(-?\d+(?:[,.]\d+)?)',
      caseSensitive: false,
    ).firstMatch(value);
    if (labeledMatch != null) {
      return ClinicalValueParser.parseDouble(labeledMatch.group(1));
    }

    final unitMatch = RegExp(
      r'(-?\d+(?:[,.]\d+)?)\s*(?:mg/dl|umol|µmol)',
      caseSensitive: false,
    ).firstMatch(value);
    if (unitMatch != null) {
      return ClinicalValueParser.parseDouble(unitMatch.group(1));
    }

    return ClinicalValueParser.parseDouble(value);
  }

  static int? _extractUrineOutput(String value) {
    if (!ClinicalValueParser.hasText(value)) {
      return null;
    }
    final lower = value.toLowerCase();
    final urineIndex = lower.indexOf('ml');
    if (urineIndex < 0 &&
        !lower.contains('nước tiểu') &&
        !lower.contains('nuoc tieu')) {
      return null;
    }
    final mlMatches = RegExp(
      r'(-?\d+)\s*ml',
      caseSensitive: false,
    ).allMatches(value);
    if (mlMatches.isNotEmpty) {
      return ClinicalValueParser.parseInteger(mlMatches.last.group(1));
    }
    return ClinicalValueParser.parseInteger(
      value.substring(0, urineIndex > 0 ? urineIndex : value.length),
    );
  }
}

void recalculateClinicalAssessment(ClinicalAssessment assessment) {
  assessment.news2Respiration = News2Scoring.scoreRespiration(
    ClinicalValueParser.parseInteger(assessment.news2RespirationMeasured),
    0,
  );
  final spo2 = ClinicalValueParser.parseInteger(assessment.news2Spo2Measured);
  assessment.news2Spo2 = assessment.news2Spo2Scale2
      ? News2Scoring.scoreSpo2Scale2(spo2, 0)
      : News2Scoring.scoreSpo2Scale1(spo2, 0);
  assessment.news2Oxygen = News2Scoring.scoreOxygenText(
    assessment.news2OxygenMeasured,
    0,
  );
  assessment.news2Temperature = News2Scoring.scoreTemperature(
    ClinicalValueParser.parseDouble(assessment.news2TemperatureMeasured),
    0,
  );
  assessment.news2SystolicBp = News2Scoring.scoreSystolicBp(
    ClinicalValueParser.parseInteger(assessment.news2SystolicBpMeasured),
    0,
  );
  assessment.news2HeartRate = News2Scoring.scoreHeartRate(
    ClinicalValueParser.parseInteger(assessment.news2HeartRateMeasured),
    0,
  );
  assessment.news2Consciousness = News2Scoring.scoreConsciousness(
    assessment.news2ConsciousnessMeasured,
    0,
  );
  assessment.news2Total = News2Scoring.total(assessment);

  assessment.qsofaRespiration =
      (ClinicalValueParser.parseInteger(assessment.news2RespirationMeasured) ??
              0) >=
          22;
  assessment.qsofaSystolicBp =
      (ClinicalValueParser.parseInteger(assessment.news2SystolicBpMeasured) ??
              999) <=
          100;
  final consciousness =
      assessment.news2ConsciousnessMeasured.trim().toUpperCase();
  assessment.qsofaConsciousness = ClinicalValueParser.hasText(consciousness) &&
      consciousness != 'A' &&
      !consciousness.contains('TINH') &&
      !consciousness.contains('TỈNH');
  assessment.qsofaTotal = QsofaScoring.total(assessment);

  assessment.sofaRespiration = SofaScoring.scoreRespiration(
    assessment.sofaRespirationMeasured,
    0,
  );
  assessment.sofaCoagulation = SofaScoring.scoreCoagulation(
    assessment.sofaCoagulationMeasured,
    0,
  );
  assessment.sofaLiver = SofaScoring.scoreLiver(
    assessment.sofaLiverMeasured,
    0,
  );
  assessment.sofaCardiovascular = SofaScoring.scoreCardiovascular(
    assessment.sofaCardiovascularMeasured,
    assessment.vasopressor,
    0,
  );
  assessment.sofaNeurologic = SofaScoring.scoreNeurologic(
    assessment.sofaNeurologicMeasured,
    0,
  );
  assessment.sofaRenal = SofaScoring.scoreRenal(
    assessment.sofaRenalMeasured,
    0,
  );
  assessment.sofaTotal = SofaScoring.total(assessment);
  assessment.sepsisDiagnosis = buildSepsisDiagnosis(assessment);
}

String buildSepsisDiagnosis(ClinicalAssessment assessment) {
  if (SofaScoring.hasSepticShock(assessment)) {
    return 'Sốc nhiễm khuẩn';
  }
  if (SofaScoring.hasSepsisBySofa(assessment)) {
    return 'Có Nhiễm khuẩn huyết';
  }
  return 'Không Nhiễm khuẩn huyết';
}

String sofaThresholdText(ClinicalAssessment assessment) {
  if (SofaScoring.hasSepsisBySofa(assessment)) {
    return 'SOFA ≥ 2: đạt ngưỡng rối loạn cơ quan theo Sepsis-3';
  }
  return 'SOFA < 2: chưa đủ ngưỡng rối loạn cơ quan theo Sepsis-3';
}
