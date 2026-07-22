// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subject_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SubjectModelAdapter extends TypeAdapter<SubjectModel> {
  @override
  final int typeId = 1;

  @override
  SubjectModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SubjectModel(
      id: fields[0] as String?,
      subjectCode: fields[1] as String,
      subjectName: fields[2] as String,
      className: fields[3] as String,
      fullMarks: fields[4] as double,
      passMarks: fields[5] as double,
      isSynced: fields[6] as bool,
      markType: fields.containsKey(7) ? fields[7] as String : 'written_only',
      writtenPassMarks: fields.containsKey(8) ? fields[8] as double : 23.0,
      mcqPassMarks: fields.containsKey(9) ? fields[9] as double : 10.0,
      isCombinedSubject: fields.containsKey(10) ? fields[10] as bool : false,
      combinedPairGroup: fields.containsKey(11) ? fields[11] as String? : null,
    );
  }

  @override
  void write(BinaryWriter writer, SubjectModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.subjectCode)
      ..writeByte(2)
      ..write(obj.subjectName)
      ..writeByte(3)
      ..write(obj.className)
      ..writeByte(4)
      ..write(obj.fullMarks)
      ..writeByte(5)
      ..write(obj.passMarks)
      ..writeByte(6)
      ..write(obj.isSynced)
      ..writeByte(7)
      ..write(obj.markType)
      ..writeByte(8)
      ..write(obj.writtenPassMarks)
      ..writeByte(9)
      ..write(obj.mcqPassMarks)
      ..writeByte(10)
      ..write(obj.isCombinedSubject)
      ..writeByte(11)
      ..write(obj.combinedPairGroup);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubjectModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
