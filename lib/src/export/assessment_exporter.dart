import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/clinical_assessment.dart';
import '../domain/scoring.dart';
import 'crf_exporter.dart';
import 'export_action.dart';

/// Orchestrates CRF export/share/print for an assessment. Has no UI
/// dependency (no `BuildContext`), so callers own the progress flag and
/// surface the returned message themselves.
class AssessmentExporter {
  const AssessmentExporter({CrfExporter exporter = const CrfExporter()})
      : _exporter = exporter;

  final CrfExporter _exporter;

  static const _androidFileChannel = MethodChannel('news2_l/android_files');

  /// Runs [action] against a recalculated copy of [source]. Returns a
  /// user-facing message to show (save), or null when there is nothing to
  /// report (share/print).
  Future<String?> run(ClinicalAssessment source, ExportAction action) async {
    final assessment = source.clone();
    recalculateClinicalAssessment(assessment, preserveExistingScores: true);
    switch (action) {
      case ExportAction.saveDocx:
        return _save(assessment, action.exportFormat);
      case ExportAction.shareDocx:
        await _share(assessment, action.exportFormat);
        return null;
      case ExportAction.printPdf:
        await _print(assessment);
        return null;
    }
  }

  Future<String> _save(
    ClinicalAssessment assessment,
    CrfExportFormat format,
  ) async {
    final file = await _exporter.export(assessment, format);
    final fileName = file.uri.pathSegments.last;
    final savedToDownloads = await _saveToDownloads(
      sourcePath: file.path,
      fileName: fileName,
      mimeType: format.mimeType,
    );
    return savedToDownloads
        ? 'Đã lưu vào Downloads/NEWS2-L: $fileName'
        : 'Đã lưu trong thư mục xuất của app: $fileName';
  }

  Future<void> _share(
    ClinicalAssessment assessment,
    CrfExportFormat format,
  ) async {
    final file = await _exporter.export(assessment, format);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: format.mimeType)],
        subject: 'NEWS2-L CRF',
        text: file.uri.pathSegments.last,
      ),
    );
  }

  Future<void> _print(ClinicalAssessment assessment) async {
    final bytes = await _exporter.buildPdfBytes(assessment);
    final fileName = CrfExporter.buildFileName(assessment, CrfExportFormat.pdf);
    await Printing.layoutPdf(
      name: fileName,
      onLayout: (_) async => bytes,
    );
  }

  Future<bool> _saveToDownloads({
    required String sourcePath,
    required String fileName,
    required String mimeType,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      await _androidFileChannel.invokeMethod<String>('saveToDownloads', {
        'sourcePath': sourcePath,
        'fileName': fileName,
        'mimeType': mimeType,
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}
