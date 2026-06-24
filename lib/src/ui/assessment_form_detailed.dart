part of 'assessment_form_screen.dart';

extension _HsDetailedForm on _AssessmentFormScreenState {
  Widget _section(
    String title, {
    required String sectionId,
    required SectionProgress progress,
    required List<Widget> children,
    required bool twoColumns,
  }) {
    final expanded = _expandedSections.contains(sectionId);
    return KeyedSubtree(
      key: _sectionKey(sectionId),
      child: clinical_ui.FormSectionAccordion(
        key: ValueKey('$sectionId-$expanded-$_formVersion'),
        title: title,
        progress: progress,
        initiallyExpanded: expanded,
        onExpansionChanged: (value) {
          _rebuild(() {
            if (value) {
              _expandedSections.add(sectionId);
            } else {
              _expandedSections.remove(sectionId);
            }
          });
        },
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 12.0;
              final availableWidth = constraints.maxWidth;
              final itemWidth =
                  twoColumns ? (availableWidth - spacing) / 2 : availableWidth;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final child in children)
                    SizedBox(
                      width: child is _FullWidth || !twoColumns
                          ? availableWidth
                          : itemWidth,
                      child: child is _FullWidth ? child.child : child,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _diagnosisOutcomeCard(
    ClinicalAssessment assessment, {
    required bool twoColumns,
  }) {
    final theme = Theme.of(context);
    final children = [
      _fullWidth(_sepsisDiagnosisOptions(assessment)),
      DropdownButtonFormField<String>(
        initialValue: assessment.treatmentOutcome.isEmpty
            ? null
            : assessment.treatmentOutcome,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Kết quả điều trị'),
        items: const [
          DropdownMenuItem(
            value: 'Khỏi / Đỡ ra viện',
            child: Text('Khỏi / Đỡ ra viện'),
          ),
          DropdownMenuItem(
            value: 'Chuyển viện',
            child: Text('Chuyển viện'),
          ),
          DropdownMenuItem(
            value: 'Nặng xin về / Tử vong',
            child: Text('Nặng xin về / Tử vong'),
          ),
        ],
        onChanged: (value) => _mutate((a) => a.treatmentOutcome = value ?? ''),
      ),
      _field('Số ngày điều trị', assessment.treatmentDays, (value) {
        assessment.treatmentDays = value;
      },
          unitOptions: const ['ngày'],
          keyboardType: TextInputType.number,
          inputFormatters: _integerInputFormatters),
    ];
    return KeyedSubtree(
      key: _sectionKey(AssessmentSections.diagnosis),
      child: clinical_ui.ClinicalSurfaceCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.assignment_turned_in_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '5. Chẩn đoán & kết cục',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 12.0;
                final availableWidth = constraints.maxWidth;
                final itemWidth = twoColumns
                    ? (availableWidth - spacing) / 2
                    : availableWidth;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final child in children)
                      SizedBox(
                        width: child is _FullWidth || !twoColumns
                            ? availableWidth
                            : itemWidth,
                        child: child is _FullWidth ? child.child : child,
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _fullWidth(Widget child) => _FullWidth(child: child);

  Widget _toggleTile(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final theme = Theme.of(context);
    return clinical_ui.ClinicalSurfaceCard(
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Icon(
            value ? Icons.check_circle : Icons.radio_button_unchecked,
            color: value
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    String value,
    void Function(String value) onChanged, {
    String? fieldId,
    String? unit,
    String? helperText,
    String? warningText,
    String? scoreText,
    ClinicalStatus scoreStatus = ClinicalStatus.normal,
    List<String>? unitOptions,
    String? selectedUnit,
    ValueChanged<String>? onUnitChanged,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    String? hint,
  }) {
    final field = clinical_ui.MedicalInputField(
      label: label,
      value: value,
      unit: unit,
      helperText: helperText,
      warningText: warningText,
      scoreText: scoreText,
      scoreStatus: scoreStatus,
      hintText: hint,
      unitOptions: unitOptions,
      selectedUnit: selectedUnit,
      onUnitChanged: onUnitChanged == null
          ? null
          : (unit) => _mutate((_) => onUnitChanged(unit)),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      focusNode: fieldId == null ? null : _focusNode(fieldId),
      onChanged: (newValue) => _mutate((assessment) {
        onChanged(newValue);
        if (fieldId != null && !ClinicalValueParser.hasText(newValue)) {
          _clearSelectionForField(assessment, fieldId);
        }
      }),
    );
    if (fieldId == null) {
      return field;
    }
    return KeyedSubtree(
      key: _fieldKey(fieldId),
      child: field,
    );
  }

  void _clearSelectionForField(ClinicalAssessment assessment, String fieldId) {
    switch (fieldId) {
      case AssessmentFields.respiration:
        assessment.news2RespirationSelected = false;
        assessment.qsofaRespirationSelected = false;
        break;
      case AssessmentFields.spo2:
        assessment.news2Spo2Selected = false;
        break;
      case AssessmentFields.oxygen:
        assessment.news2OxygenSelected = false;
        break;
      case AssessmentFields.temperature:
        assessment.news2TemperatureSelected = false;
        break;
      case AssessmentFields.systolicBp:
        assessment.news2SystolicBpSelected = false;
        assessment.qsofaSystolicBpSelected = false;
        break;
      case AssessmentFields.heartRate:
        assessment.news2HeartRateSelected = false;
        break;
      case AssessmentFields.consciousness:
        assessment.news2ConsciousnessSelected = false;
        assessment.qsofaConsciousnessSelected = false;
        break;
      case AssessmentFields.sofaRespiration:
        assessment.sofaRespirationSelected = false;
        break;
      case AssessmentFields.sofaCoagulation:
        assessment.sofaCoagulationSelected = false;
        break;
      case AssessmentFields.sofaLiver:
        assessment.sofaLiverSelected = false;
        break;
      case AssessmentFields.cardiovascular:
        if (!assessment.vasopressor) {
          assessment.sofaCardiovascularSelected = false;
        }
        break;
      case AssessmentFields.sofaNeurologic:
        assessment.sofaNeurologicSelected = false;
        break;
      case AssessmentFields.sofaRenal:
        assessment.sofaRenalSelected = false;
        break;
    }
  }

  Widget _sepsisDiagnosisOptions(ClinicalAssessment assessment) {
    final theme = Theme.of(context);
    final sofaIsComplete = sofaComplete(assessment);
    final shockIncomplete = shockInputsIncomplete(assessment);

    final ClinicalStatus sepsisStatus;
    final String sepsisBadge;
    if (!sofaIsComplete) {
      sepsisStatus = ClinicalStatus.watch;
      sepsisBadge = 'Chưa đủ';
    } else if (SofaScoring.hasSepsisBySofa(assessment)) {
      sepsisStatus = ClinicalStatus.danger;
      sepsisBadge = 'Đạt';
    } else {
      sepsisStatus = ClinicalStatus.normal;
      sepsisBadge = 'Không';
    }

    final ClinicalStatus shockStatus;
    final String shockBadge;
    final String shockHint;
    if (shockIncomplete) {
      shockStatus = ClinicalStatus.watch;
      shockBadge = 'Chưa đủ';
      shockHint = ' — cần MAP và lactate';
    } else if (SofaScoring.hasSepticShock(assessment)) {
      shockStatus = ClinicalStatus.danger;
      shockBadge = 'Đạt';
      shockHint = '';
    } else if (assessment.vasopressor) {
      shockStatus = ClinicalStatus.normal;
      shockBadge = 'Không';
      shockHint = '';
    } else {
      shockStatus = ClinicalStatus.missing;
      shockBadge = '—';
      shockHint = '';
    }

    return clinical_ui.ClinicalSurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Chẩn đoán Sepsis-3',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                'TỰ ĐỘNG',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          _diagnosisStatusRow(
            sepsisStatus,
            sepsisBadge,
            'Nhiễm khuẩn huyết (SOFA ≥ 2)',
          ),
          _diagnosisStatusRow(
            shockStatus,
            shockBadge,
            'Sốc nhiễm khuẩn$shockHint',
          ),
        ],
      ),
    );
  }

  Widget _diagnosisStatusRow(
    ClinicalStatus status,
    String badge,
    String label,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          clinical_ui.StatusBadge(status: status, label: badge, dense: true),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.25),
            ),
          ),
        ],
      ),
    );
  }

  Widget _readOnlyLine(
    String label,
    String value, {
    RiskTone? tone,
    int maxLines = 2,
  }) {
    final theme = Theme.of(context);
    final lineTone = tone ?? _clinicalTones.neutral;
    return clinical_ui.ClinicalSurfaceCard(
      color: lineTone.background,
      borderColor: lineTone.border,
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(lineTone.icon, size: 17, color: lineTone.foreground),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: lineTone.foreground,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? 'Chưa nhập dữ liệu' : value,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: lineTone.foreground,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _qsofaChecklist(ClinicalAssessment assessment) {
    return Column(
      children: [
        _readonlyCheck(
          'Nhịp thở ≥ 22 lần/phút',
          assessment.qsofaRespiration,
          ClinicalValueParser.hasText(assessment.news2RespirationMeasured),
        ),
        const SizedBox(height: 6),
        _readonlyCheck(
          'Huyết áp tâm thu ≤ 100 mmHg',
          assessment.qsofaSystolicBp,
          ClinicalValueParser.hasText(assessment.news2SystolicBpMeasured),
        ),
        const SizedBox(height: 6),
        _readonlyCheck(
          'Rối loạn ý thức (GCS < 15 / AVPU khác A)',
          assessment.qsofaConsciousness,
          ClinicalValueParser.hasText(assessment.news2ConsciousnessMeasured),
        ),
      ],
    );
  }

  Widget _readonlyCheck(String label, bool checked, bool completed) {
    final theme = Theme.of(context);
    final tones = _clinicalTones;
    final tone = !completed
        ? tones.muted
        : checked
            ? tones.danger
            : tones.success;
    return clinical_ui.ClinicalSurfaceCard(
      color: tone.background,
      borderColor: tone.border,
      radius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Row(
        children: [
          Icon(
            !completed
                ? Icons.remove_circle_outline
                : checked
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
            color: tone.foreground,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: tone.foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            completed ? (checked ? '1' : '0') : '-',
            style: theme.textTheme.labelMedium?.copyWith(
              color: tone.foreground,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniScores(List<_ScoreItem> scores) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: scores.map(
        (score) {
          final tone = score.completed
              ? componentScoreTone(score.score, _clinicalTones)
              : _clinicalTones.muted;
          return Chip(
            avatar: Icon(tone.icon, size: 16, color: tone.foreground),
            label: Text(
              score.completed
                  ? '${score.label} ${score.score}'
                  : '${score.label} -',
            ),
            backgroundColor: tone.background,
            side: BorderSide(color: tone.border),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            labelStyle: theme.textTheme.labelSmall?.copyWith(
              color: tone.foreground,
              fontWeight: FontWeight.w800,
            ),
          );
        },
      ).toList(),
    );
  }
}
