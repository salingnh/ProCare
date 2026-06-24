import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../domain/assessment_display.dart';
import '../domain/clinical_assessment.dart';
import '../services/update_controller.dart';
import 'clinical_components.dart' as clinical_ui;

/// App settings as a full screen (assessment input mode + app updates + about).
/// Replaces the previous modal dialog. Driven by the [UpdateController] plus a
/// mode-change callback supplied by the host (list shell or form screen).
class SettingsScreen extends StatefulWidget {
  final UpdateController updateController;
  final String assessmentMode;
  final ValueChanged<String> onAssessmentModeChanged;

  const SettingsScreen({
    super.key,
    required this.updateController,
    required this.assessmentMode,
    required this.onAssessmentModeChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _includePrerelease =
      widget.updateController.includePrereleaseUpdates;
  late String _assessmentMode = ClinicalAssessment.normalizeAssessmentMode(
    widget.assessmentMode,
  );
  String _version = '';

  @override
  void initState() {
    super.initState();
    widget.updateController.addListener(_onControllerChanged);
    _loadVersion();
  }

  @override
  void dispose() {
    widget.updateController.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _version = info.version);
      }
    } catch (_) {
      // Platform channel unavailable (e.g. tests) — leave the version blank.
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        children: [
          _groupLabel('Đánh giá'),
          _assessmentModeCard(),
          _groupLabel('Cập nhật ứng dụng'),
          _updateCard(),
          _groupLabel('Giới thiệu'),
          _aboutCard(),
        ],
      ),
    );
  }

  Widget _groupLabel(String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 14, 6, 8),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _assessmentModeCard() {
    final theme = Theme.of(context);
    final selectedMode = ClinicalAssessment.parseAssessmentInputMode(
      _assessmentMode,
    );
    return clinical_ui.ClinicalSurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chế độ nhập liệu',
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
          SizedBox(
            width: double.infinity,
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

  Widget _updateCard() {
    final theme = Theme.of(context);
    final update = widget.updateController.availableUpdate;
    final versionLabel =
        _version.isEmpty ? 'NEWS2-L' : 'Phiên bản $_version';
    return clinical_ui.ClinicalSurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      versionLabel,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Cài bản phát hành mới từ GitHub Releases.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              clinical_ui.StatusBadge(
                status: update == null
                    ? ClinicalStatus.normal
                    : ClinicalStatus.watch,
                label: update == null
                    ? 'Mới nhất'
                    : 'Có bản ${update.version}',
              ),
            ],
          ),
          const Divider(height: 24),
          SwitchListTile(
            value: _includePrerelease,
            onChanged: (value) {
              setState(() => _includePrerelease = value);
              widget.updateController.setIncludePrerelease(value);
            },
            contentPadding: EdgeInsets.zero,
            title: const Text('Nhận bản thử nghiệm'),
            subtitle: const Text('Mặc định tắt, chỉ bật khi cần thử nghiệm.'),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () {
                widget.updateController.checkForUpdate(force: true);
                _showMessage('Đang kiểm tra cập nhật...');
              },
              icon: const Icon(Icons.sync, size: 18),
              label: const Text('Kiểm tra cập nhật ngay'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _aboutCard() {
    return clinical_ui.ClinicalSurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
      child: Column(
        children: const [
          _AboutRow(label: 'Ứng dụng', value: 'NEWS2-L'),
          _AboutRow(label: 'Tác giả', value: 'Sang Nguyễn'),
          _AboutRow(label: 'Email', value: 'sangnvnkl@gmail.com'),
          _AboutRow(label: 'Tham chiếu', value: 'NEWS2 · qSOFA · SOFA'),
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  final String label;
  final String value;

  const _AboutRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
