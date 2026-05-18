class ClinicalValueParser {
  const ClinicalValueParser._();

  static bool hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  static int? parseInteger(String? value) {
    if (!hasText(value)) {
      return null;
    }
    final digits = value!.trim().replaceAll(RegExp(r'[^0-9-]'), '');
    if (!hasText(digits)) {
      return null;
    }
    return int.tryParse(digits);
  }

  static double? parseDouble(String? value) {
    if (!hasText(value)) {
      return null;
    }
    final normalized = value!
        .trim()
        .replaceAll(',', '.')
        .replaceAll(RegExp(r'[^0-9.-]'), '');
    if (!hasText(normalized)) {
      return null;
    }
    return double.tryParse(normalized);
  }
}
