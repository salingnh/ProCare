import 'dart:convert';

import 'package:flutter/foundation.dart';
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
  static const _assessmentModeKey = 'assessment_mode';
  static const _includePrereleaseUpdatesKey = 'include_prerelease_updates';
  static ClinicalAssessment? _webDraft;
  static String _webAssessmentMode = ClinicalAssessment.assessmentModeDetailed;
  static bool _webIncludePrereleaseUpdates = false;
  static final List<SavedAssessment> _webHistory = [];
  static int _webNextId = 1;

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
    if (kIsWeb) {
      return _webDraft?.clone() ?? ClinicalAssessment();
    }
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
    if (kIsWeb) {
      _webDraft = assessment.clone();
      return;
    }
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

  Future<String> loadAssessmentMode() async {
    if (kIsWeb) {
      return _webAssessmentMode;
    }
    final db = await _db;
    final rows = await db.query(
      'app_state',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [_assessmentModeKey],
      limit: 1,
    );
    if (rows.isEmpty) {
      return ClinicalAssessment.assessmentModeDetailed;
    }
    return ClinicalAssessment.normalizeAssessmentMode(
      rows.first['value'] as String,
    );
  }

  Future<void> saveAssessmentMode(String mode) async {
    final normalized = ClinicalAssessment.normalizeAssessmentMode(mode);
    if (kIsWeb) {
      _webAssessmentMode = normalized;
      return;
    }
    final db = await _db;
    await db.insert(
      'app_state',
      {
        'key': _assessmentModeKey,
        'value': normalized,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> loadIncludePrereleaseUpdates() async {
    if (kIsWeb) {
      return _webIncludePrereleaseUpdates;
    }
    final db = await _db;
    final rows = await db.query(
      'app_state',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [_includePrereleaseUpdatesKey],
      limit: 1,
    );
    if (rows.isEmpty) {
      return false;
    }
    return rows.first['value'] == 'true';
  }

  Future<void> saveIncludePrereleaseUpdates(bool enabled) async {
    if (kIsWeb) {
      _webIncludePrereleaseUpdates = enabled;
      return;
    }
    final db = await _db;
    await db.insert(
      'app_state',
      {
        'key': _includePrereleaseUpdatesKey,
        'value': enabled ? 'true' : 'false',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> appendAssessmentHistory(ClinicalAssessment assessment) async {
    if (kIsWeb) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final saved = assessment.clone();
      if (saved.createdAtMillis <= 0) {
        saved.createdAtMillis =
            saved.savedAtMillis > 0 ? saved.savedAtMillis : now;
      }
      saved.modifiedAtMillis = now;
      saved.savedAtMillis = now;
      _copyTimestamps(saved, assessment);
      final id = _webNextId++;
      _webHistory.insert(0, SavedAssessment(id: id, assessment: saved));
      return id;
    }
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

  Future<int> saveAssessmentHistory(
    ClinicalAssessment assessment, {
    int? id,
  }) async {
    if (id == null) {
      return appendAssessmentHistory(assessment);
    }
    if (kIsWeb) {
      final index = _webHistory.indexWhere((saved) => saved.id == id);
      if (index < 0) {
        return appendAssessmentHistory(assessment);
      }
      final now = DateTime.now().millisecondsSinceEpoch;
      final saved = assessment.clone();
      if (saved.createdAtMillis <= 0) {
        saved.createdAtMillis =
            _webHistory[index].assessment.createdAtMillis > 0
                ? _webHistory[index].assessment.createdAtMillis
                : now;
      }
      saved.modifiedAtMillis = now;
      saved.savedAtMillis = now;
      _copyTimestamps(saved, assessment);
      _webHistory[index] = SavedAssessment(id: id, assessment: saved);
      return id;
    }
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (assessment.createdAtMillis <= 0) {
      final rows = await db.query(
        'clinical_assessments',
        columns: ['created_at_millis'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      assessment.createdAtMillis =
          rows.isNotEmpty ? rows.first['created_at_millis'] as int : now;
    }
    assessment.modifiedAtMillis = now;
    assessment.savedAtMillis = now;
    final updated = await db.update(
      'clinical_assessments',
      {
        'patient_id': assessment.patientId.trim(),
        'full_name': assessment.fullName.trim(),
        'saved_at_millis': assessment.savedAtMillis,
        'modified_at_millis': assessment.modifiedAtMillis,
        'created_at_millis': assessment.createdAtMillis,
        'payload': jsonEncode(assessment.toJson()),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    if (updated == 0) {
      return appendAssessmentHistory(assessment);
    }
    return id;
  }

  Future<List<SavedAssessment>> loadAssessmentHistory({
    String query = '',
    PatientSortMode sortMode = PatientSortMode.updatedAt,
    int? limit,
    int offset = 0,
  }) async {
    if (kIsWeb) {
      final normalizedQuery = query.trim().toLowerCase();
      final rows = _webHistory.where((saved) {
        if (normalizedQuery.isEmpty) {
          return true;
        }
        final assessment = saved.assessment;
        return assessment.patientId.toLowerCase().contains(normalizedQuery) ||
            assessment.fullName.toLowerCase().contains(normalizedQuery);
      }).toList();
      rows.sort((a, b) {
        final left = a.assessment;
        final right = b.assessment;
        return switch (sortMode) {
          PatientSortMode.name => _compareTextThenNewest(
              left.fullName,
              right.fullName,
              left.modifiedAtMillis,
              right.modifiedAtMillis,
            ),
          PatientSortMode.createdAt =>
            right.createdAtMillis.compareTo(left.createdAtMillis),
          PatientSortMode.updatedAt =>
            right.modifiedAtMillis.compareTo(left.modifiedAtMillis),
        };
      });
      final start = offset.clamp(0, rows.length);
      final end =
          limit == null ? rows.length : (start + limit).clamp(0, rows.length);
      return rows.sublist(start, end).map((saved) {
        return SavedAssessment(
          id: saved.id,
          assessment: saved.assessment.clone(),
        );
      }).toList();
    }
    final db = await _db;
    final trimmedQuery = query.trim();
    final where =
        trimmedQuery.isEmpty ? null : '(patient_id LIKE ? OR full_name LIKE ?)';
    final whereArgs =
        trimmedQuery.isEmpty ? null : ['%$trimmedQuery%', '%$trimmedQuery%'];
    final orderBy = switch (sortMode) {
      PatientSortMode.name =>
        'full_name COLLATE NOCASE ASC, modified_at_millis DESC',
      PatientSortMode.createdAt => 'created_at_millis DESC',
      PatientSortMode.updatedAt => 'modified_at_millis DESC',
    };
    final rows = await db.query(
      'clinical_assessments',
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset <= 0 ? null : offset,
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
    if (kIsWeb) {
      _webHistory.removeWhere((saved) => saved.id == id);
      return;
    }
    final db = await _db;
    await db.delete(
      'clinical_assessments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static int _compareTextThenNewest(
    String leftText,
    String rightText,
    int leftSavedAt,
    int rightSavedAt,
  ) {
    final textResult =
        leftText.toLowerCase().compareTo(rightText.toLowerCase());
    if (textResult != 0) {
      return textResult;
    }
    return rightSavedAt.compareTo(leftSavedAt);
  }

  static void _copyTimestamps(
    ClinicalAssessment source,
    ClinicalAssessment target,
  ) {
    target.createdAtMillis = source.createdAtMillis;
    target.modifiedAtMillis = source.modifiedAtMillis;
    target.savedAtMillis = source.savedAtMillis;
  }
}

enum PatientSortMode {
  name,
  createdAt,
  updatedAt,
}
