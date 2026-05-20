import 'package:flutter/material.dart';

import '../export/crf_exporter.dart';

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

class ExportActionMenu extends StatelessWidget {
  final bool enabled;
  final ValueChanged<ExportAction> onSelected;

  const ExportActionMenu({
    super.key,
    required this.enabled,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ExportAction>(
      enabled: enabled,
      tooltip: 'Tác vụ',
      icon: const Icon(Icons.more_vert),
      onSelected: onSelected,
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: ExportAction.saveDocx,
          child: Row(
            children: [
              Icon(Icons.save_alt),
              SizedBox(width: 12),
              Text('Lưu DOCX'),
            ],
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: ExportAction.shareDocx,
          child: Row(
            children: [
              Icon(Icons.ios_share),
              SizedBox(width: 12),
              Text('Chia sẻ DOCX'),
            ],
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: ExportAction.printPdf,
          child: Row(
            children: [
              Icon(Icons.print_outlined),
              SizedBox(width: 12),
              Text('In PDF'),
            ],
          ),
        ),
      ],
    );
  }
}
