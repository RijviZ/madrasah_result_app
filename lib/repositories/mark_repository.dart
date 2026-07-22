// Stage 4 — Mark Repository
// Provides bulk-upsert and query operations for [MarkModel] backed by Hive.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/mark_model.dart';

class MarkRepository extends StateNotifier<List<MarkModel>> {
  final Box<MarkModel> _box;

  MarkRepository(this._box) : super(_box.values.toList());

  void _refreshState() {
    state = _box.values.toList();
  }

  // ── Bulk upsert ────────────────────────────────────────────────────────────

  /// Upserts [marks] for a specific [className] / [subjectId] combination.
  ///
  /// Strategy:
  /// 1. For each incoming mark, look up an existing mark matching
  ///    (studentId, subjectId, examType).
  /// 2. If found → update it (keep same id, reset isSynced + updatedAt).
  /// 3. If not found → insert as new.
  Future<void> bulkUpsertMarks({
    required List<MarkModel> marks,
    required String className,
    required String subjectId,
  }) async {
    // Build a lookup map: key = "studentId_subjectId_examType"
    final existingMap = <String, MarkModel>{};
    for (final m in _box.values) {
      final key = '${m.studentId}_${m.subjectId}_${m.examType}';
      existingMap[key] = m;
    }

    for (final incoming in marks) {
      final key = '${incoming.studentId}_${incoming.subjectId}_${incoming.examType}';
      final existing = existingMap[key];

      final MarkModel toSave;
      if (existing != null) {
        toSave = existing.copyWith(
          obtainedMarks: incoming.obtainedMarks,
          isSynced: false,
          updatedAt: DateTime.now(),
        );
      } else {
        toSave = incoming.copyWith(
          isSynced: false,
          updatedAt: DateTime.now(),
        );
      }
      await _box.put(toSave.id, toSave);
    }
    _refreshState();
  }

  /// Immediately saves/updates a single [MarkModel] in Hive offline storage.
  Future<void> upsertSingleMark(MarkModel incoming) async {
    MarkModel? existing;
    try {
      existing = _box.values.firstWhere(
        (m) => m.studentId == incoming.studentId && m.subjectId == incoming.subjectId && m.examType == incoming.examType,
      );
    } catch (_) {
      existing = null;
    }

    final MarkModel toSave = existing != null
        ? existing.copyWith(
            obtainedMarks: incoming.obtainedMarks,
            writtenMarks: incoming.writtenMarks,
            mcqMarks: incoming.mcqMarks,
            isSynced: false,
            updatedAt: DateTime.now(),
          )
        : incoming.copyWith(
            isSynced: false,
            updatedAt: DateTime.now(),
          );

    await _box.put(toSave.id, toSave);
    _refreshState();
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Returns all marks for a specific [studentId].
  List<MarkModel> getMarksForStudent(String studentId) {
    return _box.values.where((m) => m.studentId == studentId).toList();
  }

  /// Returns all marks for a specific [studentId] and [examType].
  List<MarkModel> getMarksForStudentByExam(String studentId, String examType) {
    return _box.values
        .where((m) => m.studentId == studentId && m.examType == examType)
        .toList();
  }

  /// Returns all marks for a [subjectId] within an [examType].
  List<MarkModel> getMarksForClassSubject({
    required String subjectId,
    required String examType,
  }) {
    return _box.values
        .where((m) => m.subjectId == subjectId && m.examType == examType)
        .toList();
  }

  /// Returns a single mark by composite key, or null.
  MarkModel? getMark({
    required String studentId,
    required String subjectId,
    required String examType,
  }) {
    try {
      return _box.values.firstWhere(
        (m) => m.studentId == studentId && m.subjectId == subjectId && m.examType == examType,
      );
    } catch (_) {
      return null;
    }
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  Future<void> deleteMark(String id) async {
    await _box.delete(id);
    _refreshState();
  }

  /// Deletes ALL marks for a given [studentId].
  Future<void> deleteMarksForStudent(String studentId) async {
    final toDelete = _box.values
        .where((m) => m.studentId == studentId)
        .map((m) => m.id)
        .toList();
    for (final id in toDelete) {
      await _box.delete(id);
    }
    _refreshState();
  }

  // ── Sync helpers ───────────────────────────────────────────────────────────

  List<MarkModel> get pendingSync =>
      _box.values.where((m) => !m.isSynced).toList();

  Future<void> markAsSynced(String id) async {
    final mark = _box.get(id);
    if (mark == null) return;
    await _box.put(id, mark.copyWith(isSynced: true));
    _refreshState();
  }

  /// Replaces local box content with [list] from backup restore.
  Future<void> restoreAll(List<MarkModel> list) async {
    await _box.clear();
    for (final mark in list) {
      await _box.put(mark.id, mark);
    }
    _refreshState();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final markRepositoryProvider =
    StateNotifierProvider<MarkRepository, List<MarkModel>>((ref) {
  final box = Hive.box<MarkModel>('marks');
  return MarkRepository(box);
});
