// Stage 4 — Student Repository
// Provides full CRUD for [StudentModel] backed by Hive, exposed via Riverpod.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student_model.dart';

// ---------------------------------------------------------------------------
// State class
// ---------------------------------------------------------------------------

class StudentRepository extends StateNotifier<List<StudentModel>> {
  final Box<StudentModel> _box;

  StudentRepository(this._box) : super(_box.values.toList());

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _refreshState() {
    state = _box.values.toList();
  }

  // ── Create ─────────────────────────────────────────────────────────────────

  Future<void> addStudent(StudentModel student) async {
    final toSave = student.copyWith(
      isSynced: false,
      updatedAt: DateTime.now(),
    );
    await _box.put(toSave.id, toSave);
    _refreshState();

    try {
      final client = Supabase.instance.client;
      await client.from('students').upsert(toSave.toJson());
      await markAsSynced(toSave.id);
    } catch (_) {}
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Returns all students for the given [className].
  List<StudentModel> getStudentsByClass(String className) {
    return _box.values
        .where((s) => s.className.trim().toLowerCase() == className.trim().toLowerCase())
        .toList()
      ..sort((a, b) => a.roll.compareTo(b.roll));
  }

  /// Returns students filtered by [className] AND [section].
  List<StudentModel> getStudentsByClassAndSection(String className, String section) {
    return _box.values
        .where((s) =>
            s.className.trim().toLowerCase() == className.trim().toLowerCase() &&
            s.section.trim().toLowerCase() == section.trim().toLowerCase())
        .toList()
      ..sort((a, b) => a.roll.compareTo(b.roll));
  }

  /// Full-text search across [StudentModel.name] and [StudentModel.roll].
  /// Optionally narrow by [className] and/or [section].
  List<StudentModel> searchStudents(
    String query, {
    String? className,
    String? section,
  }) {
    final q = query.trim().toLowerCase();
    return _box.values.where((s) {
      final nameMatch = s.name.toLowerCase().contains(q);
      final rollMatch = s.roll.toString().contains(q);
      final classMatch = className == null ||
          s.className.trim().toLowerCase() == className.trim().toLowerCase();
      final sectionMatch = section == null ||
          s.section.trim().toLowerCase() == section.trim().toLowerCase();
      return (nameMatch || rollMatch) && classMatch && sectionMatch;
    }).toList()
      ..sort((a, b) => a.roll.compareTo(b.roll));
  }

  // ── Update ─────────────────────────────────────────────────────────────────

  Future<void> updateStudent(StudentModel updated) async {
    final toSave = updated.copyWith(
      isSynced: false,
      updatedAt: DateTime.now(),
    );
    await _box.put(toSave.id, toSave);
    _refreshState();

    try {
      final client = Supabase.instance.client;
      await client.from('students').upsert(toSave.toJson());
      await markAsSynced(toSave.id);
    } catch (_) {}
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  Future<void> deleteStudent(String id) async {
    await _box.delete(id);
    _refreshState();

    try {
      final client = Supabase.instance.client;
      await client.from('students').delete().eq('id', id);
    } catch (_) {}
  }

  // ── Sync helpers ───────────────────────────────────────────────────────────

  /// Returns all students that are pending sync.
  List<StudentModel> get pendingSync =>
      _box.values.where((s) => !s.isSynced).toList();

  /// Mark a student as synced after a successful remote push.
  Future<void> markAsSynced(String id) async {
    final student = _box.get(id);
    if (student == null) return;
    await _box.put(id, student.copyWith(isSynced: true));
    _refreshState();
  }

  /// Replaces local box content with [list] from backup restore.
  Future<void> restoreAll(List<StudentModel> list) async {
    await _box.clear();
    for (final s in list) {
      await _box.put(s.id, s);
    }
    _refreshState();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final studentRepositoryProvider =
    StateNotifierProvider<StudentRepository, List<StudentModel>>((ref) {
  final box = Hive.box<StudentModel>('students');
  return StudentRepository(box);
});
