// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecordAdapter extends TypeAdapter<Record> {
  @override
  final int typeId = 5;

  @override
  Record read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Record(
      id: fields[0] as String,
      type: fields[1] as RecordType,
      amountCents: fields[2] as int,
      date: fields[3] as DateTime,
      title: fields[4] as String?,
      tag: fields[5] as String?,
      includeInStats: fields[6] as bool,
      includeInBudget: fields[7] as bool,
      categoryId: fields[8] as String?,
      accountId: fields[9] as String?,
      fromAccountId: fields[10] as String?,
      toAccountId: fields[11] as String?,
      serviceChargeCents: fields[12] as int,
      createdAt: fields[13] as DateTime,
      updatedAt: fields[14] as DateTime,
      isDeleted: fields[15] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Record obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.amountCents)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.title)
      ..writeByte(5)
      ..write(obj.tag)
      ..writeByte(6)
      ..write(obj.includeInStats)
      ..writeByte(7)
      ..write(obj.includeInBudget)
      ..writeByte(8)
      ..write(obj.categoryId)
      ..writeByte(9)
      ..write(obj.accountId)
      ..writeByte(10)
      ..write(obj.fromAccountId)
      ..writeByte(11)
      ..write(obj.toAccountId)
      ..writeByte(12)
      ..write(obj.serviceChargeCents)
      ..writeByte(13)
      ..write(obj.createdAt)
      ..writeByte(14)
      ..write(obj.updatedAt)
      ..writeByte(15)
      ..write(obj.isDeleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RecordTypeAdapter extends TypeAdapter<RecordType> {
  @override
  final int typeId = 4;

  @override
  RecordType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RecordType.spending;
      case 1:
        return RecordType.income;
      case 2:
        return RecordType.transfer;
      default:
        return RecordType.spending;
    }
  }

  @override
  void write(BinaryWriter writer, RecordType obj) {
    switch (obj) {
      case RecordType.spending:
        writer.writeByte(0);
        break;
      case RecordType.income:
        writer.writeByte(1);
        break;
      case RecordType.transfer:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecordTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
