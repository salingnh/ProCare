import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/assessment_repository.dart';
import '../domain/assessment_display.dart';

/// Risk/completeness filters applied to the saved-patient list.
enum PatientListFilter { all, incomplete, highRisk, septicShock }

/// Aggregate counts shown in the patient-list summary strip.
class PatientSummary {
  final int total;
  final int incomplete;
  final int highRisk;
  final int shock;

  const PatientSummary({
    required this.total,
    required this.incomplete,
    required this.highRisk,
    required this.shock,
  });

  const PatientSummary.empty()
      : total = 0,
        incomplete = 0,
        highRisk = 0,
        shock = 0;

  factory PatientSummary.from(List<SavedAssessment> patients) {
    var incomplete = 0;
    var highRisk = 0;
    var shock = 0;
    for (final saved in patients) {
      final assessment = saved.assessment;
      if (AssessmentDisplay.isIncompletePatient(assessment)) {
        incomplete++;
      }
      if (AssessmentDisplay.isHighRiskPatient(assessment)) {
        highRisk++;
      }
      if (AssessmentDisplay.isSepticShockPatient(assessment)) {
        shock++;
      }
    }
    return PatientSummary(
      total: patients.length,
      incomplete: incomplete,
      highRisk: highRisk,
      shock: shock,
    );
  }
}

/// Owns the saved-patient list: search, sort, in-memory filtering, paginated
/// loading and the derived summary. Pure `ChangeNotifier` (no `BuildContext`),
/// so it can be unit tested with a fake [AssessmentRepository].
class PatientListController extends ChangeNotifier {
  PatientListController({
    required AssessmentRepository repository,
    int initialPageSize = 50,
    int pageSize = 50,
  })  : _repository = repository,
        _initialPageSize = initialPageSize,
        _pageSize = pageSize;

  final AssessmentRepository _repository;
  final int _initialPageSize;
  final int _pageSize;

  List<SavedAssessment> _history = [];
  List<SavedAssessment> _filteredHistory = [];
  PatientSummary _summary = const PatientSummary.empty();
  PatientSortMode _sortMode = PatientSortMode.updatedAt;
  PatientListFilter _filter = PatientListFilter.all;
  String _searchQuery = '';
  bool _loading = false;
  bool _loadedAll = true;
  int _generation = 0;
  bool _disposed = false;

  List<SavedAssessment> get history => _history;
  List<SavedAssessment> get filteredHistory => _filteredHistory;
  PatientSummary get summary => _summary;
  PatientSortMode get sortMode => _sortMode;
  PatientListFilter get filter => _filter;
  String get searchQuery => _searchQuery;
  bool get loading => _loading;
  bool get loadedAll => _loadedAll;

  /// Marks the list as loading and clears any previous data, without fetching.
  /// Used before the deferred startup load kicks in.
  void beginInitialLoad() {
    _history = [];
    _filteredHistory = [];
    _summary = const PatientSummary.empty();
    _loading = true;
    _loadedAll = false;
    _notify();
  }

  /// Resets to an empty, idle list (e.g. the web in-memory startup path).
  void resetEmpty() {
    _history = [];
    _filteredHistory = [];
    _summary = const PatientSummary.empty();
    _loading = false;
    _loadedAll = true;
    _notify();
  }

  /// Updates the search query and reloads from the first page.
  Future<void> setSearchQuery(String query) {
    _searchQuery = query;
    return refresh();
  }

  /// Changes the sort order and reloads from the first page.
  Future<void> setSortMode(PatientSortMode mode) {
    if (mode == _sortMode) {
      return Future<void>.value();
    }
    _sortMode = mode;
    return refresh();
  }

  /// Applies a risk/completeness filter in-memory over the loaded history.
  void setFilter(PatientListFilter filter) {
    if (filter == _filter) {
      return;
    }
    _filter = filter;
    _rebuildCaches();
    _notify();
  }

  /// Reloads the first page for the current query/sort, then streams the
  /// remaining pages in the background.
  Future<void> refresh() async {
    final generation = ++_generation;
    _loading = true;
    _loadedAll = false;
    _notify();
    try {
      final history = await _repository.loadAssessmentHistory(
        query: _searchQuery,
        sortMode: _sortMode,
        limit: _initialPageSize,
      );
      if (_disposed || generation != _generation) {
        return;
      }
      final hasMore = history.length >= _initialPageSize;
      _history = history;
      _loadedAll = !hasMore;
      _loading = false;
      _rebuildCaches();
      _notify();
      if (hasMore) {
        unawaited(_loadRemaining(generation));
      }
    } catch (_) {
      if (!_disposed && generation == _generation) {
        _loading = false;
        _loadedAll = true;
        _notify();
      }
    }
  }

  /// Appends the next page of history if there is more to load.
  Future<void> loadMore({int? expectedGeneration}) async {
    if (_loading || _loadedAll) {
      return;
    }
    final generation = expectedGeneration ?? _generation;
    final offset = _history.length;
    _loading = true;
    _notify();
    try {
      final nextPage = await _repository.loadAssessmentHistory(
        query: _searchQuery,
        sortMode: _sortMode,
        limit: _pageSize,
        offset: offset,
      );
      if (_disposed || generation != _generation) {
        return;
      }
      final existingIds = _history.map((saved) => saved.id).toSet();
      _history = [
        ..._history,
        ...nextPage.where((saved) => existingIds.add(saved.id)),
      ];
      _loadedAll = nextPage.length < _pageSize;
      _loading = false;
      _rebuildCaches();
      _notify();
    } catch (_) {
      if (!_disposed && generation == _generation) {
        _loading = false;
        _loadedAll = true;
        _notify();
      }
    }
  }

  Future<void> _loadRemaining(int generation) async {
    while (!_disposed && generation == _generation && !_loadedAll) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
      if (_loading) {
        continue;
      }
      await loadMore(expectedGeneration: generation);
    }
  }

  void _rebuildCaches() {
    _filteredHistory = _filteredPatients(_history);
    _summary = PatientSummary.from(_history);
  }

  List<SavedAssessment> _filteredPatients(List<SavedAssessment> source) {
    return source.where((saved) {
      final assessment = saved.assessment;
      return switch (_filter) {
        PatientListFilter.all => true,
        PatientListFilter.incomplete =>
          AssessmentDisplay.isIncompletePatient(assessment),
        PatientListFilter.highRisk =>
          AssessmentDisplay.isHighRiskPatient(assessment),
        PatientListFilter.septicShock =>
          AssessmentDisplay.isSepticShockPatient(assessment),
      };
    }).toList();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
