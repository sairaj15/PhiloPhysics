import 'package:ephysicsapp/globals/colors.dart';
import 'package:ephysicsapp/screens/Admin/docMaster.dart';
import 'package:ephysicsapp/screens/Admin/videosPage.dart';
import 'package:ephysicsapp/services/authentication.dart';
import 'package:ephysicsapp/services/docServices.dart';
import 'package:ephysicsapp/widgets/webDisplay.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../../../widgets/popUps.dart';

Widget moduleUserCard({
  required int index,
  required Map<dynamic, dynamic> moduleDetails,
  required String section,
  required BuildContext context,
  VoidCallback? onTap,
}) {
  final String moduleName = moduleDetails['moduleName'] ?? 'Unknown';
  final String moduleId = moduleDetails['moduleId'] ?? 'Unknown';
  final int moduleNo = moduleDetails['moduleNo'] ?? 'Unknown';
  final String practicalUrl = moduleDetails['practicalUrl'] ?? '';

  return Container(
    margin: EdgeInsets.fromLTRB(10, 7, 10, 7),
    child: Card(
      elevation: 3,
      color: color1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(100)),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
        leading: Container(
          padding: EdgeInsets.only(right: 12.0),
          decoration: BoxDecoration(
            border: Border(right: BorderSide(width: 1.0, color: color5)),
          ),
          child: Text(
            moduleNo.toString(),
            style: TextStyle(fontSize: 18),
          ),
        ),
        title: Text(
          moduleName,
          overflow: TextOverflow.visible,
          style: TextStyle(
            color: color5,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        trailing: Icon(Icons.keyboard_arrow_right, color: color5, size: 30.0),
        onTap: onTap ??
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DocMaster(
                    section: section,
                    moduleName: moduleName,
                    moduleID: moduleId,
                    practicalUrl: practicalUrl,
                  ),
                ),
              );
            },
      ),
    ),
  );
}

Widget docUserCard({
  int? index,
  Map? docDetails,
  String? section,
  String? moduleID,
  BuildContext? context,
}) {
  return Container(
    margin: EdgeInsets.fromLTRB(10, 7, 10, 7),
    child: Card(
      elevation: 3,
      color: color1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(100)),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        leading: Container(
          padding: EdgeInsets.only(right: 12.0),
          decoration: BoxDecoration(
            border: Border(right: BorderSide(width: 1.0, color: color5)),
          ),
          child: Icon(Icons.note, color: color5),
        ),
        title: Text(
          docDetails!["docName"].toString(),
          overflow: TextOverflow.visible,
          style: TextStyle(
            color: color5,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        trailing: Icon(Icons.keyboard_arrow_right, color: color5, size: 30.0),
        onTap: () async {
          print("Doc Details : ${docDetails}");
          print("Section : ${section}");
          // Open the PDF first
          if (docDetails["downloadUrl"] != null && context != null) {
            openFile(docDetails["downloadUrl"], context, docDetails["docName"]);
          }

          // Increment the view count in the background
          String? studentUUID = prefs.getString('studentUUID');
          if (studentUUID != null) {
            print("Student is logged in");
            try {
              incrementPDFViewCount(studentUUID);
              FirebaseDatabase firebaseDatabase = FirebaseDatabase.instance;

              // Path to the module's documents in the database
              DatabaseReference documentsRef = firebaseDatabase
                  .ref()
                  .child(section!) // Section name passed to the widget
                  .child(moduleID!) // Module ID passed to the widget
                  .child("documents");

              // Search for the specific document
              Query query = documentsRef
                  .orderByChild("docName")
                  .equalTo(docDetails["docName"]);
              DataSnapshot snapshot = await query.get();

              if (snapshot.exists) {
                for (DataSnapshot doc in snapshot.children) {
                  // Increment 'thisNotesViewed' for the matched document
                  await doc.ref.runTransaction((mutableData) {
                    if (mutableData == null) {
                      // Initialize the data if it's null
                      return Transaction.success({"thisNotesViewed": 1});
                    }

                    // Safely cast mutableData to Map<String, dynamic>
                    Map<String, dynamic> docData = Map<String, dynamic>.from(
                        mutableData as Map<dynamic, dynamic>);

                    // Increment the view count
                    int currentCount = docData["thisNotesViewed"] ?? 0;
                    docData["thisNotesViewed"] = currentCount + 1;

                    return Transaction.success(docData);
                  });
                  print(
                      "View count incremented for document: ${docDetails["docName"]}");
                }
              } else {
                print("Document not found: ${docDetails["docName"]}");
              }
            } catch (e) {
              print("Failed to increment view count: $e");
              showToast("Failed to update view count.");
            }
          } else {
            showToast("User not logged in.");
          }
        },
      ),
    ),
  );
}

// widget video card

Widget videosCard(
    {required String? section,
    required String? moduleID,
    required BuildContext? context}) {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 10),
    child: Card(
      elevation: 3,
      color: color2,
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        leading: Container(
          padding: EdgeInsets.only(right: 12.0),
          decoration: BoxDecoration(
              border: Border(right: BorderSide(width: 1.0, color: color5))),
          child: Icon(Icons.video_library, color: color5),
        ),
        title: Text(
          'Videos',
          overflow: TextOverflow.visible,
          style: TextStyle(
            color: color5,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        trailing: Icon(Icons.keyboard_arrow_right, color: color5, size: 30.0),
        onTap: () {
          Navigator.push(
            context!,
            MaterialPageRoute(
              builder: (context) => VideosListPage(
                section: section!,
                moduleID: moduleID!,
              ),
            ),
          );
        },
      ),
    ),
  );
}

Widget videosUserCard(
    {required String? section,
    required String? moduleID,
    required BuildContext context}) {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    child: Card(
      elevation: 3,
      color: color1,
      shadowColor: Colors.grey,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(100)),
      ),
      child: ListTile(
          contentPadding:
              EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          leading: Container(
            padding: EdgeInsets.only(right: 12.0),
            decoration: BoxDecoration(
                border: Border(right: BorderSide(width: 1.0, color: color5))),
            child: Icon(Icons.video_library, color: color5),
          ),
          title: Text(
            'Videos',
            overflow: TextOverflow.visible,
            style: TextStyle(
              color: color5,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          trailing: Icon(Icons.keyboard_arrow_right, color: color5, size: 30.0),
          onTap: () async {
            print("Pushing to module videos");
            // Navigate to the VideosListPage after updating the view count
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VideosListPage(
                  section: section!,
                  moduleID: moduleID!,
                ),
              ),
            );
          }),
    ),
  );
}

Widget quizCardNotesUserAndAdmin(
    {required int index,
    required Map quizDetails,
    required String section,
    required BuildContext context}) {
  return Container(
      margin: EdgeInsets.fromLTRB(10, 7, 10, 7),
      child: Card(
          elevation: isLoggedIn() ? 1 : 3,
          color: isLoggedIn() ? color2 : color1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.horizontal(
                right: Radius.circular(isLoggedIn() ? 0 : 100)),
          ),
          child: ListTile(
            contentPadding:
                EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
            leading: Container(
              padding: EdgeInsets.only(right: 12.0),
              decoration: new BoxDecoration(
                  border: new Border(
                      right: new BorderSide(width: 1.0, color: color5))),
              child: quizDetails["quizChapNo"] != null
                  ? Text(
                      quizDetails["quizChapNo"],
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    )
                  : Icon(Icons.quiz),
            ),
            title: Text(
              quizDetails["quizName"].toString(),
              overflow: TextOverflow.visible,
              style: TextStyle(
                color: color5,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            trailing: isLoggedIn()
                ? IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      onDelete(
                          id: quizDetails["quizID"],
                          section: section,
                          context: context);
                    },
                    color: color5)
                : null,
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => QuizAppView(
                            formUrl: quizDetails["quizLink"],
                            moduleName: quizDetails["quizName"],
                          )));
            },
          )));
}
