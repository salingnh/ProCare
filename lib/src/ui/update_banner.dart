import 'package:flutter/material.dart';

import '../domain/assessment_display.dart';
import '../services/update_controller.dart';
import 'clinical_components.dart' as clinical_ui;

/// Banner shown when an app update is available. Self-contained: it listens to
/// the [UpdateController], renders nothing when there is no update, and drives
/// the download itself. Safe to place unconditionally in a layout.
class UpdateBanner extends StatelessWidget {
  final UpdateController controller;

  const UpdateBanner({super.key, required this.controller});

  Future<void> _download(BuildContext context) async {
    if (controller.downloadingUpdate || controller.availableUpdate == null) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final ok = await controller.downloadAndInstall();
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Không tải hoặc mở được bản cập nhật.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final update = controller.availableUpdate;
        if (update == null) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: clinical_ui.ClinicalInfoBanner(
            icon: Icons.system_update_alt,
            title: 'Có bản cập nhật NEWS2-L ${update.version}'
                '${update.prerelease ? ' (thử nghiệm)' : ''}',
            message: 'Tải APK mới để cập nhật ứng dụng trên thiết bị này.',
            status: ClinicalStatus.watch,
            progress: controller.downloadingUpdate
                ? LinearProgressIndicator(value: controller.downloadProgress)
                : null,
            trailing: FilledButton.icon(
              onPressed: controller.downloadingUpdate
                  ? null
                  : () => _download(context),
              icon: const Icon(Icons.download),
              label: Text(controller.downloadingUpdate ? 'Đang tải' : 'Tải'),
            ),
          ),
        );
      },
    );
  }
}
