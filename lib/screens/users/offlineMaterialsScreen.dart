import 'package:ephysicsapp/dataBase/models/pdfFileModel.dart';
import 'package:ephysicsapp/globals/constants.dart';
import 'package:ephysicsapp/widgets/pdfViewer.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class OfflineMaterialScreen extends StatefulWidget {
  const OfflineMaterialScreen({super.key});

  @override
  State<OfflineMaterialScreen> createState() => _OfflineMaterialScreenState();
}

class _OfflineMaterialScreenState extends State<OfflineMaterialScreen> {
  List<PDFFile> offlineFiles = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadOfflineFiles();
  }

  Future<void> loadOfflineFiles() async {
    if (!Hive.isBoxOpen(Hive_Pdf_key)) {
      await Hive.openBox<PDFFile>(Hive_Pdf_key);
    }

    final box = Hive.box<PDFFile>(Hive_Pdf_key);

    setState(() {
      offlineFiles = box.values.toList();
      isLoading = false;
    });

    for (var file in offlineFiles) {
      print(file.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Downloads", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: isLoading ? _buildShimmerList() : _buildFileList(context),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.black),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(height: 14, width: 120, color: Colors.grey.shade400),
                          const SizedBox(height: 6),
                          Container(height: 12, width: 180, color: Colors.grey.shade400),
                          const Spacer(),
                          Container(height: 12, width: 100, color: Colors.grey.shade400),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 80,
                    padding: const EdgeInsets.only(right: 12),
                    alignment: Alignment.bottomRight,
                    child: Container(height: 12, width: 40, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFileList(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return ListView.builder(
      itemCount: offlineFiles.length,
      itemBuilder: (context, index) {
        final file = offlineFiles[index];

        String formattedDate = "Unknown";
        formattedDate = DateFormat('dd/MM/yyyy').format(file.savedAt);

        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: width * 0.04,
            vertical: height * 0.012,
          ),
          padding: EdgeInsets.symmetric(horizontal:  width * 0.035, vertical: height * 0.01),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(color: Colors.black),
            borderRadius: BorderRadius.circular(12), // More rounded
          ),
          child: Row(
            children: [
              Container(
                width: width * 0.15,
                height: height * 0.12,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.file_open_sharp,
                  size: 36,
                  color: Colors.black,
                ),
              ),

              SizedBox(width: width * 0.035),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.fileName ?? "Unknown file",
                      style: GoogleFonts.poppins(
                        fontSize: width * 0.045,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: height * 0.0025),
                    Text(
                      file.chapterName ?? "Unknown chapter",
                      style: GoogleFonts.poppins(
                        fontSize: width * 0.037,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: height * 0.0025),
                    Text(
                      'Saved At: $formattedDate',
                      style: GoogleFonts.poppins(
                        fontSize: width * 0.032,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: height * 0.0025),
                    InkWell(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => PDFScreen(
                            path: file.filePath,
                            title: file.fileName,
                            moduleName: file.chapterName,
                            originalFileUrl: '',
                            isFromOfflineScreen: true,)
                          )
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "View",
                            style: GoogleFonts.poppins(
                              fontSize: width * 0.04,
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.blueAccent,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
