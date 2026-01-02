import 'package:ephysicsapp/services/docServices.dart';
import 'package:ephysicsapp/services/quizServices.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

showToast(String msg) {
  return Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.grey[800],
      textColor: Colors.white,
      fontSize: 16.0);
}

Future<void> onDocDelete(
    {required String docID,
    required String moduleID,
    required String section,
    required BuildContext context}) {
  return showDialog(
    context: context,
    builder: (context) => new AlertDialog(
      title: new Text('Are you sure?'),
      content: new Text('Do you want to delete this document?'),
      actions: <Widget>[
        new GestureDetector(
          onTap: () => Navigator.of(context).pop(false),
          child: Text(
            "NO",
            style: TextStyle(fontSize: 18),
          ),
        ),
        SizedBox(width: 35),
        new GestureDetector(
          onTap: () async {
            await deleteDoc(docID: docID, moduleID: moduleID, section: section);
            Navigator.of(context).pop(false);
          },
          child: Text(
            "YES",
            style: TextStyle(fontSize: 18),
          ),
        ),
      ],
    ),
  );
}

Future<void> onModuleDelete({
  required String moduleID,
  required String section,
  required BuildContext context,
  required Map moduleDetails,
}) {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Are you sure?'),
      content: Text('Do you want to delete this module?'),
      actions: <Widget>[
        GestureDetector(
          onTap: () => Navigator.of(context).pop(false),
          child: Text(
            "NO",
            style: TextStyle(fontSize: 18),
          ),
        ),
        SizedBox(width: 35),
        GestureDetector(
          onTap: () async {
            await deleteModule(
              section: section,
              moduleID: moduleID,
              moduleDetails: moduleDetails,
            );
            Navigator.of(context).pop(false);
          },
          child: Text(
            "YES",
            style: TextStyle(fontSize: 18),
          ),
        ),
      ],
    ),
  );
}

Future<void> deleteModule({
  required String moduleID,
  required String section,
  required Map moduleDetails,
}) async {
  final databaseReference = FirebaseDatabase.instance.ref();

  // Check if the module contains documents
  DataSnapshot snapshot = await databaseReference
      .child(section)
      .child(moduleID)
      .child("documents")
      .get();

  if (snapshot.exists) {
    showToast("Empty the folder first");
  } else {
    // Remove the module from Firebase Realtime Database
    await databaseReference.child(section).child(moduleID).remove();
    showToast("Removed Successfully");
  }
}

// Future<void> onModuleDelete({required String moduleID,required String section,required BuildContext context,required Map moduleDetails}) {
//     return showDialog(
//       context: context,
//       builder: (context) => new AlertDialog(
//         title: new Text('Are you sure?'),
//         content: new Text('Do you want to delete this module?'),
//         actions: <Widget>[
//           new GestureDetector(
//             onTap: () => Navigator.of(context).pop(false),
//             child: Text("NO",style: TextStyle(fontSize: 18),),
//           ),
//           SizedBox(width: 35),
//           new GestureDetector(
//             onTap: () async{
//               await deleteModule(section:section,moduleID:moduleID ,moduleDetails: moduleDetails);
//                Navigator.of(context).pop(false);
//             },
//             child: Text("YES" ,style: TextStyle(fontSize: 18),),
//           ),
//         ],
//       ),
//     );
//   }

void showResultDialog(BuildContext context, String result) {
  showDialog(
    builder: (context) => AlertDialog(
      content: Text(result),
      actions: <Widget>[
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('OK'),
        )
      ],
    ),
    context: context,
  );
}

Future<void> onDelete(
    {String? id, String? section, required BuildContext context}) {
  return showDialog(
    context: context,
    builder: (context) => new AlertDialog(
      title: new Text('Are you sure?'),
      content: new Text('Do you want to delete this Quiz?'),
      actions: <Widget>[
        new GestureDetector(
          onTap: () => Navigator.of(context).pop(false),
          child: Text(
            "NO",
            style: TextStyle(fontSize: 18),
          ),
        ),
        SizedBox(width: 35),
        new GestureDetector(
          onTap: () async {
            deleteQuiz(section: section!, quizID: id!);
            Navigator.of(context).pop(false);
          },
          child: Text(
            "YES",
            style: TextStyle(fontSize: 18),
          ),
        ),
      ],
    ),
  );
}

// Deleting Video

Future<void> onDeleteVideo({
  String? id,
  String? section,
  required BuildContext context,
  required Map<dynamic, dynamic> videoDetails,
}) {
  return showDialog(
    context: context,
    builder: (context) => new AlertDialog(
      title: new Text('Are you sure?'),
      content: new Text('Do you want to delete this Video?'),
      actions: <Widget>[
        new GestureDetector(
          onTap: () => Navigator.of(context).pop(false),
          child: Text(
            "NO",
            style: TextStyle(fontSize: 18),
          ),
        ),
        SizedBox(width: 35),
        new GestureDetector(
          onTap: () async {
            onVideoDelete(
                section: section!,
                moduleID: id!,
                context: context,
                videoDetails: videoDetails);
            Navigator.of(context).pop(false);
          },
          child: Text(
            "YES",
            style: TextStyle(fontSize: 18),
          ),
        ),
      ],
    ),
  );
}

Future<void> onVideoDelete({
  required String section,
  required String moduleID,
  required BuildContext context,
  required Map<dynamic, dynamic> videoDetails,
}) async {
  String uniqueID = videoDetails['docID'];
  try {
    // Delete from Firebase Storage
    // var storageReference = FirebaseStorage.instance
    //     .ref()
    //     .child("$section/$moduleID/videos/$uniqueID");
    // await storageReference.delete();

    // Delete from Firebase Realtime Database
    final databaseReference = FirebaseDatabase.instance.ref();
    await databaseReference
        .child(section)
        .child(moduleID)
        .child("videos")
        .child(uniqueID)
        .remove();

    showToast("Video deleted successfully");
  } catch (e) {
    print(e);
    showToast("Failed to delete video");
  }
}
