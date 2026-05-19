import 'clinical_assessment.dart';
import 'scoring.dart';

class ScaleGuidance {
  final String risk;
  final String response;

  const ScaleGuidance({
    required this.risk,
    required this.response,
  });
}

class News2GuidanceRule {
  final bool Function(ClinicalAssessment assessment) matches;
  final ScaleGuidance guidance;

  const News2GuidanceRule({
    required this.matches,
    required this.guidance,
  });
}

class ScaleGuidanceConfig {
  const ScaleGuidanceConfig._();

  static final List<News2GuidanceRule> news2Rules = [
    News2GuidanceRule(
      matches: (assessment) => assessment.news2Total >= 7,
      guidance: ScaleGuidance(
        risk: 'Cao',
        response: [
          'Điều dưỡng trực chính ngay lập tức thông báo bác sĩ điều trị, nên là bác sĩ chuyên khoa.',
          'Cần hỗ trợ của đội ngũ hồi sức, yêu cầu kỹ năng kiểm soát đường thở nâng cao.',
          'Cân nhắc chuyển bệnh nhân sang phòng bệnh nặng hoặc ICU.',
          'Phòng bệnh nặng cần có thiết bị theo dõi.',
          'Theo dõi liên tục các dấu hiệu sinh tồn.',
        ].join('\n'),
      ),
    ),
    News2GuidanceRule(
      matches: (assessment) => assessment.news2Total >= 5,
      guidance: ScaleGuidance(
        risk: 'Trung bình',
        response: [
          'Điều dưỡng trực chính ngay lập tức thông báo bác sĩ điều trị.',
          'Điều dưỡng trực chính yêu cầu bác sĩ đủ năng lực đánh giá bệnh diễn tiến cấp tính.',
          'Chuyển bệnh nhân vào khu vực có thiết bị theo dõi.',
          'Theo dõi tối thiểu mỗi 01 giờ.',
        ].join('\n'),
      ),
    ),
    News2GuidanceRule(
      matches: News2Scoring.hasSingleThreeScore,
      guidance: ScaleGuidance(
        risk: 'Trung bình - thấp',
        response: [
          'Điều dưỡng trực chính thông báo bác sĩ điều trị để đánh giá lại và quyết định kế hoạch can thiệp.',
          'Theo dõi tối thiểu mỗi 01 giờ.',
        ].join('\n'),
      ),
    ),
    News2GuidanceRule(
      matches: (_) => true,
      guidance: ScaleGuidance(
        risk: 'Thấp',
        response: [
          'Tiếp tục theo dõi NEWS2.',
          'Thông báo điều dưỡng trực chính đánh giá bệnh nhân.',
          'Điều dưỡng trực chính quyết định mức độ theo dõi và/hoặc điều chỉnh kế hoạch chăm sóc nếu cần thiết.',
          'Theo dõi tối thiểu mỗi 12 giờ nếu 0 điểm.',
          'Theo dõi tối thiểu mỗi 4 - 6 giờ nếu từ 1 - 4 điểm.',
        ].join('\n'),
      ),
    ),
  ];

  static final List<ScaleGuidance> qsofaRules = [
    const ScaleGuidance(
      risk: 'Chưa đạt ngưỡng cảnh báo qSOFA',
      response: 'qSOFA 0 - 1: tiếp tục đánh giá lâm sàng và theo dõi.',
    ),
    const ScaleGuidance(
      risk: 'Cao',
      response: 'qSOFA >= 2: nguy cơ sepsis cao hơn, cần đánh giá SOFA.',
    ),
  ];

  static final Map<int, String> sofaRiskLabels = {
    SofaScoring.riskLow: 'Thấp hơn',
    SofaScoring.riskIntermediate: 'Trung gian',
    SofaScoring.riskHigh: 'Cao',
  };

  static const ScaleGuidance sofaBelowSepsis = ScaleGuidance(
    risk: '',
    response: 'SOFA < 2: chưa đủ ngưỡng rối loạn cơ quan theo Sepsis-3.',
  );

  static const ScaleGuidance sofaSepsis = ScaleGuidance(
    risk: '',
    response: 'SOFA >= 2: đạt ngưỡng rối loạn cơ quan theo Sepsis-3.',
  );

  static ScaleGuidance news2(ClinicalAssessment assessment) {
    return news2Rules.firstWhere((rule) => rule.matches(assessment)).guidance;
  }

  static ScaleGuidance qsofa(ClinicalAssessment assessment) {
    return assessment.qsofaTotal >= 2 ? qsofaRules[1] : qsofaRules[0];
  }

  static ScaleGuidance sofa(ClinicalAssessment assessment) {
    final riskGroup = SofaScoring.riskGroup(assessment.sofaTotal);
    final risk =
        sofaRiskLabels[riskGroup] ?? sofaRiskLabels[SofaScoring.riskLow]!;
    final base =
        SofaScoring.hasSepsisBySofa(assessment) ? sofaSepsis : sofaBelowSepsis;
    return ScaleGuidance(risk: risk, response: base.response);
  }
}
