import 'dart:io';

import 'package:ephysicsapp/globals/colors.dart';
import 'package:ephysicsapp/screens/users/studentRegistration.dart';
import 'package:ephysicsapp/services/authentication.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentLogin extends StatefulWidget {
  const StudentLogin({Key? key}) : super(key: key);

  @override
  State<StudentLogin> createState() => _StudentLoginState();
}

class _StudentLoginState extends State<StudentLogin> {
  final GlobalKey<FormState> _formKeyValue = GlobalKey<FormState>();
  TextEditingController studentemailController = TextEditingController();
  TextEditingController studentpasswordController = TextEditingController();
  bool isLoading = false;
  bool _isPasswordVisible = false;
  bool isGoogleLoading = false;

  // Function to reset password
  Future<void> resetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Password reset email sent. Please check your inbox.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending password reset email: $e')),
      );
    }
  }

  Future<void> checkValidation() async {
    if (_formKeyValue.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });
      try {
        await studentLogin(
          studentemailController.text,
          studentpasswordController.text,
          context,
        );

        await saveStudentDataToPrefs();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed! Please Try Again')),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> saveStudentDataToPrefs() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await FirebaseDatabase.instance
          .ref()
          .child('Users')
          .child(user.uid)
          .get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('name', data['name'] ?? '');
        await prefs.setString('email', data['email'] ?? '');
        await prefs.setString('classDiv', data['classDiv'] ?? '');
        print('Saved name: ${data['name']}');
        print('Saved email: ${data['email']}');
        print('Saved classDiv: ${data['classDiv']}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.0),
      child: Form(
        key: _formKeyValue,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(height: MediaQuery.of(context).size.height / 30),
            Text(
              "Student Login",
              style: GoogleFonts.merriweather(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
                color: color5,
              ),
            ),
            SizedBox(height: 30),
            TextFormField(
              controller: studentemailController,
              validator: (value) {
                if (value!.isEmpty) return "Enter Email";
                return null;
              },
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "Enter Email",
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(width: 2.0),
                ),
              ),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: studentpasswordController,
              validator: (value) {
                if (value!.isEmpty) return "Enter Password";
                return null;
              },
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Row(
                    mainAxisSize:
                        MainAxisSize.min, // Use min to avoid extra width
                    children: [
                      IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible =
                                !_isPasswordVisible; // Toggle visibility
                          });
                        },
                      ),
                    ],
                  ),
                ),
                labelText: "Enter Password",
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(width: 2.0),
                ),
              ),
            ),
            SizedBox(height: 30),

            isLoading
                ? SpinKitFadingCircle(
                    color: color5,
                    size: 30.0,
                  )
                : Container(
                    height: MediaQuery.of(context).size.height / 16,
                    width: MediaQuery.of(context).size.width - 20.0,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(15), // Same border radius
                        ),
                        padding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                        backgroundColor: color5,
                      ),
                      onPressed: () {
                        checkValidation();
                      },
                      child: Text(
                        'Login',
                        style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: color1,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
            SizedBox(height: MediaQuery.of(context).size.height / 50),
            isGoogleLoading
                ? SpinKitFadingCircle(
                    color: color5,
                    size: 30.0,
                  )
                : Container(
                    height: MediaQuery.of(context).size.height / 16,
                    width: MediaQuery.of(context).size.width - 20.0,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white30,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        elevation: 2,
                      ),
                      onPressed: () async {
                        setState(() {
                          isGoogleLoading = true; // Start loading
                        });
                        await studentLoginWithGoogle(context);
                        await saveStudentDataToPrefs();
                        setState(() {
                          isGoogleLoading = false; // Stop loading
                        });
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/google_icon.png',
                            width: 30,
                            height: 30,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Sign in with Google',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            SizedBox(height: MediaQuery.of(context).size.height / 100),

            // Apple Sign-In Button
            (Platform.isIOS)
                ? Container(
                    height: MediaQuery.of(context).size.height / 16,
                    width: MediaQuery.of(context).size.width - 20.0,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        elevation: 2,
                      ),
                      onPressed: () async {
                        await studentLoginWithApple(context);
                        await saveStudentDataToPrefs();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.apple, color: Colors.white, size: 28),
                          SizedBox(width: 10),
                          Text(
                            'Sign in with Apple',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SizedBox(),

            // Forgot Password Button
            TextButton(
              onPressed: () {
                if (studentemailController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter your email first.')),
                  );
                } else {
                  resetPassword(studentemailController.text);
                }
              },
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                    color: color5, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have an account?",
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              StudentRegister()), // Replace with your registration page
                    );
                  },
                  child: Text(
                    'REGISTER',
                    style: TextStyle(
                        shadows: [Shadow(color: color5, offset: Offset(0, -2))],
                        decoration: TextDecoration.underline,
                        decorationThickness: 3,
                        decorationColor: color5,
                        decorationStyle: TextDecorationStyle.solid,
                        color: Colors.transparent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
