// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CardModelAdapter extends TypeAdapter<CardModel> {
  @override
  final int typeId = 0;

  @override
  CardModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CardModel(
      id: fields[0] as int?,
      cardNumber: fields[1] as String,
      foundAt: fields[2] as String,
      isUsed: fields[3] as bool? ?? false,
      loginUrl: fields[4] as String? ?? '',
      notes: fields[5] as String? ?? '',
      priorityOrder: (fields[6] as int?) ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, CardModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.cardNumber)
      ..writeByte(2)
      ..write(obj.foundAt)
      ..writeByte(3)
      ..write(obj.isUsed)
      ..writeByte(4)
      ..write(obj.loginUrl)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.priorityOrder);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
