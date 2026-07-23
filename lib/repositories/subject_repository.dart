// Stage 4 — Subject Repository
// Provides CRUD for [SubjectModel] backed by Hive, exposed via Riverpod.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subject_model.dart';

class SubjectRepository extends StateNotifier<List<SubjectModel>> {
  final Box<SubjectModel> _box;

  SubjectRepository(this._box) : super(_box.values.toList());

  void _refreshState() {
    state = _box.values.toList();
  }

  // ── Create ─────────────────────────────────────────────────────────────────

  Future<void> addSubject(SubjectModel subject) async {
    final toSave = subject.copyWith(isSynced: false);
    await _box.put(toSave.id, toSave);
    _refreshState();

    try {
      final client = Supabase.instance.client;
      await client.from('subjects').upsert(toSave.toJson());
      await markAsSynced(toSave.id);
    } catch (_) {}
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Returns all subjects for the given [className], sorted by subjectCode.
  List<SubjectModel> getSubjectsByClass(String className) {
    return _box.values
        .where((s) => s.className.trim().toLowerCase() == className.trim().toLowerCase())
        .toList()
      ..sort((a, b) => a.subjectCode.compareTo(b.subjectCode));
  }

  /// Returns a single subject by [id], or null if not found.
  SubjectModel? getSubjectById(String id) => _box.get(id);

  // ── Update ─────────────────────────────────────────────────────────────────

  Future<void> updateSubject(SubjectModel updated) async {
    final toSave = updated.copyWith(isSynced: false);
    await _box.put(toSave.id, toSave);
    _refreshState();

    try {
      final client = Supabase.instance.client;
      await client.from('subjects').upsert(toSave.toJson());
      await markAsSynced(toSave.id);
    } catch (_) {}
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  Future<void> deleteSubject(String id) async {
    await _box.delete(id);
    _refreshState();

    try {
      final client = Supabase.instance.client;
      await client.from('subjects').delete().eq('id', id);
    } catch (_) {}
  }

  // ── Sync helpers ───────────────────────────────────────────────────────────

  List<SubjectModel> get pendingSync =>
      _box.values.where((s) => !s.isSynced).toList();

  Future<void> markAsSynced(String id) async {
    final subject = _box.get(id);
    if (subject == null) return;
    await _box.put(id, subject.copyWith(isSynced: true));
    _refreshState();
  }

  /// Replaces local box content with [list] from backup restore.
  Future<void> restoreAll(List<SubjectModel> list) async {
    await _box.clear();
    for (final sub in list) {
      await _box.put(sub.id, sub);
    }
    _refreshState();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final subjectRepositoryProvider =
    StateNotifierProvider<SubjectRepository, List<SubjectModel>>((ref) {
  final box = Hive.box<SubjectModel>('subjects');
  return SubjectRepository(box);
});
