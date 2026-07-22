import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/mark_model.dart';
import '../models/student_model.dart';
import '../models/subject_model.dart';
import '../providers/locale_provider.dart';
import '../providers/repository_providers.dart';

class SyncResult {
  final bool success;
  final int syncedStudentsCount;
  final int syncedSubjectsCount;
  final int syncedMarksCount;
  final String message;
  final DateTime timestamp;

  const SyncResult({
    required this.success,
    required this.syncedStudentsCount,
    required this.syncedSubjectsCount,
    required this.syncedMarksCount,
    required this.message,
    required this.timestamp,
  });
}

class SyncState {
  final bool isLoading;
  final SyncResult? result;

  const SyncState({
    this.isLoading = false,
    this.result,
  });

  SyncState copyWith({
    bool? isLoading,
    SyncResult? result,
  }) {
    return SyncState(
      isLoading: isLoading ?? this.isLoading,
      result: result ?? this.result,
    );
  }
}

class SyncServiceNotifier extends StateNotifier<SyncState> {
  SyncServiceNotifier() : super(const SyncState());

  /// Helper to batch upsert list of maps in chunks to avoid single request payload limit issues
  Future<void> _upsertInChunks(SupabaseClient client, String tableName, List<Map<String, dynamic>> records, {int chunkSize = 250}) async {
    for (var i = 0; i < records.length; i += chunkSize) {
      final end = (i + chunkSize < records.length) ? i + chunkSize : records.length;
      final chunk = records.sublist(i, end);
      await client.from(tableName).upsert(chunk);
    }
  }

  /// Backs up all local Hive data (students, subjects, marks) to Supabase Cloud using normalized relational tables.
  Future<SyncResult> backupToSupabase(WidgetRef ref, BuildContext context) async {
    state = state.copyWith(isLoading: true);
    final lang = ref.read(localeProvider).languageCode;

    final allStudents = Hive.box<StudentModel>('students').values.toList();
    final allSubjects = Hive.box<SubjectModel>('subjects').values.toList();
    final allMarks = Hive.box<MarkModel>('marks').values.toList();

    try {
      final client = Supabase.instance.client;

      // 1. Chunked upserts into individual entity tables to avoid single-cell DB lockup
      if (allStudents.isNotEmpty) {
        final studentJsonList = allStudents.map((s) => s.toJson()).toList();
        await _upsertInChunks(client, 'students', studentJsonList);
      }

      if (allSubjects.isNotEmpty) {
        final subjectJsonList = allSubjects.map((sub) => sub.toJson()).toList();
        await _upsertInChunks(client, 'subjects', subjectJsonList);
      }

      if (allMarks.isNotEmpty) {
        final markJsonList = allMarks.map((m) => m.toJson()).toList();
        await _upsertInChunks(client, 'marks', markJsonList);
      }

      // 2. Write lightweight summary metadata to app_backups table without storing giant json blob
      final metadataPayload = {
        'id': 'madrasah_full_backup',
        'app_name': 'Madrasah Result App',
        'student_count': allStudents.length,
        'subject_count': allSubjects.length,
        'mark_count': allMarks.length,
        'updated_at': DateTime.now().toIso8601String(),
      };
      await client.from('app_backups').upsert(metadataPayload);

      // 3. Mark items as synced locally
      for (final s in allStudents) {
        await ref.read(studentRepositoryProvider.notifier).markAsSynced(s.id);
      }
      for (final sub in allSubjects) {
        await ref.read(subjectRepositoryProvider.notifier).markAsSynced(sub.id);
      }
      for (final m in allMarks) {
        await ref.read(markRepositoryProvider.notifier).markAsSynced(m.id);
      }

      final result = SyncResult(
        success: true,
        syncedStudentsCount: allStudents.length,
        syncedSubjectsCount: allSubjects.length,
        syncedMarksCount: allMarks.length,
        message: lang == 'bn'
            ? 'ক্লাউড ব্যাকআপ সফল হয়েছে! (স্টুডেন্ট: ${allStudents.length}, বিষয়: ${allSubjects.length}, মার্কস: ${allMarks.length})'
            : 'Cloud backup successful! (${allStudents.length} Students, ${allSubjects.length} Subjects, ${allMarks.length} Marks)',
        timestamp: DateTime.now(),
      );

      state = SyncState(isLoading: false, result: result);
      if (context.mounted) {
        _showSnackBar(context, result.message, isSuccess: true);
      }
      return result;
    } catch (e) {
      final String rawError = e.toString();
      final bool isTableMissing = rawError.contains('public.students') ||
          rawError.contains('public.subjects') ||
          rawError.contains('public.marks') ||
          rawError.contains('42P01');

      final errorMsg = isTableMissing
          ? (lang == 'bn'
              ? 'সুপাবেস ডাটাবেসে `students`, `subjects`, `marks` টেবিল তৈরি করা নেই। অনুগ্রহ করে Supabase SQL Editor এ টেবিলগুলো তৈরি করুন।'
              : 'Tables `students`, `subjects`, `marks` do not exist in Supabase database. Please create them in Supabase SQL Editor.')
          : (lang == 'bn'
              ? 'ক্লাউড ব্যাকআপ তৈরি করা যাচ্ছে না: $e'
              : 'Failed to create cloud backup: $e');

      final result = SyncResult(
        success: false,
        syncedStudentsCount: 0,
        syncedSubjectsCount: 0,
        syncedMarksCount: 0,
        message: errorMsg,
        timestamp: DateTime.now(),
      );
      state = SyncState(isLoading: false, result: result);
      if (context.mounted) {
        _showSnackBar(context, errorMsg, isSuccess: false);
      }
      return result;
    }
  }

  /// Restores all data from Supabase Cloud backup into local Hive boxes.
  /// Prefers normalized entity tables (`students`, `subjects`, `marks`) and falls back to legacy `app_backups` single-cell if needed.
  Future<SyncResult> restoreFromSupabase(WidgetRef ref, BuildContext context) async {
    state = state.copyWith(isLoading: true);
    final lang = ref.read(localeProvider).languageCode;

    try {
      final client = Supabase.instance.client;

      List<StudentModel> restoredStudents = [];
      List<SubjectModel> restoredSubjects = [];
      List<MarkModel> restoredMarks = [];

      bool loadedFromEntityTables = false;

      try {
        // Try fetching from individual relational entity tables first
        final List<dynamic> stData = await client.from('students').select();
        final List<dynamic> subData = await client.from('subjects').select();
        final List<dynamic> mData = await client.from('marks').select();

        if (stData.isNotEmpty || subData.isNotEmpty || mData.isNotEmpty) {
          restoredStudents = stData
              .map((e) => StudentModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
          restoredSubjects = subData
              .map((e) => SubjectModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
          restoredMarks = mData
              .map((e) => MarkModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();

          loadedFromEntityTables = true;
        }
      } catch (_) {
        // Table querying failed or fallback required
        loadedFromEntityTables = false;
      }

      // Legacy Fallback: Read single cell payload if normalized tables were empty or not present
      if (!loadedFromEntityTables) {
        final response = await client
            .from('app_backups')
            .select()
            .eq('id', 'madrasah_full_backup')
            .maybeSingle();

        if (response == null && restoredStudents.isEmpty && restoredSubjects.isEmpty && restoredMarks.isEmpty) {
          final msg = lang == 'bn'
              ? 'ক্লাউডে কোনো ব্যাকআপ পাওয়া যায়নি'
              : 'No cloud backup found on Supabase';
          final res = SyncResult(
            success: false,
            syncedStudentsCount: 0,
            syncedSubjectsCount: 0,
            syncedMarksCount: 0,
            message: msg,
            timestamp: DateTime.now(),
          );
          state = SyncState(isLoading: false, result: res);
          if (context.mounted) _showSnackBar(context, msg, isSuccess: false);
          return res;
        }

        if (response != null) {
          final Map<String, dynamic> data = Map<String, dynamic>.from(response);
          final List<dynamic> rawStudents = data['students'] as List<dynamic>? ?? [];
          final List<dynamic> rawSubjects = data['subjects'] as List<dynamic>? ?? [];
          final List<dynamic> rawMarks = data['marks'] as List<dynamic>? ?? [];

          restoredStudents = rawStudents
              .map((e) => StudentModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
          restoredSubjects = rawSubjects
              .map((e) => SubjectModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
          restoredMarks = rawMarks
              .map((e) => MarkModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
      }

      await ref.read(studentRepositoryProvider.notifier).restoreAll(restoredStudents);
      await ref.read(subjectRepositoryProvider.notifier).restoreAll(restoredSubjects);
      await ref.read(markRepositoryProvider.notifier).restoreAll(restoredMarks);

      final msg = lang == 'bn'
          ? 'ক্লাউড ব্যাকআপ পুনরুদ্ধার সফল হয়েছে! (স্টুডেন্ট: ${restoredStudents.length}, বিষয়: ${restoredSubjects.length}, মার্কস: ${restoredMarks.length})'
          : 'Data restored successfully from Cloud! (${restoredStudents.length} Students, ${restoredSubjects.length} Subjects, ${restoredMarks.length} Marks)';

      final result = SyncResult(
        success: true,
        syncedStudentsCount: restoredStudents.length,
        syncedSubjectsCount: restoredSubjects.length,
        syncedMarksCount: restoredMarks.length,
        message: msg,
        timestamp: DateTime.now(),
      );

      state = SyncState(isLoading: false, result: result);
      if (context.mounted) _showSnackBar(context, msg, isSuccess: true);
      return result;
    } catch (e) {
      final errorMsg = lang == 'bn'
          ? 'ব্যাকআপ পুনরুদ্ধার ব্যর্থ হয়েছে: $e'
          : 'Failed to restore cloud backup: $e';
      final result = SyncResult(
        success: false,
        syncedStudentsCount: 0,
        syncedSubjectsCount: 0,
        syncedMarksCount: 0,
        message: errorMsg,
        timestamp: DateTime.now(),
      );
      state = SyncState(isLoading: false, result: result);
      if (context.mounted) _showSnackBar(context, errorMsg, isSuccess: false);
      return result;
    }
  }

  /// Performs batch sync of all pending (isSynced == false) Hive records.
  Future<SyncResult> syncToSupabase(WidgetRef ref, BuildContext context) async {
    return backupToSupabase(ref, context);
  }

  void _showSnackBar(BuildContext context, String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess ? const Color(0xFF059669) : const Color(0xFFD97706),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Exports local database contents to a formatted JSON string backup.
  String exportBackupJson(WidgetRef ref) {
    final students = ref.read(studentRepositoryProvider);
    final subjects = ref.read(subjectRepositoryProvider);
    final marks = ref.read(markRepositoryProvider);

    final data = {
      'app': 'Madrasah Result App',
      'version': '1.0.0',
      'exported_at': DateTime.now().toIso8601String(),
      'students': students.map((s) => s.toJson()).toList(),
      'subjects': subjects.map((s) => s.toJson()).toList(),
      'marks': marks.map((m) => m.toJson()).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }
}

final syncServiceProvider = StateNotifierProvider<SyncServiceNotifier, SyncState>((ref) {
  return SyncServiceNotifier();
});
