import 'dart:io';

import 'package:ephysicsapp/globals/colors.dart';
import 'package:ephysicsapp/services/mailService.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:path/path.dart' as path;
import 'package:shimmer/shimmer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

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

  List<String> fileUrls = [];
  List<String> fileNames = [];
  List<File> selectedFiles = [];

  bool _isLoading = true;
  bool _isUploading = false;
  bool _isSubmitting = false;

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
    if (selectedFiles.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum 3 files can be attached')),
      );
      return;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null) {
        PlatformFile file = result.files.first;

        setState(() {
          selectedFiles.add(File(file.path!));
          fileNames.add(file.name);
        });
      }
    } catch (e) {
      print('Error picking file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick file: ${e.toString()}')),
      );
    }
  }

  Future<void> _submitQuery() async {
    if (_messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Message is required')),
      );
      return;
    }

    if (_rollNoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Roll No / PRN No is Required')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Upload files first
        fileUrls.clear();
        for (int i = 0; i < selectedFiles.length; i++) {
          String fileName = path.basename(selectedFiles[i].path);
          final ref =
              FirebaseStorage.instance.ref().child('queries').child(fileName);
          final uploadTask = ref.putFile(selectedFiles[i]);
          await uploadTask.whenComplete(() async {
            String downloadUrl = await ref.getDownloadURL();
            fileUrls.add(downloadUrl);
          });
        }

        // Then push to Realtime DB
        DatabaseReference queryRef =
            FirebaseDatabase.instance.ref().child('Queries').push();
        await queryRef.set({
          'name': _nameController.text,
          'email': _emailController.text,
          'classDiv': _classDivController.text,
          'rollNo': _rollNoController.text,
          'message': _messageController.text,
          'attachments': fileUrls,
          'timestamp': ServerValue.timestamp,
        });

        await MailServices().sendEmail(
          name: _nameController.text,
          email: _emailController.text,
          classDiv: _classDivController.text,
          rollNo: _rollNoController.text,
          message: _messageController.text,
          attachmentUrls: fileUrls,
        );

        // Clear form
        _messageController.clear();
        setState(() {
          fileUrls = [];
          fileNames = [];
          selectedFiles = [];
        });

        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: Colors.white.withOpacity(0.9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text('Success',
                style: TextStyle(fontWeight: FontWeight.bold, color: color5)),
            content: Text('Your query has been submitted successfully.'),
            actions: [
              TextButton(
                onPressed: () {
                  if (mounted) Navigator.of(context).pop();
                },
                child: Text('OK', style: TextStyle(color: color5)),
              )
            ],
          ),
        );
      }
    } catch (e) {
      print('Error submitting query: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit query: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Submit a Query',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _isLoading ? _buildShimmer() : _buildQueryForm(),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.9),
                  Colors.white.withOpacity(0.95),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header shimmer
                  Container(
                    width: 200,
                    height: 24,
                    color: Colors.white,
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 16,
                    color: Colors.white,
                  ),
                  SizedBox(height: 24),

                  // Field shimmers
                  Container(
                    height: 56,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    height: 56,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  SizedBox(height: 24),
                  Container(
                    height: 48,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  SizedBox(height: 24),
                  Container(
                    height: 56,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQueryForm() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24),
        child: Container(
          decoration: BoxDecoration(
            color: color3,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
            // boxShadow: [
            //   BoxShadow(
            //     color: Colors.grey.withOpacity(0.1),
            //     blurRadius: 20,
            //     spreadRadius: 1,
            //     offset: Offset(0, 8),
            //   ),
            // ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
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
                          "Fill in the form below, and we'll get in touch with you shortly.",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
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
                          child: _buildEditableField(
                              'Roll No', _rollNoController,
                              small: true)),
                    ],
                  ),

                  const SizedBox(height: 5),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _messageController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Message / Query',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        alignLabelWithHint: true,
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: Colors.grey.shade200.withOpacity(0.5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: color5, width: 1.5),
                        ),
                        contentPadding: EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_isUploading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: SpinKitThreeBounce(
                        color: color5,
                        size: 20,
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [
                            color5.withOpacity(0.8),
                            color5.withOpacity(1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color5.withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 1,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _pickFile,
                        icon: Icon(Icons.attach_file, color: Colors.white),
                        label: Text(
                          'Choose Attachment',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.all(14),
                          elevation: 0,
                        ),
                      ),
                    ),

                  if (selectedFiles.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: List.generate(selectedFiles.length, (index) {
                        return Chip(
                          label: Text(
                            path.basename(selectedFiles[index].path),
                            style: TextStyle(fontSize: 12),
                          ),
                          deleteIcon: Icon(Icons.close, size: 16),
                          onDeleted: () {
                            setState(() {
                              selectedFiles.removeAt(index);
                            });
                          },
                          backgroundColor: Colors.white.withOpacity(0.7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                                color: Colors.grey.shade200, width: 1),
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${selectedFiles.length}/3 attached',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [
                            color5.withOpacity(0.8),
                            color5.withOpacity(1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color5.withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 1,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitQuery,
                        child: _isSubmitting
                            ? SizedBox(
                                height: 24,
                                width: 24,
                                child: SpinKitFadingCircle(
                                  color: color1,
                                ))
                            : Text(
                                'Submit Query',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white),
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
        style: TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(color: Colors.grey[500]),
          filled: true,
          fillColor: Colors.white.withOpacity(0.7),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: Colors.grey.shade200.withOpacity(0.5), width: 1),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller,
      {bool small = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: small ? 56 : null,
        child: TextField(
          controller: controller,
          style: TextStyle(color: Colors.black87),
          decoration: InputDecoration(
            hintText: label,
            hintStyle: TextStyle(color: Colors.grey[500]),
            filled: true,
            fillColor: Colors.white.withOpacity(0.7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: Colors.grey.shade200.withOpacity(0.5), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color5, width: 1.5),
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16, vertical: small ? 8 : 8),
          ),
        ),
      ),
    );
  }
}
