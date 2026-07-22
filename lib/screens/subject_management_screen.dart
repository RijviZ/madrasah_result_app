// Stage 7 — Subject Management Screen (Premium UI Refresh)
// Gradient header, animated subject groups with AnimatedSize,
// colored subject code badges, improved dialogs.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_translations.dart';
import '../models/subject_model.dart';
import '../providers/locale_provider.dart';
import '../providers/repository_providers.dart';
import '../utils/madrasah_classes.dart';
import '../utils/madrasah_subjects.dart';
import '../widgets/app_pagination_bar.dart';
import '../widgets/class_dropdown_field.dart';
import '../widgets/screen_header.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Subject Management Screen
// ─────────────────────────────────────────────────────────────────────────────

class SubjectManagementScreen extends ConsumerStatefulWidget {
  const SubjectManagementScreen({super.key});

  @override
  ConsumerState<SubjectManagementScreen> createState() =>
      _SubjectManagementScreenState();
}

class _SubjectManagementScreenState
    extends ConsumerState<SubjectManagementScreen> {
  int _currentPage = 1;
  int _pageSize = 20;

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider).languageCode;
    final subjects = ref.watch(subjectRepositoryProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final totalCount = subjects.length;
    final totalPages = (totalCount / _pageSize).ceil();
    final safePage = _currentPage.clamp(1, totalPages > 0 ? totalPages : 1);
    final startIndex = (safePage - 1) * _pageSize;
    final paginatedSubjects = subjects.skip(startIndex).take(_pageSize).toList();

    // Group subjects by class name
    final Map<String, List<SubjectModel>> grouped = {};
    for (final s in paginatedSubjects) {
      grouped.putIfAbsent(s.className, () => []).add(s);
    }
    final sortedClasses = grouped.keys.toList()..sort();

    return Scaffold(
      body: Column(
        children: [
          // ── Gradient Page Header ─────────────────────────────────────────
          GradientPageHeader(
            icon: Icons.menu_book_rounded,
            title: lang == 'bn' ? 'বিষয় ব্যবস্থাপনা' : 'Subject Management',
            subtitle: lang == 'bn'
                ? 'মাদ্রাসার বিষয়সমূহ পরিচালনা করুন'
                : 'Manage Madrasah subjects by class',
            badge: lang == 'bn'
                ? '${subjects.length}টি বিষয়'
                : '${subjects.length} subjects',
            trailing: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _autoAddPresetSubjects(context, ref, lang: lang),
                    icon: const Icon(Icons.auto_awesome_rounded,
                        color: Colors.white, size: 20),
                    tooltip: lang == 'bn'
                        ? 'প্রিসেট বিষয় যোগ করুন'
                        : 'Auto-Add Presets',
                  ),
                  FilledButton.icon(
                    onPressed: () =>
                        _openSubjectForm(context, ref, lang: lang),
                    icon: const Icon(Icons.add_rounded,
                        size: 18, color: Colors.white),
                    label: Text(
                      lang == 'bn' ? 'যোগ করুন' : 'Add',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.22),
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),
            gradientColors: [const Color(0xFF6A1B9A), const Color(0xFF8E24AA)],
          ),

          // ── Content ──────────────────────────────────────────────────────
          Expanded(
            child: subjects.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.06),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.menu_book_rounded,
                              size: 52,
                              color: cs.primary.withValues(alpha: 0.25)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          lang == 'bn'
                              ? 'কোনো বিষয় যোগ করা হয়নি'
                              : 'No subjects added yet',
                          style: tt.bodyLarge?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.4)),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: [
                            FilledButton.icon(
                              onPressed: () =>
                                  _openSubjectForm(context, ref, lang: lang),
                              icon: const Icon(Icons.add_rounded),
                              label: Text(lang == 'bn'
                                  ? 'বিষয় যোগ করুন'
                                  : 'Add Subject'),
                            ),
                            FilledButton.tonalIcon(
                              onPressed: () => _autoAddPresetSubjects(context,
                                  ref, lang: lang),
                              icon: const Icon(
                                  Icons.playlist_add_check_rounded),
                              label: Text(lang == 'bn'
                                  ? 'সকল সাধারণ বিষয় একসাথে যোগ করুন'
                                  : 'Auto-Add Preset Subjects'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ...sortedClasses.asMap().entries.map((entry) {
                        final i = entry.key;
                        final cls = entry.value;
                        final classSubjects = grouped[cls]!
                          ..sort((a, b) =>
                              a.subjectCode.compareTo(b.subjectCode));
                        return StaggeredItem(
                          index: i,
                          delayMs: 60,
                          child: _ClassSubjectGroup(
                            className: cls,
                            subjects: classSubjects,
                            lang: lang,
                            onEdit: (sub) => _openSubjectForm(context, ref,
                                lang: lang, existing: sub),
                            onDelete: (sub) =>
                                _confirmDelete(context, ref, sub, lang),
                          ),
                        );
                      }),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: AppPaginationBar(
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
    );
  }

  void _openSubjectForm(
    BuildContext context,
    WidgetRef ref, {
    required String lang,
    SubjectModel? existing,
  }) {
    showDialog(
      context: context,
      builder: (_) => _SubjectFormDialog(
        existing: existing,
        lang: lang,
        onSave: (model) async {
          if (existing == null) {
            await ref
                .read(subjectRepositoryProvider.notifier)
                .addSubject(model);
          } else {
            await ref
                .read(subjectRepositoryProvider.notifier)
                .updateSubject(model);
          }
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _autoAddPresetSubjects(
    BuildContext context,
    WidgetRef ref, {
    required String lang,
  }) async {
    String selectedClass = MadrasahClasses.allClassNamesBn.first;

    final targetClass = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(lang == 'bn'
            ? 'প্রিসেট বিষয়সমূহ অটো-যোগ করুন'
            : 'Auto-Add Preset Subjects'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang == 'bn'
                  ? 'মাদ্রাসার ১৫টি সাধারণ বিষয় নির্বাচনকৃত শ্রেণীতে যুক্ত হবে:'
                  : 'All 15 standard Madrasah subjects will be added to:',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 14),
            StatefulBuilder(
              builder: (context, setDialogState) {
                return ClassDropdownField(
                  selectedClass: selectedClass,
                  lang: lang,
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedClass = val);
                    }
                  },
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('cancel'.tr(lang)),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, selectedClass),
            icon: const Icon(Icons.playlist_add_check_rounded),
            label: Text(lang == 'bn' ? 'যুক্ত করুন' : 'Add Presets'),
          ),
        ],
      ),
    );

    if (targetClass != null && context.mounted) {
      final repo = ref.read(subjectRepositoryProvider.notifier);
      final existingSubjects = repo.getSubjectsByClass(targetClass);
      final existingCodes = existingSubjects.map((s) => s.subjectCode).toSet();

      int addedCount = 0;
      for (final preset in MadrasahSubjects.presets) {
        if (!existingCodes.contains(preset.code)) {
          final sub = SubjectModel(
            subjectCode: preset.code,
            subjectName: lang == 'bn' ? preset.nameBn : preset.nameEn,
            className: targetClass,
            fullMarks: preset.fullMarks,
            passMarks: preset.passMarks,
          );
          await repo.addSubject(sub);
          addedCount++;
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lang == 'bn'
                  ? '$targetClass এ $addedCount টি প্রিসেট বিষয় সফলভাবে যুক্ত হয়েছে'
                  : 'Added $addedCount preset subject(s) to $targetClass',
            ),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    SubjectModel sub,
    String lang,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(lang == 'bn' ? 'নিশ্চিত করুন' : 'Confirm Delete'),
        content: Text(lang == 'bn'
            ? '${sub.subjectName} মুছে ফেলবেন?'
            : 'Delete ${sub.subjectName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr(lang)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            child: Text('delete'.tr(lang)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(subjectRepositoryProvider.notifier)
          .deleteSubject(sub.id);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Class group card — animated expand/collapse
// ─────────────────────────────────────────────────────────────────────────────

class _ClassSubjectGroup extends StatefulWidget {
  const _ClassSubjectGroup({
    required this.className,
    required this.subjects,
    required this.lang,
    required this.onEdit,
    required this.onDelete,
  });

  final String className;
  final List<SubjectModel> subjects;
  final String lang;
  final void Function(SubjectModel) onEdit;
  final void Function(SubjectModel) onDelete;

  @override
  State<_ClassSubjectGroup> createState() => _ClassSubjectGroupState();
}

class _ClassSubjectGroupState extends State<_ClassSubjectGroup> {
  bool _expanded = true;

  // Hash-based gradient for class name badge
  static List<Color> _classGradient(String name) {
    final palettes = [
      [const Color(0xFF006A4E), const Color(0xFF059669)],
      [const Color(0xFF1565C0), const Color(0xFF1E88E5)],
      [const Color(0xFF6A1B9A), const Color(0xFF8E24AA)],
      [const Color(0xFFE65100), const Color(0xFFEF6C00)],
      [const Color(0xFF0D7490), const Color(0xFF0891B2)],
    ];
    return palettes[name.length % palettes.length];
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final gradient = _classGradient(widget.className);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Class header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    gradient.first.withValues(alpha: 0.12),
                    gradient.last.withValues(alpha: 0.06),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Row(
                children: [
                  // Gradient class name badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: gradient.first.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      widget.className,
                      style: tt.labelMedium?.copyWith(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: gradient.first.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.lang == 'bn'
                          ? '${widget.subjects.length}টি বিষয়'
                          : '${widget.subjects.length} subjects',
                      style: tt.labelSmall?.copyWith(
                        color: gradient.first,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _expanded ? 0 : -0.25,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      Icons.keyboard_arrow_up_rounded,
                      color: gradient.first,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Animated subjects list
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOutCubic,
            child: _expanded
                ? Column(
                    children: widget.subjects.asMap().entries.map((entry) {
                      final i = entry.key;
                      final sub = entry.value;
                      final isLast = i == widget.subjects.length - 1;
                      return _SubjectRow(
                        subject: sub,
                        lang: widget.lang,
                        isLast: isLast,
                        accentColor: gradient.first,
                        onEdit: () => widget.onEdit(sub),
                        onDelete: () => widget.onDelete(sub),
                      );
                    }).toList(),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _SubjectRow extends StatelessWidget {
  const _SubjectRow({
    required this.subject,
    required this.lang,
    required this.isLast,
    required this.accentColor,
    required this.onEdit,
    required this.onDelete,
  });

  final SubjectModel subject;
  final String lang;
  final bool isLast;
  final Color accentColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.35))),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accentColor.withValues(alpha: 0.3)),
          ),
          child: Text(
            subject.subjectCode,
            style: tt.labelSmall?.copyWith(
              color: accentColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(subject.subjectName,
            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Row(
          children: [
            _MarksBadge(
              label:
                  lang == 'bn' ? 'পূর্ণ: ${subject.fullMarks.toInt()}' : 'Full: ${subject.fullMarks.toInt()}',
              color: const Color(0xFF1565C0),
            ),
            const SizedBox(width: 6),
            _MarksBadge(
              label:
                  lang == 'bn' ? 'পাস: ${subject.passMarks.toInt()}' : 'Pass: ${subject.passMarks.toInt()}',
              color: const Color(0xFF059669),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit_rounded, size: 19, color: cs.primary),
              onPressed: onEdit,
              tooltip: 'edit'.tr(lang),
            ),
            IconButton(
              icon: Icon(Icons.delete_rounded, size: 19, color: cs.error),
              onPressed: onDelete,
              tooltip: 'delete'.tr(lang),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarksBadge extends StatelessWidget {
  const _MarksBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 3),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add / Edit Subject Dialog
// ─────────────────────────────────────────────────────────────────────────────

class _SubjectFormDialog extends StatefulWidget {
  const _SubjectFormDialog({
    required this.lang,
    required this.onSave,
    this.existing,
  });

  final SubjectModel? existing;
  final String lang;
  final Future<void> Function(SubjectModel) onSave;

  @override
  State<_SubjectFormDialog> createState() => _SubjectFormDialogState();
}

class _SubjectFormDialogState extends State<_SubjectFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeCtrl;
  late TextEditingController _nameCtrl;
  late String _selectedClass;
  late TextEditingController _fullMarksCtrl;
  late TextEditingController _passMarksCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _codeCtrl = TextEditingController(text: e?.subjectCode ?? '');
    _nameCtrl = TextEditingController(text: e?.subjectName ?? '');
    _selectedClass = e?.className ?? MadrasahClasses.allClassNamesBn.first;
    _fullMarksCtrl =
        TextEditingController(text: e != null ? '${e.fullMarks.toInt()}' : '100');
    _passMarksCtrl =
        TextEditingController(text: e != null ? '${e.passMarks.toInt()}' : '33');
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _fullMarksCtrl.dispose();
    _passMarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final model = SubjectModel(
      id: widget.existing?.id,
      subjectCode: _codeCtrl.text.trim(),
      subjectName: _nameCtrl.text.trim(),
      className: _selectedClass,
      fullMarks: double.tryParse(_fullMarksCtrl.text.trim()) ?? 100,
      passMarks: double.tryParse(_passMarksCtrl.text.trim()) ?? 33,
    );
    await widget.onSave(model);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final isEdit = widget.existing != null;
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      title: Container(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Row(
          children: [
            Icon(
              isEdit ? Icons.edit_rounded : Icons.menu_book_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              isEdit
                  ? (lang == 'bn' ? 'বিষয় সম্পাদনা' : 'Edit Subject')
                  : (lang == 'bn' ? 'বিষয় যোগ করুন' : 'Add Subject'),
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ],
        ),
      ),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Preset Selector
              if (!isEdit) ...[
                DropdownButtonFormField<MadrasahSubjectItem>(
                  decoration: InputDecoration(
                    labelText: lang == 'bn'
                        ? 'প্রিসেট বিষয় থেকে নির্বাচন করুন (ঐচ্ছিক)'
                        : 'Select Subject Preset (Optional)',
                    prefixIcon: Icon(Icons.bookmark_added_rounded,
                        size: 18, color: cs.primary),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    isDense: true,
                    filled: true,
                    fillColor: cs.primaryContainer.withValues(alpha: 0.25),
                  ),
                  items: MadrasahSubjects.presets.map((item) {
                    final name = lang == 'bn'
                        ? item.nameBn
                        : '${item.nameBn} (${item.nameEn})';
                    return DropdownMenuItem(
                      value: item,
                      child: Text(name,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    );
                  }).toList(),
                  onChanged: (item) {
                    if (item != null) {
                      setState(() {
                        _nameCtrl.text =
                            lang == 'bn' ? item.nameBn : item.nameEn;
                        _codeCtrl.text = item.code;
                        _fullMarksCtrl.text = item.fullMarks.toInt().toString();
                        _passMarksCtrl.text = item.passMarks.toInt().toString();
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
              ],

              // Subject Name
              _DialogField(
                controller: _nameCtrl,
                label: 'subjectName'.tr(lang),
                icon: Icons.menu_book_rounded,
                validator: (v) => v == null || v.trim().isEmpty
                    ? (lang == 'bn' ? 'নাম লিখুন' : 'Enter name')
                    : null,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _DialogField(
                      controller: _codeCtrl,
                      label: 'subjectCode'.tr(lang),
                      icon: Icons.code_rounded,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? (lang == 'bn' ? 'কোড লিখুন' : 'Enter code')
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClassDropdownField(
                      selectedClass: _selectedClass,
                      lang: lang,
                      isDense: true,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedClass = val);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _DialogField(
                      controller: _fullMarksCtrl,
                      label: 'fullMarks'.tr(lang),
                      icon: Icons.bar_chart_rounded,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'))
                      ],
                      validator: (v) {
                        final val = double.tryParse(v ?? '');
                        if (val == null || val <= 0) {
                          return lang == 'bn' ? 'সঠিক মান দিন' : 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DialogField(
                      controller: _passMarksCtrl,
                      label: 'passMarks'.tr(lang),
                      icon: Icons.check_circle_outline_rounded,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'))
                      ],
                      validator: (v) {
                        final val = double.tryParse(v ?? '');
                        if (val == null || val < 0) {
                          return lang == 'bn' ? 'সঠিক মান দিন' : 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('cancel'.tr(lang)),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _submit,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.save_rounded, size: 18),
          label: Text('save'.tr(lang)),
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}

class _DialogField extends StatelessWidget {
  const _DialogField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
      ),
    );
  }
}
