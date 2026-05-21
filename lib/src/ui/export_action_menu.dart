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
      constraints: const BoxConstraints(minWidth: 176, maxWidth: 260),
      onSelected: onSelected,
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: ExportAction.saveDocx,
          child: _ExportMenuItem(
            icon: Icons.save_alt,
            label: 'Lưu DOCX',
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: ExportAction.shareDocx,
          child: _ExportMenuItem(
            icon: Icons.ios_share,
            label: 'Chia sẻ DOCX',
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: ExportAction.printPdf,
          child: _ExportMenuItem(
            icon: Icons.print_outlined,
            label: 'In PDF',
          ),
        ),
      ],
    );
  }
}

class _ExportMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ExportMenuItem({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
