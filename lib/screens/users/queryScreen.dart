import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;

class QueryFormScreen extends StatefulWidget {
  @override
  _QueryFormScreenState createState() => _QueryFormScreenState();
}

class _QueryFormScreenState extends State<QueryFormScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _classDivController = TextEditingController();
  final TextEditingController _rollNoController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  String? fileUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Method to load user data
  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      print("Current user UID: ${user?.uid}");

      if (user != null) {
        // Fetch user data from Firebase Realtime Database
        final snapshot = await FirebaseDatabase.instance
            .ref()
            .child('Users')
            .child(user.uid)
            .get();

        if (snapshot.exists) {
          final data = snapshot.value as Map;
          print("✅ User data from Realtime DB: $data");

          _nameController.text = data['name'] ?? '';
          _emailController.text = data['email'] ?? '';
          _classDivController.text = data['classDiv'] ?? '';
        } else {
          print("❌ No user data found in Realtime Database!");
        }

        // Fetch roll number from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        _rollNoController.text = prefs.getString('rollno') ?? '';
      }
    } catch (e) {
      print('⚠️ Error loading user data: $e');
    }
  }

  Future<void> _pickFile() async {
    // Open file picker
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      // Get the file path and name
      PlatformFile file = result.files.first;
      String fileName = path.basename(file.path!);

      try {
        // Upload the file to Firebase Storage
        final ref =
            FirebaseStorage.instance.ref().child('queries').child(fileName);
        final uploadTask = ref.putFile(File(file.path!));

        // Wait for the upload to complete
        await uploadTask.whenComplete(() async {
          // Get the file URL after upload
          String downloadUrl = await ref.getDownloadURL();

          setState(() {
            fileUrl = downloadUrl;
          });

          print("File uploaded successfully: $downloadUrl");
        });
      } catch (e) {
        print("Error uploading file: $e");
      }
    } else {
      print("User canceled the file picker");
    }
  }

  Future<void> _submitQuery() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Reference to Realtime Database
        DatabaseReference queryRef =
            FirebaseDatabase.instance.ref().child('Queries').push();

        // Push the data to Realtime Database
        await queryRef.set({
          'name': _nameController.text,
          'email': _emailController.text,
          'classDiv': _classDivController.text,
          'rollNo': _rollNoController.text,
          'message': _messageController.text,
          'attachment': fileUrl,
          'timestamp': ServerValue.timestamp, // Store timestamp
        });

        print("Query data saved to Realtime Database successfully!");
      }
    } catch (e) {
      print("Error submitting query: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Submit a Query"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: "Name"),
              readOnly: true,
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: "Email"),
              readOnly: true,
            ),
            TextField(
              controller: _classDivController,
              decoration: InputDecoration(labelText: "Class / Div"),
              readOnly: true,
            ),
            TextField(
              controller: _rollNoController,
              decoration: InputDecoration(labelText: "Roll No"),
              readOnly: true,
            ),
            TextField(
              controller: _messageController,
              decoration: InputDecoration(labelText: "Message / Query"),
              maxLines: 5,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed:
                  _pickFile, // Call the file picker when the button is pressed
              child: Text("Choose Attachment"),
            ),
            if (fileUrl != null)
              Text(
                "File uploaded: $fileUrl",
                style: TextStyle(color: Colors.green),
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _submitQuery();
              },
              child: Text("Submit Query"),
            ),
          ],
        ),
      ),
    );
  }
}
