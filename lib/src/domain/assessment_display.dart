import 'clinical_assessment.dart';
import 'clinical_value_parser.dart';
import 'scoring.dart';

enum ClinicalStatus {
  missing,
  normal,
  watch,
  warning,
  danger,
}

class MissingDataItem {
  final String id;
  final String label;
  final String sectionId;
  final String fieldId;
  final String groupLabel;

  const MissingDataItem({
    required this.id,
    required this.label,
    required this.sectionId,
    required this.fieldId,
    required this.groupLabel,
  });
}

class ScoreDisplay {
  final String title;
  final String scoreText;
  final ClinicalStatus status;
  final String statusLabel;
  final String helperText;
  final int completedCount;
  final int totalCount;

  const ScoreDisplay({
    required this.title,
    required this.scoreText,
    required this.status,
    required this.statusLabel,
    required this.helperText,
    required this.completedCount,
    required this.totalCount,
  });
}

class SectionProgress {
  final String sectionId;
  final int completedCount;
  final int totalCount;
  final List<String> missingLabels;

  const SectionProgress({
    required this.sectionId,
    required this.completedCount,
    required this.totalCount,
    required this.missingLabels,
  });

  bool get complete => completedCount >= totalCount;
}

class PatientRiskSummary {
  final bool incomplete;
  final bool highRisk;
  final bool septicShock;
  final ClinicalStatus highestStatus;

  const PatientRiskSummary({
    required this.incomplete,
    required this.highRisk,
    required this.septicShock,
    required this.highestStatus,
  });
}

class AssessmentSections {
  static const patient = 'patient';
  static const news2 = 'news2';
  static const lactate = 'lactate';
  static const sofa = 'sofa';
  static const diagnosis = 'diagnosis';
}

class AssessmentFields {
  static const patientId = 'patientId';
  static const fullName = 'fullName';
  static const admissionDate = 'admissionDate';
  static const admissionTime = 'admissionTime';
  static const respiration = 'news2Respiration';
  static const systolicBp = 'news2SystolicBp';
  static const consciousness = 'news2Consciousness';
  static const spo2 = 'news2Spo2';
  static const oxygen = 'news2Oxygen';
  static const temperature = 'news2Temperature';
  static const heartRate = 'news2HeartRate';
  static const lactate = 'lactate';
  static const lactateSampleTime = 'lactateSampleTime';
  static const cardiovascular = 'sofaCardiovascular';
  static const sofaRespiration = 'sofaRespiration';
  static const sofaCoagulation = 'sofaCoagulation';
  static const sofaLiver = 'sofaLiver';
  static const sofaNeurologic = 'sofaNeurologic';
  static const sofaRenal = 'sofaRenal';
}

class AssessmentDisplay {
  const AssessmentDisplay._();

  static bool _hasText(String value) => ClinicalValueParser.hasText(value);

  static List<MissingDataItem> news2MissingItems(
    ClinicalAssessment assessment,
  ) {
    final items = <MissingDataItem>[];
    void addIfMissing(String value, String id, String label, String fieldId) {
      if (!_hasText(value)) {
        items.add(MissingDataItem(
          id: id,
          label: label,
          sectionId: AssessmentSections.news2,
          fieldId: fieldId,
          groupLabel: 'NEWS2/qSOFA',
        ));
      }
    }

    addIfMissing(
      assessment.news2RespirationMeasured,
      'news2_respiration',
      'Nhịp thở',
      AssessmentFields.respiration,
    );
    addIfMissing(
      assessment.news2Spo2Measured,
      'news2_spo2',
      'SpO2',
      AssessmentFields.spo2,
    );
    addIfMissing(
      assessment.news2OxygenMeasured,
      'news2_oxygen',
      'Oxy hỗ trợ',
      AssessmentFields.oxygen,
    );
    addIfMissing(
      assessment.news2TemperatureMeasured,
      'news2_temperature',
      'Nhiệt độ',
      AssessmentFields.temperature,
    );
    addIfMissing(
      assessment.news2SystolicBpMeasured,
      'news2_systolic_bp',
      'HA tâm thu',
      AssessmentFields.systolicBp,
    );
    addIfMissing(
      assessment.news2HeartRateMeasured,
      'news2_heart_rate',
      'Nhịp tim',
      AssessmentFields.heartRate,
    );
    addIfMissing(
      assessment.news2ConsciousnessMeasured,
      'news2_consciousness',
      'Tri giác',
      AssessmentFields.consciousness,
    );
    return items;
  }

  static List<MissingDataItem> qsofaMissingItems(
    ClinicalAssessment assessment,
  ) {
    final allNews2 = news2MissingItems(assessment);
    return allNews2
        .where((item) =>
            item.fieldId == AssessmentFields.respiration ||
            item.fieldId == AssessmentFields.systolicBp ||
            item.fieldId == AssessmentFields.consciousness)
        .map((item) => MissingDataItem(
              id: item.id.replaceFirst('news2', 'qsofa'),
              label: item.label,
              sectionId: item.sectionId,
              fieldId: item.fieldId,
              groupLabel: 'NEWS2/qSOFA',
            ))
        .toList();
  }

  static List<MissingDataItem> sofaMissingItems(
    ClinicalAssessment assessment,
  ) {
    final items = <MissingDataItem>[];
    void addIfMissing(String value, String id, String label, String fieldId) {
      if (!_hasText(value)) {
        items.add(MissingDataItem(
          id: id,
          label: label,
          sectionId: AssessmentSections.sofa,
          fieldId: fieldId,
          groupLabel: 'SOFA',
        ));
      }
    }

    addIfMissing(
      assessment.sofaRespirationMeasured,
      'sofa_respiration',
      'Hô hấp',
      AssessmentFields.sofaRespiration,
    );
    addIfMissing(
      assessment.sofaCoagulationMeasured,
      'sofa_coagulation',
      'Đông máu',
      AssessmentFields.sofaCoagulation,
    );
    addIfMissing(
      assessment.sofaLiverMeasured,
      'sofa_liver',
      'Gan',
      AssessmentFields.sofaLiver,
    );
    if (!_hasText(assessment.sofaCardiovascularMeasured) &&
        !assessment.vasopressor) {
      items.add(const MissingDataItem(
        id: 'sofa_cardiovascular',
        label: 'Tim mạch',
        sectionId: AssessmentSections.lactate,
        fieldId: AssessmentFields.cardiovascular,
        groupLabel: 'SOFA',
      ));
    }
    addIfMissing(
      assessment.sofaNeurologicMeasured,
      'sofa_neurologic',
      'Thần kinh',
      AssessmentFields.sofaNeurologic,
    );
    addIfMissing(
      assessment.sofaRenalMeasured,
      'sofa_renal',
      'Thận',
      AssessmentFields.sofaRenal,
    );
    return items;
  }

  static List<MissingDataItem> shockMissingItems(
    ClinicalAssessment assessment,
  ) {
    if (!assessment.vasopressor) {
      return const [];
    }
    final items = <MissingDataItem>[];
    if (!_hasText(assessment.lactate)) {
      items.add(const MissingDataItem(
        id: 'shock_lactate',
        label: 'Lactate',
        sectionId: AssessmentSections.lactate,
        fieldId: AssessmentFields.lactate,
        groupLabel: 'Sốc nhiễm khuẩn',
      ));
    }
    if (!_hasText(assessment.sofaCardiovascularMeasured)) {
      items.add(const MissingDataItem(
        id: 'shock_map',
        label: 'MAP/vận mạch',
        sectionId: AssessmentSections.lactate,
        fieldId: AssessmentFields.cardiovascular,
        groupLabel: 'Sốc nhiễm khuẩn',
      ));
    }
    return items;
  }

  static List<MissingDataItem> allMissingItems(
    ClinicalAssessment assessment,
  ) {
    final seen = <String>{};
    final items = <MissingDataItem>[];
    for (final item in [
      ...news2MissingItems(assessment),
      ...sofaMissingItems(assessment),
      ...shockMissingItems(assessment),
    ]) {
      if (seen.add('${item.sectionId}:${item.fieldId}:${item.groupLabel}')) {
        items.add(item);
      }
    }
    return items;
  }

  static SectionProgress news2Progress(ClinicalAssessment assessment) {
    final missing = news2MissingItems(assessment);
    return SectionProgress(
      sectionId: AssessmentSections.news2,
      completedCount: 7 - missing.length,
      totalCount: 7,
      missingLabels: missing.map((item) => item.label).toList(),
    );
  }

  static SectionProgress qsofaProgress(ClinicalAssessment assessment) {
    final missing = qsofaMissingItems(assessment);
    return SectionProgress(
      sectionId: AssessmentSections.news2,
      completedCount: 3 - missing.length,
      totalCount: 3,
      missingLabels: missing.map((item) => item.label).toList(),
    );
  }

  static SectionProgress lactateProgress(ClinicalAssessment assessment) {
    final missing = <String>[];
    if (!_hasText(assessment.lactate)) {
      missing.add('Lactate');
    }
    if (assessment.vasopressor &&
        !_hasText(assessment.sofaCardiovascularMeasured)) {
      missing.add('MAP/vận mạch');
    }
    final total = assessment.vasopressor ? 2 : 1;
    return SectionProgress(
      sectionId: AssessmentSections.lactate,
      completedCount: total - missing.length,
      totalCount: total,
      missingLabels: missing,
    );
  }

  static SectionProgress sofaProgress(ClinicalAssessment assessment) {
    final missing = sofaMissingItems(assessment);
    return SectionProgress(
      sectionId: AssessmentSections.sofa,
      completedCount: 6 - missing.length,
      totalCount: 6,
      missingLabels: missing.map((item) => item.label).toList(),
    );
  }

  static ClinicalStatus news2Status(ClinicalAssessment assessment) {
    if (news2MissingItems(assessment).isNotEmpty) {
      return ClinicalStatus.missing;
    }
    if (assessment.news2Total >= 7) {
      return ClinicalStatus.danger;
    }
    if (assessment.news2Total >= 5) {
      return ClinicalStatus.warning;
    }
    if (News2Scoring.hasSingleThreeScore(assessment)) {
      return ClinicalStatus.watch;
    }
    return ClinicalStatus.normal;
  }

  static ClinicalStatus qsofaStatus(ClinicalAssessment assessment) {
    if (qsofaMissingItems(assessment).isNotEmpty) {
      return ClinicalStatus.missing;
    }
    return assessment.qsofaTotal >= 2
        ? ClinicalStatus.danger
        : ClinicalStatus.normal;
  }

  static ClinicalStatus sofaStatus(ClinicalAssessment assessment) {
    if (SofaScoring.hasSepticShock(assessment) ||
        SofaScoring.riskGroup(assessment.sofaTotal) == SofaScoring.riskHigh) {
      return ClinicalStatus.danger;
    }
    if (sofaMissingItems(assessment).isNotEmpty) {
      return ClinicalStatus.missing;
    }
    if (SofaScoring.riskGroup(assessment.sofaTotal) ==
        SofaScoring.riskIntermediate) {
      return ClinicalStatus.warning;
    }
    if (SofaScoring.hasSepsisBySofa(assessment)) {
      return ClinicalStatus.watch;
    }
    return ClinicalStatus.normal;
  }

  static ClinicalStatus diagnosisStatus(ClinicalAssessment assessment) {
    if (shockMissingItems(assessment).isNotEmpty ||
        sofaMissingItems(assessment).isNotEmpty) {
      return ClinicalStatus.missing;
    }
    if (SofaScoring.hasSepticShock(assessment)) {
      return ClinicalStatus.danger;
    }
    if (SofaScoring.hasSepsisBySofa(assessment)) {
      return ClinicalStatus.warning;
    }
    return ClinicalStatus.normal;
  }

  static ScoreDisplay news2ScoreDisplay(ClinicalAssessment assessment) {
    final progress = news2Progress(assessment);
    final complete = progress.complete;
    final status = news2Status(assessment);
    return ScoreDisplay(
      title: 'NEWS2',
      scoreText: complete ? '${assessment.news2Total}' : '-',
      status: status,
      statusLabel: complete ? _news2StatusLabel(assessment) : 'Chưa đủ dữ liệu',
      helperText: complete
          ? _news2Helper(assessment)
          : 'Thiếu ${progress.totalCount - progress.completedCount}/${progress.totalCount} tiêu chí',
      completedCount: progress.completedCount,
      totalCount: progress.totalCount,
    );
  }

  static ScoreDisplay qsofaScoreDisplay(ClinicalAssessment assessment) {
    final progress = qsofaProgress(assessment);
    final complete = progress.complete;
    return ScoreDisplay(
      title: 'qSOFA',
      scoreText: complete ? '${assessment.qsofaTotal}' : '-',
      status: qsofaStatus(assessment),
      statusLabel: complete
          ? (assessment.qsofaTotal >= 2 ? 'Dương tính' : 'Chưa cảnh báo')
          : 'Chưa đủ dữ liệu',
      helperText:
          complete ? 'Tổng ${assessment.qsofaTotal}/3' : 'Thiếu dữ liệu qSOFA',
      completedCount: progress.completedCount,
      totalCount: progress.totalCount,
    );
  }

  static ScoreDisplay sofaScoreDisplay(ClinicalAssessment assessment) {
    final progress = sofaProgress(assessment);
    final complete = progress.complete;
    return ScoreDisplay(
      title: 'SOFA',
      scoreText: complete ? '${assessment.sofaTotal}' : '-',
      status: sofaStatus(assessment),
      statusLabel: complete
          ? (SofaScoring.hasSepsisBySofa(assessment) ? 'SOFA >= 2' : 'SOFA < 2')
          : 'Chưa đủ dữ liệu',
      helperText: complete
          ? (SofaScoring.hasSepticShock(assessment)
              ? 'Đủ tiêu chí sốc nhiễm khuẩn'
              : sofaThresholdText(assessment))
          : 'Thiếu ${progress.totalCount - progress.completedCount}/${progress.totalCount} hệ cơ quan',
      completedCount: progress.completedCount,
      totalCount: progress.totalCount,
    );
  }

  static ScoreDisplay diagnosisScoreDisplay(ClinicalAssessment assessment) {
    final status = diagnosisStatus(assessment);
    final missing = [
      ...sofaMissingItems(assessment),
      ...shockMissingItems(assessment),
    ];
    return ScoreDisplay(
      title: 'Kết luận',
      scoreText: status == ClinicalStatus.missing ? '-' : '✓',
      status: status,
      statusLabel: status == ClinicalStatus.missing
          ? 'Chưa thể xác định'
          : assessment.sepsisDiagnosis,
      helperText: status == ClinicalStatus.missing
          ? 'Cần bổ sung ${missing.length} dữ liệu'
          : _diagnosisHelper(assessment),
      completedCount: missing.isEmpty ? 1 : 0,
      totalCount: 1,
    );
  }

  static bool isIncompletePatient(ClinicalAssessment assessment) {
    return news2MissingItems(assessment).isNotEmpty ||
        sofaMissingItems(assessment).isNotEmpty ||
        shockMissingItems(assessment).isNotEmpty;
  }

  static bool isHighRiskPatient(ClinicalAssessment assessment) {
    return news2Status(assessment) == ClinicalStatus.danger ||
        qsofaStatus(assessment) == ClinicalStatus.danger ||
        sofaStatus(assessment) == ClinicalStatus.danger ||
        diagnosisStatus(assessment) == ClinicalStatus.danger;
  }

  static bool isSepticShockPatient(ClinicalAssessment assessment) {
    return SofaScoring.hasSepticShock(assessment);
  }

  static PatientRiskSummary patientRiskSummary(ClinicalAssessment assessment) {
    final statuses = [
      news2Status(assessment),
      qsofaStatus(assessment),
      sofaStatus(assessment),
      diagnosisStatus(assessment),
    ];
    statuses.sort((a, b) => _severity(b).compareTo(_severity(a)));
    return PatientRiskSummary(
      incomplete: isIncompletePatient(assessment),
      highRisk: isHighRiskPatient(assessment),
      septicShock: isSepticShockPatient(assessment),
      highestStatus: statuses.first,
    );
  }

  static String clinicalStatusLabel(ClinicalStatus status) {
    return switch (status) {
      ClinicalStatus.missing => 'Chưa đủ dữ liệu',
      ClinicalStatus.normal => 'Bình thường',
      ClinicalStatus.watch => 'Cần theo dõi',
      ClinicalStatus.warning => 'Nguy cơ cao',
      ClinicalStatus.danger => 'Cảnh báo nặng',
    };
  }

  static int _severity(ClinicalStatus status) {
    return switch (status) {
      ClinicalStatus.missing => 0,
      ClinicalStatus.normal => 1,
      ClinicalStatus.watch => 2,
      ClinicalStatus.warning => 3,
      ClinicalStatus.danger => 4,
    };
  }

  static String _news2StatusLabel(ClinicalAssessment assessment) {
    if (assessment.news2Total >= 7) {
      return 'Nguy cơ cao';
    }
    if (assessment.news2Total >= 5) {
      return 'Cần theo dõi sát';
    }
    if (News2Scoring.hasSingleThreeScore(assessment)) {
      return 'Cần theo dõi';
    }
    return 'Nguy cơ thấp';
  }

  static String _news2Helper(ClinicalAssessment assessment) {
    if (assessment.news2Total >= 7) {
      return 'Cần đánh giá lại ngay';
    }
    if (assessment.news2Total >= 5 ||
        News2Scoring.hasSingleThreeScore(assessment)) {
      return 'Theo dõi và báo bác sĩ';
    }
    return 'Tiếp tục theo dõi';
  }

  static String _diagnosisHelper(ClinicalAssessment assessment) {
    if (SofaScoring.hasSepticShock(assessment)) {
      return 'Vận mạch + MAP >= 65 + lactate >= 2';
    }
    if (SofaScoring.hasSepsisBySofa(assessment)) {
      return 'Đạt ngưỡng rối loạn cơ quan';
    }
    return 'Chưa đạt ngưỡng Sepsis-3';
  }
}
