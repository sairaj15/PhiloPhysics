import 'package:ephysicsapp/globals/colors.dart';
import 'package:ephysicsapp/screens/Admin/widgets/quizCard.dart';
import 'package:ephysicsapp/services/general.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class QuizList extends StatefulWidget {
  QuizList({Key? key, required this.section}) : super(key: key);
  final String section;

  @override
  _QuizListState createState() => _QuizListState();
}

class _QuizListState extends State<QuizList> {
  final databaseReference = FirebaseDatabase.instance.ref().child("quiz");
  List quizDetails = [];

  @override
  void initState() {
    // TODO: implement initState
    // print(quizDetails.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color1,
      body: StreamBuilder<DataSnapshot>(
        stream: databaseReference
            .child(widget.section)
            .onValue
            .map((event) => event.snapshot),
        builder: (context, AsyncSnapshot<DataSnapshot> snap) {
          if (snap.hasData) {
            if (snap.data!.value == null) {
              return Center(
                child: Text("No data found"),
              );
            }

            Map data = snap.data!.value as Map;
            // Filter the data to only include items with 'quizChapNo' field
            Map filteredData = Map.fromEntries(
              data.entries
                  .where((entry) => entry.value.containsKey('quizChapNo')),
            );
            quizDetails = sortMap(filteredData, "quizChapNo").values.toList();
            return Column(
              children: <Widget>[
                SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: quizDetails.length,
                    itemBuilder: (context, index) {
                      print("Quiz Details are : $quizDetails");
                      return quizCard(
                        index: index,
                        quizDetails: quizDetails[index],
                        context: context,
                        section: widget.section,
                      );
                    },
                  ),
                ),
              ],
            );
          } else if (snap.hasError) {
            return Center(
              child: Text("Error: ${snap.error}"),
            );
          } else {
            return Center(
              child: SpinKitRotatingCircle(),
            );
          }
        },
      ),
    );
  }
}
