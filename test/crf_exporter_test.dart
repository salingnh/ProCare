import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:news2_l/src/domain/clinical_assessment.dart';
import 'package:news2_l/src/domain/scoring.dart';
import 'package:news2_l/src/export/crf_exporter.dart';

void main() {
  test('DOCX export includes table notes and bolds selected NEWS2 range',
      () async {
    final assessment = ClinicalAssessment(news2TemperatureMeasured: '36');
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
    expect(
      xml,
      contains(
        '<w:rPr><w:b/></w:rPr><w:t xml:space="preserve">35.1-36</w:t>',
      ),
    );
  });
}
