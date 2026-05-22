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

  static const _news2TableNote =
      '*Ghi chú: SpO2 Thang 2 chỉ dùng cho BN suy hô hấp tăng CO2 (COPD). Điểm 1, 2, 3 ở phía bên phải bảng điểm của Thang 2 chỉ áp dụng khi BN đang thở Oxy hỗ trợ.';
  static const _sofaTableNote =
      'Ghi chú đánh giá SOFA: Tăng ≥ 2 điểm so với điểm nền (nếu bệnh nhân không có bệnh nền suy tạng, mặc định điểm SOFA nền = 0).';
  static const _quickModeValueText = 'Đánh giá nhanh';

  Future<File> export(
    ClinicalAssessment assessment,
    CrfExportFormat format,
  ) async {
    final directory = await _exportDirectory();
    final file =
        File(p.join(directory.path, buildFileName(assessment, format)));
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

  Future<Uint8List> buildBytes(
    ClinicalAssessment assessment,
    CrfExportFormat format,
  ) {
    return switch (format) {
      CrfExportFormat.pdf => buildPdfBytes(assessment),
      CrfExportFormat.docx => buildDocxBytes(assessment),
    };
  }

  Future<Uint8List> buildPdfBytes(ClinicalAssessment assessment) async {
    final fontBytes = await rootBundle.load('assets/fonts/NotoSans.ttf');
    final boldFontBytes =
        await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
    final italicFontBytes =
        await rootBundle.load('assets/fonts/NotoSans-Italic.ttf');
    final mathFontBytes =
        await rootBundle.load('assets/fonts/NotoSansMath-Regular.ttf');
    final symbolsFontBytes =
        await rootBundle.load('assets/fonts/NotoSansSymbols2-Regular.ttf');
    final font = pw.Font.ttf(fontBytes);
    final boldFont = pw.Font.ttf(boldFontBytes);
    final italicFont = pw.Font.ttf(italicFontBytes);
    final mathFont = pw.Font.ttf(mathFontBytes);
    final symbolsFont = pw.Font.ttf(symbolsFontBytes);
    final document = pw.Document();
    final theme = pw.ThemeData.withFont(
      base: font,
      bold: boldFont,
      italic: italicFont,
      boldItalic: boldFont,
      fontFallback: [symbolsFont, mathFont],
    );

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
          _pdfTable(_news2Rows(assessment), note: _news2TableNote),
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
            '• Nồng độ Lactate tĩnh mạch: ${_lactateValueText(assessment)}',
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
          _pdfTable(_sofaRows(assessment), note: _sofaTableNote),
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

    return document.save();
  }

  Future<Uint8List> buildDocxBytes(ClinicalAssessment assessment) async {
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
    return Uint8List.fromList(ZipEncoder().encode(archive));
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
    await file.writeAsBytes(await buildPdfBytes(assessment));
  }

  Future<void> _writeDocx(File file, ClinicalAssessment assessment) async {
    await file.writeAsBytes(await buildDocxBytes(assessment));
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
    _paragraph(
        buffer, '• Tuổi: ${_dotsOrText(a.age)}    Giới tính: ☐ Nam    ☐ Nữ');
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
    _docxTable(buffer, _news2Rows(a), note: _news2TableNote);
    _paragraph(buffer, '2. Thang điểm qSOFA', bold: true);
    _docxTable(buffer, _qsofaRows(a));
    _paragraph(buffer, '3. Dấu ấn sinh học ban đầu', bold: true);
    _paragraph(buffer, '• Nồng độ Lactate tĩnh mạch: ${_lactateValueText(a)}');
    _paragraph(
        buffer, '• Thời gian lấy mẫu: ${_dotsOrText(a.lactateSampleTime)}');
    _paragraph(
      buffer,
      '• Phân mức độ: ${_checked(_lactateLow(a.lactateLevel))} < 2 mmol/L    '
      '${_checked(_lactateIntermediate(a.lactateLevel))} 2 - 3.9 mmol/L    '
      '${_checked(_lactateHigh(a.lactateLevel))} ≥ 4 mmol/L',
    );
    _paragraph(buffer, 'IV. THANG ĐIỂM SOFA (TIÊU CHUẨN VÀNG TRONG 24H)',
        bold: true);
    _docxTable(buffer, _sofaRows(a), note: _sofaTableNote);
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
    _paragraph(buffer,
        '• ${_checked(_contains(a.treatmentOutcome, 'Khỏi'))} Khỏi / Đỡ ra viện');
    _paragraph(buffer,
        '• ${_checked(_contains(a.treatmentOutcome, 'Chuyển'))} Chuyển viện (Tuyến TW)');
    _paragraph(
      buffer,
      '• ${_checked(_contains(a.treatmentOutcome, 'Tử vong') || _contains(a.treatmentOutcome, 'Nặng'))} Nặng xin về / Tử vong',
    );
    _paragraph(
        buffer, '3. Số ngày điều trị: ${_dotsOrText(a.treatmentDays)} ngày.');
    buffer
      ..write('<w:sectPr><w:pgSz w:w="12240" w:h="15840"/>')
      ..write(
          '<w:pgMar w:top="720" w:right="720" w:bottom="720" w:left="720"/>')
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

  static pw.Widget _pdfTable(List<List<Object>> rows, {String? note}) {
    final table = pw.Table(
      border: pw.TableBorder.all(width: 0.5),
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: rows.map((row) {
        return pw.TableRow(
          children: row.map((value) {
            final cell = _exportCell(value);
            return pw.Padding(
              padding: const pw.EdgeInsets.all(3),
              child: pw.Text(
                cell.text,
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight:
                      cell.bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
    if (note == null) {
      return table;
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        table,
        pw.Container(
          padding: const pw.EdgeInsets.all(3),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              left: pw.BorderSide(width: 0.5),
              right: pw.BorderSide(width: 0.5),
              bottom: pw.BorderSide(width: 0.5),
            ),
          ),
          child: pw.Text(
            note,
            style: pw.TextStyle(
              fontSize: 8,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  static List<List<Object>> _news2Rows(ClinicalAssessment a) {
    return [
      _news2Row([
        'Thông số',
        'Thực đo',
        'Điểm 3',
        'Điểm 2',
        'Điểm 1',
        'Điểm 0',
        'Điểm 1',
        'Điểm 2',
        'Điểm 3',
        'Điểm'
      ]),
      _news2Row([
        'Nhịp thở',
        _news2ValueText(
          a,
          a.news2RespirationMeasured,
          a.news2RespirationSelected,
          quickText: _news2RespirationQuickText(a.news2Respiration),
        ),
        '≤ 8',
        '',
        '9-11',
        '12-20',
        '',
        '21-24',
        '≥ 25',
        _scoreIfPresent(
          a.news2Respiration,
          a.news2RespirationMeasured,
          selected: a.news2RespirationSelected,
        )
      ],
          boldIndex: _news2RespirationBoldIndex(a.news2RespirationMeasured),
          boldIndexes: _usesSelectedValue(
            a.news2RespirationMeasured,
            a.news2RespirationSelected,
          )
              ? _news2RespirationQuickBoldIndexes(a.news2Respiration)
              : null),
      _news2Row([
        'SpO2 T1',
        a.news2Spo2Scale2
            ? ''
            : _news2ValueText(
                a,
                a.news2Spo2Measured,
                a.news2Spo2Selected,
                quickText: _news2Spo2Scale1QuickText(a.news2Spo2),
              ),
        '≤ 91',
        '92-93',
        '94-95',
        '≥ 96',
        '',
        '',
        '',
        a.news2Spo2Scale2
            ? ''
            : _scoreIfPresent(
                a.news2Spo2,
                a.news2Spo2Measured,
                selected: a.news2Spo2Selected,
              )
      ],
          boldIndex: a.news2Spo2Scale2
              ? null
              : _news2Spo2Scale1BoldIndex(a.news2Spo2Measured),
          boldIndexes: !a.news2Spo2Scale2 &&
                  _usesSelectedValue(
                    a.news2Spo2Measured,
                    a.news2Spo2Selected,
                  )
              ? _news2Spo2Scale1QuickBoldIndexes(a.news2Spo2)
              : null),
      _news2Row([
        'SpO2 T2',
        a.news2Spo2Scale2
            ? _news2ValueText(
                a,
                a.news2Spo2Measured,
                a.news2Spo2Selected,
                quickText: _news2Spo2Scale2QuickText(a.news2Spo2),
              )
            : '',
        '≤ 83',
        '84-85',
        '86-87',
        '88-92',
        '93-94',
        '95-96',
        '≥ 97',
        a.news2Spo2Scale2
            ? _scoreIfPresent(
                a.news2Spo2,
                a.news2Spo2Measured,
                selected: a.news2Spo2Selected,
              )
            : ''
      ],
          boldIndex: a.news2Spo2Scale2
              ? _news2Spo2Scale2BoldIndex(a.news2Spo2Measured)
              : null,
          boldIndexes: a.news2Spo2Scale2 &&
                  _usesSelectedValue(
                    a.news2Spo2Measured,
                    a.news2Spo2Selected,
                  )
              ? _news2Spo2Scale2QuickBoldIndexes(a.news2Spo2)
              : null),
      _news2Row([
        'Thở oxy',
        _news2ValueText(
          a,
          a.news2OxygenMeasured,
          a.news2OxygenSelected,
          quickText: _news2OxygenQuickText(a.news2Oxygen),
        ),
        '',
        'Có',
        '',
        'Không',
        '',
        '',
        '',
        _scoreIfPresent(
          a.news2Oxygen,
          a.news2OxygenMeasured,
          selected: a.news2OxygenSelected,
        )
      ],
          boldIndex: _news2OxygenBoldIndex(a.news2OxygenMeasured),
          boldIndexes: _usesSelectedValue(
            a.news2OxygenMeasured,
            a.news2OxygenSelected,
          )
              ? _news2OxygenQuickBoldIndexes(a.news2Oxygen)
              : null),
      _news2Row([
        'Nhiệt độ',
        _news2ValueText(
          a,
          a.news2TemperatureMeasured,
          a.news2TemperatureSelected,
          quickText: _news2TemperatureQuickText(a.news2Temperature),
        ),
        '≤ 35.0',
        '',
        '35.1-36',
        '36.1-38',
        '38.1-39',
        '≥ 39.1',
        '',
        _scoreIfPresent(
          a.news2Temperature,
          a.news2TemperatureMeasured,
          selected: a.news2TemperatureSelected,
        )
      ],
          boldIndex: _news2TemperatureBoldIndex(a.news2TemperatureMeasured),
          boldIndexes: _usesSelectedValue(
            a.news2TemperatureMeasured,
            a.news2TemperatureSelected,
          )
              ? _news2TemperatureQuickBoldIndexes(a.news2Temperature)
              : null),
      _news2Row([
        'HA tâm thu',
        _news2ValueText(
          a,
          a.news2SystolicBpMeasured,
          a.news2SystolicBpSelected,
          quickText: _news2SystolicBpQuickText(a.news2SystolicBp),
        ),
        '≤ 90',
        '91-100',
        '101-110',
        '111-219',
        '',
        '',
        '≥ 220',
        _scoreIfPresent(
          a.news2SystolicBp,
          a.news2SystolicBpMeasured,
          selected: a.news2SystolicBpSelected,
        )
      ],
          boldIndex: _news2SystolicBpBoldIndex(a.news2SystolicBpMeasured),
          boldIndexes: _usesSelectedValue(
            a.news2SystolicBpMeasured,
            a.news2SystolicBpSelected,
          )
              ? _news2SystolicBpQuickBoldIndexes(a.news2SystolicBp)
              : null),
      _news2Row([
        'Nhịp tim',
        _news2ValueText(
          a,
          a.news2HeartRateMeasured,
          a.news2HeartRateSelected,
          quickText: _news2HeartRateQuickText(a.news2HeartRate),
        ),
        '≤ 40',
        '',
        '41-50',
        '51-90',
        '91-110',
        '111-130',
        '≥ 131',
        _scoreIfPresent(
          a.news2HeartRate,
          a.news2HeartRateMeasured,
          selected: a.news2HeartRateSelected,
        )
      ],
          boldIndex: _news2HeartRateBoldIndex(a.news2HeartRateMeasured),
          boldIndexes: _usesSelectedValue(
            a.news2HeartRateMeasured,
            a.news2HeartRateSelected,
          )
              ? _news2HeartRateQuickBoldIndexes(a.news2HeartRate)
              : null),
      _news2Row([
        'Tri giác',
        _news2ValueText(
          a,
          a.news2ConsciousnessMeasured,
          a.news2ConsciousnessSelected,
          quickText: _news2ConsciousnessQuickText(a.news2Consciousness),
        ),
        'K.Đ.Ư',
        'Đau',
        'Gọi hỏi',
        'Tỉnh (A)',
        '',
        '',
        '',
        _scoreIfPresent(
          a.news2Consciousness,
          a.news2ConsciousnessMeasured,
          selected: a.news2ConsciousnessSelected,
        )
      ],
          boldIndex: _news2ConsciousnessBoldIndex(a.news2ConsciousnessMeasured),
          boldIndexes: _usesSelectedValue(
            a.news2ConsciousnessMeasured,
            a.news2ConsciousnessSelected,
          )
              ? _news2ConsciousnessQuickBoldIndexes(a.news2Consciousness)
              : null),
      _news2Row([
        'TỔNG ĐIỂM NEWS2',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        _allNews2Completed(a) ? '${a.news2Total}/21' : '........'
      ]),
    ];
  }

  static List<Object> _news2Row(
    List<String> values, {
    int? boldIndex,
    Set<int>? boldIndexes,
  }) {
    final boldCells = {
      if (boldIndex != null) boldIndex,
      ...?boldIndexes,
    };
    return [
      for (var index = 0; index < values.length; index++)
        _ExportCell(
          values[index],
          bold: boldCells.contains(index) && values[index].isNotEmpty,
        ),
    ];
  }

  static int? _news2RespirationBoldIndex(String value) {
    final number = ClinicalValueParser.parseInteger(value);
    if (number == null) {
      return null;
    }
    if (number <= 8) {
      return 2;
    }
    if (number <= 11) {
      return 4;
    }
    if (number <= 20) {
      return 5;
    }
    if (number <= 24) {
      return 7;
    }
    return 8;
  }

  static int? _news2Spo2Scale1BoldIndex(String value) {
    final number = ClinicalValueParser.parseInteger(value);
    if (number == null) {
      return null;
    }
    if (number <= 91) {
      return 2;
    }
    if (number <= 93) {
      return 3;
    }
    if (number <= 95) {
      return 4;
    }
    return 5;
  }

  static int? _news2Spo2Scale2BoldIndex(String value) {
    final number = ClinicalValueParser.parseInteger(value);
    if (number == null) {
      return null;
    }
    if (number <= 83) {
      return 2;
    }
    if (number <= 85) {
      return 3;
    }
    if (number <= 87) {
      return 4;
    }
    if (number <= 92) {
      return 5;
    }
    if (number <= 94) {
      return 6;
    }
    if (number <= 96) {
      return 7;
    }
    return 8;
  }

  static int? _news2OxygenBoldIndex(String value) {
    if (!ClinicalValueParser.hasText(value)) {
      return null;
    }
    final normalized = value.trim().toLowerCase();
    if (normalized.contains('không') ||
        normalized.contains('khong') ||
        normalized.contains('room') ||
        normalized.contains('khí phòng') ||
        normalized.contains('khi phong')) {
      return 5;
    }
    if (normalized.contains('oxy') ||
        normalized.contains('oxygen') ||
        normalized.contains('có') ||
        normalized.contains('co')) {
      return 3;
    }
    return null;
  }

  static int? _news2TemperatureBoldIndex(String value) {
    final number = ClinicalValueParser.parseDouble(value);
    if (number == null) {
      return null;
    }
    if (number <= 35.0) {
      return 2;
    }
    if (number <= 36.0) {
      return 4;
    }
    if (number <= 38.0) {
      return 5;
    }
    if (number <= 39.0) {
      return 6;
    }
    return 7;
  }

  static int? _news2SystolicBpBoldIndex(String value) {
    final number = ClinicalValueParser.parseInteger(value);
    if (number == null) {
      return null;
    }
    if (number <= 90) {
      return 2;
    }
    if (number <= 100) {
      return 3;
    }
    if (number <= 110) {
      return 4;
    }
    if (number <= 219) {
      return 5;
    }
    return 8;
  }

  static int? _news2HeartRateBoldIndex(String value) {
    final number = ClinicalValueParser.parseInteger(value);
    if (number == null) {
      return null;
    }
    if (number <= 40) {
      return 2;
    }
    if (number <= 50) {
      return 4;
    }
    if (number <= 90) {
      return 5;
    }
    if (number <= 110) {
      return 6;
    }
    if (number <= 130) {
      return 7;
    }
    return 8;
  }

  static int? _news2ConsciousnessBoldIndex(String value) {
    if (!ClinicalValueParser.hasText(value)) {
      return null;
    }
    final normalized = value.trim().toUpperCase();
    if (normalized == 'A' ||
        normalized.contains('TINH') ||
        normalized.contains('TỈNH')) {
      return 5;
    }
    if (normalized == 'V' ||
        normalized.contains('GỌI') ||
        normalized.contains('GOI') ||
        normalized.contains('LỜI') ||
        normalized.contains('LOI')) {
      return 4;
    }
    if (normalized == 'P' ||
        normalized.contains('ĐAU') ||
        normalized.contains('DAU')) {
      return 3;
    }
    if (normalized == 'C' ||
        normalized == 'U' ||
        normalized.contains('K.Đ') ||
        normalized.contains('LÚ LẪN') ||
        normalized.contains('LU LAN') ||
        normalized.contains('KHÔNG') ||
        normalized.contains('KHONG')) {
      return 2;
    }
    return null;
  }

  static String _news2RespirationQuickText(int score) {
    return switch (score) {
      0 => '12 - 20',
      1 => '9 - 11',
      2 => '21 - 24',
      _ => '≤ 8 hoặc ≥ 25',
    };
  }

  static Set<int> _news2RespirationQuickBoldIndexes(int score) {
    return switch (score) {
      0 => {5},
      1 => {4},
      2 => {7},
      _ => {2, 8},
    };
  }

  static String _news2Spo2Scale1QuickText(int score) {
    return switch (score) {
      0 => '≥ 96%',
      1 => '94 - 95%',
      2 => '92 - 93%',
      _ => '≤ 91%',
    };
  }

  static Set<int> _news2Spo2Scale1QuickBoldIndexes(int score) {
    return switch (score) {
      0 => {5},
      1 => {4},
      2 => {3},
      _ => {2},
    };
  }

  static String _news2Spo2Scale2QuickText(int score) {
    return switch (score) {
      0 => '88 - 92%',
      1 => '86 - 87% hoặc 93 - 94%',
      2 => '84 - 85% hoặc 95 - 96%',
      _ => '≤ 83% hoặc ≥ 97%',
    };
  }

  static Set<int> _news2Spo2Scale2QuickBoldIndexes(int score) {
    return switch (score) {
      0 => {5},
      1 => {4, 6},
      2 => {3, 7},
      _ => {2, 8},
    };
  }

  static String _news2OxygenQuickText(int score) {
    return score == 2 ? 'Thở Oxy' : 'Thở khí phòng';
  }

  static Set<int> _news2OxygenQuickBoldIndexes(int score) {
    return score == 2 ? {3} : {5};
  }

  static String _news2TemperatureQuickText(int score) {
    return switch (score) {
      0 => '36.1 - 38.0',
      1 => '35.1 - 36.0 hoặc 38.1 - 39.0',
      2 => '≥ 39.1',
      _ => '≤ 35.0',
    };
  }

  static Set<int> _news2TemperatureQuickBoldIndexes(int score) {
    return switch (score) {
      0 => {5},
      1 => {4, 6},
      2 => {7},
      _ => {2},
    };
  }

  static String _news2SystolicBpQuickText(int score) {
    return switch (score) {
      0 => '111 - 219',
      1 => '101 - 110',
      2 => '91 - 100',
      _ => '≤ 90 hoặc ≥ 220',
    };
  }

  static Set<int> _news2SystolicBpQuickBoldIndexes(int score) {
    return switch (score) {
      0 => {5},
      1 => {4},
      2 => {3},
      _ => {2, 8},
    };
  }

  static String _news2HeartRateQuickText(int score) {
    return switch (score) {
      0 => '51 - 90',
      1 => '41 - 50 hoặc 91 - 110',
      2 => '111 - 130',
      _ => '≤ 40 hoặc ≥ 131',
    };
  }

  static Set<int> _news2HeartRateQuickBoldIndexes(int score) {
    return switch (score) {
      0 => {5},
      1 => {4, 6},
      2 => {7},
      _ => {2, 8},
    };
  }

  static String _news2ConsciousnessQuickText(int score) {
    return score == 0 ? 'A - Tỉnh' : 'C / V / P / U';
  }

  static Set<int> _news2ConsciousnessQuickBoldIndexes(int score) {
    return score == 0 ? {5} : {2, 3, 4};
  }

  static List<List<String>> _qsofaRows(ClinicalAssessment a) {
    return [
      ['Tiêu chí', 'Điểm', 'Đánh giá'],
      [
        'Nhịp thở ≥ 22 lần/phút',
        '1',
        _qsofaChoice(a.qsofaRespiration, _qsofaRespirationCompleted(a))
      ],
      [
        'Huyết áp tâm thu ≤ 100 mmHg',
        '1',
        _qsofaChoice(a.qsofaSystolicBp, _qsofaSystolicBpCompleted(a))
      ],
      [
        'Rối loạn ý thức (GCS < 15)',
        '1',
        _qsofaChoice(a.qsofaConsciousness, _qsofaConsciousnessCompleted(a))
      ],
      [
        'TỔNG ĐIỂM qSOFA',
        '',
        _anyQsofaCompleted(a)
            ? '${a.qsofaTotal} / 3 điểm'
            : '........................ / 3 điểm'
      ],
    ];
  }

  static List<List<String>> _sofaRows(ClinicalAssessment a) {
    return [
      ['Cơ quan', 'Thông số / Kết quả thực tế', 'Điểm số'],
      [
        'Hô hấp',
        'PaO2/FiO2: ${_dotsOrQuickText(a, a.sofaRespirationMeasured, a.sofaRespirationSelected, quickText: _sofaRespirationQuickText(a.sofaRespiration))}',
        _scoreIfPresent(
          a.sofaRespiration,
          a.sofaRespirationMeasured,
          selected: a.sofaRespirationSelected,
        )
      ],
      [
        'Đông máu',
        'Tiểu cầu: ${_dotsOrQuickText(a, a.sofaCoagulationMeasured, a.sofaCoagulationSelected, quickText: _sofaCoagulationQuickText(a.sofaCoagulation))}',
        _scoreIfPresent(
          a.sofaCoagulation,
          a.sofaCoagulationMeasured,
          selected: a.sofaCoagulationSelected,
        )
      ],
      [
        'Gan',
        'Bilirubin: ${_dotsOrQuickTextWithUnit(a, a.sofaLiverMeasured, a.sofaLiverUnit, a.sofaLiverSelected, quickText: _sofaLiverQuickText(a.sofaLiver))}',
        _scoreIfPresent(
          a.sofaLiver,
          a.sofaLiverMeasured,
          selected: a.sofaLiverSelected,
        )
      ],
      [
        'Tim mạch',
        'MAP/Vận mạch: ${_dotsOrQuickText(a, a.sofaCardiovascularMeasured, a.sofaCardiovascularSelected, quickText: _sofaCardiovascularQuickText(a.sofaCardiovascular))}',
        _scoreIfPresent(
          a.sofaCardiovascular,
          a.vasopressor ? 'vasopressor' : a.sofaCardiovascularMeasured,
          selected: a.sofaCardiovascularSelected,
        )
      ],
      [
        'Thần kinh',
        'GCS: ${_dotsOrQuickText(a, a.sofaNeurologicMeasured, a.sofaNeurologicSelected, quickText: _sofaNeurologicQuickText(a.sofaNeurologic))}',
        _scoreIfPresent(
          a.sofaNeurologic,
          a.sofaNeurologicMeasured,
          selected: a.sofaNeurologicSelected,
        )
      ],
      [
        'Thận',
        'Creatinin/nước tiểu: ${_renalValueWithUnit(a.sofaRenalMeasured, a.sofaRenalUnit, quickSelected: a.sofaRenalSelected, quickText: _sofaRenalQuickText(a.sofaRenal))}',
        _scoreIfPresent(
          a.sofaRenal,
          a.sofaRenalMeasured,
          selected: a.sofaRenalSelected,
        )
      ],
      [
        'TỔNG ĐIỂM SOFA',
        '',
        _anySofaCompleted(a)
            ? '${a.sofaTotal} / 24'
            : '........................ / 24'
      ],
    ];
  }

  static String _sofaRespirationQuickText(int score) {
    return switch (score) {
      0 => 'PaO2/FiO2 ≥ 400',
      1 => 'PaO2/FiO2 < 400',
      2 => 'PaO2/FiO2 < 300',
      3 => '< 200 + hỗ trợ hô hấp',
      _ => '< 100 + hỗ trợ hô hấp',
    };
  }

  static String _sofaCoagulationQuickText(int score) {
    return switch (score) {
      0 => 'Tiểu cầu ≥ 150',
      1 => 'Tiểu cầu < 150',
      2 => 'Tiểu cầu < 100',
      3 => 'Tiểu cầu < 50',
      _ => 'Tiểu cầu < 20',
    };
  }

  static String _sofaLiverQuickText(int score) {
    return switch (score) {
      0 => 'Bilirubin < 1.2 mg/dL',
      1 => 'Bilirubin 1.2 - 1.9 mg/dL',
      2 => 'Bilirubin 2.0 - 5.9 mg/dL',
      3 => 'Bilirubin 6.0 - 11.9 mg/dL',
      _ => 'Bilirubin ≥ 12.0 mg/dL',
    };
  }

  static String _sofaCardiovascularQuickText(int score) {
    return switch (score) {
      0 => 'MAP ≥ 70',
      1 => 'MAP < 70',
      2 => 'Dopamine ≤ 5 hoặc dobutamine',
      3 => 'Dopamine > 5 hoặc norepi/epi ≤ 0.1',
      _ => 'Dopamine > 15 hoặc norepi/epi > 0.1',
    };
  }

  static String _sofaNeurologicQuickText(int score) {
    return switch (score) {
      0 => 'GCS 15',
      1 => 'GCS 13 - 14',
      2 => 'GCS 10 - 12',
      3 => 'GCS 6 - 9',
      _ => 'GCS < 6',
    };
  }

  static String _sofaRenalQuickText(int score) {
    return switch (score) {
      0 => 'Creatinin < 1.2',
      1 => 'Creatinin 1.2 - 1.9',
      2 => 'Creatinin 2.0 - 3.4',
      3 => 'Creatinin 3.5 - 4.9 hoặc nước tiểu < 500 mL',
      _ => 'Creatinin ≥ 5.0 hoặc nước tiểu < 200 mL',
    };
  }

  static void _docxTable(
    StringBuffer buffer,
    List<List<Object>> rows, {
    String? note,
  }) {
    buffer.write('<w:tbl><w:tblPr><w:tblBorders>');
    buffer.write(
        '<w:top w:val="single" w:sz="6"/><w:left w:val="single" w:sz="6"/>');
    buffer.write(
        '<w:bottom w:val="single" w:sz="6"/><w:right w:val="single" w:sz="6"/>');
    buffer.write(
        '<w:insideH w:val="single" w:sz="6"/><w:insideV w:val="single" w:sz="6"/>');
    buffer.write('</w:tblBorders></w:tblPr>');
    for (final row in rows) {
      buffer.write('<w:tr>');
      for (final value in row) {
        final cell = _exportCell(value);
        buffer.write('<w:tc><w:tcPr><w:tcW w:w="1800" w:type="dxa"/></w:tcPr>');
        _paragraph(buffer, cell.text, bold: cell.bold);
        buffer.write('</w:tc>');
      }
      buffer.write('</w:tr>');
    }
    if (note != null && rows.isNotEmpty) {
      buffer.write('<w:tr><w:tc><w:tcPr>');
      buffer.write('<w:gridSpan w:val="${rows.first.length}"/>');
      buffer.write('<w:tcW w:w="1800" w:type="dxa"/></w:tcPr>');
      _paragraph(buffer, note, italic: true);
      buffer.write('</w:tc></w:tr>');
    }
    buffer.write('</w:tbl>');
  }

  static void _paragraph(StringBuffer buffer, String text,
      {bool bold = false, bool italic = false}) {
    buffer.write('<w:p><w:r>');
    buffer.write('<w:rPr>');
    buffer.write(
      '<w:rFonts w:ascii="Noto Sans" w:hAnsi="Noto Sans" w:eastAsia="Noto Sans" w:cs="Noto Sans"/>',
    );
    buffer.write('<w:lang w:val="vi-VN" w:eastAsia="vi-VN" w:bidi="vi-VN"/>');
    if (bold) {
      buffer.write('<w:b/>');
    }
    if (italic) {
      buffer.write('<w:i/>');
    }
    buffer.write('</w:rPr>');
    buffer.write('<w:t xml:space="preserve">${_escapeXml(text)}</w:t>');
    buffer.write('</w:r></w:p>');
  }

  static _ExportCell _exportCell(Object value) {
    return value is _ExportCell ? value : _ExportCell(value.toString());
  }

  static ArchiveFile _archiveText(String name, String value) {
    final bytes = utf8.encode(value);
    return ArchiveFile(name, bytes.length, bytes);
  }

  static String _admissionText(ClinicalAssessment a) {
    if (a.admissionDate.isEmpty &&
        a.admissionTime.isEmpty &&
        a.admissionDateTime.isNotEmpty) {
      return a.admissionDateTime;
    }
    final time = a.admissionTime.isEmpty
        ? '......... giờ ......... phút'
        : a.admissionTime;
    final date = a.admissionDate.isEmpty
        ? '........./........./202......'
        : a.admissionDate;
    return '$time, ngày $date';
  }

  static String _scoreIfPresent(
    int score,
    String value, {
    bool selected = false,
  }) {
    return selected || ClinicalValueParser.hasText(value) ? '$score' : '';
  }

  static bool _allNews2Completed(ClinicalAssessment a) {
    return _fieldCompleted(
          a.news2RespirationMeasured,
          a.news2RespirationSelected,
        ) &&
        _fieldCompleted(a.news2Spo2Measured, a.news2Spo2Selected) &&
        _fieldCompleted(a.news2OxygenMeasured, a.news2OxygenSelected) &&
        _fieldCompleted(
            a.news2TemperatureMeasured, a.news2TemperatureSelected) &&
        _fieldCompleted(a.news2SystolicBpMeasured, a.news2SystolicBpSelected) &&
        _fieldCompleted(a.news2HeartRateMeasured, a.news2HeartRateSelected) &&
        _fieldCompleted(
          a.news2ConsciousnessMeasured,
          a.news2ConsciousnessSelected,
        );
  }

  static bool _anyQsofaCompleted(ClinicalAssessment a) {
    return _fieldCompleted(
          a.news2RespirationMeasured,
          a.qsofaRespirationSelected,
        ) ||
        _fieldCompleted(
          a.news2SystolicBpMeasured,
          a.qsofaSystolicBpSelected,
        ) ||
        _fieldCompleted(
          a.news2ConsciousnessMeasured,
          a.qsofaConsciousnessSelected,
        );
  }

  static bool _anySofaCompleted(ClinicalAssessment a) {
    return _fieldCompleted(
          a.sofaRespirationMeasured,
          a.sofaRespirationSelected,
        ) ||
        _fieldCompleted(
          a.sofaCoagulationMeasured,
          a.sofaCoagulationSelected,
        ) ||
        _fieldCompleted(a.sofaLiverMeasured, a.sofaLiverSelected) ||
        _fieldCompleted(
          a.sofaCardiovascularMeasured,
          a.sofaCardiovascularSelected,
        ) ||
        _fieldCompleted(a.sofaNeurologicMeasured, a.sofaNeurologicSelected) ||
        _fieldCompleted(a.sofaRenalMeasured, a.sofaRenalSelected) ||
        a.vasopressor;
  }

  static bool _fieldCompleted(String value, bool selected) {
    return selected || ClinicalValueParser.hasText(value);
  }

  static bool _usesSelectedValue(String value, bool selected) {
    return selected && !ClinicalValueParser.hasText(value);
  }

  static String _qsofaChoice(bool value, bool completed) {
    if (!completed) {
      return '☐ Có (1 điểm)      ☐ Không (0 điểm)';
    }
    return '${_checked(value)} Có (1 điểm)      ${_checked(!value)} Không (0 điểm)';
  }

  static String _checked(bool checked) => checked ? '☑' : '☐';

  static bool _qsofaRespirationCompleted(ClinicalAssessment a) {
    return _fieldCompleted(
      a.news2RespirationMeasured,
      a.qsofaRespirationSelected,
    );
  }

  static bool _qsofaSystolicBpCompleted(ClinicalAssessment a) {
    return _fieldCompleted(
      a.news2SystolicBpMeasured,
      a.qsofaSystolicBpSelected,
    );
  }

  static bool _qsofaConsciousnessCompleted(ClinicalAssessment a) {
    return _fieldCompleted(
      a.news2ConsciousnessMeasured,
      a.qsofaConsciousnessSelected,
    );
  }

  static String _news2ValueText(
    ClinicalAssessment _,
    String value,
    bool selected, {
    String? quickText,
  }) {
    if (ClinicalValueParser.hasText(value)) {
      return value.trim();
    }
    if (selected) {
      return quickText ?? _quickModeValueText;
    }
    return '';
  }

  static String _dotsOrQuickText(
    ClinicalAssessment _,
    String value,
    bool selected, {
    String? quickText,
  }) {
    if (ClinicalValueParser.hasText(value)) {
      return value.trim();
    }
    if (selected) {
      return quickText ?? _quickModeValueText;
    }
    return '........................';
  }

  static String _dotsOrText(String value) {
    return ClinicalValueParser.hasText(value)
        ? value.trim()
        : '........................';
  }

  static String _dotsOrQuickTextWithUnit(
    ClinicalAssessment _,
    String value,
    String unit,
    bool selected, {
    String? quickText,
  }) {
    if (!ClinicalValueParser.hasText(value) && selected) {
      return quickText ?? _quickModeValueText;
    }
    return _dotsOrTextWithUnit(value, unit);
  }

  static String _dotsOrTextWithUnit(String value, String unit) {
    if (!ClinicalValueParser.hasText(value)) {
      return '........................';
    }
    final text = value.trim();
    if (_hasUnitText(text) || !ClinicalValueParser.hasText(unit)) {
      return text;
    }
    return '$text ${unit.trim()}';
  }

  static String _lactateValueText(ClinicalAssessment assessment) {
    if (!ClinicalValueParser.hasText(assessment.lactate) &&
        ClinicalValueParser.hasText(assessment.lactateLevel)) {
      return assessment.lactateLevel.trim();
    }
    return _dotsOrTextWithUnit(assessment.lactate, 'mmol/L');
  }

  static String _renalValueWithUnit(
    String value,
    String unit, {
    bool quickSelected = false,
    String? quickText,
  }) {
    if (!ClinicalValueParser.hasText(value)) {
      if (quickSelected) {
        return quickText ?? _quickModeValueText;
      }
      return '........................';
    }
    final text = value.trim();
    if (_hasUnitText(text) || !ClinicalValueParser.hasText(unit)) {
      return text;
    }
    final lower = text.toLowerCase();
    final hasUrineOnly = (lower.contains('ml') ||
            lower.contains('nước tiểu') ||
            lower.contains('nuoc tieu')) &&
        !lower.contains('creatinin') &&
        !lower.contains('creatinine');
    if (hasUrineOnly) {
      return text;
    }
    return '$text ${unit.trim()}';
  }

  static bool _hasUnitText(String value) {
    final lower = value.toLowerCase();
    return lower.contains('mg/dl') ||
        lower.contains('umol') ||
        lower.contains('µmol');
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

class _ExportCell {
  final String text;
  final bool bold;

  const _ExportCell(this.text, {this.bold = false});
}
