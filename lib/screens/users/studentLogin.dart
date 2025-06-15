import 'dart:io';

import 'package:ephysicsapp/globals/colors.dart';
import 'package:ephysicsapp/screens/users/studentRegistration.dart';
import 'package:ephysicsapp/services/authentication.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final email = studentemailController.text.trim();
    final password = studentpasswordController.text;

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (email.isEmpty || !emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email')),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password cannot be empty')),
      );
      return;
    }

    if (_formKeyValue.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        await studentLogin(email, password, context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login failed! Please try again')),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
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

              /// Modern Email TextField (Radius 15, Small Height)
              TextFormField(
                controller: studentemailController,
                validator: (value) {
                  if (value!.isEmpty) return "Enter Email";
                  return null;
                },
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Enter Email",
                  prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[700]),
                  filled: true,
                  fillColor: Colors.grey[100],
                  labelStyle: TextStyle(color: Colors.grey[700]),
                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16), // Reduced height
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: color5, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.grey.shade300),
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
                  labelText: "Enter Password",
                  prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[700]),
                  suffixIcon: IconButton(
                    icon: Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: Icon(
                        _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey[700],
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  labelStyle: TextStyle(color: Colors.grey[700]),
                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16), // Reduced height
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: color5, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.grey.shade300),
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
                    padding: EdgeInsets.symmetric(
                        vertical: 10, horizontal: 30),
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

              Row(
                children: <Widget>[
                  Expanded(
                    child: Divider(
                      color: Colors.grey,
                      thickness: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      "OR",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: Colors.grey,
                      thickness: 1,
                    ),
                  ),
                ],
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
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: EdgeInsets.symmetric(
                        vertical: 12, horizontal: 24),
                    elevation: 2,
                  ),
                  onPressed: () async {
                    setState(() {
                      isGoogleLoading = true; // Start loading
                    });
                    await studentLoginWithGoogle(context);
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
                        color: Colors.white,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Sign in with Google',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height / 100),

              // Apple Sign-In Button
              (Platform.isIOS)
                  ? Column(
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height / 100),
                      Container(
                      height: MediaQuery.of(context).size.height / 16,
                      width: MediaQuery.of(context).size.width - 20.0,
                        child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: EdgeInsets.symmetric(
                            vertical: 12, horizontal: 24),
                        elevation: 2,
                      ),
                      onPressed: () async {
                        await studentLoginWithApple(context);
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
                                    ),
                    ],
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
                          shadows: [
                            Shadow(color: color5, offset: Offset(0, -2))
                          ],
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
      ),
    );
  }
}