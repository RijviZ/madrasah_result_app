import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'mark_model.g.dart';

@HiveType(typeId: 2)
class MarkModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String studentId;

  @HiveField(2)
  final String subjectId;

  @HiveField(3)
  final String examType;

  @HiveField(4)
  final double obtainedMarks;

  @HiveField(5)
  final bool isSynced;

  @HiveField(6)
  final DateTime updatedAt;

  @HiveField(7)
  final double writtenMarks;

  @HiveField(8)
  final double mcqMarks;

  MarkModel({
    String? id,
    required this.studentId,
    required this.subjectId,
    required this.examType,
    required this.obtainedMarks,
    this.writtenMarks = 0.0,
    this.mcqMarks = 0.0,
    this.isSynced = false,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        updatedAt = updatedAt ?? DateTime.now();

  MarkModel copyWith({
    String? id,
    String? studentId,
    String? subjectId,
    String? examType,
    double? obtainedMarks,
    double? writtenMarks,
    double? mcqMarks,
    bool? isSynced,
    DateTime? updatedAt,
  }) {
    return MarkModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      subjectId: subjectId ?? this.subjectId,
      examType: examType ?? this.examType,
      obtainedMarks: obtainedMarks ?? this.obtainedMarks,
      writtenMarks: writtenMarks ?? this.writtenMarks,
      mcqMarks: mcqMarks ?? this.mcqMarks,
      isSynced: isSynced ?? this.isSynced,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'subject_id': subjectId,
      'exam_type': examType,
      'obtained_marks': obtainedMarks,
      'written_marks': writtenMarks,
      'mcq_marks': mcqMarks,
      'is_synced': isSynced,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory MarkModel.fromJson(Map<String, dynamic> json) {
    final double obt = (json['obtained_marks'] as num?)?.toDouble() ?? (json['obtainedMarks'] as num?)?.toDouble() ?? 0.0;
    final double w = (json['written_marks'] as num?)?.toDouble() ?? (json['writtenMarks'] as num?)?.toDouble() ?? 0.0;
    final double m = (json['mcq_marks'] as num?)?.toDouble() ?? (json['mcqMarks'] as num?)?.toDouble() ?? 0.0;

    return MarkModel(
      id: json['id'] as String?,
      studentId: json['student_id'] as String? ?? json['studentId'] as String? ?? '',
      subjectId: json['subject_id'] as String? ?? json['subjectId'] as String? ?? '',
      examType: json['exam_type'] as String? ?? json['examType'] as String? ?? '',
      obtainedMarks: obt > 0 ? obt : (w + m),
      writtenMarks: w,
      mcqMarks: m,
      isSynced: json['is_synced'] as bool? ?? json['isSynced'] as bool? ?? false,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : (json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : DateTime.now()),
    );
  }
}
