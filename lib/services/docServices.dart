import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:ephysicsapp/dataBase/models/pdfFileModel.dart';
import 'package:ephysicsapp/globals/colors.dart';
import 'package:ephysicsapp/globals/constants.dart';
import 'package:ephysicsapp/widgets/pdfViewer.dart';
import 'package:ephysicsapp/widgets/popUps.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';

addDoc(
    {required String section,
    required String moduleID,
    required String docName,
    required File doc}) async {
  var uuid = Uuid();
  String uniqueID = uuid.v1();
  late String downloadUrl;
  try {
    var storageReference =
        FirebaseStorage.instance.ref().child("$section/$moduleID/$uniqueID");
    var uploadTask = storageReference.putFile(doc);
    await uploadTask.whenComplete(() async {
      await storageReference.getDownloadURL().then((fileURL) {
        downloadUrl = fileURL;
      });
    });

    final databaseReference = FirebaseDatabase.instance.ref();
    await databaseReference
        .child(section)
        .child(moduleID)
        .child("documents")
        .child(uniqueID)
        .set({
      "docName": docName,
      "docID": uniqueID,
      "downloadUrl": downloadUrl,
    });
    showToast("Added Sucessfully");
  } catch (e) {
    print(e);
    showToast("Failed to add Video");
  }
}

Future<void> addVideo({
  required String section,
  required String moduleID,
  required String docName,
  required String docLink,
  required String thumbnailLink,
  required BuildContext context,
}) async {
  var uuid = Uuid();
  String uniqueID = uuid.v1();

  try {
    final databaseReference = FirebaseDatabase.instance.ref();
    await databaseReference
        .child(section)
        .child(moduleID)
        .child("videos")
        .child(uniqueID)
        .set({
      "videoName": docName,
      "docID": uniqueID,
      "videoDownloadUrl": docLink,
      "thumbnailDownloadUrl": thumbnailLink,
    });
    print(docLink);
    print(docLink);
    showToast("Video Added Successfully");
    print("$docLink && $thumbnailLink");
    Navigator.pop(context);
  } catch (e) {
    print(e);
    showToast("Failed to add Video");
  }
}

deleteDoc(
    {required String docID,
    required String moduleID,
    required String section}) async {
  var storageReference =
      FirebaseStorage.instance.ref().child("$section/$moduleID/" + docID);
  var uploadTask = storageReference.delete();
  await uploadTask.whenComplete(() async {
    await FirebaseDatabase.instance
        .ref()
        .child(section)
        .child(moduleID)
        .child("documents")
        .child(docID)
        .remove();
    showToast("Removed Successfully");
  });
}

Future<void> openFile(
    String url, BuildContext context, String title, String chapterName) async {
  // Show a loading dialog while downloading
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Center(
        child: SpinKitFadingCircle(
          color: color5,
          size: 30.0,
        ),
      );
    },
  );

  // Start downloading the PDF file in the background
  createFileOfPdfUrl(url).then((f) {
    String remotePDFpath = f.path;

    // Dismiss the loading dialog after the file is downloaded
    Navigator.of(context, rootNavigator: true).pop();

    // Navigate to the PDF screen once the file is ready
    if (remotePDFpath.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PDFScreen(
            path: remotePDFpath,
            title: title,
            moduleName: chapterName,
            originalFileUrl: url,
          ),
        ),
      );
    }
  }).catchError((e) {
    Navigator.of(context, rootNavigator: true)
        .pop(); // Dismiss loading on error
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      duration: Duration(seconds: 5),
      content: Text('Error downloading PDF. Check your connection.'),
    ));
  });
}

Future<File> createFileOfPdfUrl(String pdfUrl) async {
  Completer<File> completer = Completer();
  print("Start download file from internet!");
  try {
    // "https://berlin2017.droidcon.cod.newthinking.net/sites/global.droidcon.cod.newthinking.net/files/media/documents/Flutter%20-%2060FPS%20UI%20of%20the%20future%20%20-%20DroidconDE%2017.pdf";
    // final url = "https://pdfkit.org/docs/guide.pdf";
    final url = pdfUrl;
    final filename = url.substring(url.lastIndexOf("/") + 1);

    var dir = await getApplicationDocumentsDirectory();
    print("${dir.path}/$filename");
    File file = File("${dir.path}/$filename");

    if (!(await file.exists())) {
      print("--------------------doesnt  exist");
      var request = await HttpClient().getUrl(Uri.parse(url));
      var response = await request.close();
      var bytes = await consolidateHttpClientResponseBytes(response);
      print("URL: $url");
      print("Status Code: ${response.statusCode}");
      print("Content Type: ${response.headers.contentType}");
      print("Bytes Length: ${bytes.length}");
      await file.writeAsBytes(bytes, flush: true);
    } else
      print("--------------------Already exist");

    print("Checking stored PDF cache...");
    await printCacheSize();
    completer.complete(file);
  } catch (e) {
    throw Exception('Error parsing asset file!');
  }

  return completer.future;
}

// Future<File> createFileOfPdfUrl(String pdfUrl) async {
//   String assetPath = "assets/pdfs/formula_list.pdf";

//   final byteData = await rootBundle.load(assetPath);

//   final dir = await getApplicationDocumentsDirectory();

//   final file = File("${dir.path}/demo.pdf");

//   await file.writeAsBytes(
//     byteData.buffer.asUint8List(),
//     flush: true,
//   );

//   return file;
// }

Future<void> printCacheSize() async {
  var dir = await getApplicationDocumentsDirectory();
  int totalSize = 0;

  List<FileSystemEntity> files = Directory(dir.path).listSync();
  for (var file in files) {
    if (file is File) {
      int fileSize = await file.length();
      totalSize += fileSize;
      print("File: ${file.path} | Size: ${fileSize / (1024 * 1024)} MB");
    }
  }

  print("🔹 Total Cache Size: ${totalSize / (1024 * 1024)} MB");
}

//  Future getFuture(String url,BuildContext context) {
//     return Future(() async {
//       await openFile( url,context);
//       return 'Read File';
//     });
//   }

// Future<void> openDocProgressIndicator(BuildContext context,String url) async {
//     var result = await showDialog(
//         context: context,
//         child: FutureProgressDialog(getFuture(url,context), message: Text('Opening File...')));
//     showResultDialog(context, result);
//   }

// fetchDocs(String section,String moduleID ) async{
// var connectivityResult = await (Connectivity().checkConnectivity());
// if (connectivityResult != ConnectivityResult.none) {
//   final databaseReference = FirebaseDatabase.instance.reference();
//  databaseReference.child(section).child(moduleID).child("documents").once().then((value){

//    return value.value;
//  });

//   }
// else if (connectivityResult == ConnectivityResult.none) {

//   }
// }

// Student PDF Views Increment
Future<void> incrementPDFViewCount(String studentUUID) async {
  try {
    DatabaseReference dbRef = FirebaseDatabase.instance.ref();
    DatabaseEvent event = await dbRef
        .child('Users')
        .child(studentUUID)
        .child('pdfsViewed')
        .once();

    DataSnapshot snapshot = event.snapshot;
    if (snapshot.exists) {
      print("PDF Count Exists");
      int currentViewCount = snapshot.value as int;
      await dbRef.child('Users').child(studentUUID).update({
        'pdfsViewed': currentViewCount + 1,
      });
      print("Incremented in User");
    } else {
      await dbRef.child('Users').child(studentUUID).child('pdfsViewed').set(1);
      print("Initialized in User");
    }
  } catch (e) {
    print("Error incrementing PDF view count: $e");
  }
}

class DownloadService {
  static ValueNotifier<bool> isDownloading = ValueNotifier(false);
  static ValueNotifier<double> progress = ValueNotifier(0.0);

  static Future<void> savePdfOffline(
    BuildContext context,
    String url,
    String fileName,
    String chapterName,
  ) async {
    try {
      var box = Hive.box<PDFFile>(Hive_Pdf_key);

      final alreadyExists = box.values.any(
          (pdf) => pdf.chapterName == chapterName && pdf.fileName == fileName);

      if (alreadyExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "$fileName File for '$chapterName' is already downloaded."),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      isDownloading.value = true;
      progress.value = 0.0;

      final dir = await getApplicationDocumentsDirectory();
      final filePath =
          "${dir.path}/${chapterName.replaceAll(' ', '_') + fileName.replaceAll(' ', '_')}";

      Dio dio = Dio();
      await dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            progress.value = received / total;
          }
        },
      );

      box.add(PDFFile(
        fileName: fileName,
        filePath: filePath,
        chapterName: chapterName,
        savedAt: DateTime.now(),
      ));

      isDownloading.value = false;

      // 2. Show success SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Downloaded '$fileName' successfully."),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      isDownloading.value = false;

      // 3. Show failure SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to download '$fileName'. Please try again."),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
