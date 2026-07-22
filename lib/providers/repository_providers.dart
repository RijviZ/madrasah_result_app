// Stage 4 — Aggregated Repository Providers
// Exports all three repositories and derived computed providers.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/mark_repository.dart';
import '../repositories/student_repository.dart';
import '../repositories/subject_repository.dart';

export '../repositories/student_repository.dart';
export '../repositories/subject_repository.dart';
export '../repositories/mark_repository.dart';

// ---------------------------------------------------------------------------
// Sync Status Provider
// ---------------------------------------------------------------------------

/// Enum representing the overall sync state of the app.
enum SyncStatus {
  /// All data has been pushed to the remote — nothing pending.
  synced,

  /// At least one record is awaiting sync.
  pending,
}

/// Derived provider: aggregates pending counts across all repositories.
/// Returns [SyncStatus.pending] if ANY model has `isSynced == false`.
final syncStatusProvider = Provider<SyncStatus>((ref) {
  final students = ref.watch(studentRepositoryProvider);
  final subjects = ref.watch(subjectRepositoryProvider);
  final marks = ref.watch(markRepositoryProvider);

  final hasPending =
      students.any((s) => !s.isSynced) ||
      subjects.any((s) => !s.isSynced) ||
      marks.any((m) => !m.isSynced);

  return hasPending ? SyncStatus.pending : SyncStatus.synced;
});

// ---------------------------------------------------------------------------
// Derived stat providers used by the Dashboard
// ---------------------------------------------------------------------------

/// Total number of enrolled students.
final totalStudentsProvider = Provider<int>((ref) {
  return ref.watch(studentRepositoryProvider).length;
});

/// Total number of configured subjects.
final totalSubjectsProvider = Provider<int>((ref) {
  return ref.watch(subjectRepositoryProvider).length;
});

/// Recent activity log entries (max 20, newest first).
///
/// Generates a synthetic activity string from the latest mark updates.
/// Format: "Marks saved — `studentId` / `subjectId`"
final recentActivityProvider = Provider<List<RecentActivity>>((ref) {
  final marks = ref.watch(markRepositoryProvider);
  if (marks.isEmpty) return [];

  // Group by (subjectId, examType) to produce per-subject messages
  final grouped = <String, DateTime>{};
  for (final m in marks) {
    final key = '${m.subjectId}_${m.examType}';
    final existing = grouped[key];
    if (existing == null || m.updatedAt.isAfter(existing)) {
      grouped[key] = m.updatedAt;
    }
  }

  final entries = grouped.entries.map((e) {
    final parts = e.key.split('_');
    return RecentActivity(
      subjectId: parts.first,
      examType: parts.length > 1 ? parts.last : '',
      timestamp: e.value,
    );
  }).toList()
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

  return entries.take(20).toList();
});

/// Lightweight value object for an activity log entry.
class RecentActivity {
  final String subjectId;
  final String examType;
  final DateTime timestamp;

  const RecentActivity({
    required this.subjectId,
    required this.examType,
    required this.timestamp,
  });
}
