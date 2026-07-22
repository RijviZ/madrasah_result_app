import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'student_model.g.dart';

@HiveType(typeId: 0)
class StudentModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int roll;

  @HiveField(3)
  final String className;

  @HiveField(4)
  final String section;

  @HiveField(5)
  final bool isSynced;

  @HiveField(6)
  final DateTime updatedAt;

  StudentModel({
    String? id,
    required this.name,
    required this.roll,
    required this.className,
    required this.section,
    this.isSynced = false,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        updatedAt = updatedAt ?? DateTime.now();

  StudentModel copyWith({
    String? id,
    String? name,
    int? roll,
    String? className,
    String? section,
    bool? isSynced,
    DateTime? updatedAt,
  }) {
    return StudentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      roll: roll ?? this.roll,
      className: className ?? this.className,
      section: section ?? this.section,
      isSynced: isSynced ?? this.isSynced,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'roll': roll,
      'class_name': className,
      'section': section,
      'is_synced': isSynced,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'] as String?,
      name: json['name'] as String? ?? '',
      roll: (json['roll'] as num?)?.toInt() ?? 0,
      className: json['class_name'] as String? ?? json['className'] as String? ?? '',
      section: json['section'] as String? ?? '',
      isSynced: json['is_synced'] as bool? ?? json['isSynced'] as bool? ?? false,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : (json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : DateTime.now()),
    );
  }
}
