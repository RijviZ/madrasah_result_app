// Stage 8 — Results & Marksheet Preview Screen
// Previews aggregated student results and provides PDF print/download capabilities.

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../l10n/app_translations.dart';
import '../models/mark_model.dart';
import '../models/student_model.dart';
import '../models/subject_model.dart';
import '../providers/locale_provider.dart';
import '../providers/repository_providers.dart';
import '../services/pdf_report_service.dart';
import '../utils/grading_engine.dart';
import '../widgets/app_pagination_bar.dart';
import '../widgets/class_dropdown_field.dart';
import '../widgets/screen_header.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  String? _selectedClass;
  String? _selectedSection;
  String _selectedExamType = 'Half Yearly';
  String _sortBy = 'position';
  String? _selectedStudentId;
  Set<String> _excludedStudentIds = {};
  int _currentPage = 1;
  int _pageSize = 20;

  static const _examTypes = ['Half Yearly', 'Annual', 'Test', 'Pre-Test'];

  Future<void> _printClassResultsWithProgress({
    required String className,
    required String examType,
    required List<StudentModel> students,
    required List<SubjectModel> subjects,
    required List<MarkModel> marks,
    required String lang,
  }) async {
    int currentProcessed = 0;
    final total = students.length;

    StateSetter? setProgressState;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        final cs = Theme.of(dialogCtx).colorScheme;
        final tt = Theme.of(dialogCtx).textTheme;

        return StatefulBuilder(
          builder: (context, setState) {
            setProgressState = setState;
            final progress = total > 0 ? (currentProcessed / total).clamp(0.0, 1.0) : 0.0;
            final percentInt = (progress * 100).toInt();

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              contentPadding: const EdgeInsets.all(24),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.print_rounded,
                      color: Color(0xFF059669),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    lang == 'bn' ? 'ফলাফল শিট তৈরি করা হচ্ছে...' : 'Generating Class Results...',
                    style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    lang == 'bn'
                        ? 'প্রসেসিং হচ্ছে: ${GradingEngine.formatInt(currentProcessed, lang)} / ${GradingEngine.formatInt(total, lang)} শিক্ষার্থী ($percentInt%)'
                        : 'Processing: $currentProcessed / $total Students ($percentInt%)',
                    style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.7)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: cs.primaryContainer,
                      color: const Color(0xFF059669),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    Uint8List? pdfBytes;
    try {
      pdfBytes = await PdfReportService.printClassTabulationSheet(
        className: className,
        examType: examType,
        students: students,
        subjects: subjects,
        marks: marks,
        langCode: lang,
        onProgress: (processed, totalCount) {
          currentProcessed = processed;
          if (setProgressState != null) {
            setProgressState!(() {});
          }
        },
      );
    } catch (e) {
      debugPrint('Error generating tabulation PDF: $e');
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    if (pdfBytes != null && pdfBytes.isNotEmpty) {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes!,
        name: 'Class_Tabulation_${className.replaceAll(" ", "_")}_$examType',
      );
    }
  }

  Future<Map<String, StudentRank>> _computeRanksAsync({
    required List<StudentModel> classStudents,
    required List<SubjectModel> subjects,
    required List<MarkModel> allMarks,
    required String examType,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 30));
    return GradingEngine.calculateStudentRanks(
      classStudents: classStudents,
      subjects: subjects,
      allMarks: allMarks,
      examType: examType,
    );
  }

  Widget _buildLoadingView(BuildContext context, String lang) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: Color(0xFF059669),
                strokeWidth: 3,
              ),
              const SizedBox(height: 20),
              Text(
                lang == 'bn' ? 'ফলাফল ও মেধা স্থান প্রসেস করা হচ্ছে...' : 'Processing Results & Merit Ranks...',
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                lang == 'bn' ? 'অনুগ্রহ করে অপেক্ষা করুন' : 'Please wait a moment',
                style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider).languageCode;
    final allStudents = ref.watch(studentRepositoryProvider);
    final allSubjects = ref.watch(subjectRepositoryProvider);
    final allMarks = ref.watch(markRepositoryProvider);
    final cs = Theme.of(context).colorScheme;

    final classes = allStudents.map((s) => s.className).toSet().toList()..sort();

    final classSubjects = _selectedClass == null
        ? <SubjectModel>[]
        : allSubjects
            .where((s) => s.className.trim().toLowerCase() == _selectedClass!.trim().toLowerCase())
            .toList()
          ..sort((a, b) => a.subjectCode.compareTo(b.subjectCode));

    final classStudentsForRanking = _selectedClass == null
        ? <StudentModel>[]
        : allStudents
            .where((s) => s.className.trim().toLowerCase() == _selectedClass!.trim().toLowerCase())
            .toList();

    final filteredStudents = _selectedClass == null
        ? <StudentModel>[]
        : allStudents
            .where((s) =>
                s.className.trim().toLowerCase() == _selectedClass!.trim().toLowerCase() &&
                (_selectedSection == null || s.section == _selectedSection))
            .toList();

    final sections = _selectedClass == null
        ? <String>[]
        : allStudents
            .where((s) => s.className.trim().toLowerCase() == _selectedClass!.trim().toLowerCase())
            .map((s) => s.section)
            .toSet()
            .toList()
          ..sort();

    StudentModel? selectedStudent;
    if (_selectedStudentId != null) {
      try {
        selectedStudent = filteredStudents.firstWhere((s) => s.id == _selectedStudentId);
      } catch (_) {
        selectedStudent = null;
      }
    }

    return Scaffold(
      body: Column(
        children: [
          // ── Gradient Page Header ─────────────────────────────────────────
          GradientPageHeader(
            icon: Icons.assignment_rounded,
            title: lang == 'bn' ? 'ফলাফল ও মার্কশিট' : 'Results & Marksheet',
            subtitle: lang == 'bn'
                ? 'শ্রেণী নির্বাচন করে ফলাফল ও মার্কশিট দেখুন'
                : 'View and print results, tabulations and marksheets',
            gradientColors: [const Color(0xFF0D7490), const Color(0xFF0891B2)],
          ),
          // ── Filter Bar ────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow.withValues(alpha: 0.6),
              border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4))),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                // Class Dropdown
                SizedBox(
                  width: 200,
                  child: ClassDropdownField(
                    selectedClass: _selectedClass,
                    onChanged: (v) => setState(() {
                      _selectedClass = v;
                      _selectedSection = null;
                      _selectedStudentId = null;
                      _excludedStudentIds.clear();
                    }),
                    lang: lang,
                    customClasses: classes,
                  ),
                ),

                // Section Dropdown
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedSection,
                    onChanged: _selectedClass == null
                        ? null
                        : (v) => setState(() {
                              _selectedSection = v;
                              _selectedStudentId = null;
                            }),
                    decoration: InputDecoration(
                      labelText: 'section'.tr(lang),
                      prefixIcon: const Icon(Icons.group_rounded, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                      filled: true,
                      fillColor: cs.surfaceContainerLow,
                    ),
                    items: sections.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  ),
                ),

                // Exam Type Dropdown
                SizedBox(
                  width: 170,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedExamType,
                    onChanged: (v) => setState(() {
                      _selectedExamType = v ?? 'Half Yearly';
                    }),
                    decoration: InputDecoration(
                      labelText: 'examType'.tr(lang),
                      prefixIcon: const Icon(Icons.event_note_rounded, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                      filled: true,
                      fillColor: cs.surfaceContainerLow,
                    ),
                    items: _examTypes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  ),
                ),

                // Sort Dropdown
                SizedBox(
                  width: 190,
                  child: DropdownButtonFormField<String>(
                    initialValue: _sortBy,
                    onChanged: (v) => setState(() {
                      _sortBy = v ?? 'position';
                    }),
                    decoration: InputDecoration(
                      labelText: lang == 'bn' ? 'ক্রমানুসারে' : 'Sort By',
                      prefixIcon: const Icon(Icons.sort_rounded, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                      filled: true,
                      fillColor: cs.surfaceContainerLow,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'position',
                        child: Text(lang == 'bn' ? 'মেধা স্থান' : 'Merit Position'),
                      ),
                      DropdownMenuItem(
                        value: 'roll',
                        child: Text(lang == 'bn' ? 'রোল নম্বর' : 'Roll Number'),
                      ),
                      DropdownMenuItem(
                        value: 'name',
                        child: Text(lang == 'bn' ? 'শিক্ষার্থীর নাম' : 'Student Name'),
                      ),
                    ],
                  ),
                ),

                // Student Dropdown
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedStudentId,
                    onChanged: filteredStudents.isEmpty
                        ? null
                        : (v) => setState(() => _selectedStudentId = v),
                    decoration: InputDecoration(
                      labelText: lang == 'bn' ? 'শিক্ষার্থী' : 'Student',
                      prefixIcon: const Icon(Icons.person_rounded, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                      filled: true,
                      fillColor: cs.surfaceContainerLow,
                    ),
                    items: filteredStudents.map((st) {
                      return DropdownMenuItem(
                        value: st.id,
                        child: Text(
                          '${GradingEngine.formatInt(st.roll, lang)}. ${st.name}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                  ),
                ),

                if (_selectedClass != null && filteredStudents.isNotEmpty) ...[
                  FilledButton.icon(
                    onPressed: () {
                      final targetStudents = filteredStudents
                          .where((s) => !_excludedStudentIds.contains(s.id))
                          .toList();

                      if (targetStudents.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              lang == 'bn'
                                  ? 'অন্তত ১ জন শিক্ষার্থী নির্বাচন করতে হবে'
                                  : 'Select at least 1 student to print results',
                            ),
                            backgroundColor: const Color(0xFFDC2626),
                          ),
                        );
                        return;
                      }

                      _printClassResultsWithProgress(
                        className: _selectedClass!,
                        examType: _selectedExamType,
                        students: targetStudents,
                        subjects: classSubjects,
                        marks: allMarks,
                        lang: lang,
                      );
                    },
                    icon: const Icon(Icons.print_rounded, size: 18),
                    label: Text(
                      lang == 'bn'
                          ? 'ফলাফল প্রিন্ট (${GradingEngine.formatInt(filteredStudents.where((s) => !_excludedStudentIds.contains(s.id)).length, lang)})'
                          : 'Print Results (${filteredStudents.where((s) => !_excludedStudentIds.contains(s.id)).length})',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Main Content Area ─────────────────────────────────────────────
          Expanded(
            child: _selectedClass == null
                ? _buildEmptyPrompt(context, lang, lang == 'bn' ? 'শ্রেণী নির্বাচন করুন' : 'Select a Class to view results')
                : filteredStudents.isEmpty
                    ? _buildEmptyPrompt(context, lang, lang == 'bn' ? 'এই শ্রেণীতে কোনো শিক্ষার্থী নেই' : 'No students in this class')
                    : selectedStudent != null
                        ? _buildSingleStudentResult(selectedStudent, classSubjects, allMarks, lang)
                        : FutureBuilder<Map<String, StudentRank>>(
                            key: ValueKey('$_selectedClass-$_selectedExamType-${allMarks.length}'),
                            future: _computeRanksAsync(
                              classStudents: classStudentsForRanking,
                              subjects: classSubjects,
                              allMarks: allMarks,
                              examType: _selectedExamType,
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return _buildLoadingView(context, lang);
                              }
                              final ranks = snapshot.data ?? {};

                              final sortedList = List<StudentModel>.from(filteredStudents);
                              if (_sortBy == 'position') {
                                sortedList.sort((a, b) {
                                  final rankA = ranks[a.id]?.classPosition ?? 9999;
                                  final rankB = ranks[b.id]?.classPosition ?? 9999;
                                  if (rankA != rankB) return rankA.compareTo(rankB);
                                  return a.roll.compareTo(b.roll);
                                });
                              } else if (_sortBy == 'name') {
                                sortedList.sort((a, b) => a.name.compareTo(b.name));
                              } else {
                                sortedList.sort((a, b) => a.roll.compareTo(b.roll));
                              }

                              final totalCount = sortedList.length;
                              final totalPages = (totalCount / _pageSize).ceil();
                              final safePage = _currentPage.clamp(1, totalPages > 0 ? totalPages : 1);
                              final startIndex = (safePage - 1) * _pageSize;
                              final paginatedList = sortedList.skip(startIndex).take(_pageSize).toList();

                              return Column(
                                children: [
                                  Expanded(
                                    child: _buildStudentGrid(paginatedList, classSubjects, allMarks, lang, ranks),
                                  ),
                                  AppPaginationBar(
                                    currentPage: safePage,
                                    totalItems: totalCount,
                                    pageSize: _pageSize,
                                    onPageChanged: (p) => setState(() => _currentPage = p),
                                    onPageSizeChanged: (sz) => setState(() {
                                      _pageSize = sz;
                                      _currentPage = 1;
                                    }),
                                    lang: lang,
                                  ),
                                ],
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPrompt(BuildContext context, String lang, String message) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.assignment_rounded, size: 72, color: cs.primary.withValues(alpha: 0.25)),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.45),
                ),
          ),
        ],
      ),
    );
  }

  // ── Grid of all students in class with summary cards & quick print ────────
  Widget _buildStudentGrid(
    List<StudentModel> students,
    List<SubjectModel> subjects,
    List<MarkModel> marks,
    String lang,
    Map<String, StudentRank> ranks,
  ) {
    final cs = Theme.of(context).colorScheme;
    final allSelected = _excludedStudentIds.isEmpty;
    final includedCount = students.where((s) => !_excludedStudentIds.contains(s.id)).length;

    return Column(
      children: [
        // Selection Header Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4))),
          ),
          child: Row(
            children: [
              Checkbox(
                value: allSelected,
                activeColor: const Color(0xFF059669),
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _excludedStudentIds.clear();
                    } else {
                      _excludedStudentIds = students.map((s) => s.id).toSet();
                    }
                  });
                },
              ),
              Text(
                lang == 'bn'
                    ? 'সকল শিক্ষার্থী নির্বাচন (${GradingEngine.formatInt(includedCount, lang)} / ${GradingEngine.formatInt(students.length, lang)})'
                    : 'Select All (${GradingEngine.formatInt(includedCount, lang)} / ${GradingEngine.formatInt(students.length, lang)})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const Spacer(),
              if (_excludedStudentIds.isNotEmpty)
                TextButton.icon(
                  onPressed: () => setState(() => _excludedStudentIds.clear()),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(lang == 'bn' ? 'পুনরায় সব নির্বাচন' : 'Select All'),
                ),
            ],
          ),
        ),

        // Student List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: students.length,
            itemBuilder: (context, i) {
              final st = students[i];
              final isExcluded = _excludedStudentIds.contains(st.id);
              final rank = ranks[st.id];

              // Compute results
              final List<double> gpas = [];
              final List<double> marksList = [];
              final List<double> passMarksList = [];

              for (final sub in subjects) {
                final mark = marks.firstWhere(
                  (m) => m.studentId == st.id && m.subjectId == sub.id && m.examType == _selectedExamType,
                  orElse: () => MarkModel(studentId: st.id, subjectId: sub.id, examType: _selectedExamType, obtainedMarks: 0),
                );
                final grade = GradingEngine.getGradeAndGPA(mark.obtainedMarks, sub.fullMarks);
                gpas.add(grade.gradePoint);
                marksList.add(mark.obtainedMarks);
                passMarksList.add(sub.passMarks);
              }

              final res = subjects.isEmpty
                  ? const FinalResult(overallGPA: 0, finalGrade: 'F', totalObtainedMarks: 0, totalFullMarks: 0, isPassed: false)
                  : GradingEngine.calculateFinalResult(gpaList: gpas, marksList: marksList, passMarksList: passMarksList, subjects: subjects);

              final cs = Theme.of(context).colorScheme;
              final tt = Theme.of(context).textTheme;

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                color: isExcluded ? cs.surfaceContainerLow.withValues(alpha: 0.4) : cs.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isExcluded
                        ? cs.outlineVariant.withValues(alpha: 0.2)
                        : cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      // Selection Checkbox
                      Checkbox(
                        value: !isExcluded,
                        activeColor: const Color(0xFF059669),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _excludedStudentIds.remove(st.id);
                            } else {
                              _excludedStudentIds.add(st.id);
                            }
                          });
                        },
                      ),
                      const SizedBox(width: 4),

                      // Avatar Roll
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: isExcluded ? cs.surfaceContainerHigh : cs.primaryContainer,
                        child: Text(
                          GradingEngine.formatInt(st.roll, lang),
                          style: tt.titleMedium?.copyWith(
                            color: isExcluded ? cs.onSurface.withValues(alpha: 0.5) : cs.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(st.name, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(
                        '${st.className} · ${st.section}   |   ${lang == 'bn' ? "প্রাপ্ত নম্বর" : "Obtained"}: ${GradingEngine.formatInt(res.totalObtainedMarks.toInt(), lang)}',
                        style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
                      ),
                      if (rank != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          '${lang == 'bn' ? "মেধা স্থান" : "Merit Position"}: #${GradingEngine.formatInt(rank.classPosition, lang)}',
                          style: tt.bodySmall?.copyWith(color: cs.primary, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ],
                  ),
                ),

                // Result Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: res.isPassed
                        ? const Color(0xFF16A34A).withValues(alpha: 0.15)
                        : const Color(0xFFDC2626).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: res.isPassed ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        res.isPassed ? (lang == 'bn' ? 'পাস' : 'PASS') : (lang == 'bn' ? 'ফেল' : 'FAIL'),
                        style: TextStyle(
                          color: res.isPassed ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'GPA ${GradingEngine.formatNumber(res.overallGPA, lang)}',
                        style: TextStyle(
                          color: res.isPassed ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Action Buttons
                IconButton(
                  icon: const Icon(Icons.remove_red_eye_rounded),
                  tooltip: lang == 'bn' ? 'বিস্তারিত দেখুন' : 'View Details',
                  onPressed: () => setState(() => _selectedStudentId = st.id),
                ),
                FilledButton.icon(
                  onPressed: () {
                    PdfReportService.printReportCard(
                      student: st,
                      examType: _selectedExamType,
                      subjects: subjects,
                      marks: marks,
                      langCode: lang,
                      classPosition: rank?.classPosition,
                      sectionPosition: rank?.sectionPosition,
                    );
                  },
                  icon: const Icon(Icons.print_rounded, size: 18),
                  label: Text('printResult'.tr(lang)),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  ),
],
);
}

  // ── Detailed Single Student Result Marksheet Preview ───────────────────────
  Widget _buildSingleStudentResult(
    StudentModel student,
    List<SubjectModel> subjects,
    List<MarkModel> marks,
    String lang,
  ) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final List<double> gpas = [];
    final List<double> marksList = [];
    final List<double> passMarksList = [];
    final List<Map<String, dynamic>> subjectDetails = [];

    for (final sub in subjects) {
      final markModel = marks.firstWhere(
        (m) => m.studentId == student.id && m.subjectId == sub.id && m.examType == _selectedExamType,
        orElse: () => MarkModel(studentId: student.id, subjectId: sub.id, examType: _selectedExamType, obtainedMarks: 0),
      );
      final gradeRes = GradingEngine.getGradeAndGPA(markModel.obtainedMarks, sub.fullMarks);
      gpas.add(gradeRes.gradePoint);
      marksList.add(markModel.obtainedMarks);
      passMarksList.add(sub.passMarks);

      subjectDetails.add({
        'subject': sub,
        'obtained': markModel.obtainedMarks,
        'grade': gradeRes.letterGrade,
        'gpa': gradeRes.gradePoint,
        'isPassed': markModel.obtainedMarks >= sub.passMarks,
      });
    }

    final finalResult = subjects.isEmpty
        ? const FinalResult(overallGPA: 0, finalGrade: 'F', totalObtainedMarks: 0, totalFullMarks: 0, isPassed: false)
        : GradingEngine.calculateFinalResult(gpaList: gpas, marksList: marksList, passMarksList: passMarksList, subjects: subjects);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Back Button & Print Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _selectedStudentId = null),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: Text(lang == 'bn' ? 'সকল শিক্ষার্থী' : 'All Students'),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      final allClassStudents = ref.read(studentRepositoryProvider)
                          .where((s) => s.className.trim().toLowerCase() == student.className.trim().toLowerCase())
                          .toList();
                      final ranks = GradingEngine.calculateStudentRanks(
                        classStudents: allClassStudents,
                        subjects: subjects,
                        allMarks: marks,
                        examType: _selectedExamType,
                      );
                      final rank = ranks[student.id];

                      PdfReportService.printReportCard(
                        student: student,
                        examType: _selectedExamType,
                        subjects: subjects,
                        marks: marks,
                        langCode: lang,
                        classPosition: rank?.classPosition,
                        sectionPosition: rank?.sectionPosition,
                      );
                    },
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                    label: Text('generateMarksheet'.tr(lang)),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Marksheet Container Paper Card ───────────────────────────
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'institutionTitleBn'.tr('bn'),
                              style: tt.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: cs.onPrimaryContainer,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'institutionTitle'.tr('en'),
                              style: tt.bodySmall?.copyWith(
                                color: cs.onPrimaryContainer.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Chip(
                              label: Text('$_selectedExamType - 2026'),
                              backgroundColor: cs.surface,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Student Info Box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${'name'.tr(lang)}: ${student.name}', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('${'class'.tr(lang)}: ${student.className}   |   ${'section'.tr(lang)}: ${student.section}'),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${'roll'.tr(lang)}: ${GradingEngine.formatInt(student.roll, lang)}', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('ID: ${student.id.substring(0, 8).toUpperCase()}', style: tt.bodySmall),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Subject Breakdown Table
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Table(
                          border: TableBorder.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
                          columnWidths: const {
                            0: FlexColumnWidth(1.2),
                            1: FlexColumnWidth(3.0),
                            2: FlexColumnWidth(1.2),
                            3: FlexColumnWidth(1.2),
                            4: FlexColumnWidth(1.5),
                            5: FlexColumnWidth(1.0),
                            6: FlexColumnWidth(1.0),
                          },
                          children: [
                            TableRow(
                              decoration: BoxDecoration(color: cs.primary),
                              children: [
                                _tableHeader('subjectCode'.tr(lang), cs),
                                _tableHeader('subjectName'.tr(lang), cs),
                                _tableHeader('fullMarks'.tr(lang), cs),
                                _tableHeader('passMarks'.tr(lang), cs),
                                _tableHeader('obtainedMarks'.tr(lang), cs),
                                _tableHeader('grade'.tr(lang), cs),
                                _tableHeader('gpa'.tr(lang), cs),
                              ],
                            ),
                            ...subjectDetails.map((item) {
                              final SubjectModel sub = item['subject'];
                              final double obt = item['obtained'];
                              final bool pass = item['isPassed'];

                              return TableRow(
                                decoration: BoxDecoration(
                                  color: pass ? null : cs.errorContainer.withValues(alpha: 0.2),
                                ),
                                children: [
                                  _tableCell(sub.subjectCode, alignCenter: true),
                                  _tableCell(sub.subjectName),
                                  _tableCell(GradingEngine.formatInt(sub.fullMarks.toInt(), lang), alignCenter: true),
                                  _tableCell(GradingEngine.formatInt(sub.passMarks.toInt(), lang), alignCenter: true),
                                  _tableCell(GradingEngine.formatInt(obt.toInt(), lang), alignCenter: true, isBold: true),
                                  _tableCell(item['grade'], alignCenter: true, isBold: true),
                                  _tableCell(GradingEngine.formatNumber(item['gpa'], lang), alignCenter: true),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Summary Banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: finalResult.isPassed
                              ? const Color(0xFF16A34A).withValues(alpha: 0.12)
                              : const Color(0xFFDC2626).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: finalResult.isPassed ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${'totalMarks'.tr(lang)}: ${GradingEngine.formatInt(finalResult.totalObtainedMarks.toInt(), lang)} / ${GradingEngine.formatInt(finalResult.totalFullMarks.toInt(), lang)}',
                                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  lang == 'bn'
                                      ? 'সর্বমোট জিপিএ: ${GradingEngine.formatNumber(finalResult.overallGPA, lang)}   |   প্রাপ্ত গ্রেড: ${finalResult.finalGrade}'
                                      : 'Overall GPA: ${GradingEngine.formatNumber(finalResult.overallGPA, lang)}   |   Grade: ${finalResult.finalGrade}',
                                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Chip(
                              label: Text(
                                finalResult.isPassed ? (lang == 'bn' ? 'উত্তীর্ণ / PASSED' : 'PASSED') : (lang == 'bn' ? 'অনুত্তীর্ণ / FAILED' : 'FAILED'),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              backgroundColor: finalResult.isPassed ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tableHeader(String text, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.bold, fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _tableCell(String text, {bool alignCenter = false, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 12),
        textAlign: alignCenter ? TextAlign.center : TextAlign.left,
      ),
    );
  }
}
