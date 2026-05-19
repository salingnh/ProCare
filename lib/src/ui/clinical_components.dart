import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/assessment_display.dart';

class ClinicalStatusStyle {
  final Color background;
  final Color border;
  final Color foreground;
  final IconData icon;

  const ClinicalStatusStyle({
    required this.background,
    required this.border,
    required this.foreground,
    required this.icon,
  });
}

ClinicalStatusStyle clinicalStatusStyle(
  BuildContext context,
  ClinicalStatus status,
) {
  final scheme = Theme.of(context).colorScheme;
  return switch (status) {
    ClinicalStatus.missing => ClinicalStatusStyle(
        background: const Color(0xFFEEF3F2),
        border: const Color(0xFFC6D6D2),
        foreground: const Color(0xFF5F6F6B),
        icon: Icons.remove_circle_outline,
      ),
    ClinicalStatus.normal => ClinicalStatusStyle(
        background: const Color(0xFFE7F6ED),
        border: const Color(0xFFA8DDB8),
        foreground: const Color(0xFF1D7A46),
        icon: Icons.check_circle,
      ),
    ClinicalStatus.watch => ClinicalStatusStyle(
        background: const Color(0xFFFFF6D8),
        border: const Color(0xFFFFD978),
        foreground: const Color(0xFF8A6500),
        icon: Icons.info_outline,
      ),
    ClinicalStatus.warning => ClinicalStatusStyle(
        background: const Color(0xFFFFEAD6),
        border: const Color(0xFFFFBE7A),
        foreground: const Color(0xFFA34A00),
        icon: Icons.warning_amber,
      ),
    ClinicalStatus.danger => ClinicalStatusStyle(
        background: const Color(0xFFFFE1E1),
        border: scheme.error.withValues(alpha: 0.36),
        foreground: const Color(0xFFB42318),
        icon: Icons.error_outline,
      ),
  };
}

class StatusBadge extends StatelessWidget {
  final ClinicalStatus status;
  final String label;
  final bool dense;

  const StatusBadge({
    super.key,
    required this.status,
    required this.label,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = clinicalStatusStyle(context, status);
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: style.background,
        border: Border.all(color: style.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: dense ? 14 : 16, color: style.foreground),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.visible,
              style: theme.textTheme.labelSmall?.copyWith(
                color: style.foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ClinicalSummaryCard extends StatelessWidget {
  final ScoreDisplay display;
  final VoidCallback? onTap;

  const ClinicalSummaryCard({
    super.key,
    required this.display,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = clinicalStatusStyle(context, display.status);
    final theme = Theme.of(context);
    return Card.filled(
      color: style.background,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: style.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                display.title,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: style.foreground,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                display.scoreText,
                style: theme.textTheme.displaySmall?.copyWith(
                  color: style.foreground,
                  fontWeight: FontWeight.w900,
                  height: 0.95,
                ),
              ),
              const SizedBox(height: 10),
              StatusBadge(
                status: display.status,
                label: display.statusLabel,
                dense: true,
              ),
              const SizedBox(height: 8),
              Text(
                display.helperText,
                maxLines: 3,
                overflow: TextOverflow.visible,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: style.foreground,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MissingDataPanel extends StatelessWidget {
  final List<MissingDataItem> items;
  final ValueChanged<MissingDataItem> onItemTap;

  const MissingDataPanel({
    super.key,
    required this.items,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final groups = <String, List<MissingDataItem>>{};
    for (final item in items) {
      groups.putIfAbsent(item.groupLabel, () => []).add(item);
    }
    return Card.outlined(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.playlist_add_check_circle_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Cần bổ sung để hoàn tất đánh giá',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final entry in groups.entries) ...[
              Text(
                entry.key,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final item in entry.value)
                    ActionChip(
                      label: Text(item.label),
                      avatar: const Icon(Icons.arrow_downward, size: 16),
                      onPressed: () => onItemTap(item),
                    ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class FormSectionAccordion extends StatelessWidget {
  final String title;
  final SectionProgress progress;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onExpansionChanged;
  final List<Widget> children;

  const FormSectionAccordion({
    super.key,
    required this.title,
    required this.progress,
    required this.children,
    this.initiallyExpanded = false,
    this.onExpansionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final missingText = progress.missingLabels.isEmpty
        ? 'Đã đủ dữ liệu'
        : 'Còn thiếu: ${progress.missingLabels.join(', ')}';
    return Card.outlined(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        maintainState: true,
        onExpansionChanged: onExpansionChanged,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            missingText,
            overflow: TextOverflow.visible,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatusBadge(
              status: progress.complete
                  ? ClinicalStatus.normal
                  : ClinicalStatus.missing,
              label: '${progress.completedCount}/${progress.totalCount}',
              dense: true,
            ),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more),
          ],
        ),
        children: children,
      ),
    );
  }
}

class MedicalInputField extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final String? unit;
  final String? helperText;
  final String? warningText;
  final String? errorText;
  final String? scoreText;
  final String? hintText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final FocusNode? focusNode;

  const MedicalInputField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.unit,
    this.helperText,
    this.warningText,
    this.errorText,
    this.scoreText,
    this.hintText,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final warning = warningText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          initialValue: value,
          focusNode: focusNode,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            labelText: label,
            hintText: hintText,
            suffixText: unit,
            helperText: helperText,
            helperMaxLines: 3,
            errorText: errorText,
          ),
          onChanged: onChanged,
        ),
        if (warning != null && errorText == null) ...[
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.warning_amber,
                size: 16,
                color: Color(0xFFA34A00),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  warning,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFA34A00),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
        if (scoreText != null) ...[
          const SizedBox(height: 4),
          Text(
            scoreText!,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ],
    );
  }
}

class SaveStatusIndicator extends StatelessWidget {
  final String label;
  final ClinicalStatus status;

  const SaveStatusIndicator({
    super.key,
    required this.label,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return StatusBadge(status: status, label: label, dense: true);
  }
}

class ScoreBreakdownRow extends StatelessWidget {
  final String label;
  final String measured;
  final String scoreText;
  final ClinicalStatus status;

  const ScoreBreakdownRow({
    super.key,
    required this.label,
    required this.measured,
    required this.scoreText,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final style = clinicalStatusStyle(context, status);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: style.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: style.foreground,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  measured,
                  overflow: TextOverflow.visible,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: style.foreground,
                  ),
                ),
              ],
            ),
          ),
          Text(
            scoreText,
            style: theme.textTheme.titleMedium?.copyWith(
              color: style.foreground,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class PatientCard extends StatelessWidget {
  final String name;
  final String identityLine;
  final String admissionLine;
  final String updatedText;
  final List<Widget> badges;
  final Widget? actionMenu;
  final VoidCallback onTap;

  const PatientCard({
    super.key,
    required this.name,
    required this.identityLine,
    required this.admissionLine,
    required this.updatedText,
    required this.badges,
    required this.onTap,
    this.actionMenu,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card.outlined(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      overflow: TextOverflow.visible,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (actionMenu != null) actionMenu!,
                ],
              ),
              const SizedBox(height: 6),
              Text(
                identityLine,
                overflow: TextOverflow.visible,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                admissionLine,
                overflow: TextOverflow.visible,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (badges.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(spacing: 6, runSpacing: 6, children: badges),
              ],
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  updatedText,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
