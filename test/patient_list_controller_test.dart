import 'package:flutter_test/flutter_test.dart';
import 'package:news2_l/src/data/assessment_repository.dart';
import 'package:news2_l/src/domain/clinical_assessment.dart';
import 'package:news2_l/src/ui/patient_list_controller.dart';

class _FakeRepository extends AssessmentRepository {
  _FakeRepository(this.items);

  final List<SavedAssessment> items;
  String lastQuery = '';
  PatientSortMode lastSort = PatientSortMode.updatedAt;

  @override
  Future<List<SavedAssessment>> loadAssessmentHistory({
    String query = '',
    PatientSortMode sortMode = PatientSortMode.updatedAt,
    int? limit,
    int offset = 0,
  }) async {
    lastQuery = query;
    lastSort = sortMode;
    var rows = items;
    final normalized = query.trim().toLowerCase();
    if (normalized.isNotEmpty) {
      rows = rows
          .where((saved) =>
              saved.assessment.patientId.toLowerCase().contains(normalized) ||
              saved.assessment.fullName.toLowerCase().contains(normalized))
          .toList();
    }
    final start = offset.clamp(0, rows.length);
    final end =
        limit == null ? rows.length : (start + limit).clamp(0, rows.length);
    return rows.sublist(start, end);
  }
}

List<SavedAssessment> _patients(int count) {
  return List.generate(
    count,
    (i) => SavedAssessment(
      id: i + 1,
      assessment: ClinicalAssessment(patientId: 'P$i', fullName: 'Name $i'),
    ),
  );
}

void main() {
  test('refresh loads history, derives caches and notifies', () async {
    final controller = PatientListController(
      repository: _FakeRepository(_patients(3)),
    );
    var notified = 0;
    controller.addListener(() => notified++);

    await controller.refresh();

    expect(controller.history.length, 3);
    expect(controller.filteredHistory.length, 3);
    expect(controller.summary.total, 3);
    expect(controller.loadedAll, isTrue);
    expect(controller.loading, isFalse);
    expect(notified, greaterThan(0));
    controller.dispose();
  });

  test('setSearchQuery forwards the query to the repository', () async {
    final repository = _FakeRepository(_patients(5));
    final controller = PatientListController(repository: repository);

    await controller.setSearchQuery('Name 2');

    expect(repository.lastQuery, 'Name 2');
    expect(controller.history.length, 1);
    expect(controller.history.first.assessment.fullName, 'Name 2');
    controller.dispose();
  });

  test('setSortMode forwards the sort mode and reloads', () async {
    final repository = _FakeRepository(_patients(2));
    final controller = PatientListController(repository: repository);

    await controller.setSortMode(PatientSortMode.name);

    expect(repository.lastSort, PatientSortMode.name);
    expect(controller.sortMode, PatientSortMode.name);
    controller.dispose();
  });

  test('refresh auto-paginates the remaining pages', () async {
    final controller = PatientListController(
      repository: _FakeRepository(_patients(5)),
      initialPageSize: 2,
      pageSize: 2,
    );

    await controller.refresh();
    expect(controller.history.length, 2);
    expect(controller.loadedAll, isFalse);

    // Let the background loadRemaining loop drain the rest.
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(controller.history.length, 5);
    expect(controller.loadedAll, isTrue);
    controller.dispose();
  });

  test('setFilter(all) keeps the full list', () async {
    final controller = PatientListController(
      repository: _FakeRepository(_patients(4)),
    );
    await controller.refresh();

    controller.setFilter(PatientListFilter.all);

    expect(controller.filter, PatientListFilter.all);
    expect(controller.filteredHistory.length, controller.history.length);
    controller.dispose();
  });
}
