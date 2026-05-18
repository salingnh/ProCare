import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../domain/clinical_assessment.dart';

class SavedAssessment {
  final int id;
  final ClinicalAssessment assessment;

  const SavedAssessment({
    required this.id,
    required this.assessment,
  });
}

class AssessmentRepository {
  static const _databaseName = 'news2_l.db';
  static const _databaseVersion = 1;
  static const _draftKey = 'current_assessment';

  Database? _database;

  Future<Database> get _db async {
    final existing = _database;
    if (existing != null) {
      return existing;
    }
    final databasePath = await getDatabasesPath();
    final database = await openDatabase(
      p.join(databasePath, _databaseName),
      version: _databaseVersion,
      onCreate: (db, version) async {
        await db.execute('''
CREATE TABLE app_state (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
)
''');
        await db.execute('''
CREATE TABLE clinical_assessments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  patient_id TEXT NOT NULL,
  full_name TEXT NOT NULL,
  saved_at_millis INTEGER NOT NULL,
  modified_at_millis INTEGER NOT NULL,
  created_at_millis INTEGER NOT NULL,
  payload TEXT NOT NULL
)
''');
        await db.execute(
          'CREATE INDEX idx_clinical_assessments_saved_at ON clinical_assessments(saved_at_millis DESC)',
        );
        await db.execute(
          'CREATE INDEX idx_clinical_assessments_patient ON clinical_assessments(patient_id, full_name)',
        );
      },
    );
    _database = database;
    return database;
  }

  Future<ClinicalAssessment> loadCurrentAssessment() async {
    final db = await _db;
    final rows = await db.query(
      'app_state',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [_draftKey],
      limit: 1,
    );
    if (rows.isEmpty) {
      return ClinicalAssessment();
    }
    try {
      return ClinicalAssessment.fromJson(
        jsonDecode(rows.first['value'] as String) as Map<String, dynamic>,
      );
    } catch (_) {
      return ClinicalAssessment();
    }
  }

  Future<void> saveCurrentAssessment(ClinicalAssessment assessment) async {
    final db = await _db;
    await db.insert(
      'app_state',
      {
        'key': _draftKey,
        'value': jsonEncode(assessment.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> appendAssessmentHistory(ClinicalAssessment assessment) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (assessment.createdAtMillis <= 0) {
      assessment.createdAtMillis =
          assessment.savedAtMillis > 0 ? assessment.savedAtMillis : now;
    }
    assessment.modifiedAtMillis = now;
    assessment.savedAtMillis = now;
    final payload = jsonEncode(assessment.toJson());
    return db.insert('clinical_assessments', {
      'patient_id': assessment.patientId.trim(),
      'full_name': assessment.fullName.trim(),
      'saved_at_millis': assessment.savedAtMillis,
      'modified_at_millis': assessment.modifiedAtMillis,
      'created_at_millis': assessment.createdAtMillis,
      'payload': payload,
    });
  }

  Future<List<SavedAssessment>> loadAssessmentHistory({
    String query = '',
    PatientSortMode sortMode = PatientSortMode.newest,
  }) async {
    final db = await _db;
    final trimmedQuery = query.trim();
    final where = trimmedQuery.isEmpty
        ? null
        : '(patient_id LIKE ? OR full_name LIKE ?)';
    final whereArgs = trimmedQuery.isEmpty
        ? null
        : ['%$trimmedQuery%', '%$trimmedQuery%'];
    final orderBy = switch (sortMode) {
      PatientSortMode.name => 'full_name COLLATE NOCASE ASC, saved_at_millis DESC',
      PatientSortMode.patientId =>
        'patient_id COLLATE NOCASE ASC, saved_at_millis DESC',
      PatientSortMode.newest => 'saved_at_millis DESC',
    };
    final rows = await db.query(
      'clinical_assessments',
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
    );
    return rows.map((row) {
      return SavedAssessment(
        id: row['id'] as int,
        assessment: ClinicalAssessment.fromJson(
          jsonDecode(row['payload'] as String) as Map<String, dynamic>,
        ),
      );
    }).toList();
  }

  Future<void> deleteAssessment(int id) async {
    final db = await _db;
    await db.delete(
      'clinical_assessments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

enum PatientSortMode {
  newest,
  name,
  patientId,
}
