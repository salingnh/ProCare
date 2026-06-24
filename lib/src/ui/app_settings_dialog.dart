import 'package:flutter/material.dart';

import '../domain/assessment_display.dart';
import '../domain/clinical_assessment.dart';
import '../services/update_controller.dart';
import 'clinical_components.dart' as clinical_ui;

/// Shows the app settings dialog (assessment input mode + update options).
///
/// [onAssessmentModeChanged] is invoked with the new mode value; [showMessage]
/// surfaces a transient message from the host screen's messenger.
Future<void> showAppSettingsDialog({
  required BuildContext context,
  required UpdateController updateController,
  required String assessmentMode,
  required ValueChanged<String> onAssessmentModeChanged,
  required ValueChanged<String> showMessage,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => _AppSettingsDialog(
      updateController: updateController,
      initialAssessmentMode: assessmentMode,
      onAssessmentModeChanged: onAssessmentModeChanged,
      showMessage: showMessage,
    ),
  );
}

class _AppSettingsDialog extends StatefulWidget {
  final UpdateController updateController;
  final String initialAssessmentMode;
  final ValueChanged<String> onAssessmentModeChanged;
  final ValueChanged<String> showMessage;

  const _AppSettingsDialog({
    required this.updateController,
    required this.initialAssessmentMode,
    required this.onAssessmentModeChanged,
    required this.showMessage,
  });

  @override
  State<_AppSettingsDialog> createState() => _AppSettingsDialogState();
}

class _AppSettingsDialogState extends State<_AppSettingsDialog> {
  late bool _includePrereleaseUpdates =
      widget.updateController.includePrereleaseUpdates;
  late String _assessmentMode = ClinicalAssessment.normalizeAssessmentMode(
    widget.initialAssessmentMode,
  );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cài đặt app'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _assessmentModeCard(),
              const SizedBox(height: 12),
              clinical_ui.ClinicalSurfaceCard(
                padding: EdgeInsets.zero,
                child: SwitchListTile(
                  value: _includePrereleaseUpdates,
                  onChanged: (value) {
                    setState(() => _includePrereleaseUpdates = value);
                    widget.updateController.setIncludePrerelease(value);
                  },
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  title: const Text('Cài bản prerelease'),
                  subtitle: const Text(
                    'Mặc định tắt, chỉ bật khi cần thử nghiệm',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              clinical_ui.ClinicalInfoBanner(
                icon: Icons.system_update_alt,
                title: 'Cập nhật ứng dụng',
                message: 'Kiểm tra bản phát hành mới từ GitHub Releases.',
                status: ClinicalStatus.missing,
                trailing: OutlinedButton.icon(
                  onPressed: () {
                    widget.updateController.checkForUpdate(force: true);
                    widget.showMessage('Đang kiểm tra cập nhật...');
                  },
                  icon: const Icon(Icons.sync, size: 18),
                  label: const Text('Kiểm tra ngay'),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
    );
  }

  Widget _assessmentModeCard() {
    final theme = Theme.of(context);
    final selectedMode = ClinicalAssessment.parseAssessmentInputMode(
      _assessmentMode,
    );
    return clinical_ui.ClinicalSurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mode đánh giá',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Áp dụng cho phiếu mới và phiếu mở chỉnh sửa.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<ClinicalAssessmentInputMode>(
              showSelectedIcon: false,
              selected: {selectedMode},
              segments: const [
                ButtonSegment(
                  value: ClinicalAssessmentInputMode.detailed,
                  icon: Icon(Icons.monitor_heart_outlined),
                  label: Text('Chi tiết'),
                ),
                ButtonSegment(
                  value: ClinicalAssessmentInputMode.quick,
                  icon: Icon(Icons.touch_app_outlined),
                  label: Text('Nhanh'),
                ),
              ],
              onSelectionChanged: (selection) {
                final mode = ClinicalAssessment.assessmentModeValue(
                  selection.first,
                );
                setState(() => _assessmentMode = mode);
                widget.onAssessmentModeChanged(mode);
              },
            ),
          ),
        ],
      ),
    );
  }
}
