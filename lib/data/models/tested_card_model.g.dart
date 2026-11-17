// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tested_card_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TestedCardModelAdapter extends TypeAdapter<TestedCardModel> {
  @override
  final int typeId = 2;

  @override
  TestedCardModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TestedCardModel(
      id: fields[0] as int?,
      cardNumber: fields[1] as String,
      testedAt: fields[2] as String,
      status: fields[3] as String? ?? 'failed',
      portalMessage: fields[4] as String? ?? '',
      isLastTested: fields[5] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, TestedCardModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.cardNumber)
      ..writeByte(2)
      ..write(obj.testedAt)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.portalMessage)
      ..writeByte(5)
      ..write(obj.isLastTested);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestedCardModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
