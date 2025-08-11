import 'package:hive/hive.dart';

part 'pdfFileModel.g.dart';

@HiveType(typeId: 0)
class PDFFile extends HiveObject {
  @HiveField(0)
  final String fileName;

  @HiveField(1)
  final String filePath;

  @HiveField(2)
  final String chapterName;

  @HiveField(3)
  final DateTime savedAt;

  PDFFile({
    required this.fileName,
    required this.filePath,
    required this.chapterName,
    required this.savedAt,
  });
}
