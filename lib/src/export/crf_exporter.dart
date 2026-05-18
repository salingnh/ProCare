import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/clinical_assessment.dart';
import '../domain/clinical_value_parser.dart';

enum CrfExportFormat {
  pdf('pdf', 'application/pdf'),
  docx(
    'docx',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  );

  final String extension;
  final String mimeType;

  const CrfExportFormat(this.extension, this.mimeType);
}

class CrfExporter {
  const CrfExporter();

  Future<File> export(
    ClinicalAssessment assessment,
    CrfExportFormat format,
  ) async {
    final directory = await _exportDirectory();
    final file = File(p.join(directory.path, buildFileName(assessment, format)));
    switch (format) {
      case CrfExportFormat.pdf:
        await _writePdf(file, assessment);
        break;
      case CrfExportFormat.docx:
        await _writeDocx(file, assessment);
        break;
    }
    return file;
  }

  static String buildFileName(
    ClinicalAssessment assessment,
    CrfExportFormat format,
  ) {
    final identity = _firstText(
      assessment.patientId,
      _firstText(assessment.fullName, 'benh-nhan'),
    );
    final now = DateTime.now();
    final stamp =
        '${now.year}${_two(now.month)}${_two(now.day)}-${_two(now.hour)}${_two(now.minute)}';
    return 'NEWS2-L-${sanitizeFileName(identity)}-$stamp.${format.extension}';
  }

  static String sanitizeFileName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'benh-nhan';
    }
    final safe = trimmed
        .replaceAll(RegExp(r'[^\p{L}\p{N}._-]+', unicode: true), '-')
        .replaceAll(RegExp('-{2,}'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return safe.isEmpty ? 'benh-nhan' : safe;
  }

  Future<Directory> _exportDirectory() async {
    final external = await getExternalStorageDirectory();
    final base = external ?? await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(base.path, 'exports'));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<void> _writePdf(File file, ClinicalAssessment assessment) async {
    final fontBytes = await rootBundle.load('assets/fonts/NotoSans.ttf');
    final font = pw.Font.ttf(fontBytes);
    final document = pw.Document();
    final theme = pw.ThemeData.withFont(base: font, bold: font);

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(36),
        theme: theme,
        build: (context) => [
          _pdfTitle('BẢNG THU THẬP SỐ LIỆU NGHIÊN CỨU (CRF)'),
          _pdfText(
            'Mã bệnh nhân (ID): ${_dotsOrText(assessment.patientId)}    '
            'Ngày giờ vào viện: ${_admissionText(assessment)}',
          ),
          _pdfSection('I. TIÊU CHUẨN LỰA CHỌN VÀ LOẠI TRỪ'),
          _pdfTable([
            ['Tiêu chí', 'Có', 'Không'],
            ['1. Bệnh nhân ≥ 18 tuổi nhập viện tại Khoa Cấp cứu', '☐', '☐'],
            [
              '2. Nghi ngờ nhiễm trùng (có chỉ định dùng kháng sinh TM và/hoặc cấy máu)',
              '☐',
              '☐',
            ],
            [
              '3. Có xét nghiệm định lượng nồng độ lactate máu tĩnh mạch lúc phân loại/giờ đầu',
              '☐',
              '☐',
            ],
            [
              '4. Tử vong trong vòng 24 giờ đầu trước khi hoàn thành xét nghiệm',
              '☐',
              '☐',
            ],
            [
              '5. Đã can thiệp hồi sức/kháng sinh liều cao từ tuyến dưới chuyển lên',
              '☐',
              '☐',
            ],
          ]),
          _pdfSection('II. THÔNG TIN HÀNH CHÍNH & BỆNH NỀN'),
          _pdfText('• Họ và tên: ${_dotsOrText(assessment.fullName)}'),
          _pdfText(
            '• Tuổi: ${_dotsOrText(assessment.age)}    Giới tính: ☐ Nam    ☐ Nữ',
          ),
          _pdfText(
            '• Lý do vào viện: ${_dotsOrText(_firstText(assessment.admissionReason, assessment.suspectedInfection))}',
          ),
          _pdfText(
            '• Cơ quan nhiễm trùng: ${_dotsOrText(_firstText(assessment.infectionOrgan, assessment.suspectedInfection))}',
          ),
          _pdfText(
            '• Bệnh lý nền: ☐ ĐTĐ  ☐ Suy thận  ☐ Suy gan  ☐ Tăng HA  ☐ COPD   Khác: ..........',
          ),
          _pdfSection('III. ĐÁNH GIÁ BAN ĐẦU LÚC NHẬP VIỆN'),
          _pdfText('1. Thang điểm NEWS2'),
          _pdfTable(_news2Rows(assessment)),
        ],
      ),
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(36),
        theme: theme,
        build: (context) => [
          _pdfText('2. Thang điểm qSOFA'),
          _pdfTable(_qsofaRows(assessment)),
          _pdfSection('3. Dấu ấn sinh học ban đầu'),
          _pdfText(
            '• Nồng độ Lactate tĩnh mạch: ${_dotsOrText(assessment.lactate)} mmol/L',
          ),
          _pdfText(
            '• Thời gian lấy mẫu: ${_dotsOrText(assessment.lactateSampleTime)}',
          ),
          _pdfText(
            '• Phân mức độ: ${_checked(_lactateLow(assessment.lactateLevel))} < 2 mmol/L    '
            '${_checked(_lactateIntermediate(assessment.lactateLevel))} 2 - 3.9 mmol/L    '
            '${_checked(_lactateHigh(assessment.lactateLevel))} ≥ 4 mmol/L',
          ),
          _pdfSection('IV. THANG ĐIỂM SOFA (TIÊU CHUẨN VÀNG TRONG 24H)'),
          _pdfTable(_sofaRows(assessment)),
          _pdfSection('V. KẾT CỤC LÂM SÀNG'),
          _pdfText('1. Chẩn đoán xác định (Theo Sepsis-3):'),
          _pdfText(
            '• ${_checked(_contains(assessment.sepsisDiagnosis, 'Có Nhiễm') || _contains(assessment.sepsisDiagnosis, 'Có nhiễm'))} Có Nhiễm khuẩn huyết (SOFA ≥ 2)',
          ),
          _pdfText(
            '• ${_checked(_contains(assessment.sepsisDiagnosis, 'Không'))} Không Nhiễm khuẩn huyết (SOFA < 2)',
          ),
          _pdfText(
            '• ${_checked(_contains(assessment.sepsisDiagnosis, 'Sốc'))} Sốc nhiễm khuẩn',
          ),
          _pdfText('2. Kết quả điều trị:'),
          _pdfText(
            '• ${_checked(_contains(assessment.treatmentOutcome, 'Khỏi'))} Khỏi / Đỡ ra viện',
          ),
          _pdfText(
            '• ${_checked(_contains(assessment.treatmentOutcome, 'Chuyển'))} Chuyển viện (Tuyến TW)',
          ),
          _pdfText(
            '• ${_checked(_contains(assessment.treatmentOutcome, 'Tử vong') || _contains(assessment.treatmentOutcome, 'Nặng'))} Nặng xin về / Tử vong',
          ),
          _pdfText(
            '3. Số ngày điều trị: ${_dotsOrText(assessment.treatmentDays)} ngày.',
          ),
        ],
      ),
    );

    await file.writeAsBytes(await document.save());
  }

  Future<void> _writeDocx(File file, ClinicalAssessment assessment) async {
    final documentXml = _documentXml(assessment);
    final archive = Archive()
      ..addFile(_archiveText('[Content_Types].xml', '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>
'''))
      ..addFile(_archiveText('_rels/.rels', '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>
'''))
      ..addFile(_archiveText('word/document.xml', documentXml));
    final bytes = ZipEncoder().encode(archive);
    await file.writeAsBytes(bytes ?? const []);
  }

  String _documentXml(ClinicalAssessment a) {
    final buffer = StringBuffer()
      ..write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
      ..write(
        '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body>',
      );
    _paragraph(buffer, 'BẢNG THU THẬP SỐ LIỆU NGHIÊN CỨU (CRF)', bold: true);
    _paragraph(
      buffer,
      'Mã bệnh nhân (ID): ${_dotsOrText(a.patientId)}    Ngày giờ vào viện: ${_admissionText(a)}',
    );
    _paragraph(buffer, 'I. TIÊU CHUẨN LỰA CHỌN VÀ LOẠI TRỪ', bold: true);
    _docxTable(buffer, [
      ['Tiêu chí', 'Có', 'Không'],
      ['1. Bệnh nhân ≥ 18 tuổi nhập viện tại Khoa Cấp cứu', '☐', '☐'],
      [
        '2. Nghi ngờ nhiễm trùng (có chỉ định dùng kháng sinh TM và/hoặc cấy máu)',
        '☐',
        '☐',
      ],
      [
        '3. Có xét nghiệm định lượng nồng độ lactate máu tĩnh mạch lúc phân loại/giờ đầu',
        '☐',
        '☐',
      ],
      [
        '4. Tử vong trong vòng 24 giờ đầu trước khi hoàn thành xét nghiệm',
        '☐',
        '☐',
      ],
      [
        '5. Đã can thiệp hồi sức/kháng sinh liều cao từ tuyến dưới chuyển lên',
        '☐',
        '☐',
      ],
    ]);
    _paragraph(buffer, 'II. THÔNG TIN HÀNH CHÍNH & BỆNH NỀN', bold: true);
    _paragraph(buffer, '• Họ và tên: ${_dotsOrText(a.fullName)}');
    _paragraph(buffer, '• Tuổi: ${_dotsOrText(a.age)}    Giới tính: ☐ Nam    ☐ Nữ');
    _paragraph(
      buffer,
      '• Lý do vào viện: ${_dotsOrText(_firstText(a.admissionReason, a.suspectedInfection))}',
    );
    _paragraph(
      buffer,
      '• Cơ quan nhiễm trùng: ${_dotsOrText(_firstText(a.infectionOrgan, a.suspectedInfection))}',
    );
    _paragraph(
      buffer,
      '• Bệnh lý nền: ☐ ĐTĐ  ☐ Suy thận  ☐ Suy gan  ☐ Tăng HA  ☐ COPD   Khác: ..........',
    );
    _paragraph(buffer, 'III. ĐÁNH GIÁ BAN ĐẦU LÚC NHẬP VIỆN', bold: true);
    _docxTable(buffer, _news2Rows(a));
    _paragraph(buffer, '2. Thang điểm qSOFA', bold: true);
    _docxTable(buffer, _qsofaRows(a));
    _paragraph(buffer, '3. Dấu ấn sinh học ban đầu', bold: true);
    _paragraph(buffer, '• Nồng độ Lactate tĩnh mạch: ${_dotsOrText(a.lactate)} mmol/L');
    _paragraph(buffer, '• Thời gian lấy mẫu: ${_dotsOrText(a.lactateSampleTime)}');
    _paragraph(
      buffer,
      '• Phân mức độ: ${_checked(_lactateLow(a.lactateLevel))} < 2 mmol/L    '
      '${_checked(_lactateIntermediate(a.lactateLevel))} 2 - 3.9 mmol/L    '
      '${_checked(_lactateHigh(a.lactateLevel))} ≥ 4 mmol/L',
    );
    _paragraph(buffer, 'IV. THANG ĐIỂM SOFA (TIÊU CHUẨN VÀNG TRONG 24H)', bold: true);
    _docxTable(buffer, _sofaRows(a));
    _paragraph(buffer, 'V. KẾT CỤC LÂM SÀNG', bold: true);
    _paragraph(buffer, '1. Chẩn đoán xác định (Theo Sepsis-3):');
    _paragraph(
      buffer,
      '• ${_checked(_contains(a.sepsisDiagnosis, 'Có Nhiễm') || _contains(a.sepsisDiagnosis, 'Có nhiễm'))} Có Nhiễm khuẩn huyết (SOFA ≥ 2)',
    );
    _paragraph(
      buffer,
      '• ${_checked(_contains(a.sepsisDiagnosis, 'Không'))} Không Nhiễm khuẩn huyết (SOFA < 2)',
    );
    _paragraph(
      buffer,
      '• ${_checked(_contains(a.sepsisDiagnosis, 'Sốc'))} Sốc nhiễm khuẩn',
    );
    _paragraph(buffer, '2. Kết quả điều trị:');
    _paragraph(buffer, '• ${_checked(_contains(a.treatmentOutcome, 'Khỏi'))} Khỏi / Đỡ ra viện');
    _paragraph(buffer, '• ${_checked(_contains(a.treatmentOutcome, 'Chuyển'))} Chuyển viện (Tuyến TW)');
    _paragraph(
      buffer,
      '• ${_checked(_contains(a.treatmentOutcome, 'Tử vong') || _contains(a.treatmentOutcome, 'Nặng'))} Nặng xin về / Tử vong',
    );
    _paragraph(buffer, '3. Số ngày điều trị: ${_dotsOrText(a.treatmentDays)} ngày.');
    buffer
      ..write('<w:sectPr><w:pgSz w:w="12240" w:h="15840"/>')
      ..write('<w:pgMar w:top="720" w:right="720" w:bottom="720" w:left="720"/>')
      ..write('</w:sectPr></w:body></w:document>');
    return buffer.toString();
  }

  static pw.Widget _pdfTitle(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _pdfSection(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 10, bottom: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _pdfText(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
    );
  }

  static pw.Widget _pdfTable(List<List<String>> rows) {
    return pw.Table(
      border: pw.TableBorder.all(width: 0.5),
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: rows.map((row) {
        return pw.TableRow(
          children: row.map((cell) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(3),
              child: pw.Text(cell, style: const pw.TextStyle(fontSize: 8)),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  static List<List<String>> _news2Rows(ClinicalAssessment a) {
    return [
      ['Thông số', 'Thực đo', 'Điểm 3', 'Điểm 2', 'Điểm 1', 'Điểm 0', 'Điểm 1', 'Điểm 2', 'Điểm 3', 'Điểm'],
      ['Nhịp thở', a.news2RespirationMeasured, '≤ 8', '', '9-11', '12-20', '', '21-24', '≥ 25', _scoreIfPresent(a.news2Respiration, a.news2RespirationMeasured)],
      ['SpO2 T1', a.news2Spo2Scale2 ? '' : a.news2Spo2Measured, '≤ 91', '92-93', '94-95', '≥ 96', '', '', '', a.news2Spo2Scale2 ? '' : _scoreIfPresent(a.news2Spo2, a.news2Spo2Measured)],
      ['SpO2 T2', a.news2Spo2Scale2 ? a.news2Spo2Measured : '', '≤ 83', '84-85', '86-87', '88-92', '93-94', '95-96', '≥ 97', a.news2Spo2Scale2 ? _scoreIfPresent(a.news2Spo2, a.news2Spo2Measured) : ''],
      ['Thở oxy', a.news2OxygenMeasured, 'Có', '', '', 'Không', '', '', '', _scoreIfPresent(a.news2Oxygen, a.news2OxygenMeasured)],
      ['Nhiệt độ', a.news2TemperatureMeasured, '≤ 35.0', '', '35.1-36', '36.1-38', '38.1-39', '≥ 39.1', '', _scoreIfPresent(a.news2Temperature, a.news2TemperatureMeasured)],
      ['HA tâm thu', a.news2SystolicBpMeasured, '≤ 90', '91-100', '101-110', '111-219', '', '', '≥ 220', _scoreIfPresent(a.news2SystolicBp, a.news2SystolicBpMeasured)],
      ['Nhịp tim', a.news2HeartRateMeasured, '≤ 40', '', '41-50', '51-90', '91-110', '111-130', '≥ 131', _scoreIfPresent(a.news2HeartRate, a.news2HeartRateMeasured)],
      ['Tri giác', a.news2ConsciousnessMeasured, 'K.Đ.Ư', 'Đau', 'Gọi hỏi', 'Tỉnh (A)', '', '', '', _scoreIfPresent(a.news2Consciousness, a.news2ConsciousnessMeasured)],
      ['TỔNG ĐIỂM NEWS2', '', '', '', '', '', '', '', '', _allNews2Completed(a) ? '${a.news2Total}/21' : '........'],
    ];
  }

  static List<List<String>> _qsofaRows(ClinicalAssessment a) {
    return [
      ['Tiêu chí', 'Điểm', 'Đánh giá'],
      ['Nhịp thở ≥ 22 lần/phút', '1', _qsofaChoice(a.qsofaRespiration, ClinicalValueParser.hasText(a.news2RespirationMeasured))],
      ['Huyết áp tâm thu ≤ 100 mmHg', '1', _qsofaChoice(a.qsofaSystolicBp, ClinicalValueParser.hasText(a.news2SystolicBpMeasured))],
      ['Rối loạn ý thức (GCS < 15)', '1', _qsofaChoice(a.qsofaConsciousness, ClinicalValueParser.hasText(a.news2ConsciousnessMeasured))],
      ['TỔNG ĐIỂM qSOFA', '', _anyQsofaCompleted(a) ? '${a.qsofaTotal} / 3 điểm' : '........................ / 3 điểm'],
    ];
  }

  static List<List<String>> _sofaRows(ClinicalAssessment a) {
    return [
      ['Cơ quan', 'Thông số / Kết quả thực tế', 'Điểm số'],
      ['Hô hấp', 'PaO2/FiO2: ${_dotsOrText(a.sofaRespirationMeasured)}', _scoreIfPresent(a.sofaRespiration, a.sofaRespirationMeasured)],
      ['Đông máu', 'Tiểu cầu: ${_dotsOrText(a.sofaCoagulationMeasured)}', _scoreIfPresent(a.sofaCoagulation, a.sofaCoagulationMeasured)],
      ['Gan', 'Bilirubin: ${_dotsOrText(a.sofaLiverMeasured)}', _scoreIfPresent(a.sofaLiver, a.sofaLiverMeasured)],
      ['Tim mạch', 'MAP/Vận mạch: ${_dotsOrText(a.sofaCardiovascularMeasured)}', _scoreIfPresent(a.sofaCardiovascular, a.vasopressor ? 'vasopressor' : a.sofaCardiovascularMeasured)],
      ['Thần kinh', 'GCS: ${_dotsOrText(a.sofaNeurologicMeasured)}', _scoreIfPresent(a.sofaNeurologic, a.sofaNeurologicMeasured)],
      ['Thận', 'Creatinin/nước tiểu: ${_dotsOrText(a.sofaRenalMeasured)}', _scoreIfPresent(a.sofaRenal, a.sofaRenalMeasured)],
      ['TỔNG ĐIỂM SOFA', '', _anySofaCompleted(a) ? '${a.sofaTotal} / 24' : '........................ / 24'],
    ];
  }

  static void _docxTable(StringBuffer buffer, List<List<String>> rows) {
    buffer.write('<w:tbl><w:tblPr><w:tblBorders>');
    buffer.write('<w:top w:val="single" w:sz="6"/><w:left w:val="single" w:sz="6"/>');
    buffer.write('<w:bottom w:val="single" w:sz="6"/><w:right w:val="single" w:sz="6"/>');
    buffer.write('<w:insideH w:val="single" w:sz="6"/><w:insideV w:val="single" w:sz="6"/>');
    buffer.write('</w:tblBorders></w:tblPr>');
    for (final row in rows) {
      buffer.write('<w:tr>');
      for (final cell in row) {
        buffer.write('<w:tc><w:tcPr><w:tcW w:w="1800" w:type="dxa"/></w:tcPr>');
        _paragraph(buffer, cell);
        buffer.write('</w:tc>');
      }
      buffer.write('</w:tr>');
    }
    buffer.write('</w:tbl>');
  }

  static void _paragraph(StringBuffer buffer, String text, {bool bold = false}) {
    buffer.write('<w:p><w:r>');
    if (bold) {
      buffer.write('<w:rPr><w:b/></w:rPr>');
    }
    buffer.write('<w:t xml:space="preserve">${_escapeXml(text)}</w:t>');
    buffer.write('</w:r></w:p>');
  }

  static ArchiveFile _archiveText(String name, String value) {
    final bytes = utf8.encode(value);
    return ArchiveFile(name, bytes.length, bytes);
  }

  static String _admissionText(ClinicalAssessment a) {
    if (a.admissionDate.isEmpty && a.admissionTime.isEmpty && a.admissionDateTime.isNotEmpty) {
      return a.admissionDateTime;
    }
    final time = a.admissionTime.isEmpty ? '......... giờ ......... phút' : a.admissionTime;
    final date = a.admissionDate.isEmpty ? '........./........./202......' : a.admissionDate;
    return '$time, ngày $date';
  }

  static String _scoreIfPresent(int score, String value) {
    return ClinicalValueParser.hasText(value) ? '$score' : '';
  }

  static bool _allNews2Completed(ClinicalAssessment a) {
    return ClinicalValueParser.hasText(a.news2RespirationMeasured) &&
        ClinicalValueParser.hasText(a.news2Spo2Measured) &&
        ClinicalValueParser.hasText(a.news2OxygenMeasured) &&
        ClinicalValueParser.hasText(a.news2TemperatureMeasured) &&
        ClinicalValueParser.hasText(a.news2SystolicBpMeasured) &&
        ClinicalValueParser.hasText(a.news2HeartRateMeasured) &&
        ClinicalValueParser.hasText(a.news2ConsciousnessMeasured);
  }

  static bool _anyQsofaCompleted(ClinicalAssessment a) {
    return ClinicalValueParser.hasText(a.news2RespirationMeasured) ||
        ClinicalValueParser.hasText(a.news2SystolicBpMeasured) ||
        ClinicalValueParser.hasText(a.news2ConsciousnessMeasured);
  }

  static bool _anySofaCompleted(ClinicalAssessment a) {
    return ClinicalValueParser.hasText(a.sofaRespirationMeasured) ||
        ClinicalValueParser.hasText(a.sofaCoagulationMeasured) ||
        ClinicalValueParser.hasText(a.sofaLiverMeasured) ||
        ClinicalValueParser.hasText(a.sofaCardiovascularMeasured) ||
        ClinicalValueParser.hasText(a.sofaNeurologicMeasured) ||
        ClinicalValueParser.hasText(a.sofaRenalMeasured) ||
        a.vasopressor;
  }

  static String _qsofaChoice(bool value, bool completed) {
    if (!completed) {
      return '☐ Có (1 điểm)      ☐ Không (0 điểm)';
    }
    return '${_checked(value)} Có (1 điểm)      ${_checked(!value)} Không (0 điểm)';
  }

  static String _checked(bool checked) => checked ? '☑' : '☐';

  static String _dotsOrText(String value) {
    return ClinicalValueParser.hasText(value) ? value.trim() : '........................';
  }

  static String _firstText(String first, String fallback) {
    return ClinicalValueParser.hasText(first) ? first.trim() : fallback.trim();
  }

  static bool _contains(String value, String needle) {
    return value.toLowerCase().contains(needle.toLowerCase());
  }

  static bool _lactateLow(String value) => value.trim().startsWith('<');

  static bool _lactateHigh(String value) => value.contains('4');

  static bool _lactateIntermediate(String value) {
    return ClinicalValueParser.hasText(value) &&
        !_lactateLow(value) &&
        value.contains('2') &&
        !_lactateHigh(value);
  }

  static String _escapeXml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
