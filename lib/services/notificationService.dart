// import 'dart:convert';
//
// import 'package:firebase_database/firebase_database.dart';
// import 'package:http/http.dart' as http;
//
// class NotificationService {
//
//   Future<void> sendDailyNotificationIfNeeded(DatabaseReference dbRef) async {
//     final now = DateTime.now();
//     final today = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
//
//     final notifyRef = dbRef.child('notifications').child('lastDocNotifyDate');
//     final snapshot = await notifyRef.get();
//
//     if (!snapshot.exists || snapshot.value != today) {
//       await sendFcmToAllUsers();
//       await notifyRef.set(today);
//     }
//   }
//
//   Future<void> sendFcmToAllUsers() async {
//     const serverKey = "sxcsjsnnaOpAdn_1wjk";
//
//     await http.post(
//       Uri.parse('https://fcm.googleapis.com/fcm/send'),
//       headers: {
//         'Content-Type': 'application/json',
//         'Authorization': 'key=$serverKey',
//       },
//       body: jsonEncode({
//         "to": "/topics/doc_updates",
//         "notification": {
//           "title": "New Study Material Alert !",
//           "body": "A new study material was uploaded today. Check it out.",
//         },
//         "priority": "high",
//       }),
//     );
//   }
//
//
// }