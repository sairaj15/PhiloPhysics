import 'dart:convert';
import 'package:ephysicsapp/globals/constants.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;

class DataAutomateService {

  Future<void> updateGoogleSheetData() async {

    final scriptUrl = dataAutomateScriptUrl;

    List<Map<String,dynamic>> userData = await buildUserDataList();

    final response = await http.post(
      Uri.parse(scriptUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(userData),
    );

    if (response.statusCode == 200 || response.statusCode == 302) {
      print(" ====== Sheet updated successfully ====== ");
    } else {
      print("Error: ${response.body}");
    }
  }


  Future<List<Map<String, dynamic>>> buildUserDataList() async {
    final DatabaseReference ref = FirebaseDatabase.instance.ref('Users');
    final DataSnapshot snapshot = await ref.get();

    List<Map<String, dynamic>> usersList = [];

    if (snapshot.exists && snapshot.value is Map) {
      final Map usersMap = snapshot.value as Map;

      for (final entry in usersMap.entries) {
        final user = Map<String, dynamic>.from(entry.value);

        int totalAppSeconds = 0;
        if (user['AppUsage'] != null) {
          final appUsage = Map<String, dynamic>.from(user['AppUsage']);
          for (final month in appUsage.values) {
            final dates = Map<String, dynamic>.from(month);
            for (final timeStr in dates.values) {
              totalAppSeconds += _timeToSeconds(timeStr);
            }
          }
        }

        int totalPdfSeconds = 0;
        if (user['PdfUsage'] != null) {
          final pdfUsage = Map<String, dynamic>.from(user['PdfUsage']);
          for (final month in pdfUsage.values) {
            final dates = Map<String, dynamic>.from(month);
            for (final timeStr in dates.values) {
              totalPdfSeconds += _timeToSeconds(timeStr);
            }
          }
        }

        usersList.add({
          "name": user["name"] ?? "",
          "email": user["email"] ?? "",
          "classDiv": user["classDiv"] ?? "",
          "role": user["role"] ?? "",
          "pdfsViewed": user["pdfsViewed"] ?? 0,
          "college": user["college"] ?? "",
          "totalAppTime": _secondsToHMS(totalAppSeconds),
          "totalPdfTime": _secondsToHMS(totalPdfSeconds),
        });
      }
    }

    return usersList;
  }

  int _timeToSeconds(String timeStr) {
    final parts = timeStr.split(':').map(int.parse).toList();
    return parts[0] * 3600 + parts[1] * 60 + parts[2];
  }

  String _secondsToHMS(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    return duration.toString().split('.').first;
  }

}