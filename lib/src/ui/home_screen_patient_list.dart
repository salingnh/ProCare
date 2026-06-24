part of 'home_screen.dart';

extension _HsPatientList on _HomeScreenState {
  Widget _buildPatientList() {
    final patients = _listController.filteredHistory;
    final showHeader = _listController.history.isNotEmpty ||
        _listController.searchQuery.trim().isNotEmpty ||
        _listController.filter != PatientListFilter.all;
    return Column(
      children: [
        if (showHeader)
          Padding(
            padding: EdgeInsets.fromLTRB(
              12,
              patients.isEmpty ? 8 : 12,
              12,
              patients.isEmpty ? 6 : 10,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 620;
                final searchField = TextField(
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Tìm theo mã BN hoặc họ tên',
                    prefixIcon: Icon(Icons.search),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (value) {
                    _listController.setSearchQuery(value);
                  },
                );
                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      searchField,
                      if (_listController.history.isNotEmpty ||
                          _listController.filter != PatientListFilter.all) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _patientSortControl(compact: true),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: _patientFilterMenu()),
                          ],
                        ),
                      ],
                      if (patients.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _patientSummaryStrip(_listController.summary, compact: true),
                      ],
                    ],
                  );
                }
                final sortControl = _patientSortControl();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(child: searchField),
                        const SizedBox(width: 12),
                        sortControl,
                      ],
                    ),
                    if (patients.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        runSpacing: 8,
                        children: [
                          _patientFilterChips(),
                          _patientSummaryStrip(_listController.summary),
                        ],
                      ),
                    ] else if (_listController.history.isNotEmpty ||
                        _listController.filter != PatientListFilter.all) ...[
                      const SizedBox(height: 10),
                      _patientFilterChips(),
                    ],
                  ],
                );
              },
            ),
          ),
        Expanded(
          child: patients.isEmpty
              ? (_listController.loading
                  ? _patientListLoadingState()
                  : _emptyPatientState())
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        NotificationListener<ScrollNotification>(
                          onNotification: (notification) =>
                              _handlePatientScroll(notification, patients),
                          child: MasonryGridView.count(
                            controller: _patientScrollControllerOrCreate,
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                            crossAxisCount:
                                _patientGridColumns(constraints.maxWidth),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            itemCount:
                                patients.length + (_listController.loading ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == patients.length) {
                                return _patientPageLoadingTile();
                              }
                              if (index < 0 || index >= patients.length) {
                                return const SizedBox.shrink();
                              }
                              return _patientCard(patients[index]);
                            },
                          ),
                        ),
                        ValueListenableBuilder<_PatientScrollBubbleState>(
                          valueListenable: _patientScrollBubble,
                          builder: (context, bubble, child) {
                            if (!bubble.visible || bubble.label.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return Positioned(
                              top: _patientScrollBubbleTop(
                                constraints,
                                bubble.fraction,
                              ),
                              right: 12,
                              child: _patientScrollBubbleWidget(bubble.label),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _patientSortControl({bool compact = false}) {
    if (compact) {
      return PopupMenuButton<PatientSortMode>(
        initialValue: _listController.sortMode,
        tooltip: 'Sắp xếp',
        onSelected: _selectPatientSort,
        itemBuilder: (context) => [
          _patientSortMenuItem(PatientSortMode.name),
          _patientSortMenuItem(PatientSortMode.createdAt),
          _patientSortMenuItem(PatientSortMode.updatedAt),
        ],
        child: _patientListMenuButton(
          icon: Icons.sort,
          label: _patientSortLabel(_listController.sortMode, compact: true),
        ),
      );
    }
    return SegmentedButton<PatientSortMode>(
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        visualDensity: VisualDensity.compact,
      ),
      selected: {_listController.sortMode},
      segments: const [
        ButtonSegment(
          value: PatientSortMode.name,
          label: Text('Tên'),
          icon: Icon(Icons.sort_by_alpha),
        ),
        ButtonSegment(
          value: PatientSortMode.createdAt,
          label: Text('Ngày tạo'),
          icon: Icon(Icons.event_available),
        ),
        ButtonSegment(
          value: PatientSortMode.updatedAt,
          label: Text('Ngày cập nhật'),
          icon: Icon(Icons.update),
        ),
      ],
      onSelectionChanged: (selection) {
        _selectPatientSort(selection.first);
      },
    );
  }

  PopupMenuItem<PatientSortMode> _patientSortMenuItem(PatientSortMode mode) {
    final selected = _listController.sortMode == mode;
    return PopupMenuItem(
      value: mode,
      child: Row(
        children: [
          Icon(selected ? Icons.check : null, size: 18),
          const SizedBox(width: 8),
          Text(_patientSortLabel(mode)),
        ],
      ),
    );
  }

  String _patientSortLabel(PatientSortMode mode, {bool compact = false}) {
    return switch (mode) {
      PatientSortMode.name => 'Tên',
      PatientSortMode.createdAt => compact ? 'Ngày tạo' : 'Ngày tạo',
      PatientSortMode.updatedAt => compact ? 'Cập nhật' : 'Ngày cập nhật',
    };
  }

  void _selectPatientSort(PatientSortMode next) {
    if (next == _listController.sortMode) {
      return;
    }
    _patientScrollBubble.value = const _PatientScrollBubbleState.hidden();
    if (_patientScrollControllerOrCreate.hasClients) {
      _patientScrollControllerOrCreate.jumpTo(0);
    }
    _listController.setSortMode(next);
  }

  Widget _patientFilterChips() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _patientFilterChip(PatientListFilter.all, 'Tất cả'),
        _patientFilterChip(PatientListFilter.incomplete, 'Chưa đủ dữ liệu'),
        _patientFilterChip(PatientListFilter.highRisk, 'Nguy cơ cao'),
        _patientFilterChip(PatientListFilter.septicShock, 'Sốc NK'),
      ],
    );
  }

  Widget _patientFilterMenu() {
    return PopupMenuButton<PatientListFilter>(
      initialValue: _listController.filter,
      tooltip: 'Lọc danh sách',
      onSelected: _selectPatientFilter,
      itemBuilder: (context) => [
        _patientFilterMenuItem(PatientListFilter.all),
        _patientFilterMenuItem(PatientListFilter.incomplete),
        _patientFilterMenuItem(PatientListFilter.highRisk),
        _patientFilterMenuItem(PatientListFilter.septicShock),
      ],
      child: _patientListMenuButton(
        icon: Icons.filter_list,
        label: _patientFilterLabel(_listController.filter, compact: true),
      ),
    );
  }

  PopupMenuItem<PatientListFilter> _patientFilterMenuItem(PatientListFilter filter) {
    final selected = _listController.filter == filter;
    return PopupMenuItem(
      value: filter,
      child: Row(
        children: [
          Icon(selected ? Icons.check : null, size: 18),
          const SizedBox(width: 8),
          Text(_patientFilterLabel(filter)),
        ],
      ),
    );
  }

  Widget _patientListMenuButton({
    required IconData icon,
    required String label,
  }) {
    final theme = Theme.of(context);
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: ShapeDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.arrow_drop_down,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  String _patientFilterLabel(PatientListFilter filter, {bool compact = false}) {
    return switch (filter) {
      PatientListFilter.all => 'Tất cả',
      PatientListFilter.incomplete => compact ? 'Chưa đủ' : 'Chưa đủ dữ liệu',
      PatientListFilter.highRisk => 'Nguy cơ cao',
      PatientListFilter.septicShock => 'Sốc NK',
    };
  }

  Widget _patientFilterChip(PatientListFilter filter, String label) {
    final theme = Theme.of(context);
    final selected = _listController.filter == filter;
    final status = switch (filter) {
      PatientListFilter.all => ClinicalStatus.normal,
      PatientListFilter.incomplete => ClinicalStatus.missing,
      PatientListFilter.highRisk => ClinicalStatus.warning,
      PatientListFilter.septicShock => ClinicalStatus.danger,
    };
    final style = clinical_ui.clinicalStatusStyle(context, status);
    return FilterChip(
      selected: selected,
      label: Text(label),
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      selectedColor: style.background,
      checkmarkColor: style.foreground,
      side: BorderSide(
        color: selected ? style.border : theme.colorScheme.outlineVariant,
      ),
      labelStyle: theme.textTheme.labelMedium?.copyWith(
        color: selected ? style.foreground : theme.colorScheme.onSurfaceVariant,
        fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
      ),
      onSelected: (_) {
        _selectPatientFilter(filter);
      },
    );
  }

  void _selectPatientFilter(PatientListFilter filter) {
    if (filter == _listController.filter) {
      return;
    }
    _patientScrollBubble.value = const _PatientScrollBubbleState.hidden();
    _listController.setFilter(filter);
    if (_patientScrollControllerOrCreate.hasClients) {
      _patientScrollControllerOrCreate.jumpTo(0);
    }
  }

  Widget _patientSummaryStrip(
    PatientSummary summary, {
    bool compact = false,
  }) {
    final badges = [
      _summaryBadge('Tổng', summary.total, ClinicalStatus.normal),
      _summaryBadge('Chưa đủ', summary.incomplete, ClinicalStatus.missing),
      _summaryBadge('Nguy cơ cao', summary.highRisk, ClinicalStatus.warning),
      _summaryBadge('Sốc NK', summary.shock, ClinicalStatus.danger),
    ];
    if (compact) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < badges.length; i++) ...[
              badges[i],
              if (i < badges.length - 1) const SizedBox(width: 6),
            ],
          ],
        ),
      );
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: badges,
    );
  }

  Widget _summaryBadge(String label, int count, ClinicalStatus status) {
    return clinical_ui.StatusBadge(
      status: status,
      label: '$label: $count',
      dense: true,
    );
  }

  Widget _patientListLoadingState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox.square(
            dimension: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Đang tải danh sách...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _patientPageLoadingTile() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      ),
    );
  }

  Widget _emptyPatientState() {
    final theme = Theme.of(context);
    final activeFilter =
        _listController.searchQuery.trim().isNotEmpty || _listController.filter != PatientListFilter.all;
    return Center(
      child: clinical_ui.ClinicalSurfaceCard(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 42,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              activeFilter
                  ? 'Không có phiếu phù hợp'
                  : 'Chưa có phiếu theo dõi',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              activeFilter
                  ? 'Thử đổi bộ lọc hoặc từ khóa tìm kiếm.'
                  : 'Tạo phiếu đầu tiên để ghi nhận NEWS2, lactate và SOFA.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _startNew,
              icon: const Icon(Icons.add),
              label: const Text('Phiếu mới'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _patientCard(SavedAssessment saved) {
    final assessment = saved.assessment;
    final treatmentOutcome = assessment.treatmentOutcome.trim();
    final badges = <Widget>[
      _scoreBadge(AssessmentDisplay.news2ScoreDisplay(assessment)),
      _scoreBadge(AssessmentDisplay.qsofaScoreDisplay(assessment)),
      _scoreBadge(AssessmentDisplay.sofaScoreDisplay(assessment)),
      if (ClinicalValueParser.hasText(assessment.lactate))
        clinical_ui.StatusBadge(
          status: SofaScoring.lactateAtLeastTwo(assessment)
              ? ClinicalStatus.warning
              : ClinicalStatus.normal,
          label: 'Lactate: ${assessment.lactate.trim()}',
          dense: true,
        ),
      if (AssessmentDisplay.isSepticShockPatient(assessment))
        const clinical_ui.StatusBadge(
          status: ClinicalStatus.danger,
          label: 'Sốc NK',
          dense: true,
        ),
    ];
    return clinical_ui.PatientCard(
      name: assessment.fullName.trim().isEmpty
          ? 'Chưa nhập tên bệnh nhân'
          : assessment.fullName.trim(),
      identityLine: _patientIdentityLine(assessment),
      admissionLine: _patientAdmissionLine(assessment),
      updatedText: _patientSortTimestampText(assessment),
      badges: badges,
      treatmentOutcomeLine: treatmentOutcome.isEmpty
          ? null
          : 'Kết quả điều trị: $treatmentOutcome',
      treatmentOutcomeStatus: _treatmentOutcomeStatus(treatmentOutcome),
      actionMenu: _patientActionMenu(assessment),
      onTap: () => _openSaved(saved),
    );
  }

  Widget _scoreBadge(ScoreDisplay display) {
    final value = display.scoreText == '-' ? '' : ' ${display.scoreText}';
    return clinical_ui.StatusBadge(
      status: display.status,
      label: '${display.title}:$value ${display.statusLabel}',
      dense: true,
    );
  }

  Widget _patientActionMenu(ClinicalAssessment assessment) {
    return ExportActionMenu(
      enabled: !_exporting,
      onSelected: (action) => _handleExportAction(assessment, action),
    );
  }

  ClinicalStatus _treatmentOutcomeStatus(String value) {
    final normalized = value.toLowerCase();
    if (normalized.contains('tử vong') ||
        normalized.contains('tu vong') ||
        normalized.contains('nặng') ||
        normalized.contains('nang')) {
      return ClinicalStatus.danger;
    }
    if (normalized.contains('chuyển') || normalized.contains('chuyen')) {
      return ClinicalStatus.watch;
    }
    return ClinicalStatus.normal;
  }

  String _patientAdmissionLine(ClinicalAssessment assessment) {
    final date = _compactDateText(assessment.admissionDate.trim());
    final time = assessment.admissionTime.trim();
    if (date.isEmpty && time.isEmpty) {
      return 'Chưa nhập thời gian nhập viện';
    }
    if (date.isEmpty) {
      return 'Nhập viện: $time';
    }
    if (time.isEmpty) {
      return 'Nhập viện: $date';
    }
    return 'Nhập viện: $time · $date';
  }

  String _patientIdentityLine(ClinicalAssessment assessment) {
    final patientId = assessment.patientId.trim();
    final age = assessment.age.trim();
    if (patientId.isEmpty && age.isEmpty) {
      return '';
    }
    if (age.isEmpty) {
      return 'Mã BN: $patientId';
    }
    if (patientId.isEmpty) {
      return 'Tuổi: $age';
    }
    return 'Mã BN: $patientId · Tuổi: $age';
  }

  String _patientSortTimestampText(ClinicalAssessment assessment) {
    final millis = _listController.sortMode == PatientSortMode.createdAt
        ? assessment.createdAtMillis
        : assessment.modifiedAtMillis;
    return _formatRelativeTime(millis);
  }

  String _formatRelativeTime(int millis) {
    if (millis <= 0) {
      return 'Chưa cập nhật';
    }
    final value = DateTime.fromMillisecondsSinceEpoch(millis);
    final diff = DateTime.now().difference(value);
    if (diff.isNegative || diff.inSeconds < 60) {
      return 'Vừa cập nhật';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    }
    if (diff.inDays < 30) {
      return '${diff.inDays} ngày trước';
    }
    return '${_two(value.day)}/${_two(value.month)}/${value.year}';
  }

  String _compactDateText(String value) {
    if (value.isEmpty) {
      return '';
    }
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match != null) {
      final year = match.group(1);
      final month = match.group(2);
      final day = match.group(3);
      if (year != null && month != null && day != null) {
        return '$day/$month/$year';
      }
    }
    return value;
  }

  int _patientGridColumns(double width) {
    if (width >= 1100) {
      return 3;
    }
    if (width >= 680) {
      return 2;
    }
    return 1;
  }

  bool _handlePatientScroll(
    ScrollNotification notification,
    List<SavedAssessment> patients,
  ) {
    if (notification.metrics.axis != Axis.vertical) {
      return false;
    }
    if (notification.metrics.extentAfter < 720) {
      unawaited(_listController.loadMore());
    }
    final label = _patientScrollLabel(notification.metrics, patients);
    final fraction = _patientScrollFraction(notification.metrics);
    _patientScrollBubbleTimer?.cancel();
    _patientScrollBubble.value = _PatientScrollBubbleState(
      visible: label.isNotEmpty,
      label: label,
      fraction: fraction,
    );
    _patientScrollBubbleTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) {
        return;
      }
      _patientScrollBubble.value = const _PatientScrollBubbleState.hidden();
    });
    return false;
  }

  double _patientScrollFraction(ScrollMetrics metrics) {
    final maxScrollExtent = metrics.maxScrollExtent;
    if (maxScrollExtent <= 0) {
      return 0;
    }
    final fraction =
        (metrics.pixels / maxScrollExtent).clamp(0.0, 1.0).toDouble();
    return (fraction * 100).round() / 100;
  }

  String _patientScrollLabel(
    ScrollMetrics metrics,
    List<SavedAssessment> patients,
  ) {
    if (patients.isEmpty) {
      return '';
    }
    final maxScrollExtent = metrics.maxScrollExtent;
    final fraction = maxScrollExtent <= 0
        ? 0.0
        : (metrics.pixels / maxScrollExtent).clamp(0.0, 1.0);
    final index = (fraction * (patients.length - 1))
        .round()
        .clamp(0, patients.length - 1);
    final assessment = patients[index].assessment;
    if (_listController.sortMode == PatientSortMode.name) {
      return _patientNameIndex(assessment);
    }
    final millis = _listController.sortMode == PatientSortMode.createdAt
        ? assessment.createdAtMillis
        : assessment.modifiedAtMillis;
    return _formatPatientDate(millis);
  }

  double _patientScrollBubbleTop(
    BoxConstraints constraints,
    double scrollFraction,
  ) {
    final maxTop = constraints.maxHeight - 56;
    final availableTop = (maxTop - 12).clamp(0.0, double.infinity).toDouble();
    final fraction = scrollFraction.clamp(0.0, 1.0).toDouble();
    return 12 + (availableTop * fraction);
  }

  Widget _patientScrollBubbleWidget(String label) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.primaryContainer,
      elevation: 1,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  String _patientNameIndex(ClinicalAssessment assessment) {
    final source = assessment.fullName.trim().isNotEmpty
        ? assessment.fullName.trim()
        : assessment.patientId.trim();
    if (source.isEmpty) {
      return '#';
    }
    final first = source.characters.first.toUpperCase();
    return RegExp(r'[A-ZÀ-Ỹ]').hasMatch(first) ? first : '#';
  }

  String _formatPatientDate(int millis) {
    if (millis <= 0) {
      return '--/--';
    }
    final value = DateTime.fromMillisecondsSinceEpoch(millis);
    return '${_two(value.day)}/${_two(value.month)}';
  }

}
