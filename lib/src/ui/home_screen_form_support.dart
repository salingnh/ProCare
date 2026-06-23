part of 'home_screen.dart';

extension _HsFormSupport on _HomeScreenState {
  GlobalKey _sectionKey(String sectionId) {
    return _sectionKeys.putIfAbsent(sectionId, GlobalKey.new);
  }

  GlobalKey _fieldKey(String fieldId) {
    return _fieldKeys.putIfAbsent(fieldId, GlobalKey.new);
  }

  FocusNode _focusNode(String fieldId) {
    return _fieldFocusNodes.putIfAbsent(fieldId, FocusNode.new);
  }

  String _sectionForDisplay(ScoreDisplay display) {
    return switch (display.title) {
      'NEWS2' || 'qSOFA' => AssessmentSections.news2,
      'SOFA' => AssessmentSections.sofa,
      _ => AssessmentSections.diagnosis,
    };
  }

  void _jumpToMissingItem(MissingDataItem item) {
    _rebuild(() {
      _expandedSections.add(item.sectionId);
      _formVersion++;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fieldContext = _fieldKeys[item.fieldId]?.currentContext;
      if (fieldContext != null) {
        Scrollable.ensureVisible(
          fieldContext,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: 0.18,
        );
        _fieldFocusNodes[item.fieldId]?.requestFocus();
        return;
      }
      _scrollToSection(item.sectionId);
    });
  }

  void _scrollToSection(String sectionId) {
    _rebuild(() {
      _expandedSections.add(sectionId);
      _formVersion++;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sectionContext = _sectionKeys[sectionId]?.currentContext;
      if (sectionContext != null) {
        Scrollable.ensureVisible(
          sectionContext,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: 0.08,
        );
      }
    });
  }

  SectionProgress _patientProgress(ClinicalAssessment assessment) {
    final missing = <String>[
      if (!ClinicalValueParser.hasText(assessment.patientId)) 'Mã bệnh nhân',
      if (!ClinicalValueParser.hasText(assessment.fullName)) 'Họ và tên',
      if (!ClinicalValueParser.hasText(assessment.admissionDate))
        'Ngày nhập viện',
      if (!ClinicalValueParser.hasText(assessment.admissionTime))
        'Giờ nhập viện',
    ];
    return SectionProgress(
      sectionId: AssessmentSections.patient,
      completedCount: 4 - missing.length,
      totalCount: 4,
      missingLabels: missing,
    );
  }

  String _defaultOpenSection(ClinicalAssessment assessment) {
    final sections = [
      _patientProgress(assessment),
      AssessmentDisplay.news2Progress(assessment),
      AssessmentDisplay.lactateProgress(assessment),
      AssessmentDisplay.sofaProgress(assessment),
    ];
    return sections
        .firstWhere(
          (section) => !section.complete,
          orElse: () => sections.first,
        )
        .sectionId;
  }

  String? _scoreText(String value, String text) {
    return ClinicalValueParser.hasText(value) ? text : null;
  }

  ClinicalStatus _scoreStatus(int score) {
    if (score >= 3) {
      return ClinicalStatus.danger;
    }
    if (score >= 2) {
      return ClinicalStatus.warning;
    }
    if (score == 1) {
      return ClinicalStatus.watch;
    }
    return ClinicalStatus.normal;
  }

  String _missingSentence(SectionProgress progress) {
    if (progress.missingLabels.isEmpty) {
      return 'Đã đủ dữ liệu';
    }
    return 'Còn thiếu: ${progress.missingLabels.join(', ')}';
  }

  String? _rangeWarning(
    String value, {
    required double min,
    required double max,
    required String label,
  }) {
    final number = ClinicalValueParser.parseDouble(value);
    if (number == null) {
      return null;
    }
    if (number < min || number > max) {
      return '$label ngoài khoảng thường gặp, vui lòng kiểm tra lại';
    }
    return null;
  }

  String? _lactateWarning(String value) {
    final lactate = ClinicalValueParser.parseDouble(value);
    if (lactate == null) {
      return null;
    }
    if (lactate >= 4) {
      return 'Lactate cao, cần đánh giá tưới máu và sốc nhiễm khuẩn';
    }
    if (lactate >= 2) {
      return 'Lactate tăng, cần theo dõi sát';
    }
    return null;
  }

  String _selectedFieldUnit(
    String fieldId,
    String value,
    List<String> units, {
    String? savedUnit,
  }) {
    return _selectedUnit(value, units) ??
        _normalizeUnit(savedUnit, units) ??
        _fieldUnitSelections[fieldId] ??
        units.first;
  }

  String? _selectedUnit(String value, List<String> units) {
    final lower = value.toLowerCase();
    for (final unit in units) {
      if (lower.contains(unit.toLowerCase())) {
        return unit;
      }
      if (unit == 'µmol/L' && lower.contains('umol')) {
        return unit;
      }
    }
    return null;
  }

  String? _normalizeUnit(String? value, List<String> units) {
    if (value == null) {
      return null;
    }
    final lower = value.toLowerCase();
    for (final unit in units) {
      if (lower == unit.toLowerCase()) {
        return unit;
      }
      if (unit == 'µmol/L' && lower == 'umol/l') {
        return unit;
      }
    }
    return null;
  }

  String _replaceTrailingUnit(String value, String unit) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    final withoutUnit = trimmed
        .replaceAll(
            RegExp(r'\s*(mg/dl|µmol/l|umol/l)\s*$', caseSensitive: false), '')
        .trim();
    return '$withoutUnit $unit';
  }

  String _formatClock(int millis) {
    if (millis <= 0) {
      return '--:--';
    }
    final value = DateTime.fromMillisecondsSinceEpoch(millis);
    return '${_two(value.hour)}:${_two(value.minute)}';
  }

  bool _hasMeaningfulHistoryData(ClinicalAssessment assessment) {
    return _hasAnyClinicalData(assessment) ||
        _hasQuickScoreData(assessment) ||
        ClinicalValueParser.hasText(assessment.lactateLevel) ||
        ClinicalValueParser.hasText(assessment.news2RespirationMeasured) ||
        ClinicalValueParser.hasText(assessment.news2SystolicBpMeasured) ||
        ClinicalValueParser.hasText(assessment.news2HeartRateMeasured) ||
        ClinicalValueParser.hasText(assessment.lactate) ||
        ClinicalValueParser.hasText(assessment.sofaNeurologicMeasured) ||
        ClinicalValueParser.hasText(assessment.treatmentOutcome);
  }
}
