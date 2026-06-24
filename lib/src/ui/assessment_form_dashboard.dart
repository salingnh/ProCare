part of 'assessment_form_screen.dart';

extension _HsDashboard on _AssessmentFormScreenState {
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
        child: _compactClinicalDashboard(displays, missingItems),
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
