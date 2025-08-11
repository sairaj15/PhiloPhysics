 import 'package:ephysicsapp/globals/colors.dart';
import 'package:ephysicsapp/services/docServices.dart';
import 'package:ephysicsapp/widgets/popUps.dart';
import 'package:flutter/material.dart';

 Widget docCard({
   required int index,
   required Map docDetails,
   required String section,
   required String moduleID,
   required BuildContext context,
   required String moduleName,
 }) {
   return GestureDetector(
     onTap: () {
       print("Pdf tapped by admin");
       openFile(docDetails["downloadUrl"], context, docDetails["docName"],moduleName);
     },
     child: Container(
       child: Card(
         margin: EdgeInsets.only(left: 15, right: 15, top: 7, bottom: 7),
         semanticContainer: true,
         child: Container(
           color: color2,
           child: Column(
             children: <Widget>[
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceAround,
                 children: <Widget>[
                   Container(
                     width: MediaQuery.of(context).size.width / 1.4,
                     padding: EdgeInsets.only(top: 30, bottom: 30, left: 10, right: 10),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: <Widget>[
                         Text(
                           docDetails["docName"].toString(),
                           overflow: TextOverflow.visible,
                           style: TextStyle(
                             fontSize: 16,
                             fontWeight: FontWeight.bold,
                           ),
                         ),
                       ],
                     ),
                   ),
                   Container(
                     margin: EdgeInsets.only(top: 5),
                     child: Column(
                       children: <Widget>[
                         SizedBox(
                           width: 10,
                         ),
                         IconButton(
                           icon: Icon(Icons.delete),
                           color: color5,
                           onPressed: () {
                             onDocDelete(
                                 docID: docDetails["docID"],
                                 section: section,
                                 moduleID: moduleID,
                                 context: context);
                           },
                         ),
                       ],
                     ),
                   )
                 ],
               )
             ],
           ),
         ),
       ),
     ),
   );
 }