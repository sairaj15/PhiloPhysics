import 'dart:io';

import 'package:ephysicsapp/globals/colors.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:path/path.dart' as path;
import 'package:shimmer/shimmer.dart';

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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot = await FirebaseDatabase.instance
            .ref()
            .child('Users')
            .child(user.uid)
            .get();
        if (snapshot.exists) {
          final data = snapshot.value as Map;
          _nameController.text = data['name'] ?? '';
          _emailController.text = data['email'] ?? '';
          _classDivController.text = data['classDiv'] ?? '';
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      PlatformFile file = result.files.first;
      String fileName = path.basename(file.path!);
      try {
        final ref =
            FirebaseStorage.instance.ref().child('queries').child(fileName);
        final uploadTask = ref.putFile(File(file.path!));
        await uploadTask.whenComplete(() async {
          String downloadUrl = await ref.getDownloadURL();
          setState(() {
            fileUrl = downloadUrl;
          });
        });
      } catch (e) {
        print('Error uploading file: $e');
      }
    }
  }

  Future<void> _submitQuery() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DatabaseReference queryRef =
            FirebaseDatabase.instance.ref().child('Queries').push();
        await queryRef.set({
          'name': _nameController.text,
          'email': _emailController.text,
          'classDiv': _classDivController.text,
          'rollNo': _rollNoController.text,
          'message': _messageController.text,
          'attachment': fileUrl,
          'timestamp': ServerValue.timestamp,
        });
      }
    } catch (e) {
      print('Error submitting query: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Submit a Query',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading ? _buildShimmer() : _buildQueryForm(),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          6,
          (index) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Container(
              height: index == 4 ? 100 : 50,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQueryForm() {
    return SingleChildScrollView(
      child: Container(
        color: Color(0xFFF9F9F9),
        padding: const EdgeInsets.all(16),
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 5,
          shadowColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Submit your query',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: color5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Fill in the form below, and we’ll get in touch with you shortly.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blueGrey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                _buildReadOnlyField('Name', _nameController),
                _buildReadOnlyField('Email', _emailController),

                Row(
                  children: [
                    Expanded(
                        child: _buildEditableField(
                            'Class / Div', _classDivController,
                            small: true)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildEditableField('Roll No', _rollNoController,
                            small: true)),
                  ],
                ),

                const SizedBox(
                  height: 12,
                ),

                TextField(
                  controller: _messageController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Message / Query',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _pickFile,
                  icon: Icon(Icons.attach_file),
                  label: Text('Choose Attachment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color5,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.all(14),
                  ),
                ),
                if (fileUrl != null) ...[
                  SizedBox(height: 10),
                  Text(
                    'File uploaded: $fileUrl',
                    style: TextStyle(color: Colors.green),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitQuery,
                    child: Text('Submit Query'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color5,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      textStyle:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          hintText: label,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller,
      {bool small = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: small ? 48 : null,
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: label,
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 12, vertical: small ? 8 : 16),
          ),
        ),
      ),
    );
  }
}
