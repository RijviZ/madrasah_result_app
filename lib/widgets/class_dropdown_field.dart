// Class Selector Widget for Madrasah Education Levels
// Displays categorized dropdown items for ইবতেদায়ী, দাখিল, and আলিম.

import 'package:flutter/material.dart';
import '../l10n/app_translations.dart';
import '../utils/madrasah_classes.dart';

class ClassDropdownField extends StatelessWidget {
  const ClassDropdownField({
    super.key,
    required this.selectedClass,
    required this.onChanged,
    required this.lang,
    this.labelText,
    this.isDense = true,
    this.fillColor,
    this.customClasses = const [],
  });

  final String? selectedClass;
  final ValueChanged<String?> onChanged;
  final String lang;
  final String? labelText;
  final bool isDense;
  final Color? fillColor;
  final List<String> customClasses;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Collect all unique preset class names
    final presetNames = MadrasahClasses.allClassNamesBn.toSet();
    final additionalCustom = customClasses.where((c) => !presetNames.contains(c)).toList();

    return DropdownButtonFormField<String>(
      initialValue: selectedClass,
      onChanged: onChanged,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: labelText ?? 'class'.tr(lang),
        prefixIcon: const Icon(Icons.class_rounded, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: isDense,
        filled: true,
        fillColor: fillColor ?? cs.surfaceContainerLow,
      ),
      validator: (v) => v == null || v.trim().isEmpty
          ? (lang == 'bn' ? 'শ্রেণী নির্বাচন করুন' : 'Select class')
          : null,
      items: [
        // ── Categorized Preset Madrasah Classes ──────────────────────────────
        for (final category in MadrasahClasses.categories) ...[
          DropdownMenuItem<String>(
            enabled: false,
            value: 'category_${category.titleBn}',
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                lang == 'bn' ? category.titleBn : category.titleEn,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: cs.primary,
                ),
              ),
            ),
          ),
          for (final cls in category.classes)
            DropdownMenuItem<String>(
              value: cls.nameBn,
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  lang == 'bn' ? cls.nameBn : '${cls.nameBn} (${cls.nameEn})',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
        ],

        // ── Additional Custom Classes from Database ──────────────────────────
        if (additionalCustom.isNotEmpty) ...[
          DropdownMenuItem<String>(
            enabled: false,
            value: 'category_custom',
            child: Text(
              lang == 'bn' ? 'অন্যান্য শ্রেণী' : 'Other Classes',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: cs.primary,
              ),
            ),
          ),
          for (final customName in additionalCustom)
            DropdownMenuItem<String>(
              value: customName,
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(customName, style: const TextStyle(fontSize: 13)),
              ),
            ),
        ],
      ],
    );
  }
}
