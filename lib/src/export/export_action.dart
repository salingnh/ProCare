import 'crf_exporter.dart';

/// The export/share/print actions offered for a CRF.
enum ExportAction {
  saveDocx,
  shareDocx,
  printPdf,
}

extension ExportActionFormat on ExportAction {
  CrfExportFormat get exportFormat {
    return switch (this) {
      ExportAction.saveDocx || ExportAction.shareDocx => CrfExportFormat.docx,
      ExportAction.printPdf => CrfExportFormat.pdf,
    };
  }
}
