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
        background: const Color(0xFFE4ECE9),
        border: const Color(0xFF8FA5A0),
        foreground: const Color(0xFF243D38),
        icon: Icons.remove_circle_outline,
      ),
    ClinicalStatus.normal => ClinicalStatusStyle(
        background: const Color(0xFFE3F4EA),
        border: const Color(0xFF7AC49B),
        foreground: const Color(0xFF0F6B3A),
        icon: Icons.check_circle,
      ),
    ClinicalStatus.watch => ClinicalStatusStyle(
        background: const Color(0xFFFFF2C2),
        border: const Color(0xFFE7B835),
        foreground: const Color(0xFF6C4A00),
        icon: Icons.info_outline,
      ),
    ClinicalStatus.warning => ClinicalStatusStyle(
        background: const Color(0xFFFFE3C2),
        border: const Color(0xFFE89A43),
        foreground: const Color(0xFF8A3B00),
        icon: Icons.warning_amber,
      ),
    ClinicalStatus.danger => ClinicalStatusStyle(
        background: const Color(0xFFFFE1E1),
        border: scheme.error.withValues(alpha: 0.36),
        foreground: const Color(0xFF982117),
        icon: Icons.error_outline,
      ),
  };
}

class ClinicalSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final VoidCallback? onTap;
  final Clip clipBehavior;

  const ClinicalSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin = EdgeInsets.zero,
    this.color,
    this.borderColor,
    this.radius = 16,
    this.onTap,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final resolvedColor = color ?? scheme.surfaceContainerLowest;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: borderColor ?? scheme.outlineVariant),
    );
    final content = Padding(
      padding: padding,
      child: child,
    );
    return Padding(
      padding: margin,
      child: Material(
        color: resolvedColor,
        elevation: 0,
        shadowColor: scheme.shadow.withValues(alpha: 0.08),
        surfaceTintColor: Colors.transparent,
        shape: shape,
        clipBehavior: clipBehavior,
        child: onTap == null
            ? content
            : InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(radius),
                child: content,
              ),
      ),
    );
  }
}

class ClinicalInfoBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? trailing;
  final Widget? progress;
  final ClinicalStatus status;

  const ClinicalInfoBanner({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.trailing,
    this.progress,
    this.status = ClinicalStatus.normal,
  });

  @override
  Widget build(BuildContext context) {
    final style = clinicalStatusStyle(context, status);
    final theme = Theme.of(context);
    return ClinicalSurfaceCard(
      color: style.background,
      borderColor: style.border,
      radius: 14,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: style.foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: style.foreground,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    message!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: style.foreground,
                      height: 1.25,
                    ),
                  ),
                ],
                if (progress != null) ...[
                  const SizedBox(height: 8),
                  progress!,
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            trailing!,
          ],
        ],
      ),
    );
  }
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: style.background,
        border: Border.all(color: style.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 8 : 10,
          vertical: dense ? 4 : 6,
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
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ClinicalSummaryCard extends StatelessWidget {
  final ScoreDisplay display;
  final VoidCallback? onTap;
  final bool compact;

  const ClinicalSummaryCard({
    super.key,
    required this.display,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = clinicalStatusStyle(context, display.status);
    final theme = Theme.of(context);
    return ClinicalSurfaceCard(
      color: style.background,
      borderColor: style.border,
      radius: compact ? 12 : 16,
      padding: EdgeInsets.all(compact ? 10 : 14),
      onTap: onTap,
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
          SizedBox(height: compact ? 5 : 8),
          Text(
            display.scoreText,
            style: (compact
                    ? theme.textTheme.headlineSmall
                    : theme.textTheme.displaySmall)
                ?.copyWith(
              color: style.foreground,
              fontWeight: FontWeight.w900,
              height: 0.95,
            ),
          ),
          SizedBox(height: compact ? 7 : 10),
          if (!compact)
            StatusBadge(
              status: display.status,
              label: display.statusLabel,
              dense: true,
            ),
          if (!compact) ...[
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
          ] else
            StatusBadge(
              status: display.status,
              label: display.statusLabel,
              dense: true,
            ),
        ],
      ),
    );
  }
}

class ClinicalSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;

  const ClinicalSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                overflow: TextOverflow.visible,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        trailing,
      ],
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
      color: theme.colorScheme.surfaceContainerLowest,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        maintainState: true,
        onExpansionChanged: onExpansionChanged,
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        title: ClinicalSectionHeader(
          title: title,
          subtitle: missingText,
          trailing: StatusBadge(
            status: progress.complete
                ? ClinicalStatus.normal
                : ClinicalStatus.missing,
            label: '${progress.completedCount}/${progress.totalCount}',
            dense: true,
          ),
        ),
        trailing: const Icon(Icons.expand_more),
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
  final ClinicalStatus scoreStatus;
  final String? hintText;
  final List<String>? unitOptions;
  final String? selectedUnit;
  final ValueChanged<String>? onUnitChanged;
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
    this.scoreStatus = ClinicalStatus.normal,
    this.hintText,
    this.unitOptions,
    this.selectedUnit,
    this.onUnitChanged,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final warning = warningText;
    final units = unitOptions ??
        (unit == null || unit!.trim().isEmpty ? null : <String>[unit!]);
    final selected =
        selectedUnit ?? (units?.isNotEmpty == true ? units!.first : null);
    final unitButton = units == null || units.isEmpty || selected == null
        ? null
        : Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: SizedBox(
              width: 92,
              height: 34,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 34),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  backgroundColor: theme.colorScheme.primaryContainer,
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                  disabledBackgroundColor:
                      theme.colorScheme.surfaceContainerHighest,
                  disabledForegroundColor: theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: units.length <= 1 || onUnitChanged == null
                    ? null
                    : () {
                        final currentIndex = units.indexOf(selected);
                        final nextIndex = currentIndex < 0
                            ? 0
                            : (currentIndex + 1) % units.length;
                        onUnitChanged!(units[nextIndex]);
                      },
                child: Text(
                  selected,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          );
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
            suffixText: unitButton == null ? unit : null,
            suffixIcon: unitButton,
            suffixIconConstraints: unitButton == null
                ? null
                : const BoxConstraints(
                    minWidth: 100,
                    maxWidth: 100,
                    minHeight: 40,
                  ),
            helperText: helperText,
            helperMaxLines: 3,
            errorText: errorText,
          ),
          onChanged: onChanged,
        ),
        if (warning != null && errorText == null) ...[
          const SizedBox(height: 6),
          ClinicalSurfaceCard(
            color: const Color(0xFFFFF8E6),
            borderColor: const Color(0xFFE4BA62),
            radius: 10,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber,
                  size: 16,
                  color: Color(0xFF7A4D00),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    warning,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF7A4D00),
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (scoreText != null) ...[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: StatusBadge(
              status: scoreStatus,
              label: scoreText!,
              dense: true,
            ),
          ),
        ],
      ],
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
    final chipStyle = clinicalStatusStyle(context, ClinicalStatus.missing);
    final groups = <String, List<MissingDataItem>>{};
    for (final item in items) {
      groups.putIfAbsent(item.groupLabel, () => []).add(item);
    }
    return ClinicalSurfaceCard(
      color: theme.colorScheme.surfaceContainerLowest,
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
              Expanded(
                child: Text(
                  'Cần bổ sung để hoàn tất đánh giá',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
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
                    avatar: Icon(
                      Icons.arrow_downward,
                      size: 16,
                      color: chipStyle.foreground,
                    ),
                    backgroundColor: chipStyle.background,
                    elevation: 0,
                    pressElevation: 1,
                    surfaceTintColor: Colors.transparent,
                    side: BorderSide(color: chipStyle.border),
                    shape: StadiumBorder(
                      side: BorderSide(color: chipStyle.border),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    labelStyle: theme.textTheme.labelMedium?.copyWith(
                      color: chipStyle.foreground,
                      fontWeight: FontWeight.w900,
                    ),
                    onPressed: () => onItemTap(item),
                  ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
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
    return ClinicalSurfaceCard(
      color: style.background,
      borderColor: style.border,
      radius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
    return ClinicalSurfaceCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      onTap: onTap,
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
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            admissionLine,
            overflow: TextOverflow.visible,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.2,
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
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
