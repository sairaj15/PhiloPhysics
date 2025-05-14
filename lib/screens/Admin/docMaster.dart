import 'package:ephysicsapp/globals/colors.dart';
import 'package:ephysicsapp/screens/Admin/addDoc.dart';
import 'package:ephysicsapp/screens/Admin/addVideo.dart';
import 'package:ephysicsapp/screens/Admin/widgets/docCard.dart';
import 'package:ephysicsapp/screens/users/widgets/cards.dart';
import 'package:ephysicsapp/services/authentication.dart';
import 'package:ephysicsapp/services/general.dart';
import 'package:ephysicsapp/widgets/generalWidgets.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class DocMaster extends StatefulWidget {
  DocMaster(
      {Key? key,
      required this.section,
      required this.moduleID,
      required this.moduleName})
      : super(key: key);
  final String section;
  final String moduleID;
  final String moduleName;

  @override
  _DocMasterState createState() => _DocMasterState();
}

class _DocMasterState extends State<DocMaster> {
  final databaseReference =
      FirebaseDatabase.instance; // Shorten for readability
  List documents = [];

  @override
  void initState() {
    print(widget.moduleName);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color1,
      appBar: AppBar(
        title: Text(
          widget.moduleName,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            StreamBuilder<DatabaseEvent>(
              stream: databaseReference
                  .ref()
                  .child(widget.section)
                  .child(widget.moduleID)
                  .child("documents")
                  .onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snap) {
                if (snap.hasData) {
                  final dataSnapshot = snap.data!.snapshot;

                  if (!snap.hasError && dataSnapshot.value != null) {
                    Map<dynamic, dynamic>? data;
                    if (dataSnapshot.value != null) {
                      data = dataSnapshot.value as Map<dynamic, dynamic>;
                    }
                    documents = sortMap(data!, "docName").values.toList();

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: BouncingScrollPhysics(),
                      itemCount: documents.length,
                      itemBuilder: (context, index) {
                        return isLoggedIn()
                            ? docCard(
                                index: index,
                                docDetails: documents[index],
                                context: context,
                                section: widget.section,
                                moduleID: widget.moduleID,
                              )
                            : docUserCard(
                                index: index,
                                docDetails: documents[index],
                                context: context,
                                section: widget.section,
                                moduleID: widget.moduleID,
                              );
                      },
                    );
                  } else if (!snap.hasError && dataSnapshot.value == null) {
                    return Center(child: Text("No data found"));
                  } else {
                    return Center(child: Text("Error: ${snap.error}"));
                  }
                } else {
                  return Center(child: SpinKitRotatingCircle());
                }
              },
            ),
            (widget.moduleName != "copyright-certificate")
                ? (isLoggedIn()
                    ? videosCard(
                        context: context,
                        moduleID: widget.moduleID,
                        section: widget.section,
                      )
                    : videosUserCard(
                        context: context,
                        moduleID: widget.moduleID,
                        section: widget.section,
                      ))
                : SizedBox(), // Or any other widget you want to display when moduleName is "copyright-certificate"
          ],
        ),
      ),
      floatingActionButton: isLoggedIn()
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FloatingActionButton(
                    heroTag: 'videoHero',
                    backgroundColor: color4,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddVideo(
                            section: widget.section,
                            moduleID: widget.moduleID,
                          ),
                        ),
                      );
                    },
                    tooltip: 'Add Video',
                    child: Icon(Icons.video_collection_outlined),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FloatingActionButton(
                    heroTag: 'documentHero',
                    backgroundColor: color4,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddDoc(
                            section: widget.section,
                            moduleID: widget.moduleID,
                          ),
                        ),
                      );
                    },
                    tooltip: 'Add Document',
                    child: Icon(Icons.add),
                  ),
                ),
              ],
            )
          : Container(),
    );
  }
}
