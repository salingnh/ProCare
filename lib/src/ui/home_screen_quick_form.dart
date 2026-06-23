part of 'home_screen.dart';

extension _HsQuickForm on _HomeScreenState {
  Widget _quickSectionCard(
    String title, {
    required List<Widget> children,
    String? subtitle,
    String? sectionId,
    SectionProgress? progress,
  }) {
    final theme = Theme.of(context);
    final card = clinical_ui.ClinicalSurfaceCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.18,
                  ),
                ),
              ),
              if (progress != null) ...[
                const SizedBox(width: 10),
                _quickProgressPill(progress),
              ],
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.25,
              ),
            ),
          ],
          const SizedBox(height: 14),
          ..._withVerticalSpacing(children, spacing: 14),
        ],
      ),
    );
    if (sectionId == null) {
      return card;
    }
    return KeyedSubtree(
      key: _sectionKey(sectionId),
      child: card,
    );
  }

  List<Widget> _withVerticalSpacing(
    List<Widget> children, {
    required double spacing,
  }) {
    final spaced = <Widget>[];
    for (final child in children) {
      if (spaced.isNotEmpty) {
        spaced.add(SizedBox(height: spacing));
      }
      spaced.add(child);
    }
    return spaced;
  }

  Widget _quickProgressPill(SectionProgress progress) {
    final theme = Theme.of(context);
    final tone =
        progress.complete ? _clinicalTones.success : _clinicalTones.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: tone.background,
        border: Border.all(color: tone.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${progress.completedCount}/${progress.totalCount}',
        style: theme.textTheme.labelSmall?.copyWith(
          color: tone.foreground,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _quickFieldGrid({
    required bool twoColumns,
    required List<Widget> children,
  }) {
    return LayoutBuilder(
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
    );
  }

  Widget _quickNews2Section(ClinicalAssessment assessment) {
    final spo2Options = assessment.news2Spo2Scale2
        ? const [
            _QuickScoreOption('88 - 92%', 0),
            _QuickScoreOption('86 - 87% hoặc 93 - 94%', 1),
            _QuickScoreOption('84 - 85% hoặc 95 - 96%', 2),
            _QuickScoreOption('≤ 83% hoặc ≥ 97%', 3),
          ]
        : const [
            _QuickScoreOption('≥ 96%', 0),
            _QuickScoreOption('94 - 95%', 1),
            _QuickScoreOption('92 - 93%', 2),
            _QuickScoreOption('≤ 91%', 3),
          ];
    return _quickSectionCard(
      '2. NEWS2/qSOFA - đánh giá nhanh',
      sectionId: AssessmentSections.news2,
      progress: AssessmentDisplay.news2Progress(assessment),
      children: [
        _quickSpo2ScaleCard(assessment),
        _quickScoreGroup(
          title: 'Nhịp thở (lần/phút)',
          selected: assessment.news2RespirationSelected,
          score: assessment.news2Respiration,
          fieldId: AssessmentFields.respiration,
          options: const [
            _QuickScoreOption('12 - 20', 0),
            _QuickScoreOption('9 - 11', 1),
            _QuickScoreOption('21 - 24', 2),
            _QuickScoreOption('≤ 8 hoặc ≥ 25', 3),
          ],
          onSelected: (score) => _mutate((a) {
            a.news2Respiration = score;
            a.news2RespirationSelected = true;
          }),
          onClear: () => _mutate((a) => a.news2RespirationSelected = false),
        ),
        _quickScoreGroup(
          title: assessment.news2Spo2Scale2
              ? 'SpO2 (%) - Thang 2'
              : 'SpO2 (%) - Thang 1',
          subtitle: assessment.news2Spo2Scale2
              ? 'Bệnh nhân có nguy cơ suy hô hấp tăng CO2'
              : 'Bệnh nhân không có nguy cơ suy hô hấp tăng CO2',
          selected: assessment.news2Spo2Selected,
          score: assessment.news2Spo2,
          fieldId: AssessmentFields.spo2,
          options: spo2Options,
          onSelected: (score) => _mutate((a) {
            a.news2Spo2 = score;
            a.news2Spo2Selected = true;
          }),
          onClear: () => _mutate((a) => a.news2Spo2Selected = false),
        ),
        _quickScoreGroup(
          title: 'Hỗ trợ hô hấp',
          selected: assessment.news2OxygenSelected,
          score: assessment.news2Oxygen,
          fieldId: AssessmentFields.oxygen,
          options: const [
            _QuickScoreOption('Thở khí phòng', 0),
            _QuickScoreOption('Thở Oxy', 2),
          ],
          onSelected: (score) => _mutate((a) {
            a.news2Oxygen = score;
            a.news2OxygenSelected = true;
          }),
          onClear: () => _mutate((a) => a.news2OxygenSelected = false),
        ),
        _quickScoreGroup(
          title: 'Huyết áp tâm thu (mmHg)',
          selected: assessment.news2SystolicBpSelected,
          score: assessment.news2SystolicBp,
          fieldId: AssessmentFields.systolicBp,
          options: const [
            _QuickScoreOption('111 - 219', 0),
            _QuickScoreOption('101 - 110', 1),
            _QuickScoreOption('91 - 100', 2),
            _QuickScoreOption('≤ 90 hoặc ≥ 220', 3),
          ],
          onSelected: (score) => _mutate((a) {
            a.news2SystolicBp = score;
            a.news2SystolicBpSelected = true;
          }),
          onClear: () => _mutate((a) => a.news2SystolicBpSelected = false),
        ),
        _quickScoreGroup(
          title: 'Nhịp tim (lần/phút)',
          selected: assessment.news2HeartRateSelected,
          score: assessment.news2HeartRate,
          fieldId: AssessmentFields.heartRate,
          options: const [
            _QuickScoreOption('51 - 90', 0),
            _QuickScoreOption('41 - 50 hoặc 91 - 110', 1),
            _QuickScoreOption('111 - 130', 2),
            _QuickScoreOption('≤ 40 hoặc ≥ 131', 3),
          ],
          onSelected: (score) => _mutate((a) {
            a.news2HeartRate = score;
            a.news2HeartRateSelected = true;
          }),
          onClear: () => _mutate((a) => a.news2HeartRateSelected = false),
        ),
        _quickScoreGroup(
          title: 'Nhiệt độ (°C)',
          selected: assessment.news2TemperatureSelected,
          score: assessment.news2Temperature,
          fieldId: AssessmentFields.temperature,
          options: const [
            _QuickScoreOption('36.1 - 38.0', 0),
            _QuickScoreOption('35.1 - 36.0 hoặc 38.1 - 39.0', 1),
            _QuickScoreOption('≥ 39.1', 2),
            _QuickScoreOption('≤ 35.0', 3),
          ],
          onSelected: (score) => _mutate((a) {
            a.news2Temperature = score;
            a.news2TemperatureSelected = true;
          }),
          onClear: () => _mutate((a) => a.news2TemperatureSelected = false),
        ),
        _quickScoreGroup(
          title: 'Tri giác (AVPU)',
          selected: assessment.news2ConsciousnessSelected,
          score: assessment.news2Consciousness,
          fieldId: AssessmentFields.consciousness,
          options: const [
            _QuickScoreOption('A - Tỉnh', 0),
            _QuickScoreOption('C / V / P / U', 3),
          ],
          onSelected: (score) => _mutate((a) {
            a.news2Consciousness = score;
            a.news2ConsciousnessSelected = true;
          }),
          onClear: () => _mutate((a) => a.news2ConsciousnessSelected = false),
        ),
        _quickSubheading('qSOFA'),
        _quickScoreGroup(
          title: 'Nhịp thở ≥ 22 lần/phút',
          selected: assessment.qsofaRespirationSelected,
          score: assessment.qsofaRespiration ? 1 : 0,
          fieldId: AssessmentFields.qsofaRespiration,
          options: const [
            _QuickScoreOption('Không', 0),
            _QuickScoreOption('Có', 1),
          ],
          onSelected: (score) => _mutate((a) {
            a.qsofaRespiration = score == 1;
            a.qsofaRespirationSelected = true;
          }),
          onClear: () => _mutate((a) => a.qsofaRespirationSelected = false),
        ),
        _quickScoreGroup(
          title: 'Huyết áp tâm thu ≤ 100 mmHg',
          selected: assessment.qsofaSystolicBpSelected,
          score: assessment.qsofaSystolicBp ? 1 : 0,
          fieldId: AssessmentFields.qsofaSystolicBp,
          options: const [
            _QuickScoreOption('Không', 0),
            _QuickScoreOption('Có', 1),
          ],
          onSelected: (score) => _mutate((a) {
            a.qsofaSystolicBp = score == 1;
            a.qsofaSystolicBpSelected = true;
          }),
          onClear: () => _mutate((a) => a.qsofaSystolicBpSelected = false),
        ),
        _quickScoreGroup(
          title: 'Rối loạn ý thức',
          selected: assessment.qsofaConsciousnessSelected,
          score: assessment.qsofaConsciousness ? 1 : 0,
          fieldId: AssessmentFields.qsofaConsciousness,
          options: const [
            _QuickScoreOption('Không', 0),
            _QuickScoreOption('Có', 1),
          ],
          onSelected: (score) => _mutate((a) {
            a.qsofaConsciousness = score == 1;
            a.qsofaConsciousnessSelected = true;
          }),
          onClear: () => _mutate((a) => a.qsofaConsciousnessSelected = false),
        ),
        _miniScores([
          _ScoreItem(
            'Nhịp thở',
            assessment.news2Respiration,
            completed: assessment.news2RespirationSelected,
          ),
          _ScoreItem(
            'HA',
            assessment.news2SystolicBp,
            completed: assessment.news2SystolicBpSelected,
          ),
          _ScoreItem(
            'Tri giác',
            assessment.news2Consciousness,
            completed: assessment.news2ConsciousnessSelected,
          ),
          _ScoreItem(
            'SpO2',
            assessment.news2Spo2,
            completed: assessment.news2Spo2Selected,
          ),
          _ScoreItem(
            'Oxy',
            assessment.news2Oxygen,
            completed: assessment.news2OxygenSelected,
          ),
          _ScoreItem(
            'Nhiệt',
            assessment.news2Temperature,
            completed: assessment.news2TemperatureSelected,
          ),
          _ScoreItem(
            'Mạch',
            assessment.news2HeartRate,
            completed: assessment.news2HeartRateSelected,
          ),
        ]),
        _readOnlyLine(
          'Kết luận NEWS2',
          _news2ConclusionText(assessment),
          tone: _news2Tone(assessment),
          maxLines: 9,
        ),
        _readOnlyLine(
          'Kết luận qSOFA',
          _qsofaConclusionText(assessment),
          tone: _qsofaTone(assessment),
          maxLines: 5,
        ),
      ],
    );
  }

  Widget _quickHemodynamicsSection(
    ClinicalAssessment assessment, {
    required bool twoColumns,
  }) {
    return _quickSectionCard(
      '3. Lactate & huyết động',
      sectionId: AssessmentSections.lactate,
      progress: AssessmentDisplay.lactateProgress(assessment),
      children: [
        _quickLactateLevelGroup(assessment),
        _quickFieldGrid(
          twoColumns: twoColumns,
          children: [
            _field('Thời gian lấy mẫu lactate', assessment.lactateSampleTime,
                (value) {
              assessment.lactateSampleTime = value;
            },
                fieldId: AssessmentFields.lactateSampleTime,
                hint: 'HH:mm',
                keyboardType: TextInputType.datetime,
                inputFormatters: _timeInputFormatters),
            _field('Tim mạch - MAP/Vận mạch (mmHg; thuốc/liều)',
                assessment.sofaCardiovascularMeasured, (value) {
              assessment.sofaCardiovascularMeasured = value;
            },
                fieldId: AssessmentFields.cardiovascular,
                scoreText: _scoreText(
                  assessment.sofaCardiovascularMeasured,
                  'Điểm SOFA tim mạch: ${assessment.sofaCardiovascular}',
                ),
                scoreStatus: _scoreStatus(assessment.sofaCardiovascular),
                hint: 'VD: MAP 65 hoặc norepi 0.2'),
            _toggleTile(
              'Có dùng vận mạch',
              assessment.vasopressor,
              (value) => _mutate((a) => a.vasopressor = value),
            ),
          ],
        ),
        _readOnlyLine(
          'Phân mức Lactate',
          assessment.lactateLevel.isEmpty
              ? 'Chưa nhập lactate'
              : assessment.lactateLevel,
          tone: _lactateComplete(assessment) ? null : _clinicalTones.muted,
        ),
      ],
    );
  }

  Widget _quickLactateLevelGroup(ClinicalAssessment assessment) {
    return _quickChoiceGroup(
      title: 'Lactate tĩnh mạch',
      subtitle: 'Chọn nhanh phân mức lactate lúc phân loại/giờ đầu',
      selectedValue: assessment.lactateLevel,
      fieldId: AssessmentFields.lactate,
      options: const [
        _QuickChoiceOption('< 2 mmol/L', '< 2 mmol/L', 'Bình thường'),
        _QuickChoiceOption('2 - 3.9 mmol/L', '2 - 3.9 mmol/L', 'Tăng'),
        _QuickChoiceOption('≥ 4 mmol/L', '≥ 4 mmol/L', 'Cao'),
      ],
      onSelected: (value) => _mutate((a) {
        a.lactate = '';
        a.lactateLevel = value;
      }),
      onClear: () => _mutate((a) {
        a.lactate = '';
        a.lactateLevel = '';
      }),
    );
  }

  Widget _quickSofaSection(ClinicalAssessment assessment) {
    const sofaRespirationOptions = [
      _QuickScoreOption('PaO2/FiO2 ≥ 400', 0),
      _QuickScoreOption('PaO2/FiO2 < 400', 1),
      _QuickScoreOption('PaO2/FiO2 < 300', 2),
      _QuickScoreOption('< 200 + hỗ trợ hô hấp', 3),
      _QuickScoreOption('< 100 + hỗ trợ hô hấp', 4),
    ];
    const sofaCoagulationOptions = [
      _QuickScoreOption('Tiểu cầu ≥ 150', 0),
      _QuickScoreOption('Tiểu cầu < 150', 1),
      _QuickScoreOption('Tiểu cầu < 100', 2),
      _QuickScoreOption('Tiểu cầu < 50', 3),
      _QuickScoreOption('Tiểu cầu < 20', 4),
    ];
    const sofaLiverOptions = [
      _QuickScoreOption('Bilirubin < 1.2', 0),
      _QuickScoreOption('Bilirubin 1.2 - 1.9', 1),
      _QuickScoreOption('Bilirubin 2.0 - 5.9', 2),
      _QuickScoreOption('Bilirubin 6.0 - 11.9', 3),
      _QuickScoreOption('Bilirubin ≥ 12.0', 4),
    ];
    const sofaCardiovascularOptions = [
      _QuickScoreOption('MAP ≥ 70', 0),
      _QuickScoreOption('MAP < 70', 1),
      _QuickScoreOption('Dopamine ≤ 5 hoặc dobutamine', 2),
      _QuickScoreOption('Dopamine > 5 hoặc norepi/epi ≤ 0.1', 3),
      _QuickScoreOption('Dopamine > 15 hoặc norepi/epi > 0.1', 4),
    ];
    const sofaNeurologicOptions = [
      _QuickScoreOption('GCS 15', 0),
      _QuickScoreOption('GCS 13 - 14', 1),
      _QuickScoreOption('GCS 10 - 12', 2),
      _QuickScoreOption('GCS 6 - 9', 3),
      _QuickScoreOption('GCS < 6', 4),
    ];
    const sofaRenalOptions = [
      _QuickScoreOption('Creatinin < 1.2', 0),
      _QuickScoreOption('Creatinin 1.2 - 1.9', 1),
      _QuickScoreOption('Creatinin 2.0 - 3.4', 2),
      _QuickScoreOption('Creatinin 3.5 - 4.9 hoặc nước tiểu < 500 mL', 3),
      _QuickScoreOption('Creatinin ≥ 5.0 hoặc nước tiểu < 200 mL', 4),
    ];
    return _quickSectionCard(
      '4. SOFA 24 giờ - chọn điểm nhanh',
      sectionId: AssessmentSections.sofa,
      progress: AssessmentDisplay.sofaProgress(assessment),
      children: [
        _quickScoreGroup(
          title: 'Hô hấp',
          selected: assessment.sofaRespirationSelected,
          score: assessment.sofaRespiration,
          fieldId: AssessmentFields.sofaRespiration,
          options: sofaRespirationOptions,
          minTileWidth: 132,
          onSelected: (score) => _mutate((a) {
            a.sofaRespiration = score;
            a.sofaRespirationSelected = true;
          }),
          onClear: () => _mutate((a) => a.sofaRespirationSelected = false),
        ),
        _quickScoreGroup(
          title: 'Đông máu',
          selected: assessment.sofaCoagulationSelected,
          score: assessment.sofaCoagulation,
          fieldId: AssessmentFields.sofaCoagulation,
          options: sofaCoagulationOptions,
          minTileWidth: 132,
          onSelected: (score) => _mutate((a) {
            a.sofaCoagulation = score;
            a.sofaCoagulationSelected = true;
          }),
          onClear: () => _mutate((a) => a.sofaCoagulationSelected = false),
        ),
        _quickScoreGroup(
          title: 'Gan',
          selected: assessment.sofaLiverSelected,
          score: assessment.sofaLiver,
          fieldId: AssessmentFields.sofaLiver,
          subtitle: 'Bilirubin theo mg/dL',
          options: sofaLiverOptions,
          minTileWidth: 132,
          onSelected: (score) => _mutate((a) {
            a.sofaLiver = score;
            a.sofaLiverSelected = true;
          }),
          onClear: () => _mutate((a) => a.sofaLiverSelected = false),
        ),
        _quickScoreGroup(
          title: 'Tim mạch',
          selected: assessment.sofaCardiovascularSelected,
          score: assessment.sofaCardiovascular,
          fieldId: AssessmentFields.sofaCardiovascularScore,
          subtitle: 'Liều vận mạch theo µg/kg/phút',
          options: sofaCardiovascularOptions,
          minTileWidth: 132,
          onSelected: (score) => _mutate((a) {
            a.sofaCardiovascular = score;
            a.sofaCardiovascularSelected = true;
          }),
          onClear: () => _mutate((a) => a.sofaCardiovascularSelected = false),
        ),
        _quickScoreGroup(
          title: 'Thần kinh',
          selected: assessment.sofaNeurologicSelected,
          score: assessment.sofaNeurologic,
          fieldId: AssessmentFields.sofaNeurologic,
          options: sofaNeurologicOptions,
          minTileWidth: 132,
          onSelected: (score) => _mutate((a) {
            a.sofaNeurologic = score;
            a.sofaNeurologicSelected = true;
          }),
          onClear: () => _mutate((a) => a.sofaNeurologicSelected = false),
        ),
        _quickScoreGroup(
          title: 'Thận',
          selected: assessment.sofaRenalSelected,
          score: assessment.sofaRenal,
          fieldId: AssessmentFields.sofaRenal,
          subtitle: 'Creatinin theo mg/dL hoặc nước tiểu/24 giờ',
          options: sofaRenalOptions,
          minTileWidth: 132,
          onSelected: (score) => _mutate((a) {
            a.sofaRenal = score;
            a.sofaRenalSelected = true;
          }),
          onClear: () => _mutate((a) => a.sofaRenalSelected = false),
        ),
        _miniScores([
          _ScoreItem(
            'Hô hấp',
            assessment.sofaRespiration,
            completed: assessment.sofaRespirationSelected,
          ),
          _ScoreItem(
            'Đông máu',
            assessment.sofaCoagulation,
            completed: assessment.sofaCoagulationSelected,
          ),
          _ScoreItem(
            'Gan',
            assessment.sofaLiver,
            completed: assessment.sofaLiverSelected,
          ),
          _ScoreItem(
            'Tim mạch',
            assessment.sofaCardiovascular,
            completed: assessment.sofaCardiovascularSelected,
          ),
          _ScoreItem(
            'Thần kinh',
            assessment.sofaNeurologic,
            completed: assessment.sofaNeurologicSelected,
          ),
          _ScoreItem(
            'Thận',
            assessment.sofaRenal,
            completed: assessment.sofaRenalSelected,
          ),
        ]),
        _readOnlyLine(
          'Ngưỡng Sepsis-3',
          _sofaComplete(assessment)
              ? sofaThresholdText(assessment)
              : _missingSentence(AssessmentDisplay.sofaProgress(assessment)),
          tone: _sofaThresholdTone(assessment),
        ),
        _readOnlyLine(
          'Kết luận SOFA',
          _sofaConclusionText(assessment),
          tone: _sofaTone(assessment),
          maxLines: 5,
        ),
      ],
    );
  }

  Widget _quickSpo2ScaleCard(ClinicalAssessment assessment) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return clinical_ui.ClinicalSurfaceCard(
      color: scheme.primaryContainer.withValues(alpha: 0.35),
      borderColor: scheme.primary.withValues(alpha: 0.18),
      radius: 16,
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Row(
        children: [
          Icon(
            Icons.air_outlined,
            color: scheme.primary,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bệnh nhân có suy hô hấp?',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Bật nếu bệnh nhân có tiền sử suy hô hấp do tăng CO2 máu.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onPrimaryContainer.withValues(alpha: 0.78),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: assessment.news2Spo2Scale2,
            onChanged: (value) => _mutate((a) => a.news2Spo2Scale2 = value),
          ),
        ],
      ),
    );
  }

  Widget _quickSubheading(String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _quickScoreGroup({
    required String title,
    required bool selected,
    required int score,
    required List<_QuickScoreOption> options,
    required ValueChanged<int> onSelected,
    required VoidCallback onClear,
    String? subtitle,
    String? fieldId,
    double minTileWidth = 112,
  }) {
    final theme = Theme.of(context);
    final selector = clinical_ui.ClinicalSurfaceCard(
      radius: 16,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.25,
              ),
            ),
          ],
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 10.0;
              final columns = _quickScoreColumnCount(
                constraints.maxWidth,
                options.length,
                minTileWidth: minTileWidth,
              );
              final tileWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final option in options)
                    SizedBox(
                      width: tileWidth,
                      child: _quickScoreTile(
                        option: option,
                        selected: selected && score == option.score,
                        onSelected: () => onSelected(option.score),
                        onClear: onClear,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
    if (fieldId == null) {
      return selector;
    }
    return KeyedSubtree(
      key: _fieldKey(fieldId),
      child: selector,
    );
  }

  Widget _quickChoiceGroup({
    required String title,
    required String selectedValue,
    required List<_QuickChoiceOption> options,
    required ValueChanged<String> onSelected,
    required VoidCallback onClear,
    String? subtitle,
    String? fieldId,
  }) {
    final theme = Theme.of(context);
    final selector = clinical_ui.ClinicalSurfaceCard(
      radius: 16,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.25,
              ),
            ),
          ],
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 10.0;
              final columns = _quickScoreColumnCount(
                constraints.maxWidth,
                options.length,
                minTileWidth: 112,
              );
              final tileWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final option in options)
                    SizedBox(
                      width: tileWidth,
                      child: _quickChoiceTile(
                        option: option,
                        selected: selectedValue == option.value,
                        onSelected: () => onSelected(option.value),
                        onClear: onClear,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
    if (fieldId == null) {
      return selector;
    }
    return KeyedSubtree(
      key: _fieldKey(fieldId),
      child: selector,
    );
  }

  Widget _quickChoiceTile({
    required _QuickChoiceOption option,
    required bool selected,
    required VoidCallback onSelected,
    required VoidCallback onClear,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tone = selected ? _clinicalTones.attention : null;
    return clinical_ui.ClinicalSurfaceCard(
      color: tone?.background ?? scheme.surfaceContainerLowest,
      borderColor: tone?.border ?? scheme.outlineVariant,
      radius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      onTap: selected ? onClear : onSelected,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 68),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              option.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tone?.foreground ?? scheme.onSurface,
                fontWeight: FontWeight.w900,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              option.helper,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: tone?.foreground ??
                    scheme.onSurfaceVariant.withValues(alpha: 0.72),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _quickScoreColumnCount(
    double width,
    int optionCount, {
    required double minTileWidth,
  }) {
    const spacing = 10.0;
    var columns = ((width + spacing) / (minTileWidth + spacing)).floor();
    if (columns < 1) {
      columns = 1;
    }
    final maxColumns = width >= 760
        ? 5
        : width >= 520
            ? 4
            : width >= 340
                ? 3
                : width >= 220
                    ? 2
                    : 1;
    if (columns > maxColumns) {
      columns = maxColumns;
    }
    return columns > optionCount ? optionCount : columns;
  }

  Widget _quickScoreTile({
    required _QuickScoreOption option,
    required bool selected,
    required VoidCallback onSelected,
    required VoidCallback onClear,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tone = selected ? _componentScoreTone(option.score) : null;
    return clinical_ui.ClinicalSurfaceCard(
      color: tone?.background ?? scheme.surfaceContainerLowest,
      borderColor: tone?.border ?? scheme.outlineVariant,
      radius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      onTap: selected ? onClear : onSelected,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 68),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              option.label,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tone?.foreground ?? scheme.onSurface,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '${option.score} điểm',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: tone?.foreground ??
                    scheme.onSurfaceVariant.withValues(alpha: 0.72),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
