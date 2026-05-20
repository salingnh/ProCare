import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:news2_l/src/domain/clinical_assessment.dart';
import 'package:news2_l/src/domain/scoring.dart';
import 'package:news2_l/src/export/crf_exporter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('DOCX export includes table notes and bolds selected NEWS2 range',
      () async {
    final assessment = ClinicalAssessment(
      news2RespirationMeasured: '25',
      news2Spo2Measured: '94',
      news2OxygenMeasured: 'Có',
      news2TemperatureMeasured: '36',
      news2SystolicBpMeasured: '100',
      news2HeartRateMeasured: '120',
      news2ConsciousnessMeasured: 'C',
      sofaLiverMeasured: '34.2',
      sofaLiverUnit: 'µmol/L',
      sofaRenalMeasured: '177',
      sofaRenalUnit: 'µmol/L',
    );
    recalculateClinicalAssessment(assessment);

    final bytes = await const CrfExporter().buildDocxBytes(assessment);
    final archive = ZipDecoder().decodeBytes(bytes);
    final document = archive.files.firstWhere(
      (file) => file.name == 'word/document.xml',
    );
    final xml = utf8.decode(document.content as List<int>);

    expect(
      xml,
      contains(
        '*Ghi chú: SpO2 Thang 2 chỉ dùng cho BN suy hô hấp tăng CO2 (COPD). Điểm 1, 2, 3 ở phía bên phải bảng điểm của Thang 2 chỉ áp dụng khi BN đang thở Oxy hỗ trợ.',
      ),
    );
    expect(
      xml,
      contains(
        'Ghi chú đánh giá SOFA: Tăng ≥ 2 điểm so với điểm nền (nếu bệnh nhân không có bệnh nền suy tạng, mặc định điểm SOFA nền = 0).',
      ),
    );
    expect(xml, contains('w:rFonts w:ascii="Noto Sans"'));
    expect(xml, contains('w:lang w:val="vi-VN"'));
    expect(_hasBoldRun(xml, '≥ 25'), isTrue);
    expect(_hasBoldRun(xml, '94-95'), isTrue);
    expect(_hasBoldRun(xml, 'Có'), isTrue);
    expect(_hasBoldRun(xml, '35.1-36'), isTrue);
    expect(_hasBoldRun(xml, '91-100'), isTrue);
    expect(_hasBoldRun(xml, '111-130'), isTrue);
    expect(_hasBoldRun(xml, 'K.Đ.Ư'), isTrue);
    expect(xml, contains('Bilirubin: 34.2 µmol/L'));
    expect(xml, contains('Creatinin/nước tiểu: 177 µmol/L'));
  });

  test('DOCX export bolds selected NEWS2 SpO2 scale 2 range', () async {
    final assessment = ClinicalAssessment(
      news2Spo2Scale2: true,
      news2Spo2Measured: '95',
    );
    recalculateClinicalAssessment(assessment);

    final xml = await _buildDocxXml(assessment);

    expect(_hasBoldRun(xml, '95-96'), isTrue);
  });

  test('PDF export builds with Unicode note and checkbox fonts', () async {
    final assessment = ClinicalAssessment(
      news2ConsciousnessMeasured: 'C',
      lactateLevel: '2 - 3.9 mmol/L',
      sepsisDiagnosis: 'Sốc nhiễm khuẩn',
      treatmentOutcome: 'Khỏi / Đỡ ra viện',
    );
    recalculateClinicalAssessment(assessment);

    final bytes = await const CrfExporter().buildPdfBytes(assessment);

    expect(bytes.length, greaterThan(1000));
    expect(bytes.take(4), equals('%PDF'.codeUnits));
  });
}

Future<String> _buildDocxXml(ClinicalAssessment assessment) async {
  final bytes = await const CrfExporter().buildDocxBytes(assessment);
  final archive = ZipDecoder().decodeBytes(bytes);
  final document = archive.files.firstWhere(
    (file) => file.name == 'word/document.xml',
  );
  return utf8.decode(document.content as List<int>);
}

bool _hasBoldRun(String xml, String text) {
  final pattern = RegExp(
    '<w:rPr>.*?<w:b/>.*?</w:rPr><w:t xml:space="preserve">${RegExp.escape(text)}</w:t>',
    dotAll: true,
  );
  return pattern.hasMatch(xml);
}
