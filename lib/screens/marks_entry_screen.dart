// Stage 6 — Marks Entry Screen
// Responsive: PlutoGrid table on desktop, card ListView on mobile.
// Filter bar: Class, Section, ExamType, Subject dropdowns.
// Live grade/GPA recalculation as marks are typed.
// "Save All Marks" bottom bar with bilingual SnackBar.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluto_grid/pluto_grid.dart';
import '../l10n/app_translations.dart';
import '../models/mark_model.dart';
import '../models/student_model.dart';
import '../models/subject_model.dart';
import '../providers/locale_provider.dart';
import '../providers/repository_providers.dart';
import '../utils/grading_engine.dart';
import '../utils/madrasah_subjects.dart';
import '../widgets/class_dropdown_field.dart';
import '../widgets/screen_header.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Marks Entry Screen
// ─────────────────────────────────────────────────────────────────────────────

class MarksEntryScreen extends ConsumerStatefulWidget {
  const MarksEntryScreen({super.key});

  @override
  ConsumerState<MarksEntryScreen> createState() => _MarksEntryScreenState();
}

class _MarksEntryScreenState extends ConsumerState<MarksEntryScreen> {
  // Filter selections
  String? _selectedClass;
  String? _selectedSection;
  String _selectedExamType = 'Half Yearly';
  String? _selectedSubjectId;

  // In-memory draft: studentId → obtainedMarks
  final Map<String, double> _marksDraft = {};

  bool _isSaving = false;

  // ── Derived lists ─────────────────────────────────────────────────────────

  List<String> _distinctClasses(List<StudentModel> students) {
    final set = <String>{};
    set.addAll(students.map((s) => s.className));
    final result = set.toList()..sort();
    return result;
  }

  List<String> _distinctSections(List<StudentModel> students, String? cls) {
    if (cls == null) return [];
    return students
        .where((s) => s.className.trim().toLowerCase() == cls.trim().toLowerCase())
        .map((s) => s.section)
        .toSet()
        .toList()
      ..sort();
  }

  List<StudentModel> _filteredStudents(List<StudentModel> all) {
    if (_selectedClass == null) return [];
    return all
        .where((s) =>
            s.className.trim().toLowerCase() == _selectedClass!.trim().toLowerCase() &&
            (_selectedSection == null || s.section == _selectedSection))
        .toList()
      ..sort((a, b) => a.roll.compareTo(b.roll));
  }

  SubjectModel? _activeSubject(List<SubjectModel> subjects) {
    if (_selectedSubjectId == null) return null;
    try {
      return subjects.firstWhere((s) => s.id == _selectedSubjectId);
    } catch (_) {
      return null;
    }
  }

  // ── Initialise draft from existing saved marks ────────────────────────────

  void _initDraft(List<StudentModel> students, List<MarkModel> savedMarks) {
    for (final st in students) {
      try {
        final existing = savedMarks.firstWhere(
          (m) =>
              m.studentId == st.id &&
              m.subjectId == _selectedSubjectId &&
              m.examType == _selectedExamType,
        );
        _marksDraft[st.id] = existing.obtainedMarks;
      } catch (_) {
        _marksDraft.putIfAbsent(st.id, () => 0.0);
      }
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _saveAll(
    List<StudentModel> students,
    SubjectModel subject,
    String lang,
  ) async {
    setState(() => _isSaving = true);
    final marks = students.map((st) {
      return MarkModel(
        studentId: st.id,
        subjectId: subject.id,
        examType: _selectedExamType,
        obtainedMarks: _marksDraft[st.id] ?? 0.0,
      );
    }).toList();

    await ref.read(markRepositoryProvider.notifier).bulkUpsertMarks(
          marks: marks,
          className: _selectedClass!,
          subjectId: subject.id,
        );
    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              lang == 'bn'
                  ? '${subject.subjectName} এর সকল নম্বর সফলভাবে সংরক্ষিত হয়েছে'
                  : 'Saved all marks for ${subject.subjectName}',
            ),
          ],
        ),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _autoAddClassSubjects(String className, String lang) async {
    final repo = ref.read(subjectRepositoryProvider.notifier);
    int count = 0;
    for (final preset in MadrasahSubjects.presets) {
      final sub = SubjectModel(
        subjectCode: preset.code,
        subjectName: lang == 'bn' ? preset.nameBn : preset.nameEn,
        className: className,
        fullMarks: preset.fullMarks,
        passMarks: preset.passMarks,
        markType: preset.markType,
        writtenPassMarks: preset.writtenPassMarks,
        mcqPassMarks: preset.mcqPassMarks,
        isCombinedSubject: preset.isCombinedSubject,
        combinedPairGroup: preset.combinedPairGroup,
      );
      await repo.addSubject(sub);
      count++;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang == 'bn'
                ? '$className এ $count টি বিষয় যুক্ত হয়েছে'
                : 'Added $count subjects to $className',
          ),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider).languageCode;
    final allStudents = ref.watch(studentRepositoryProvider);
    final allSubjects = ref.watch(subjectRepositoryProvider);
    final allMarks = ref.watch(markRepositoryProvider);
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 800;

    final classes = _distinctClasses(allStudents);
    if (_selectedClass == null && classes.isNotEmpty) {
      _selectedClass = classes.contains('ষষ্ঠ শ্রেণি') ? 'ষষ্ঠ শ্রেণি' : classes.first;
    }

    final sections = _distinctSections(allStudents, _selectedClass);
    final filteredStudents = _filteredStudents(allStudents);

    // Filter subjects matching selected class
    final classSubjects = _selectedClass == null
        ? <SubjectModel>[]
        : allSubjects
            .where((s) => s.className.trim().toLowerCase() == _selectedClass!.trim().toLowerCase())
            .toList()
          ..sort((a, b) => a.subjectCode.compareTo(b.subjectCode));

    // Auto-select first subject of class if not selected or if current selection is invalid for this class
    if (_selectedClass != null && classSubjects.isNotEmpty) {
      if (_selectedSubjectId == null || !classSubjects.any((s) => s.id == _selectedSubjectId)) {
        _selectedSubjectId = classSubjects.first.id;
      }
    }

    final activeSubject = _activeSubject(allSubjects);

    // Init draft whenever filters change
    if (activeSubject != null) {
      _initDraft(filteredStudents, allMarks);
    }

    return Scaffold(
      body: Column(
        children: [
          // ── Gradient Page Header (Desktop Only to Maximize Mobile Screen Space) ──
          if (isDesktop)
            GradientPageHeader(
              icon: Icons.edit_note_rounded,
              title: lang == 'bn' ? 'নম্বর প্রবেশ' : 'Marks Entry',
              subtitle: lang == 'bn'
                  ? 'শ্রেণী ও বিষয় নির্বাচন করে নম্বর প্রবেশ করুন'
                  : 'Select class, exam type and subject to enter marks',
              gradientColors: [const Color(0xFFE65100), const Color(0xFFEF6C00)],
            ),
          // ── Filter Bar ───────────────────────────────────────────
          _FilterBar(
            lang: lang,
            classes: classes,
            sections: sections,
            subjects: classSubjects,
            selectedClass: _selectedClass,
            selectedSection: _selectedSection,
            selectedExamType: _selectedExamType,
            selectedSubjectId: _selectedSubjectId,
            onClassChanged: (v) => setState(() {
              _selectedClass = v;
              _selectedSection = null;
              final matchingSubjects = allSubjects
                  .where((s) => s.className.trim().toLowerCase() == (v ?? '').trim().toLowerCase())
                  .toList()
                ..sort((a, b) => a.subjectCode.compareTo(b.subjectCode));
              _selectedSubjectId = matchingSubjects.isNotEmpty ? matchingSubjects.first.id : null;
              _marksDraft.clear();
            }),
            onSectionChanged: (v) => setState(() {
              _selectedSection = v;
              _marksDraft.clear();
            }),
            onExamTypeChanged: (v) => setState(() {
              _selectedExamType = v ?? 'Half Yearly';
              _marksDraft.clear();
            }),
            onSubjectChanged: (v) => setState(() {
              _selectedSubjectId = v;
              _marksDraft.clear();
            }),
          ),

          // ── Content ──────────────────────────────────────────────────────
          Expanded(
            child: activeSubject == null || filteredStudents.isEmpty
                ? _EmptyPrompt(
                    lang: lang,
                    hasClass: _selectedClass != null,
                    hasSubject: activeSubject != null,
                    hasStudents: filteredStudents.isNotEmpty,
                    selectedClass: _selectedClass,
                    onAddSubjects: _selectedClass == null
                        ? null
                        : () => _autoAddClassSubjects(_selectedClass!, lang),
                  )
                : (isDesktop
                    ? _DesktopGrid(
                        students: filteredStudents,
                        subject: activeSubject,
                        marksDraft: _marksDraft,
                        lang: lang,
                        onMarksChanged: (id, val) {
                          _marksDraft[id] = val;
                          ref.read(markRepositoryProvider.notifier).upsertSingleMark(
                                MarkModel(
                                  studentId: id,
                                  subjectId: activeSubject.id,
                                  examType: _selectedExamType,
                                  obtainedMarks: val,
                                ),
                              );
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) setState(() {});
                          });
                        },
                      )
                    : _MobileListView(
                        students: filteredStudents,
                        subject: activeSubject,
                        marksDraft: _marksDraft,
                        lang: lang,
                        onMarksChanged: (id, val) {
                          _marksDraft[id] = val;
                          ref.read(markRepositoryProvider.notifier).upsertSingleMark(
                                MarkModel(
                                  studentId: id,
                                  subjectId: activeSubject.id,
                                  examType: _selectedExamType,
                                  obtainedMarks: val,
                                ),
                              );
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) setState(() {});
                          });
                        },
                      )),
          ),

          // ── Save Bottom Bar ───────────────────────────────────────────────
          if (activeSubject != null && filteredStudents.isNotEmpty)
            _SaveBottomBar(
              lang: lang,
              isSaving: _isSaving,
              studentCount: filteredStudents.length,
              onSave: () => _saveAll(filteredStudents, activeSubject, lang),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter Bar
// ─────────────────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.lang,
    required this.classes,
    required this.sections,
    required this.subjects,
    required this.selectedClass,
    required this.selectedSection,
    required this.selectedExamType,
    required this.selectedSubjectId,
    required this.onClassChanged,
    required this.onSectionChanged,
    required this.onExamTypeChanged,
    required this.onSubjectChanged,
  });

  final String lang;
  final List<String> classes;
  final List<String> sections;
  final List<SubjectModel> subjects;
  final String? selectedClass;
  final String? selectedSection;
  final String selectedExamType;
  final String? selectedSubjectId;
  final ValueChanged<String?> onClassChanged;
  final ValueChanged<String?> onSectionChanged;
  final ValueChanged<String?> onExamTypeChanged;
  final ValueChanged<String?> onSubjectChanged;

  static const _examTypes = ['Half Yearly', 'Annual', 'Test', 'Pre-Test'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isMobile = MediaQuery.of(context).size.width <= 650;

    if (isMobile) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow.withValues(alpha: 0.6),
          border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4))),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ClassDropdownField(
                    selectedClass: selectedClass,
                    onChanged: onClassChanged,
                    lang: lang,
                    customClasses: classes,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FilterDropdown(
                    label: 'section'.tr(lang),
                    value: selectedSection,
                    items: sections,
                    onChanged: onSectionChanged,
                    icon: Icons.group_rounded,
                    enabled: selectedClass != null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _FilterDropdown(
                    label: 'examType'.tr(lang),
                    value: selectedExamType,
                    items: _examTypes,
                    onChanged: onExamTypeChanged,
                    icon: Icons.event_note_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FilterDropdown(
                    label: 'subjectName'.tr(lang),
                    value: selectedSubjectId,
                    items: subjects.map((s) => s.id).toList(),
                    displayItems: subjects.map((s) => s.subjectName).toList(),
                    onChanged: onSubjectChanged,
                    icon: Icons.menu_book_rounded,
                    enabled: selectedClass != null && subjects.isNotEmpty,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow.withValues(alpha: 0.6),
        border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4))),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        children: [
          SizedBox(
            width: 200,
            child: ClassDropdownField(
              selectedClass: selectedClass,
              onChanged: onClassChanged,
              lang: lang,
              customClasses: classes,
            ),
          ),
          _FilterDropdown(
            label: 'section'.tr(lang),
            value: selectedSection,
            items: sections,
            onChanged: onSectionChanged,
            icon: Icons.group_rounded,
            enabled: selectedClass != null,
            width: 180,
          ),
          _FilterDropdown(
            label: 'examType'.tr(lang),
            value: selectedExamType,
            items: _examTypes,
            onChanged: onExamTypeChanged,
            icon: Icons.event_note_rounded,
            width: 180,
          ),
          _FilterDropdown(
            label: 'subjectName'.tr(lang),
            value: selectedSubjectId,
            items: subjects.map((s) => s.id).toList(),
            displayItems: subjects.map((s) => s.subjectName).toList(),
            onChanged: onSubjectChanged,
            icon: Icons.menu_book_rounded,
            enabled: selectedClass != null && subjects.isNotEmpty,
            width: 180,
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.icon,
    this.displayItems,
    this.enabled = true,
    this.width,
  });

  final String label;
  final String? value;
  final List<String> items;
  final List<String>? displayItems;
  final ValueChanged<String?> onChanged;
  final IconData icon;
  final bool enabled;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final safeValue = (value != null && items.contains(value)) ? value : null;

    final dropdown = DropdownButtonFormField<String>(
      key: ValueKey(safeValue),
      initialValue: safeValue,
      onChanged: enabled ? onChanged : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        isDense: true,
        filled: true,
        fillColor: enabled
            ? cs.surfaceContainerLow
            : cs.surfaceContainerLow.withValues(alpha: 0.5),
      ),
      hint: Text(label,
          style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.45), fontSize: 13)),
      items: List.generate(items.length, (i) {
        return DropdownMenuItem(
          value: items[i],
          child: Text(
            displayItems != null ? displayItems![i] : items[i],
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13),
          ),
        );
      }),
    );

    if (width != null) {
      return SizedBox(width: width, child: dropdown);
    }
    return dropdown;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty prompt
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyPrompt extends StatelessWidget {
  const _EmptyPrompt({
    required this.lang,
    required this.hasClass,
    required this.hasSubject,
    required this.hasStudents,
    this.selectedClass,
    this.onAddSubjects,
  });

  final String lang;
  final bool hasClass;
  final bool hasSubject;
  final bool hasStudents;
  final String? selectedClass;
  final VoidCallback? onAddSubjects;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    String msg;
    if (!hasClass) {
      msg = lang == 'bn'
          ? 'শ্রেণী ও বিষয় নির্বাচন করুন'
          : 'Select a Class and Subject to begin';
    } else if (!hasSubject) {
      msg = lang == 'bn'
          ? 'এই শ্রেণীতে কোনো বিষয় যোগ করা হয়নি'
          : 'No subjects added for this class yet';
    } else {
      msg = lang == 'bn'
          ? 'এই শ্রেণীতে কোনো শিক্ষার্থী নেই'
          : 'No students found for this class/section';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_note_rounded,
                size: 72, color: cs.primary.withValues(alpha: 0.25)),
            const SizedBox(height: 16),
            Text(
              msg,
              style: tt.bodyLarge
                  ?.copyWith(color: cs.onSurface.withValues(alpha: 0.55)),
              textAlign: TextAlign.center,
            ),
            if (hasClass && !hasSubject && onAddSubjects != null) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onAddSubjects,
                icon: const Icon(Icons.playlist_add_check_rounded),
                label: Text(
                  lang == 'bn'
                      ? '$selectedClass এর বিষয়সমূহ যোগ করুন'
                      : 'Add Subjects for $selectedClass',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Desktop PlutoGrid View
// ─────────────────────────────────────────────────────────────────────────────

class _DesktopGrid extends StatefulWidget {
  const _DesktopGrid({
    required this.students,
    required this.subject,
    required this.marksDraft,
    required this.lang,
    required this.onMarksChanged,
  });

  final List<StudentModel> students;
  final SubjectModel subject;
  final Map<String, double> marksDraft;
  final String lang;
  final void Function(String studentId, double val) onMarksChanged;

  @override
  State<_DesktopGrid> createState() => _DesktopGridState();
}

class _DesktopGridState extends State<_DesktopGrid> {
  late PlutoGridStateManager _stateManager;
  late List<PlutoColumn> _columns;
  late List<PlutoRow> _rows;

  @override
  void initState() {
    super.initState();
    _buildGrid();
  }

  @override
  void didUpdateWidget(_DesktopGrid old) {
    super.didUpdateWidget(old);
    final subjectChanged = old.subject.id != widget.subject.id;
    final studentListChanged = old.students.length != widget.students.length;

    if (subjectChanged || studentListChanged) {
      _buildGrid();
      try {
        _stateManager.removeAllRows();
        _stateManager.appendRows(_rows);
      } catch (_) {
        // _stateManager not initialized yet by PlutoGrid onLoaded callback
      }
    }
  }

  void _buildGrid() {
    final lang = widget.lang;

    _columns = [
      PlutoColumn(
        title: 'roll'.tr(lang),
        field: 'roll',
        type: PlutoColumnType.number(),
        width: 80,
        enableEditingMode: false,
        textAlign: PlutoColumnTextAlign.center,
        titleTextAlign: PlutoColumnTextAlign.center,
      ),
      PlutoColumn(
        title: 'studentName'.tr(lang),
        field: 'name',
        type: PlutoColumnType.text(),
        width: 200,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: lang == 'bn' ? 'পূর্ণমান' : 'Max Marks',
        field: 'maxMarks',
        type: PlutoColumnType.number(),
        width: 90,
        enableEditingMode: false,
        textAlign: PlutoColumnTextAlign.center,
        titleTextAlign: PlutoColumnTextAlign.center,
      ),
      PlutoColumn(
        title: lang == 'bn' ? 'সর্বোচ্চ' : 'Topper',
        field: 'topperMarks',
        type: PlutoColumnType.number(format: '#'),
        width: 95,
        enableEditingMode: false,
        textAlign: PlutoColumnTextAlign.center,
        titleTextAlign: PlutoColumnTextAlign.center,
      ),
      PlutoColumn(
        title: 'obtainedMarks'.tr(lang),
        field: 'marks',
        type: PlutoColumnType.number(format: '#'),
        width: 140,
        textAlign: PlutoColumnTextAlign.right,
        titleTextAlign: PlutoColumnTextAlign.right,
      ),
      PlutoColumn(
        title: 'grade'.tr(lang),
        field: 'grade',
        type: PlutoColumnType.text(),
        width: 90,
        enableEditingMode: false,
        textAlign: PlutoColumnTextAlign.center,
        titleTextAlign: PlutoColumnTextAlign.center,
      ),
      PlutoColumn(
        title: 'gpa'.tr(lang),
        field: 'gpa',
        type: PlutoColumnType.number(format: '#.##'),
        width: 90,
        enableEditingMode: false,
        textAlign: PlutoColumnTextAlign.center,
        titleTextAlign: PlutoColumnTextAlign.center,
      ),
      PlutoColumn(
        title: 'status'.tr(lang),
        field: 'status',
        type: PlutoColumnType.text(),
        width: 120,
        enableEditingMode: false,
        textAlign: PlutoColumnTextAlign.center,
        titleTextAlign: PlutoColumnTextAlign.center,
        renderer: (rendererContext) {
          final isPass = rendererContext.cell.value == 'PASS';
          return Container(
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isPass
                    ? const Color(0xFF16A34A).withValues(alpha: 0.15)
                    : const Color(0xFFDC2626).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isPass ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                ),
              ),
              child: Text(
                isPass
                    ? (lang == 'bn' ? 'উত্তীর্ণ' : 'PASS')
                    : (lang == 'bn' ? 'অনুত্তীর্ণ' : 'FAIL'),
                style: TextStyle(
                  color: isPass ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    ];

    double highestMark = 0.0;
    for (final v in widget.marksDraft.values) {
      if (v > highestMark) highestMark = v;
    }

    _rows = widget.students.map((st) {
      final obtained = widget.marksDraft[st.id] ?? 0.0;
      final gradeRes =
          GradingEngine.getGradeAndGPA(obtained, widget.subject.fullMarks);
      final isPass = obtained >= widget.subject.passMarks;

      return PlutoRow(
        cells: {
          'id': PlutoCell(value: st.id),
          'roll': PlutoCell(value: st.roll),
          'name': PlutoCell(value: st.name),
          'maxMarks': PlutoCell(value: widget.subject.fullMarks.toInt()),
          'topperMarks': PlutoCell(value: highestMark > 0 ? highestMark : '-'),
          'marks': PlutoCell(value: obtained),
          'grade': PlutoCell(value: gradeRes.letterGrade),
          'gpa': PlutoCell(value: gradeRes.gradePoint),
          'status': PlutoCell(value: isPass ? 'PASS' : 'FAIL'),
        },
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PlutoGrid(
      columns: _columns,
      rows: _rows,
      onLoaded: (event) {
        _stateManager = event.stateManager;
        _stateManager.setSelectingMode(PlutoGridSelectingMode.cell);
      },
      onChanged: (event) {
        if (event.column.field == 'marks') {
          final row = event.row;
          final studentId = row.cells['id']!.value as String;
          final newMarks = double.tryParse(event.value.toString()) ?? 0.0;

          if (newMarks > widget.subject.fullMarks) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  widget.lang == 'bn'
                      ? 'প্রাপ্ত নম্বর পূর্ণমান (${widget.subject.fullMarks.toInt()}) এর চেয়ে বেশি হতে পারে না'
                      : 'Marks cannot exceed full marks (${widget.subject.fullMarks.toInt()})',
                ),
                backgroundColor: const Color(0xFFDC2626),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          }

          final clamped = newMarks.clamp(0.0, widget.subject.fullMarks);
          row.cells['marks']!.value = clamped.toInt();

          widget.onMarksChanged(studentId, clamped);

          final gradeRes =
              GradingEngine.getGradeAndGPA(clamped, widget.subject.fullMarks);
          final isPass = clamped >= widget.subject.passMarks;

          row.cells['grade']!.value = gradeRes.letterGrade;
          row.cells['gpa']!.value = gradeRes.gradePoint;
          row.cells['status']!.value = isPass ? 'PASS' : 'FAIL';
          _stateManager.notifyListeners();
          _stateManager.moveCurrentCell(PlutoMoveDirection.down);
        }
      },
      configuration: PlutoGridConfiguration(
        style: PlutoGridStyleConfig(
          gridBackgroundColor: cs.surface,
          rowColor: cs.surface,
          cellTextStyle: TextStyle(color: cs.onSurface, fontSize: 13),
          columnTextStyle: TextStyle(
              color: cs.onSurface, fontWeight: FontWeight.bold, fontSize: 13),
          borderColor: cs.outlineVariant.withValues(alpha: 0.5),
          activatedBorderColor: cs.primary,
          gridBorderColor: cs.outlineVariant.withValues(alpha: 0.5),
        ),
        shortcut: const PlutoGridShortcut(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mobile ListView
// ─────────────────────────────────────────────────────────────────────────────

class _MobileListView extends StatefulWidget {
  const _MobileListView({
    required this.students,
    required this.subject,
    required this.marksDraft,
    required this.lang,
    required this.onMarksChanged,
  });

  final List<StudentModel> students;
  final SubjectModel subject;
  final Map<String, double> marksDraft;
  final String lang;
  final void Function(String studentId, double val) onMarksChanged;

  @override
  State<_MobileListView> createState() => _MobileListViewState();
}

class _MobileListViewState extends State<_MobileListView> {
  final List<FocusNode> _focusNodes = [];

  @override
  void initState() {
    super.initState();
    _updateFocusNodes();
  }

  @override
  void didUpdateWidget(_MobileListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.students.length != widget.students.length) {
      _updateFocusNodes();
    }
  }

  void _updateFocusNodes() {
    for (var f in _focusNodes) {
      f.dispose();
    }
    _focusNodes.clear();
    for (int i = 0; i < widget.students.length; i++) {
      _focusNodes.add(FocusNode());
    }
  }

  @override
  void dispose() {
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 80),
      itemCount: widget.students.length,
      itemBuilder: (context, i) {
        final st = widget.students[i];
        final obtained = widget.marksDraft[st.id] ?? 0.0;
        final isLast = i == widget.students.length - 1;
        final nextFocus = isLast ? null : (_focusNodes.length > i + 1 ? _focusNodes[i + 1] : null);

        return _MobileMarkCard(
          key: ValueKey('${st.id}_${widget.subject.id}'),
          student: st,
          subject: widget.subject,
          obtained: obtained,
          lang: widget.lang,
          focusNode: _focusNodes.length > i ? _focusNodes[i] : null,
          nextFocusNode: nextFocus,
          isLastItem: isLast,
          onChanged: (val) => widget.onMarksChanged(st.id, val),
        );
      },
    );
  }
}

class _MobileMarkCard extends StatefulWidget {
  const _MobileMarkCard({
    super.key,
    required this.student,
    required this.subject,
    required this.obtained,
    required this.lang,
    required this.onChanged,
    this.focusNode,
    this.nextFocusNode,
    this.isLastItem = false,
  });

  final StudentModel student;
  final SubjectModel subject;
  final double obtained;
  final String lang;
  final ValueChanged<double> onChanged;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final bool isLastItem;

  @override
  State<_MobileMarkCard> createState() => _MobileMarkCardState();
}

class _MobileMarkCardState extends State<_MobileMarkCard> {
  late TextEditingController _controller;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.obtained == 0.0
          ? ''
          : (widget.obtained % 1 == 0
              ? widget.obtained.toInt().toString()
              : widget.obtained.toString()),
    );
    widget.focusNode?.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = widget.focusNode?.hasFocus ?? false;
      });
    }
  }

  @override
  void didUpdateWidget(_MobileMarkCard old) {
    super.didUpdateWidget(old);
    if (old.obtained != widget.obtained && !_isFocused) {
      _controller.text = widget.obtained == 0.0
          ? ''
          : (widget.obtained % 1 == 0
              ? widget.obtained.toInt().toString()
              : widget.obtained.toString());
    }
    if (old.focusNode != widget.focusNode) {
      old.focusNode?.removeListener(_onFocusChange);
      widget.focusNode?.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_onFocusChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final obtained = double.tryParse(_controller.text) ?? 0.0;
    final isPassed = obtained >= widget.subject.passMarks;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: _isFocused
            ? cs.primaryContainer.withValues(alpha: 0.15)
            : cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isFocused
              ? cs.primary
              : cs.outlineVariant.withValues(alpha: 0.4),
          width: _isFocused ? 1.8 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            // Roll badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                GradingEngine.formatInt(widget.student.roll, widget.lang),
                style: TextStyle(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Student Name
            Expanded(
              child: Text(
                widget.student.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            // Marks Input Box (single line)
            SizedBox(
              width: 95,
              height: 40,
              child: TextFormField(
                focusNode: widget.focusNode,
                controller: _controller,
                textInputAction: widget.isLastItem ? TextInputAction.done : TextInputAction.next,
                onFieldSubmitted: (_) {
                  if (widget.nextFocusNode != null) {
                    widget.nextFocusNode!.requestFocus();
                  }
                },
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
                decoration: InputDecoration(
                  hintText: '0',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  suffixText: '/${widget.subject.fullMarks.toInt()}',
                  suffixStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
                  filled: true,
                  fillColor: cs.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: cs.primary, width: 1.8),
                  ),
                ),
                onChanged: (val) {
                  final parsed = double.tryParse(val) ?? 0.0;
                  final clamped = parsed.clamp(0.0, widget.subject.fullMarks);
                  widget.onChanged(clamped);
                  setState(() {});
                },
              ),
            ),
            const SizedBox(width: 6),
            // Pass / Fail status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isPassed
                    ? const Color(0xFF16A34A).withValues(alpha: 0.12)
                    : const Color(0xFFDC2626).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isPassed ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                ),
              ),
              child: Text(
                isPassed
                    ? (widget.lang == 'bn' ? 'পাস' : 'PASS')
                    : (widget.lang == 'bn' ? 'ফেল' : 'FAIL'),
                style: TextStyle(
                  color: isPassed ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Save Bottom Bar
// ─────────────────────────────────────────────────────────────────────────────

class _SaveBottomBar extends StatelessWidget {
  const _SaveBottomBar({
    required this.lang,
    required this.isSaving,
    required this.studentCount,
    required this.onSave,
  });

  final String lang;
  final bool isSaving;
  final int studentCount;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5))),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            onPressed: isSaving ? null : onSave,
            icon: isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save_rounded, size: 20),
            label: Text(
              isSaving
                  ? (lang == 'bn' ? 'সংরক্ষণ করা হচ্ছে...' : 'Saving...')
                  : (lang == 'bn'
                      ? '$studentCount জন শিক্ষার্থীর সকল নম্বর সংরক্ষণ করুন'
                      : 'Save All Marks ($studentCount students)'),
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
    );
  }
}
