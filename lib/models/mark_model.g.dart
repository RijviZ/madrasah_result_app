// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mark_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MarkModelAdapter extends TypeAdapter<MarkModel> {
  @override
  final int typeId = 2;

  @override
  MarkModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MarkModel(
      id: fields[0] as String?,
      studentId: fields[1] as String,
      subjectId: fields[2] as String,
      examType: fields[3] as String,
      obtainedMarks: fields[4] as double,
      isSynced: fields[5] as bool,
      updatedAt: fields[6] as DateTime?,
      writtenMarks: fields.containsKey(7) ? fields[7] as double : 0.0,
      mcqMarks: fields.containsKey(8) ? fields[8] as double : 0.0,
    );
  }

  @override
  void write(BinaryWriter writer, MarkModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.studentId)
      ..writeByte(2)
      ..write(obj.subjectId)
      ..writeByte(3)
      ..write(obj.examType)
      ..writeByte(4)
      ..write(obj.obtainedMarks)
      ..writeByte(5)
      ..write(obj.isSynced)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.writtenMarks)
      ..writeByte(8)
      ..write(obj.mcqMarks);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarkModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
