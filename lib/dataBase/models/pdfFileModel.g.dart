// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pdfFileModel.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PDFFileAdapter extends TypeAdapter<PDFFile> {
  @override
  final int typeId = 0;

  @override
  PDFFile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PDFFile(
      fileName: fields[0] as String,
      filePath: fields[1] as String,
      chapterName: fields[2] as String,
      savedAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PDFFile obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.fileName)
      ..writeByte(1)
      ..write(obj.filePath)
      ..writeByte(2)
      ..write(obj.chapterName)
      ..writeByte(3)
      ..write(obj.savedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PDFFileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
