// Madrasah Standard Class Structure & Presets
// Categorized by Ebtedayi (Primary), Dakhil (Secondary), and Alim (Higher Secondary).

class MadrasahClassCategory {
  final String titleBn;
  final String titleEn;
  final List<MadrasahClassInfo> classes;

  const MadrasahClassCategory({
    required this.titleBn,
    required this.titleEn,
    required this.classes,
  });
}

class MadrasahClassInfo {
  final String nameBn;
  final String nameEn;
  final String code;

  const MadrasahClassInfo({
    required this.nameBn,
    required this.nameEn,
    required this.code,
  });
}

class MadrasahClasses {
  MadrasahClasses._();

  static const List<MadrasahClassCategory> categories = [
    MadrasahClassCategory(
      titleBn: 'প্রাথমিক শিক্ষা (ইবতেদায়ী)',
      titleEn: 'Primary Education (Ebtedayi)',
      classes: [
        MadrasahClassInfo(nameBn: 'প্রথম শ্রেণি', nameEn: 'Class 1', code: 'ebt_1'),
        MadrasahClassInfo(nameBn: 'দ্বিতীয় শ্রেণি', nameEn: 'Class 2', code: 'ebt_2'),
        MadrasahClassInfo(nameBn: 'তৃতীয় শ্রেণি', nameEn: 'Class 3', code: 'ebt_3'),
        MadrasahClassInfo(nameBn: 'চতুর্থ শ্রেণি', nameEn: 'Class 4', code: 'ebt_4'),
        MadrasahClassInfo(nameBn: 'পঞ্চম শ্রেণি', nameEn: 'Class 5', code: 'ebt_5'),
      ],
    ),
    MadrasahClassCategory(
      titleBn: 'নিম্ন মাধ্যমিক ও মাধ্যমিক শিক্ষা (দাখিল)',
      titleEn: 'Secondary Education (Dakhil)',
      classes: [
        MadrasahClassInfo(nameBn: 'ষষ্ঠ শ্রেণি', nameEn: 'Class 6', code: 'dak_6'),
        MadrasahClassInfo(nameBn: 'সপ্তম শ্রেণি', nameEn: 'Class 7', code: 'dak_7'),
        MadrasahClassInfo(nameBn: 'অষ্টম শ্রেণি', nameEn: 'Class 8', code: 'dak_8'),
        MadrasahClassInfo(nameBn: 'নবম শ্রেণি', nameEn: 'Class 9', code: 'dak_9'),
        MadrasahClassInfo(nameBn: 'দশম শ্রেণি', nameEn: 'Class 10', code: 'dak_10'),
      ],
    ),
    MadrasahClassCategory(
      titleBn: 'উচ্চ মাধ্যমিক শিক্ষা (আলিম)',
      titleEn: 'Higher Secondary Education (Alim)',
      classes: [
        MadrasahClassInfo(nameBn: 'আলিম ১ম বর্ষ', nameEn: 'Alim 1st Year', code: 'alm_1'),
        MadrasahClassInfo(nameBn: 'আলিম ২য় বর্ষ', nameEn: 'Alim 2nd Year', code: 'alm_2'),
      ],
    ),
  ];

  /// Flat list of all preset class names in Bangla.
  static List<String> get allClassNamesBn {
    final List<String> names = [];
    for (final cat in categories) {
      for (final cls in cat.classes) {
        names.add(cls.nameBn);
      }
    }
    return names;
  }

  /// Flat list of all preset class names in English.
  static List<String> get allClassNamesEn {
    final List<String> names = [];
    for (final cat in categories) {
      for (final cls in cat.classes) {
        names.add(cls.nameEn);
      }
    }
    return names;
  }

  /// Returns preset class names matching current active language code.
  static List<String> classNames(String langCode) {
    return langCode == 'bn' ? allClassNamesBn : allClassNamesEn;
  }
}
