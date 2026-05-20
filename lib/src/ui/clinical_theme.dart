import 'package:flutter/material.dart';

class ClinicalTones extends ThemeExtension<ClinicalTones> {
  final RiskTone success;
  final RiskTone attention;
  final RiskTone warning;
  final RiskTone danger;
  final RiskTone neutral;
  final RiskTone muted;

  const ClinicalTones({
    required this.success,
    required this.attention,
    required this.warning,
    required this.danger,
    required this.neutral,
    required this.muted,
  });

  factory ClinicalTones.fromColorScheme(ColorScheme scheme) {
    return ClinicalTones(
      success: const RiskTone(
        background: Color(0xFFEAF7EE),
        border: Color(0xFFA8DDB8),
        foreground: Color(0xFF1B6B36),
        icon: Icons.check_circle,
        severity: 1,
      ),
      attention: const RiskTone(
        background: Color(0xFFFFF8E1),
        border: Color(0xFFFFD978),
        foreground: Color(0xFF7A5A00),
        icon: Icons.info,
        severity: 2,
      ),
      warning: const RiskTone(
        background: Color(0xFFFFF0E0),
        border: Color(0xFFFFBE7A),
        foreground: Color(0xFFAD4E00),
        icon: Icons.warning_amber,
        severity: 3,
      ),
      danger: RiskTone(
        background: scheme.errorContainer,
        border: scheme.error.withValues(alpha: 0.36),
        foreground: scheme.onErrorContainer,
        icon: Icons.error,
        severity: 4,
      ),
      neutral: RiskTone(
        background: scheme.surfaceContainerHighest,
        border: scheme.outlineVariant,
        foreground: scheme.onSurfaceVariant,
        icon: Icons.radio_button_unchecked,
        severity: 1,
      ),
      muted: RiskTone(
        background: scheme.surfaceContainerHigh,
        border: scheme.outlineVariant,
        foreground: scheme.onSurfaceVariant.withValues(alpha: 0.72),
        icon: Icons.remove_circle_outline,
        severity: 0,
      ),
    );
  }

  @override
  ClinicalTones copyWith({
    RiskTone? success,
    RiskTone? attention,
    RiskTone? warning,
    RiskTone? danger,
    RiskTone? neutral,
    RiskTone? muted,
  }) {
    return ClinicalTones(
      success: success ?? this.success,
      attention: attention ?? this.attention,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      neutral: neutral ?? this.neutral,
      muted: muted ?? this.muted,
    );
  }

  @override
  ClinicalTones lerp(ThemeExtension<ClinicalTones>? other, double t) {
    if (other is! ClinicalTones) {
      return this;
    }
    return ClinicalTones(
      success: success.lerp(other.success, t),
      attention: attention.lerp(other.attention, t),
      warning: warning.lerp(other.warning, t),
      danger: danger.lerp(other.danger, t),
      neutral: neutral.lerp(other.neutral, t),
      muted: muted.lerp(other.muted, t),
    );
  }
}

class RiskTone {
  final Color background;
  final Color border;
  final Color foreground;
  final IconData icon;
  final int severity;

  const RiskTone({
    required this.background,
    required this.border,
    required this.foreground,
    required this.icon,
    required this.severity,
  });

  RiskTone copyWith({
    Color? background,
    Color? border,
    Color? foreground,
    IconData? icon,
    int? severity,
  }) {
    return RiskTone(
      background: background ?? this.background,
      border: border ?? this.border,
      foreground: foreground ?? this.foreground,
      icon: icon ?? this.icon,
      severity: severity ?? this.severity,
    );
  }

  RiskTone lerp(RiskTone other, double t) {
    return RiskTone(
      background: Color.lerp(background, other.background, t)!,
      border: Color.lerp(border, other.border, t)!,
      foreground: Color.lerp(foreground, other.foreground, t)!,
      icon: t < 0.5 ? icon : other.icon,
      severity: t < 0.5 ? severity : other.severity,
    );
  }
}
