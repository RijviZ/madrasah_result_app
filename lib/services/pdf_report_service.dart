// Stage 8 — PDF Report Card Service
// Generates A4 PDF marksheets with shaped Bangla via bangla_pdf_fixer (ANSI/Kalpurush)
// and English via pw.Text with NotoSansBengali document theme.

import 'package:bangla_pdf_fixer/bangla_pdf_fixer.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/mark_model.dart';
import '../models/student_model.dart';
import '../models/subject_model.dart';
import '../utils/grading_engine.dart';

class PdfReportService {
  PdfReportService._();

  /// Whether the BanglaFontManager has been pre-loaded.
  static bool _fontsInitialized = false;

  /// Pre-loads all bangla_pdf_fixer bundled Kalpurush/ANSI fonts.
  /// Must be called once before generating any PDF.
  static Future<void> _ensureBanglaFonts() async {
    if (!_fontsInitialized) {
      await BanglaFontManager().initialize();
      _fontsInitialized = true;
    }
  }

  static Future<pw.ThemeData> _loadPdfTheme() async {
    pw.Font fontRegular;
    pw.Font fontBold;

    try {
      final regularData = await rootBundle.load('assets/fonts/NotoSansBengali-Regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/NotoSansBengali-Bold.ttf');
      fontRegular = pw.Font.ttf(regularData);
      fontBold = pw.Font.ttf(boldData);
    } catch (_) {
      try {
        fontRegular = await PdfGoogleFonts.notoSansBengaliRegular();
        fontBold = await PdfGoogleFonts.notoSansBengaliBold();
      } catch (_) {
        try {
          fontRegular = await PdfGoogleFonts.hindSiliguriRegular();
          fontBold = await PdfGoogleFonts.hindSiliguriBold();
        } catch (_) {
          fontRegular = pw.Font.helvetica();
          fontBold = pw.Font.helveticaBold();
        }
      }
    }

    return pw.ThemeData.withFont(
      base: fontRegular,
      bold: fontBold,
      fontFallback: [fontRegular, fontBold],
    );
  }

  static final _bnRe = RegExp(r'[\u0980-\u09FF]');

  /// Renders mixed Bengali/English text.
  /// - Pure Bengali words → [BanglaText] from bangla_pdf_fixer (ANSI-encoded Kalpurush font, fixed reshaper)
  /// - All-Latin/numeric text → [pw.Text] with document-theme font (NotoSansBengali)
  /// - Mixed tokens are split at space boundaries and stacked in a [pw.Row]
  static pw.Widget _bn(
    String text,
    double fontSize, {
    bool bold = false,
    PdfColor? color,
    pw.TextAlign textAlign = pw.TextAlign.left,
  }) {
    if (text.isEmpty) return pw.SizedBox.shrink();

    final fw = bold ? pw.FontWeight.bold : pw.FontWeight.normal;
    final style = pw.TextStyle(
      fontSize: fontSize,
      fontWeight: fw,
      color: color,
    );

    // No Bengali at all → fast path
    if (!_bnRe.hasMatch(text)) {
      return pw.Text(text, textAlign: textAlign, style: style);
    }

    // All Bengali (no Latin) → single BanglaText
    final latinRe = RegExp(r'[A-Za-z0-9]');
    if (!latinRe.hasMatch(text)) {
      return BanglaText(
        text,
        fontSize: fontSize,
        fontWeight: fw,
        color: color ?? PdfColors.black,
        textAlign: textAlign,
      );
    }

    // Mixed: split by spaces, render each token appropriately
    final tokens = text.split(' ');
    final children = <pw.Widget>[];
    for (final tok in tokens) {
      if (tok.isEmpty) continue;
      if (_bnRe.hasMatch(tok)) {
        children.add(BanglaText(
          tok,
          fontSize: fontSize,
          fontWeight: fw,
          color: color ?? PdfColors.black,
        ));
      } else {
        children.add(pw.Text(tok, style: style));
      }
      children.add(pw.SizedBox(width: fontSize * 0.25));
    }
    if (children.isNotEmpty) children.removeLast(); // remove trailing spacer

    if (children.length == 1) return children.first;

    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: children,
    );
  }

  /// Generates an A4 PDF document bytes for a student's report card.
  static Future<Uint8List> generateReportCard({
    required StudentModel student,
    required String examType,
    required List<SubjectModel> subjects,
    required List<MarkModel> marks,
    required String langCode,
    int? classPosition,
    int? sectionPosition,
  }) async {
    await _ensureBanglaFonts();
    final theme = await _loadPdfTheme();
    final pdf = pw.Document(theme: theme);

    // Build subject-wise results
    final List<double> gpaList = [];
    final List<double> marksList = [];
    final List<double> passMarksList = [];

    final List<Map<String, dynamic>> subjectRows = [];

    for (final subject in subjects) {
      final markModel = marks.firstWhere(
        (m) => m.subjectId == subject.id && m.studentId == student.id && m.examType == examType,
        orElse: () => MarkModel(
          studentId: student.id,
          subjectId: subject.id,
          examType: examType,
          obtainedMarks: 0,
        ),
      );

      // Calculate topper mark in class for this subject
      double topperMark = 0.0;
      final subjectMarks = marks.where((m) => m.subjectId == subject.id && m.examType == examType);
      if (subjectMarks.isNotEmpty) {
        topperMark = subjectMarks.map((m) => m.obtainedMarks).fold(0.0, (prev, val) => val > prev ? val : prev);
      }

      final obtained = markModel.obtainedMarks;
      final gradeRes = GradingEngine.getGradeAndGPA(obtained, subject.fullMarks);

      gpaList.add(gradeRes.gradePoint);
      marksList.add(obtained);
      passMarksList.add(subject.passMarks);

      subjectRows.add({
        'code': subject.subjectCode,
        'name': subject.subjectName,
        'fullMarks': subject.fullMarks,
        'passMarks': subject.passMarks,
        'topperMarks': topperMark,
        'obtainedMarks': obtained,
        'grade': gradeRes.letterGrade,
        'gpa': gradeRes.gradePoint,
      });
    }

    final finalResult = gpaList.isEmpty
        ? const FinalResult(
            overallGPA: 0,
            finalGrade: 'F',
            totalObtainedMarks: 0,
            totalFullMarks: 0,
            isPassed: false,
          )
        : GradingEngine.calculateFinalResult(
            gpaList: gpaList,
            marksList: marksList,
            passMarksList: passMarksList,
            subjects: subjects,
          );

    final isBn = langCode == 'bn';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // ── Header Section ───────────────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.teal900,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    _bn(
                      'হাজী আলতাফ হোসেন হরিন্দীয়া আলিম মাদ্রাসা',
                      17,
                      bold: true,
                      color: PdfColors.white,
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 2),
                    _bn(
                      'Haji Altaf Hossen Horindia Alim Madrasah',
                      12,
                      bold: true,
                      color: PdfColors.teal100,
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 4),
                    _bn(
                      isBn
                          ? 'ডাকঘর: হরিন্দীয়া, ইউনিয়ন: কুশনা, থানা: কোটচাঁদপুর, জেলা: ঝিনাইদহ, বিভাগ: খুলনা'
                          : 'P.O: Horindia, Union: Kushna, Upazila: Kotchandpur, Dist: Jhenaidah, Div: Khulna',
                      9,
                      color: PdfColors.white,
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 3),
                    _bn(
                      isBn
                          ? 'ইআইআইএন (EIIN): ১১৬৬৬৪   |   মোবাইল: ০১৭১৬৮৭৫০৫১   |   পর্যায়: আলিম (মাদ্রাসা)'
                          : 'EIIN: 116664   |   Mobile: 01716875051   |   Level: Alim (Madrasah)',
                      9,
                      bold: true,
                      color: PdfColors.teal100,
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 6),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(12),
                      ),
                      child: _bn(
                        '${isBn ? "নম্বরপত্র / একাডেমিক ট্রান্সক্রিপ্ট" : "Academic Transcript"} ($examType - ${GradingEngine.toBanglaNumeral('2026', langCode)})',
                        11,
                        bold: true,
                        color: PdfColors.teal900,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // ── Student Info Box ─────────────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.teal700, width: 1),
                  borderRadius: pw.BorderRadius.circular(6),
                  color: PdfColors.teal50,
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _bn(
                          '${isBn ? "শিক্ষার্থীর নাম" : "Student Name"}: ${student.name}',
                          11,
                          bold: true,
                        ),
                        pw.SizedBox(height: 4),
                        _bn(
                          '${isBn ? "শ্রেণী" : "Class"}: ${student.className}   |   ${isBn ? "শাখা" : "Section"}: ${student.section}',
                          10,
                        ),
                        if (classPosition != null) ...[
                          pw.SizedBox(height: 3),
                          _bn(
                            '${isBn ? "মেধা স্থান" : "Class Rank"}: ${GradingEngine.formatInt(classPosition, langCode)}',
                            10,
                            bold: true,
                            color: PdfColors.teal900,
                          ),
                        ],
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        _bn(
                          '${isBn ? "রোল নম্বর" : "Roll No"}: ${GradingEngine.formatInt(student.roll, langCode)}',
                          11,
                          bold: true,
                        ),
                        pw.SizedBox(height: 4),
                        _bn(
                          'ID: ${student.id.length > 8 ? student.id.substring(0, 8).toUpperCase() : student.id.toUpperCase()}',
                          9,
                          color: PdfColors.grey800,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // ── Marks Details Table ──────────────────────────────────────
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.8),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1.0), // Code
                  1: const pw.FlexColumnWidth(2.8), // Subject Name
                  2: const pw.FlexColumnWidth(1.0), // Full Marks
                  3: const pw.FlexColumnWidth(1.0), // Pass Marks
                  4: const pw.FlexColumnWidth(1.1), // Topper Marks
                  5: const pw.FlexColumnWidth(1.3), // Obtained
                  6: const pw.FlexColumnWidth(0.9), // Grade
                  7: const pw.FlexColumnWidth(0.9), // GPA
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.teal800),
                    children: [
                      _buildHeaderCell(isBn ? 'কোড' : 'Code'),
                      _buildHeaderCell(isBn ? 'বিষয়ের নাম' : 'Subject Name'),
                      _buildHeaderCell(isBn ? 'পূর্ণমান' : 'Full'),
                      _buildHeaderCell(isBn ? 'পাস' : 'Pass'),
                      _buildHeaderCell(isBn ? 'সর্বোচ্চ' : 'Topper'),
                      _buildHeaderCell(isBn ? 'প্রাপ্ত নম্বর' : 'Obtained'),
                      _buildHeaderCell(isBn ? 'গ্রেড' : 'Grade'),
                      _buildHeaderCell(isBn ? 'জিপিএ' : 'GPA'),
                    ],
                  ),
                  // Table Rows
                  ...subjectRows.map((row) {
                    final double obt = row['obtainedMarks'];
                    final double passM = row['passMarks'];
                    final bool isFail = obt < passM;

                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: isFail ? PdfColors.red50 : PdfColors.white,
                      ),
                      children: [
                        _buildDataCell(row['code'].toString(), alignCenter: true),
                        _buildDataCell(row['name'].toString()),
                        _buildDataCell(GradingEngine.formatInt((row['fullMarks'] as double).toInt(), langCode), alignCenter: true),
                        _buildDataCell(GradingEngine.formatInt((row['passMarks'] as double).toInt(), langCode), alignCenter: true),
                        _buildDataCell(GradingEngine.formatInt((row['topperMarks'] as double).toInt(), langCode), alignCenter: true),
                        _buildDataCell(
                          GradingEngine.formatInt((row['obtainedMarks'] as double).toInt(), langCode),
                          bold: true,
                          alignCenter: true,
                          color: isFail ? PdfColors.red800 : PdfColors.black,
                        ),
                        _buildDataCell(
                          row['grade'].toString(),
                          bold: true,
                          alignCenter: true,
                          color: isFail ? PdfColors.red800 : PdfColors.teal900,
                        ),
                        _buildDataCell(
                          GradingEngine.formatNumber(row['gpa'], langCode),
                          alignCenter: true,
                        ),
                      ],
                    );
                  }),
                ],
              ),

              pw.SizedBox(height: 16),

              // ── Summary Box ──────────────────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: finalResult.isPassed ? PdfColors.green50 : PdfColors.red50,
                  border: pw.Border.all(
                    color: finalResult.isPassed ? PdfColors.green700 : PdfColors.red700,
                    width: 1.2,
                  ),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _bn(
                          '${isBn ? "মোট প্রাপ্ত নম্বর" : "Total Obtained Marks"}: ${GradingEngine.formatInt(finalResult.totalObtainedMarks.toInt(), langCode)} / ${GradingEngine.formatInt(finalResult.totalFullMarks.toInt(), langCode)}',
                          11,
                          bold: true,
                        ),
                        pw.SizedBox(height: 4),
                        _bn(
                          isBn
                              ? 'সর্বমোট জিপিএ: ${GradingEngine.formatNumber(finalResult.overallGPA, langCode)}   |   প্রাপ্ত গ্রেড: ${finalResult.finalGrade}'
                              : 'Overall GPA: ${GradingEngine.formatNumber(finalResult.overallGPA, langCode)}   |   Grade: ${finalResult.finalGrade}',
                          11,
                          bold: true,
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: pw.BoxDecoration(
                        color: finalResult.isPassed ? PdfColors.green700 : PdfColors.red700,
                        borderRadius: pw.BorderRadius.circular(16),
                      ),
                      child: _bn(
                        finalResult.isPassed
                            ? (isBn ? 'উত্তীর্ণ / PASSED' : 'PASSED')
                            : (isBn ? 'অনুত্তীর্ণ / FAILED' : 'FAILED'),
                        12,
                        bold: true,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // ── Signatures Section ────────────────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 130,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(top: pw.BorderSide(color: PdfColors.grey700, width: 1)),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      _bn(
                        isBn ? 'শ্রেণী শিক্ষকের স্বাক্ষর' : 'Class Teacher Signature',
                        10,
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 130,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(top: pw.BorderSide(color: PdfColors.grey700, width: 1)),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      _bn(
                        isBn ? 'অধ্যক্ষ / সুপারিনটেনডেন্ট' : 'Principal / Superintendent',
                        10,
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: _bn(
                  isBn ? 'কম্পিউটার দ্বারা প্রস্তুতকৃত রেজাল্ট শিট' : 'Generated by Madrasah Result App',
                  8,
                  color: PdfColors.grey600,
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Triggers instant print preview / browser print / pdf download modal.
  static Future<void> printReportCard({
    required StudentModel student,
    required String examType,
    required List<SubjectModel> subjects,
    required List<MarkModel> marks,
    required String langCode,
    int? classPosition,
    int? sectionPosition,
  }) async {
    final pdfBytes = await generateReportCard(
      student: student,
      examType: examType,
      subjects: subjects,
      marks: marks,
      langCode: langCode,
      classPosition: classPosition,
      sectionPosition: sectionPosition,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Marksheet_${student.name.replaceAll(" ", "_")}_${student.roll}',
    );
  }

  /// Generates and prints a 1-click Class Tabulation / Merit List Summary Sheet PDF.
  static Future<Uint8List> printClassTabulationSheet({
    required String className,
    required String examType,
    required List<StudentModel> students,
    required List<SubjectModel> subjects,
    required List<MarkModel> marks,
    required String langCode,
    void Function(int processed, int total)? onProgress,
  }) async {
    await _ensureBanglaFonts();
    final theme = await _loadPdfTheme();
    final pdf = pw.Document(theme: theme);
    final isBn = langCode == 'bn';

    final ranks = GradingEngine.calculateStudentRanks(
      classStudents: students,
      subjects: subjects,
      allMarks: marks,
      examType: examType,
    );

    final sortedStudents = List<StudentModel>.from(students);
    sortedStudents.sort((a, b) {
      final rankA = ranks[a.id]?.classPosition ?? 9999;
      final rankB = ranks[b.id]?.classPosition ?? 9999;
      if (rankA != rankB) return rankA.compareTo(rankB);
      return a.roll.compareTo(b.roll);
    });

    final tableRowsWidget = <pw.TableRow>[];
    int passCount = 0;
    int failCount = 0;

    // Header Row
    tableRowsWidget.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.teal800),
        children: [
          _buildHeaderCell(isBn ? 'স্থান' : 'Rank'),
          _buildHeaderCell(isBn ? 'রোল' : 'Roll'),
          _buildHeaderCell(isBn ? 'শিক্ষার্থীর নাম' : 'Student Name'),
          _buildHeaderCell(isBn ? 'শাখা' : 'Sec'),
          _buildHeaderCell(isBn ? 'মোট নম্বর' : 'Total Marks'),
          _buildHeaderCell(isBn ? 'জিপিএ' : 'GPA'),
          _buildHeaderCell(isBn ? 'গ্রেড' : 'Grade'),
          _buildHeaderCell(isBn ? 'ফলাফল' : 'Status'),
        ],
      ),
    );

    for (int i = 0; i < sortedStudents.length; i++) {
      final st = sortedStudents[i];
      onProgress?.call(i + 1, sortedStudents.length);
      await Future<void>.delayed(Duration.zero);
      final rank = ranks[st.id]?.classPosition ?? 0;
      final List<double> gpas = [];
      final List<double> marksList = [];
      final List<double> passMarksList = [];

      for (final sub in subjects) {
        final markModel = marks.firstWhere(
          (m) => m.studentId == st.id && m.subjectId == sub.id && m.examType == examType,
          orElse: () => MarkModel(studentId: st.id, subjectId: sub.id, examType: examType, obtainedMarks: 0),
        );
        final gradeRes = GradingEngine.getGradeAndGPA(markModel.obtainedMarks, sub.fullMarks);
        gpas.add(gradeRes.gradePoint);
        marksList.add(markModel.obtainedMarks);
        passMarksList.add(sub.passMarks);
      }

      final res = subjects.isEmpty
          ? const FinalResult(overallGPA: 0, finalGrade: 'F', totalObtainedMarks: 0, totalFullMarks: 0, isPassed: false)
          : GradingEngine.calculateFinalResult(gpaList: gpas, marksList: marksList, passMarksList: passMarksList, subjects: subjects);

      if (res.isPassed) {
        passCount++;
      } else {
        failCount++;
      }

      final isEven = i % 2 == 0;

      tableRowsWidget.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(color: isEven ? PdfColors.white : PdfColors.grey100),
          children: [
            _buildDataCell(GradingEngine.formatInt(rank, langCode), alignCenter: true),
            _buildDataCell(GradingEngine.formatInt(st.roll, langCode), alignCenter: true),
            _buildDataCell(st.name),
            _buildDataCell(st.section, alignCenter: true),
            _buildDataCell(
              '${GradingEngine.formatInt(res.totalObtainedMarks.toInt(), langCode)} / ${GradingEngine.formatInt(res.totalFullMarks.toInt(), langCode)}',
              alignCenter: true,
            ),
            _buildDataCell(GradingEngine.formatNumber(res.overallGPA, langCode), alignCenter: true),
            _buildDataCell(res.finalGrade, alignCenter: true, bold: true),
            _buildDataCell(
              res.isPassed ? (isBn ? 'পাস' : 'PASS') : (isBn ? 'ফেল' : 'FAIL'),
              alignCenter: true,
              bold: true,
              color: res.isPassed ? PdfColors.green800 : PdfColors.red800,
            ),
          ],
        ),
      );
    }

    final totalCount = sortedStudents.length;
    final passRate = totalCount > 0 ? ((passCount / totalCount) * 100).toStringAsFixed(1) : '0';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            // Header
            pw.Container(
              alignment: pw.Alignment.center,
              padding: const pw.EdgeInsets.only(bottom: 12),
              child: pw.Column(
                children: [
                  _bn('হাজী আলতাফ হোসেন হরিন্দীয়া আলিম মাদ্রাসা', 16, bold: true, color: PdfColors.teal900),
                  pw.SizedBox(height: 2),
                  _bn('ডাকঘর: হরিন্দীয়া, ইউনিয়ন: কুশনা, কোটচাঁদপুর, ঝিনাইদহ', 9, color: PdfColors.grey700),
                  pw.SizedBox(height: 8),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.teal800,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: _bn(
                      '${isBn ? "শ্রেণীভিত্তিক সামগ্রিক ফলাফল ও মেধা তালিকা" : "Class Merit List & Result Summary"} ($examType - ${GradingEngine.toBanglaNumeral("2026", langCode)})',
                      11,
                      bold: true,
                      color: PdfColors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Class info bar
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const pw.EdgeInsets.only(bottom: 10),
              decoration: pw.BoxDecoration(
                color: PdfColors.teal50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.teal700, width: 0.5),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _bn('${isBn ? "শ্রেণী" : "Class"}: $className', 10, bold: true),
                  _bn('${isBn ? "মোট শিক্ষার্থী" : "Total"}: ${GradingEngine.formatInt(totalCount, langCode)}', 10, bold: true),
                  _bn('${isBn ? "কৃতকার্য" : "Passed"}: ${GradingEngine.formatInt(passCount, langCode)}', 10, bold: true, color: PdfColors.green800),
                  _bn('${isBn ? "অকৃতকার্য" : "Failed"}: ${GradingEngine.formatInt(failCount, langCode)}', 10, bold: true, color: PdfColors.red800),
                  _bn('${isBn ? "পাসের হার" : "Pass Rate"}: ${GradingEngine.toBanglaNumeral(passRate, langCode)}%', 10, bold: true),
                ],
              ),
            ),

            // Results Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(35),
                1: const pw.FixedColumnWidth(35),
                2: const pw.FlexColumnWidth(3),
                3: const pw.FixedColumnWidth(35),
                4: const pw.FixedColumnWidth(75),
                5: const pw.FixedColumnWidth(40),
                6: const pw.FixedColumnWidth(40),
                7: const pw.FixedColumnWidth(45),
              },
              children: tableRowsWidget,
            ),
          ];
        },
      ),
    );

    return await pdf.save();
  }

  // ── Helper Table Cell Builders ─────────────────────────────────────────────

  static pw.Widget _buildHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: _bn(
        text,
        9,
        bold: true,
        color: PdfColors.white,
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildDataCell(
    String text, {
    bool bold = false,
    bool alignCenter = false,
    PdfColor color = PdfColors.black,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: _bn(
        text,
        9,
        bold: bold,
        color: color,
        textAlign: alignCenter ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }
}
