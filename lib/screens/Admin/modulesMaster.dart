import 'package:ephysicsapp/globals/colors.dart';
import 'package:ephysicsapp/screens/Admin/addChapter.dart';
import 'package:ephysicsapp/screens/Admin/widgets/moduleCard.dart';
import 'package:ephysicsapp/screens/users/widgets/cards.dart';
import 'package:ephysicsapp/services/authentication.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class ModuleMaster extends StatefulWidget {
  ModuleMaster({Key? key, required this.section}) : super(key: key);
  final String section;

  @override
  _ModuleMasterState createState() => _ModuleMasterState();
}

class _ModuleMasterState extends State<ModuleMaster> {
  final DatabaseReference databaseReference = FirebaseDatabase.instance.ref();
  List<Map<dynamic, dynamic>> modules = [];

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color1,
      body: StreamBuilder<DatabaseEvent>(
        stream: databaseReference.child(widget.section).onValue,
        builder: (context, snapshot) {
          if (snapshot.hasData && !snapshot.hasError) {
            DataSnapshot dataSnapshot = snapshot.data!.snapshot;
            Map<dynamic, dynamic>? data = dataSnapshot.value as Map<dynamic, dynamic>?;

            modules.clear();
            if (data != null) {
              data.forEach((key, value) {
                if (value != null && value['moduleNo'] != null) {
                  modules.add({
                    'moduleId': key,
                    'moduleName': value['moduleName'] ?? 'Unknown',
                    'moduleNo': value['moduleNo'] is int ? value['moduleNo'] : int.tryParse(value['moduleNo']) ?? 0,
                  });
                }
              });

              // Filter out modules without moduleNo
              modules = modules.where((module) => module.containsKey('moduleNo')).toList();

              // Sort modules by moduleNo in ascending order
              modules.sort((a, b) => a['moduleNo'].compareTo(b['moduleNo']));

              print(modules);
    }

            return Column(
              children: <Widget>[
                SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: modules.length,
                    itemBuilder: (context, index) {
                      return isLoggedIn()
                          ? moduleCard(
                        index: index,
                        moduleDetails: modules[index],
                        context: context,
                        section: widget.section,
                      )
                          : moduleUserCard(
                        index: index,
                        moduleDetails: modules[index],
                        context: context,
                        section: widget.section,
                      );
                    },
                  ),
                ),
              ],
            );
          } else if (snapshot.hasData &&
              !snapshot.hasError &&
              snapshot.data!.snapshot.value == null) {
            return Center(
              child: Text("No data found"),
            );
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
      floatingActionButton: !isLoggedIn()
          ? Container()
          : FloatingActionButton(
        backgroundColor: color4,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddChapter(section: widget.section),
            ),
          );
        },
        tooltip: 'Add Document',
        child: Icon(Icons.add),
      ),
    );
  }
}
