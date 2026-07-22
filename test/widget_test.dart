import 'package:flutter_test/flutter_test.dart';
import 'package:madrasah_result_app/models/mark_model.dart';
import 'package:madrasah_result_app/models/student_model.dart';
import 'package:madrasah_result_app/models/subject_model.dart';
import 'package:madrasah_result_app/services/pdf_report_service.dart';
import 'package:madrasah_result_app/utils/grading_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GradingEngine', () {
    test('A+ grade for >= 80%', () {
      final result = GradingEngine.getGradeAndGPA(90, 100);
      expect(result.letterGrade, 'A+');
      expect(result.gradePoint, 5.00);
    });

    test('A grade for >= 70%', () {
      final result = GradingEngine.getGradeAndGPA(75, 100);
      expect(result.letterGrade, 'A');
      expect(result.gradePoint, 4.00);
    });

    test('A- grade for >= 60%', () {
      final result = GradingEngine.getGradeAndGPA(65, 100);
      expect(result.letterGrade, 'A-');
      expect(result.gradePoint, 3.50);
    });

    test('B grade for >= 50%', () {
      final result = GradingEngine.getGradeAndGPA(55, 100);
      expect(result.letterGrade, 'B');
      expect(result.gradePoint, 3.00);
    });

    test('C grade for >= 40%', () {
      final result = GradingEngine.getGradeAndGPA(45, 100);
      expect(result.letterGrade, 'C');
      expect(result.gradePoint, 2.00);
    });

    test('D grade for >= 33%', () {
      final result = GradingEngine.getGradeAndGPA(33, 100);
      expect(result.letterGrade, 'D');
      expect(result.gradePoint, 1.00);
    });

    test('F grade for < 33%', () {
      final result = GradingEngine.getGradeAndGPA(20, 100);
      expect(result.letterGrade, 'F');
      expect(result.gradePoint, 0.00);
    });

    test('calculateFinalResult - all passed', () {
      final result = GradingEngine.calculateFinalResult(
        gpaList: [5.0, 4.0, 3.5],
        marksList: [90, 75, 65],
        passMarksList: [33, 33, 33],
      );
      expect(result.isPassed, true);
      expect(result.totalObtainedMarks, 230);
      expect(result.overallGPA, closeTo(4.17, 0.01));
    });

    test('calculateFinalResult - fails if any mark < passMark', () {
      final result = GradingEngine.calculateFinalResult(
        gpaList: [5.0, 0.0, 4.0],
        marksList: [90, 20, 75],
        passMarksList: [33, 33, 33],
      );
      expect(result.isPassed, false);
    });

    test('calculateFinalResult - passes 1st+2nd combined paper if total >= 66', () {
      final eng1 = SubjectModel(
        subjectCode: '108',
        subjectName: 'English 1st Paper',
        className: 'Class 6',
        fullMarks: 100,
        passMarks: 33,
        isCombinedSubject: true,
        combinedPairGroup: 'english',
      );
      final eng2 = SubjectModel(
        subjectCode: '109',
        subjectName: 'English 2nd Paper',
        className: 'Class 6',
        fullMarks: 100,
        passMarks: 33,
        isCombinedSubject: true,
        combinedPairGroup: 'english',
      );

      final result = GradingEngine.calculateFinalResult(
        gpaList: [3.0, 1.0], // Eng1 (50) -> B (3.0), Eng2 (20) -> F (0.0)
        marksList: [50.0, 20.0],
        passMarksList: [33.0, 33.0],
        subjects: [eng1, eng2],
      );

      // Combined 50 + 20 = 70 >= 66 -> Passed!
      expect(result.isPassed, true);
      expect(result.totalObtainedMarks, 70.0);
    });

    test('toBanglaNumeral converts digits in bn locale', () {
      expect(GradingEngine.toBanglaNumeral('5.00', 'bn'), '৫.০০');
      expect(GradingEngine.toBanglaNumeral('5.00', 'en'), '5.00');
    });

    test('formatInt uses Bangla numerals when bn', () {
      expect(GradingEngine.formatInt(42, 'bn'), '৪২');
      expect(GradingEngine.formatInt(42, 'en'), '42');
    });

    test('throws ArgumentError for zero fullMarks', () {
      expect(
        () => GradingEngine.getGradeAndGPA(50, 0),
        throwsArgumentError,
      );
    });
  });

  group('PdfReportService', () {
    test('generateReportCard returns valid PDF bytes', () async {
      final student = StudentModel(
        id: 'test-student-1',
        name: 'আব্দুল্লাহ',
        roll: 1,
        className: 'Class 6',
        section: 'A',
      );

      final subject = SubjectModel(
        id: 'test-subject-1',
        subjectCode: '101',
        subjectName: 'Quran Majeed',
        className: 'Class 6',
        fullMarks: 100,
        passMarks: 33,
      );

      final mark = MarkModel(
        studentId: student.id,
        subjectId: subject.id,
        examType: 'Half Yearly',
        obtainedMarks: 85,
      );

      final pdfBytes = await PdfReportService.generateReportCard(
        student: student,
        examType: 'Half Yearly',
        subjects: [subject],
        marks: [mark],
        langCode: 'bn',
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.isNotEmpty, true);
    });
  });
}
