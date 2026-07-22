import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'subject_model.g.dart';

@HiveType(typeId: 1)
class SubjectModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String subjectCode;

  @HiveField(2)
  final String subjectName;

  @HiveField(3)
  final String className;

  @HiveField(4)
  final double fullMarks;

  @HiveField(5)
  final double passMarks;

  @HiveField(6)
  final bool isSynced;

  @HiveField(7)
  final String markType; // 'written_only', 'mcq_only', 'written_mcq'

  @HiveField(8)
  final double writtenPassMarks;

  @HiveField(9)
  final double mcqPassMarks;

  @HiveField(10)
  final bool isCombinedSubject;

  @HiveField(11)
  final String? combinedPairGroup;

  SubjectModel({
    String? id,
    required this.subjectCode,
    required this.subjectName,
    required this.className,
    required this.fullMarks,
    this.passMarks = 33.0,
    this.isSynced = false,
    this.markType = 'written_only',
    this.writtenPassMarks = 23.0,
    this.mcqPassMarks = 10.0,
    this.isCombinedSubject = false,
    this.combinedPairGroup,
  }) : id = id ?? const Uuid().v4();

  SubjectModel copyWith({
    String? id,
    String? subjectCode,
    String? subjectName,
    String? className,
    double? fullMarks,
    double? passMarks,
    bool? isSynced,
    String? markType,
    double? writtenPassMarks,
    double? mcqPassMarks,
    bool? isCombinedSubject,
    String? combinedPairGroup,
  }) {
    return SubjectModel(
      id: id ?? this.id,
      subjectCode: subjectCode ?? this.subjectCode,
      subjectName: subjectName ?? this.subjectName,
      className: className ?? this.className,
      fullMarks: fullMarks ?? this.fullMarks,
      passMarks: passMarks ?? this.passMarks,
      isSynced: isSynced ?? this.isSynced,
      markType: markType ?? this.markType,
      writtenPassMarks: writtenPassMarks ?? this.writtenPassMarks,
      mcqPassMarks: mcqPassMarks ?? this.mcqPassMarks,
      isCombinedSubject: isCombinedSubject ?? this.isCombinedSubject,
      combinedPairGroup: combinedPairGroup ?? this.combinedPairGroup,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject_code': subjectCode,
      'subject_name': subjectName,
      'class_name': className,
      'full_marks': fullMarks,
      'pass_marks': passMarks,
      'is_synced': isSynced,
      'mark_type': markType,
      'written_pass_marks': writtenPassMarks,
      'mcq_pass_marks': mcqPassMarks,
      'is_combined_subject': isCombinedSubject,
      'combined_pair_group': combinedPairGroup,
    };
  }

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: json['id'] as String?,
      subjectCode: json['subject_code'] as String? ?? json['subjectCode'] as String? ?? '',
      subjectName: json['subject_name'] as String? ?? json['subjectName'] as String? ?? '',
      className: json['class_name'] as String? ?? json['className'] as String? ?? '',
      fullMarks: (json['full_marks'] as num?)?.toDouble() ?? (json['fullMarks'] as num?)?.toDouble() ?? 100.0,
      passMarks: (json['pass_marks'] as num?)?.toDouble() ?? (json['passMarks'] as num?)?.toDouble() ?? 33.0,
      isSynced: json['is_synced'] as bool? ?? json['isSynced'] as bool? ?? false,
      markType: json['mark_type'] as String? ?? json['markType'] as String? ?? 'written_only',
      writtenPassMarks: (json['written_pass_marks'] as num?)?.toDouble() ?? (json['writtenPassMarks'] as num?)?.toDouble() ?? 23.0,
      mcqPassMarks: (json['mcq_pass_marks'] as num?)?.toDouble() ?? (json['mcqPassMarks'] as num?)?.toDouble() ?? 10.0,
      isCombinedSubject: json['is_combined_subject'] as bool? ?? json['isCombinedSubject'] as bool? ?? false,
      combinedPairGroup: json['combined_pair_group'] as String? ?? json['combinedPairGroup'] as String?,
    );
  }
}
