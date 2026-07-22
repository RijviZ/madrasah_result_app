// Standard Madrasah Subject Presets & Utility
// Contains official Bangladesh Madrasah Education Board Dakhil / Alim subject names, codes, mark types, and combined paper rules.

class MadrasahSubjectItem {
  final String nameBn;
  final String nameEn;
  final String code;
  final double fullMarks;
  final double passMarks;
  final String markType; // 'written_only', 'mcq_only', 'written_mcq'
  final double writtenFullMarks;
  final double writtenPassMarks;
  final double mcqFullMarks;
  final double mcqPassMarks;
  final bool isCombinedSubject;
  final String? combinedPairGroup; // 'bangla', 'english', 'arabic'
  final bool isElective;

  const MadrasahSubjectItem({
    required this.nameBn,
    required this.nameEn,
    required this.code,
    this.fullMarks = 100,
    this.passMarks = 33,
    this.markType = 'written_only',
    this.writtenFullMarks = 100,
    this.writtenPassMarks = 33,
    this.mcqFullMarks = 0,
    this.mcqPassMarks = 0,
    this.isCombinedSubject = false,
    this.combinedPairGroup,
    this.isElective = false,
  });
}

class MadrasahSubjects {
  MadrasahSubjects._();

  static const List<MadrasahSubjectItem> presets = [
    // ── Compulsory Subjects (আবশ্যিক বিষয়) ──────────────────────────────────
    MadrasahSubjectItem(
      nameBn: 'কোরআন মাজীদ ও তাজবীদ',
      nameEn: 'Quran Majid & Tajwid',
      code: '101',
      markType: 'written_only',
      fullMarks: 100,
      passMarks: 33,
    ),
    MadrasahSubjectItem(
      nameBn: 'হাদীস শরীফ',
      nameEn: 'Hadith Sharif',
      code: '102',
      markType: 'written_only',
      fullMarks: 100,
      passMarks: 33,
    ),
    MadrasahSubjectItem(
      nameBn: 'আকাইদ ও ফিকহ',
      nameEn: 'Aqaid & Fiqh',
      code: '103',
      markType: 'written_only',
      fullMarks: 100,
      passMarks: 33,
    ),
    MadrasahSubjectItem(
      nameBn: 'বাংলা ১ম পত্র',
      nameEn: 'Bangla 1st Paper',
      code: '104',
      markType: 'written_mcq',
      fullMarks: 100,
      passMarks: 33,
      writtenFullMarks: 70,
      writtenPassMarks: 23,
      mcqFullMarks: 30,
      mcqPassMarks: 10,
      isCombinedSubject: true,
      combinedPairGroup: 'bangla',
    ),
    MadrasahSubjectItem(
      nameBn: 'বাংলা ২য় পত্র',
      nameEn: 'Bangla 2nd Paper',
      code: '105',
      markType: 'written_mcq',
      fullMarks: 100,
      passMarks: 33,
      writtenFullMarks: 70,
      writtenPassMarks: 23,
      mcqFullMarks: 30,
      mcqPassMarks: 10,
      isCombinedSubject: true,
      combinedPairGroup: 'bangla',
    ),
    MadrasahSubjectItem(
      nameBn: 'ইংরেজি ১ম পত্র',
      nameEn: 'English 1st Paper',
      code: '107',
      markType: 'written_only',
      fullMarks: 100,
      passMarks: 33,
      isCombinedSubject: true,
      combinedPairGroup: 'english',
    ),
    MadrasahSubjectItem(
      nameBn: 'ইংরেজি ২য় পত্র',
      nameEn: 'English 2nd Paper',
      code: '108',
      markType: 'written_only',
      fullMarks: 100,
      passMarks: 33,
      isCombinedSubject: true,
      combinedPairGroup: 'english',
    ),
    MadrasahSubjectItem(
      nameBn: 'গণিত',
      nameEn: 'Mathematics',
      code: '109',
      markType: 'written_mcq',
      fullMarks: 100,
      passMarks: 33,
      writtenFullMarks: 70,
      writtenPassMarks: 23,
      mcqFullMarks: 30,
      mcqPassMarks: 10,
    ),
    MadrasahSubjectItem(
      nameBn: 'তথ্য ও যোগাযোগ প্রযুক্তি',
      nameEn: 'ICT',
      code: '154',
      markType: 'mcq_only',
      fullMarks: 50,
      passMarks: 17,
      mcqFullMarks: 25,
      mcqPassMarks: 8,
    ),

    // ── Elective & Additional Subjects (ঐচ্ছিক ও অতিরিক্ত বিষয়) ─────────────
    MadrasahSubjectItem(
      nameBn: 'ইসলামি ইতিহাস',
      nameEn: 'Islamic History',
      code: '106',
      markType: 'written_only',
      fullMarks: 100,
      passMarks: 33,
      isElective: true,
    ),
    MadrasahSubjectItem(
      nameBn: 'মানতিক',
      nameEn: 'Mantiq',
      code: '112',
      markType: 'written_only',
      fullMarks: 100,
      passMarks: 33,
      isElective: true,
    ),
    MadrasahSubjectItem(
      nameBn: 'উচ্চতর গণিত',
      nameEn: 'Higher Mathematics',
      code: '114',
      markType: 'written_mcq',
      fullMarks: 100,
      passMarks: 33,
      writtenFullMarks: 75,
      writtenPassMarks: 25,
      mcqFullMarks: 25,
      mcqPassMarks: 8,
      isElective: true,
    ),
    MadrasahSubjectItem(
      nameBn: 'শারীরিক শিক্ষা ও স্বাস্থ্য',
      nameEn: 'Physical Education & Health',
      code: '133',
      markType: 'written_only',
      fullMarks: 50,
      passMarks: 17,
      isElective: true,
    ),
    MadrasahSubjectItem(
      nameBn: 'কৃষি শিক্ষা',
      nameEn: 'Agriculture Studies',
      code: '134',
      markType: 'written_mcq',
      fullMarks: 100,
      passMarks: 33,
      writtenFullMarks: 75,
      writtenPassMarks: 25,
      mcqFullMarks: 25,
      mcqPassMarks: 8,
      isElective: true,
    ),
    MadrasahSubjectItem(
      nameBn: 'পদার্থবিজ্ঞান',
      nameEn: 'Physics',
      code: '136',
      markType: 'written_mcq',
      fullMarks: 100,
      passMarks: 33,
      writtenFullMarks: 75,
      writtenPassMarks: 25,
      mcqFullMarks: 25,
      mcqPassMarks: 8,
      isElective: true,
    ),
    MadrasahSubjectItem(
      nameBn: 'রসায়ন',
      nameEn: 'Chemistry',
      code: '137',
      markType: 'written_mcq',
      fullMarks: 100,
      passMarks: 33,
      writtenFullMarks: 75,
      writtenPassMarks: 25,
      mcqFullMarks: 25,
      mcqPassMarks: 8,
      isElective: true,
    ),
    MadrasahSubjectItem(
      nameBn: 'জীববিজ্ঞান',
      nameEn: 'Biology',
      code: '138',
      markType: 'written_mcq',
      fullMarks: 100,
      passMarks: 33,
      writtenFullMarks: 75,
      writtenPassMarks: 25,
      mcqFullMarks: 25,
      mcqPassMarks: 8,
      isElective: true,
    ),
    MadrasahSubjectItem(
      nameBn: 'গার্হস্থ্য বিজ্ঞান',
      nameEn: 'Home Science',
      code: '151',
      markType: 'written_mcq',
      fullMarks: 100,
      passMarks: 33,
      writtenFullMarks: 75,
      writtenPassMarks: 25,
      mcqFullMarks: 25,
      mcqPassMarks: 8,
      isElective: true,
    ),
    MadrasahSubjectItem(
      nameBn: 'ক্যারিয়ার শিক্ষা',
      nameEn: 'Career Education',
      code: '156',
      markType: 'written_only',
      fullMarks: 50,
      passMarks: 17,
      isElective: true,
    ),
  ];

  static List<String> presetNames(String langCode) {
    return presets.map((s) => langCode == 'bn' ? s.nameBn : s.nameEn).toList();
  }

  static MadrasahSubjectItem? findByCode(String code) {
    try {
      return presets.firstWhere((s) => s.code == code);
    } catch (_) {
      return null;
    }
  }

  static MadrasahSubjectItem? findByName(String name) {
    try {
      return presets.firstWhere(
        (s) => s.nameBn == name || s.nameEn == name,
      );
    } catch (_) {
      return null;
    }
  }
}
