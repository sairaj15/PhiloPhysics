// vlab_chapters_page.dart
import 'package:ephysicsapp/screens/users/v-labs/vlabs_webview_page.dart';
import 'package:ephysicsapp/screens/users/widgets/cards.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ephysicsapp/globals/colors.dart';

class VLabChaptersPage extends StatefulWidget {
  @override
  _VLabChaptersPageState createState() => _VLabChaptersPageState();
}

class _VLabChaptersPageState extends State<VLabChaptersPage> {
  final DatabaseReference databaseReference = FirebaseDatabase.instance.ref();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: databaseReference.child('4').onValue,
      builder: (context, snapshot) {
        if (snapshot.hasData && !snapshot.hasError) {
          DataSnapshot dataSnapshot = snapshot.data!.snapshot;
          Map<dynamic, dynamic>? data =
              dataSnapshot.value as Map<dynamic, dynamic>?;

          List<Map<dynamic, dynamic>> chapters = [];
          if (data != null) {
            data.forEach((key, value) {
              if (value != null && value['vlabUrl'] != null) {
                chapters.add({
                  'moduleName': value['moduleName'] ?? 'Unknown',
                  'moduleNo': value['moduleNo'] ?? 0,
                  'vlabUrl': value['vlabUrl'],
                });
              }
            });

            // Sort by moduleNo
            chapters.sort((a, b) =>
                (a['moduleNo'] as int).compareTo(b['moduleNo'] as int));
          }

          if (chapters.isEmpty) {
            return Center(child: Text("No V-Lab chapters found"));
          }

          return ListView.builder(
            itemCount: chapters.length,
            itemBuilder: (context, index) {
              return moduleUserCard(
                index: index,
                moduleDetails: {
                  'moduleName': chapters[index]['moduleName'],
                  'moduleNo': chapters[index]['moduleNo'],
                  // Add other fields if your card uses them
                },
                context: context,
                section: "4",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VLabWebViewPage(
                        title: chapters[index]['moduleName'],
                        url: chapters[index]['vlabUrl'],
                      ),
                    ),
                  );
                },
              );
            },
          );
        } else if (snapshot.hasData &&
            !snapshot.hasError &&
            snapshot.data!.snapshot.value == null) {
          return Center(child: Text("No V-Lab chapters found"));
        } else {
          return Center(
            child: SpinKitFadingCircle(
              color: color5,
              size: 30.0,
            ),
          );
        }
      },
    );
  }
}
