// Grading Engine — Stage 3 & Stage 8
// Provides grade calculation utilities, combined paper (1st+2nd) pass rules, and bilingual numeral conversion.

import '../models/mark_model.dart';
import '../models/student_model.dart';
import '../models/subject_model.dart';

// ---------------------------------------------------------------------------
// Data classes
// ---------------------------------------------------------------------------

/// Holds the letter grade and grade point for a single subject attempt.
class GradeResult {
  final String letterGrade;
  final double gradePoint;

  const GradeResult({
    required this.letterGrade,
    required this.gradePoint,
  });

  @override
  String toString() => 'GradeResult(letterGrade: $letterGrade, gradePoint: $gradePoint)';
}

/// Holds the aggregated final result for a student across all subjects.
class FinalResult {
  final double overallGPA;
  final String finalGrade;
  final double totalObtainedMarks;
  final double totalFullMarks;

  /// `false` if ANY uncombined subject has obtainedMarks < passMark, or combined paper pair < 66.
  final bool isPassed;

  const FinalResult({
    required this.overallGPA,
    required this.finalGrade,
    required this.totalObtainedMarks,
    required this.totalFullMarks,
    required this.isPassed,
  });

  @override
  String toString() =>
      'FinalResult(overallGPA: $overallGPA, finalGrade: $finalGrade, '
      'totalObtained: $totalObtainedMarks, totalFull: $totalFullMarks, isPassed: $isPassed)';
}

/// Holds the merit rank of a student in class and section.
class StudentRank {
  final int classPosition;
  final int sectionPosition;

  const StudentRank({
    required this.classPosition,
    required this.sectionPosition,
  });

  @override
  String toString() => 'StudentRank(classPosition: $classPosition, sectionPosition: $sectionPosition)';
}

// ---------------------------------------------------------------------------
// Grading Engine
// ---------------------------------------------------------------------------

/// Stateless utility class providing grade computation and numeral helpers.
class GradingEngine {
  GradingEngine._(); // prevent instantiation

  // ── Grade scale ──────────────────────────────────────────────────────────
  // Percentage  │ Letter Grade │ Grade Point
  // ≥ 80%       │ A+           │ 5.00
  // ≥ 70%       │ A            │ 4.00
  // ≥ 60%       │ A-           │ 3.50
  // ≥ 50%       │ B            │ 3.00
  // ≥ 40%       │ C            │ 2.00
  // ≥ 33%       │ D            │ 1.00
  // <  33%      │ F            │ 0.00

  /// Returns [GradeResult] for the given [marks] out of [fullMarks].
  ///
  /// Throws [ArgumentError] if [fullMarks] ≤ 0.
  static GradeResult getGradeAndGPA(double marks, double fullMarks) {
    if (fullMarks <= 0) {
      throw ArgumentError('fullMarks must be greater than 0, got $fullMarks');
    }

    // Clamp marks to valid range
    final clamped = marks.clamp(0.0, fullMarks);
    final percentage = (clamped / fullMarks) * 100.0;

    if (percentage >= 80.0) return const GradeResult(letterGrade: 'A+', gradePoint: 5.00);
    if (percentage >= 70.0) return const GradeResult(letterGrade: 'A', gradePoint: 4.00);
    if (percentage >= 60.0) return const GradeResult(letterGrade: 'A-', gradePoint: 3.50);
    if (percentage >= 50.0) return const GradeResult(letterGrade: 'B', gradePoint: 3.00);
    if (percentage >= 40.0) return const GradeResult(letterGrade: 'C', gradePoint: 2.00);
    if (percentage >= 33.0) return const GradeResult(letterGrade: 'D', gradePoint: 1.00);
    return const GradeResult(letterGrade: 'F', gradePoint: 0.00);
  }

  /// Calculates the aggregate final result for a student.
  ///
  /// Parameters:
  /// - [gpaList]       : GPA per subject (derived from [getGradeAndGPA])
  /// - [marksList]     : Obtained marks per subject
  /// - [passMarksList] : Minimum pass marks per subject
  /// - [subjects]      : Optional subject models for 1st+2nd paper combined pass rule calculation
  ///
  /// `isPassed` is `false` if any uncombined subject fails, or any 1st+2nd combined pair fails.
  static FinalResult calculateFinalResult({
    required List<double> gpaList,
    required List<double> marksList,
    required List<double> passMarksList,
    List<double>? fullMarksList,
    List<SubjectModel>? subjects,
  }) {
    if (gpaList.isEmpty) {
      throw ArgumentError('gpaList must not be empty');
    }
    if (gpaList.length != marksList.length || marksList.length != passMarksList.length) {
      throw ArgumentError(
        'gpaList, marksList and passMarksList must have the same length. '
        'Got ${gpaList.length}, ${marksList.length}, ${passMarksList.length}',
      );
    }

    // Overall GPA is the arithmetic mean of subject GPAs
    final double totalGPA = gpaList.fold(0.0, (sum, gpa) => sum + gpa);
    final double overallGPA = double.parse((totalGPA / gpaList.length).toStringAsFixed(2));

    // Total marks
    final double totalObtained = marksList.fold(0.0, (sum, m) => sum + m);
    final double totalFull = (subjects != null && subjects.isNotEmpty)
        ? subjects.fold(0.0, (sum, s) => sum + s.fullMarks)
        : (fullMarksList != null && fullMarksList.isNotEmpty
            ? fullMarksList.fold(0.0, (sum, f) => sum + f)
            : passMarksList.length * 100.0);

    bool isPassed = true;

    // Evaluate 1st + 2nd combined subject paper pairs if subjects list is provided
    if (subjects != null && subjects.length == marksList.length) {
      final processedIndices = <int>{};

      for (int i = 0; i < subjects.length; i++) {
        if (processedIndices.contains(i)) continue;

        final sub1 = subjects[i];

        // Check if subject belongs to a combined 1st+2nd paper pair (e.g. English 1st & 2nd)
        final pairGroup = _detectCombinedGroup(sub1);

        if (pairGroup != null) {
          // Find matching second paper in the list
          int pairIdx = -1;
          for (int j = i + 1; j < subjects.length; j++) {
            if (!processedIndices.contains(j) && _detectCombinedGroup(subjects[j]) == pairGroup) {
              pairIdx = j;
              break;
            }
          }

          if (pairIdx != -1) {
            processedIndices.add(i);
            processedIndices.add(pairIdx);

            final combinedMarks = marksList[i] + marksList[pairIdx];
            final combinedPassMarks = passMarksList[i] + passMarksList[pairIdx]; // e.g. 33 + 33 = 66 out of 200

            if (combinedMarks < combinedPassMarks) {
              isPassed = false;
            }
            continue;
          }
        }

        // Single / non-combined subject check
        processedIndices.add(i);
        if (marksList[i] < passMarksList[i] || gpaList[i] == 0.0) {
          isPassed = false;
        }
      }
    } else {
      // Standard single-subject pass evaluation
      for (int i = 0; i < marksList.length; i++) {
        if (marksList[i] < passMarksList[i] || gpaList[i] == 0.0) {
          isPassed = false;
          break;
        }
      }
    }

    // Derive final grade from overall GPA
    final String finalGrade = _gradeFromGPA(overallGPA);

    return FinalResult(
      overallGPA: overallGPA,
      finalGrade: finalGrade,
      totalObtainedMarks: totalObtained,
      totalFullMarks: totalFull,
      isPassed: isPassed,
    );
  }

  /// Computes Class Position & Section Position for all students in a class.
  static Map<String, StudentRank> calculateStudentRanks({
    required List<StudentModel> classStudents,
    required List<SubjectModel> subjects,
    required List<MarkModel> allMarks,
    required String examType,
  }) {
    final Map<String, FinalResult> studentResults = {};

    for (final st in classStudents) {
      final List<double> gpas = [];
      final List<double> marksList = [];
      final List<double> passMarksList = [];

      for (final sub in subjects) {
        final markModel = allMarks.firstWhere(
          (m) => m.studentId == st.id && m.subjectId == sub.id && m.examType == examType,
          orElse: () => MarkModel(studentId: st.id, subjectId: sub.id, examType: examType, obtainedMarks: 0),
        );
        final gradeRes = getGradeAndGPA(markModel.obtainedMarks, sub.fullMarks);
        gpas.add(gradeRes.gradePoint);
        marksList.add(markModel.obtainedMarks);
        passMarksList.add(sub.passMarks);
      }

      final result = subjects.isEmpty
          ? const FinalResult(overallGPA: 0, finalGrade: 'F', totalObtainedMarks: 0, totalFullMarks: 0, isPassed: false)
          : calculateFinalResult(gpaList: gpas, marksList: marksList, passMarksList: passMarksList, subjects: subjects);

      studentResults[st.id] = result;
    }

    // Sort class students for Class Position
    final sortedClassStudents = List<StudentModel>.from(classStudents);
    sortedClassStudents.sort((a, b) {
      final resA = studentResults[a.id]!;
      final resB = studentResults[b.id]!;

      if (resA.isPassed != resB.isPassed) {
        return resA.isPassed ? -1 : 1;
      }
      if (resA.totalObtainedMarks != resB.totalObtainedMarks) {
        return resB.totalObtainedMarks.compareTo(resA.totalObtainedMarks);
      }
      if (resA.overallGPA != resB.overallGPA) {
        return resB.overallGPA.compareTo(resA.overallGPA);
      }
      return a.roll.compareTo(b.roll);
    });

    final Map<String, int> classPosMap = {};
    for (int i = 0; i < sortedClassStudents.length; i++) {
      classPosMap[sortedClassStudents[i].id] = i + 1;
    }

    // Group students by section for Section Position
    final Map<String, List<StudentModel>> sectionGroups = {};
    for (final st in classStudents) {
      final sec = st.section.trim().isEmpty ? 'Default' : st.section.trim();
      sectionGroups.putIfAbsent(sec, () => []).add(st);
    }

    final Map<String, int> secPosMap = {};
    for (final secList in sectionGroups.values) {
      secList.sort((a, b) {
        final resA = studentResults[a.id]!;
        final resB = studentResults[b.id]!;

        if (resA.isPassed != resB.isPassed) {
          return resA.isPassed ? -1 : 1;
        }
        if (resA.totalObtainedMarks != resB.totalObtainedMarks) {
          return resB.totalObtainedMarks.compareTo(resA.totalObtainedMarks);
        }
        if (resA.overallGPA != resB.overallGPA) {
          return resB.overallGPA.compareTo(resA.overallGPA);
        }
        return a.roll.compareTo(b.roll);
      });

      for (int i = 0; i < secList.length; i++) {
        secPosMap[secList[i].id] = i + 1;
      }
    }

    final Map<String, StudentRank> ranks = {};
    for (final st in classStudents) {
      ranks[st.id] = StudentRank(
        classPosition: classPosMap[st.id] ?? 1,
        sectionPosition: secPosMap[st.id] ?? 1,
      );
    }

    return ranks;
  }

  /// Helper to detect if a subject is part of a 1st & 2nd paper combined pair
  static String? _detectCombinedGroup(SubjectModel sub) {
    if (sub.isCombinedSubject && sub.combinedPairGroup != null) {
      return sub.combinedPairGroup;
    }
    final name = sub.subjectName.toLowerCase();
    if (name.contains('বাংলা') || name.contains('bangla')) return 'bangla';
    if (name.contains('ইংরেজ') || name.contains('english')) return 'english';
    if (name.contains('আরব') || name.contains('arabic')) return 'arabic';
    return null;
  }

  // ── Numeral helpers ───────────────────────────────────────────────────────

  /// Maps each English digit character to its Bangla Unicode equivalent.
  static const Map<String, String> _banglaDigits = {
    '0': '০',
    '1': '১',
    '2': '২',
    '3': '৩',
    '4': '৪',
    '5': '৫',
    '6': '৬',
    '7': '৭',
    '8': '৮',
    '9': '৯',
  };

  /// Converts all English digits (0–9) in [input] to Bangla digits (০–৯)
  /// **only** when [langCode] is `'bn'`. Returns [input] unchanged otherwise.
  static String toBanglaNumeral(String input, String langCode) {
    if (langCode != 'bn') return input;
    final buffer = StringBuffer();
    for (final ch in input.runes) {
      final char = String.fromCharCode(ch);
      buffer.write(_banglaDigits[char] ?? char);
    }
    return buffer.toString();
  }

  /// Convenience: converts a [double] to its localized string representation.
  static String formatNumber(double value, String langCode, {int decimals = 2}) {
    final raw = value.toStringAsFixed(decimals);
    return toBanglaNumeral(raw, langCode);
  }

  /// Convenience: converts an [int] to its localized string representation.
  static String formatInt(int value, String langCode) {
    return toBanglaNumeral(value.toString(), langCode);
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  static String _gradeFromGPA(double gpa) {
    if (gpa >= 5.00) return 'A+';
    if (gpa >= 4.00) return 'A';
    if (gpa >= 3.50) return 'A-';
    if (gpa >= 3.00) return 'B';
    if (gpa >= 2.00) return 'C';
    if (gpa >= 1.00) return 'D';
    return 'F';
  }
}
