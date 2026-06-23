part of 'home_screen.dart';

extension _HsDashboard on _HomeScreenState {
  RiskTone _qsofaTone(ClinicalAssessment assessment) {
    final tones = _clinicalTones;
    if (!_qsofaComplete(assessment)) {
      return tones.muted;
    }
    return assessment.qsofaTotal >= 2 ? tones.danger : tones.success;
  }

  RiskTone _sofaTone(ClinicalAssessment assessment) {
    final tones = _clinicalTones;
    if (SofaScoring.hasSepticShock(assessment) ||
        SofaScoring.riskGroup(assessment.sofaTotal) == SofaScoring.riskHigh) {
      return tones.danger;
    }
    if (!_sofaComplete(assessment)) {
      return tones.muted;
    }
    if (SofaScoring.riskGroup(assessment.sofaTotal) ==
        SofaScoring.riskIntermediate) {
      return tones.warning;
    }
    if (SofaScoring.hasSepsisBySofa(assessment)) {
      return tones.attention;
    }
    return tones.success;
  }

  RiskTone _sofaThresholdTone(ClinicalAssessment assessment) {
    final tones = _clinicalTones;
    if (!_sofaComplete(assessment)) {
      return tones.muted;
    }
    return SofaScoring.hasSepsisBySofa(assessment)
        ? tones.warning
        : tones.success;
  }

  RiskTone _diagnosisTone(ClinicalAssessment assessment) {
    final tones = _clinicalTones;
    if (_shockInputsIncomplete(assessment)) {
      return tones.muted;
    }
    if (SofaScoring.hasSepticShock(assessment)) {
      return tones.danger;
    }
    if (!_sofaComplete(assessment)) {
      return tones.muted;
    }
    if (SofaScoring.hasSepsisBySofa(assessment)) {
      return tones.warning;
    }
    return tones.success;
  }

  RiskTone _componentScoreTone(int score) {
    final tones = _clinicalTones;
    if (score >= 3) {
      return tones.danger;
    }
    if (score >= 2) {
      return tones.warning;
    }
    if (score == 1) {
      return tones.attention;
    }
    return tones.success;
  }

  bool _news2Complete(ClinicalAssessment assessment) {
    if (assessment.isQuickMode) {
      return assessment.news2RespirationSelected &&
          assessment.news2Spo2Selected &&
          assessment.news2OxygenSelected &&
          assessment.news2TemperatureSelected &&
          assessment.news2SystolicBpSelected &&
          assessment.news2HeartRateSelected &&
          assessment.news2ConsciousnessSelected;
    }
    return ClinicalValueParser.hasText(assessment.news2RespirationMeasured) &&
        ClinicalValueParser.hasText(assessment.news2Spo2Measured) &&
        ClinicalValueParser.hasText(assessment.news2OxygenMeasured) &&
        ClinicalValueParser.hasText(assessment.news2TemperatureMeasured) &&
        ClinicalValueParser.hasText(assessment.news2SystolicBpMeasured) &&
        ClinicalValueParser.hasText(assessment.news2HeartRateMeasured) &&
        ClinicalValueParser.hasText(assessment.news2ConsciousnessMeasured);
  }

  bool _qsofaComplete(ClinicalAssessment assessment) {
    if (assessment.isQuickMode) {
      return assessment.qsofaRespirationSelected &&
          assessment.qsofaSystolicBpSelected &&
          assessment.qsofaConsciousnessSelected;
    }
    return ClinicalValueParser.hasText(assessment.news2RespirationMeasured) &&
        ClinicalValueParser.hasText(assessment.news2SystolicBpMeasured) &&
        ClinicalValueParser.hasText(assessment.news2ConsciousnessMeasured);
  }

  bool _lactateComplete(ClinicalAssessment assessment) {
    return ClinicalValueParser.hasText(assessment.lactate) ||
        (assessment.isQuickMode &&
            ClinicalValueParser.hasText(assessment.lactateLevel));
  }

  bool _shockInputsIncomplete(ClinicalAssessment assessment) {
    if (!assessment.vasopressor) {
      return false;
    }
    return !_lactateComplete(assessment) ||
        !ClinicalValueParser.hasText(assessment.sofaCardiovascularMeasured);
  }

  bool _sofaCardiovascularComplete(ClinicalAssessment assessment) {
    if (assessment.isQuickMode) {
      return assessment.sofaCardiovascularSelected;
    }
    return ClinicalValueParser.hasText(assessment.sofaCardiovascularMeasured) ||
        assessment.vasopressor;
  }

  bool _sofaComplete(ClinicalAssessment assessment) {
    if (assessment.isQuickMode) {
      return assessment.sofaRespirationSelected &&
          assessment.sofaCoagulationSelected &&
          assessment.sofaLiverSelected &&
          assessment.sofaCardiovascularSelected &&
          assessment.sofaNeurologicSelected &&
          assessment.sofaRenalSelected;
    }
    return ClinicalValueParser.hasText(assessment.sofaRespirationMeasured) &&
        ClinicalValueParser.hasText(assessment.sofaCoagulationMeasured) &&
        ClinicalValueParser.hasText(assessment.sofaLiverMeasured) &&
        _sofaCardiovascularComplete(assessment) &&
        ClinicalValueParser.hasText(assessment.sofaNeurologicMeasured) &&
        ClinicalValueParser.hasText(assessment.sofaRenalMeasured);
  }

  String? _diagnosisRequirementText(ClinicalAssessment assessment) {
    if (_shockInputsIncomplete(assessment)) {
      return 'Cần nhập MAP và lactate để đánh giá sốc nhiễm khuẩn';
    }
    if (!_sofaComplete(assessment)) {
      return 'Cần nhập đủ 6 hệ cơ quan để hoàn tất SOFA';
    }
    return null;
  }

  String _news2ConclusionText(ClinicalAssessment assessment) {
    if (!_news2Complete(assessment)) {
      return 'Cần nhập đủ 7 tiêu chí NEWS2 để hoàn tất tính điểm';
    }
    final guidance = ScaleGuidanceConfig.news2(assessment);
    return 'Điểm: NEWS2 ${assessment.news2Total}\nNguy cơ: ${guidance.risk}\nPhản ứng: ${guidance.response}';
  }

  String _qsofaConclusionText(ClinicalAssessment assessment) {
    if (!_qsofaComplete(assessment)) {
      return 'Cần nhập nhịp thở, huyết áp tâm thu và tri giác để hoàn tất qSOFA';
    }
    final guidance = ScaleGuidanceConfig.qsofa(assessment);
    return 'Điểm: qSOFA ${assessment.qsofaTotal}/3\nNguy cơ: ${guidance.risk}\nPhản ứng: ${guidance.response}';
  }

  String _sofaConclusionText(ClinicalAssessment assessment) {
    if (!_sofaComplete(assessment)) {
      return 'Cần nhập đủ 6 hệ cơ quan để hoàn tất SOFA';
    }
    final guidance = ScaleGuidanceConfig.sofa(assessment);
    return 'Điểm: SOFA ${assessment.sofaTotal}\nNguy cơ: ${guidance.risk}\nPhản ứng: ${guidance.response}';
  }

  Widget _clinicalDashboard(ClinicalAssessment assessment) {
    final theme = Theme.of(context);
    final displays = [
      AssessmentDisplay.news2ScoreDisplay(assessment),
      AssessmentDisplay.qsofaScoreDisplay(assessment),
      AssessmentDisplay.sofaScoreDisplay(assessment),
    ];
    final missingItems = AssessmentDisplay.allMissingItems(assessment);
    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            if (compact) {
              return _compactClinicalDashboard(displays, missingItems);
            }
            final cards = [
              for (final display in displays)
                SizedBox(
                  width: (constraints.maxWidth - 24) / 3,
                  child: clinical_ui.ClinicalSummaryCard(
                    display: display,
                    onTap: () => _scrollToSection(_sectionForDisplay(display)),
                  ),
                ),
            ];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < cards.length; i++) ...[
                        cards[i],
                        if (i < cards.length - 1) const SizedBox(width: 12),
                      ],
                    ],
                  ),
                ),
                if (missingItems.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  clinical_ui.MissingDataPanel(
                    items: missingItems,
                    onItemTap: _jumpToMissingItem,
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _compactClinicalDashboard(
    List<ScoreDisplay> displays,
    List<MissingDataItem> missingItems,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            for (var i = 0; i < displays.length; i++) ...[
              Expanded(child: _compactScoreTile(displays[i])),
              if (i < displays.length - 1) const SizedBox(width: 6),
            ],
          ],
        ),
        if (missingItems.isNotEmpty) ...[
          const SizedBox(height: 8),
          _compactMissingDataButton(missingItems),
        ],
      ],
    );
  }

  Widget _compactScoreTile(ScoreDisplay display) {
    final style = clinical_ui.clinicalStatusStyle(context, display.status);
    final theme = Theme.of(context);
    return Tooltip(
      message:
          '${display.title}: ${display.statusLabel}. ${display.helperText}',
      child: Material(
        color: style.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: style.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _scrollToSection(_sectionForDisplay(display)),
          child: SizedBox(
            height: 52,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(style.icon, size: 13, color: style.foreground),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          display.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: style.foreground,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    display.scoreText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: style.foreground,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _compactMissingDataButton(List<MissingDataItem> missingItems) {
    final theme = Theme.of(context);
    final style =
        clinical_ui.clinicalStatusStyle(context, ClinicalStatus.missing);
    return Material(
      color: style.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: style.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showMissingDataSheet(missingItems),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            children: [
              Icon(Icons.playlist_add_check_circle_outlined,
                  size: 18, color: style.foreground),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cần bổ sung ${missingItems.length} dữ liệu',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: style.foreground,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                'Xem',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMissingDataSheet(List<MissingDataItem> missingItems) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SingleChildScrollView(
              child: clinical_ui.MissingDataPanel(
                items: missingItems,
                onItemTap: (item) {
                  Navigator.of(context).pop();
                  _jumpToMissingItem(item);
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
