import 'dart:io';

import 'package:ephysicsapp/globals/colors.dart';
import 'package:ephysicsapp/services/authentication.dart';
import 'package:ephysicsapp/widgets/popUps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

class StudentRegister extends StatefulWidget {
  const StudentRegister({Key? key}) : super(key: key);

  @override
  State<StudentRegister> createState() => _StudentRegisterState();
}

class _StudentRegisterState extends State<StudentRegister> {
  String password = '';
  String confirmPassword = '';

  bool hasUppercase = false;
  bool hasSpecialChar = false;
  bool hasNumber = false;
  bool hasMinLength = false;
  bool isPasswordMatching = false;

  FocusNode passwordFocusNode = FocusNode();
  bool isPasswordFieldFocused = false;

  final GlobalKey<FormState> _formKeyValue = GlobalKey<FormState>();

  TextEditingController studentAccCreationemailController =
      TextEditingController();
  TextEditingController studentAccCreationnameController =
      TextEditingController();
  TextEditingController studentAccCreationYearDivController =
      TextEditingController();
  TextEditingController studentAccCreationpasswordController =
      TextEditingController();
  TextEditingController otherCollegeNameController = TextEditingController();

  // Track the selected college radio button
  String _selectedCollege = 'Sakec';
  bool _isOtherCollegeSelected = false;

  bool _isPasswordVisible = false; // Track password visibility
  bool _isConfPasswordVisible = false;

  bool isLoading = false;

  // Future<void> checkValidation() async {
  //   if (!_formKeyValue.currentState!.validate()) {
  //     showToast("Please fill all the fields correctly");
  //     return;
  //   }
  //
  //   if (!hasUppercase || !hasSpecialChar || !hasNumber || !hasMinLength) {
  //     showToast("Password does not meet all criteria");
  //     return;
  //   }
  //
  //   if (!isPasswordMatching) {
  //     showToast("Passwords do not match");
  //     return;
  //   }
  //
  //   String collegeName =
  //       _selectedCollege == 'Sakec' ? 'Sakec' : otherCollegeNameController.text;
  //
  //   // Platform-aware sign-in choice
  //   String? chosenProvider = await showDialog<String>(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Text("Choose Sign-In Method"),
  //         content: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             ListTile(
  //               leading: Icon(Icons.account_circle),
  //               title: Text("Google Sign-In"),
  //               onTap: () => Navigator.of(context).pop('google'),
  //             ),
  //             if (Platform.isIOS) // Only show Apple Sign-In on iOS
  //               ListTile(
  //                 leading: Icon(Icons.apple),
  //                 title: Text("Apple Sign-In"),
  //                 onTap: () => Navigator.of(context).pop('apple'),
  //               ),
  //             ListTile(
  //               leading: Icon(Icons.person_outline),
  //               title: Text("Skip (No Social Sign-In)"),
  //               onTap: () => Navigator.of(context).pop('none'),
  //             ),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  //
  //   if (chosenProvider == null) return; // Dialog dismissed
  //
  //   setState(() {
  //     isLoading = true;
  //   });
  //
  //   try {
  //     // Register student account
  //     await Studentregister(
  //       studentAccCreationemailController.text,
  //       studentAccCreationnameController.text,
  //       studentAccCreationYearDivController.text,
  //       studentAccCreationpasswordController.text,
  //       collegeName,
  //       context,
  //     );
  //
  //     // Perform sign-in based on choice
  //     switch (chosenProvider) {
  //       case 'google':
  //         await studentLoginWithGoogle(
  //             context); // <-- Your existing Google sign-in logic
  //         break;
  //       case 'apple':
  //         await studentLoginWithApple(
  //             context); // <-- You'll implement this next
  //         break;
  //       case 'none':
  //         break;
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Registration failed! Please try again')),
  //     );
  //   } finally {
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }

  Future<void> checkValidation() async {
    if (!_formKeyValue.currentState!.validate()) {
      showToast("Please fill all the fields correctly");
      return;
    }

    if (!hasUppercase || !hasSpecialChar || !hasNumber || !hasMinLength) {
      showToast("Password does not meet all criteria");
      return;
    }

    if (!isPasswordMatching) {
      showToast("Passwords do not match");
      return;
    }

    String collegeName =
    _selectedCollege == 'Sakec' ? 'Sakec' : otherCollegeNameController.text;

    // // Show the pop-up dialog to inform the user about Google Sign-In
    // await showDialog(
    //   context: context,
    //   barrierDismissible: false,
    //   builder: (BuildContext context) {
    //     return AlertDialog(
    //       title: Text("Important Notice"),
    //       content: Text(
    //         "A Google Sign-In popup will appear. If you don't wish to link your Google account, please press the back button on your device to skip linking. This is required to complete registration.",
    //       ),
    //       actions: <Widget>[
    //         TextButton(
    //           onPressed: () {
    //             Navigator.of(context).pop(); // Close the dialog
    //           },
    //           child: Text("Got it"),
    //         ),
    //       ],
    //     );
    //   },
    // );

    setState(() {
      isLoading = true;
    });
    try {
      await Studentregister(
        studentAccCreationemailController.text,
        studentAccCreationnameController.text,
        studentAccCreationYearDivController.text,
        studentAccCreationpasswordController.text,
        collegeName,
        context,
      );
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


  @override
  void initState() {
    super.initState();
    passwordFocusNode.addListener(() {
      setState(() {
        isPasswordFieldFocused = passwordFocusNode.hasFocus;
      });
    });
  }

  void checkPasswordStrength(String password) {
    setState(() {
      this.password = password;
      hasUppercase = password.contains(RegExp(r'[A-Z]'));
      hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      hasNumber = password.contains(RegExp(r'[0-9]'));
      hasMinLength = password.length >= 8 && password.length <= 20;
    });
  }

  void checkPasswordMatch(String confirmPassword) {
    setState(() {
      this.confirmPassword = confirmPassword;
      isPasswordMatching = password == confirmPassword;
    });
  }

  Widget buildPasswordCriteriaIcon(bool criteria) {
    return Icon(
      criteria ? Icons.check_circle : Icons.cancel,
      color: criteria ? Colors.green : Colors.red,
    );
  }

  Widget buildPasswordCheckConditions() {
    if (hasUppercase == true &&
        hasMinLength == true &&
        hasNumber == true &&
        hasSpecialChar == true) {
      return Icon(
        Icons.check_circle,
        color: Colors.green,
      );
    }
    return Icon(
      Icons.cancel,
      color: Colors.red,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Create An Account'),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKeyValue,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  height: MediaQuery.of(context).size.height / 80,
                ),
                Text(
                  "Student Register",
                  style: GoogleFonts.merriweather(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      color: color5),
                ),
                SizedBox(height: 30),
                TextFormField(
                  controller: studentAccCreationnameController,
                  validator: (value) {
                    if (value!.isEmpty) return "Enter Name";
                    return null;
                  },
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    labelStyle: TextStyle(color: Colors.grey[700]),
                    prefixIcon: Icon(Icons.person_2_outlined, color: Colors.grey[700]), // optional
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: color5, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    border: OutlineInputBorder(),
                    labelText: "Enter Name",
                  ),
                ),
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      Text(
                        "Select College : ",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w400),
                      ),
                      SizedBox(width: MediaQuery.of(context).size.width *
                          0.01),
                      Expanded(
                        child: Wrap(
                          alignment: WrapAlignment
                              .center, // Ensures items are centered
                          spacing: MediaQuery.of(context).size.width *
                              0.02, // Responsive spacing
                          runSpacing: MediaQuery.of(context).size.height *
                              0.01, // Prevents tight stacking
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize
                                  .min, // Prevents extra space issues
                              children: [
                                Radio<String>(
                                  value: 'Sakec',
                                  groupValue: _selectedCollege,
                                  onChanged: (String? value) {
                                    setState(() {
                                      _selectedCollege = value!;
                                      _isOtherCollegeSelected = false;
                                    });
                                  },
                                ),
                                Text(
                                  'SAKEC',
                                  style: GoogleFonts.roboto(
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                            0.04, // Responsive text
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FontStyle.normal,
                                    color: color5,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Radio<String>(
                                  value: 'Others',
                                  groupValue: _selectedCollege,
                                  onChanged: (String? value) {
                                    setState(() {
                                      _selectedCollege = value!;
                                      _isOtherCollegeSelected = true;
                                    });
                                  },
                                ),
                                Text(
                                  'OTHER',
                                  style: GoogleFonts.roboto(
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                            0.04,
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FontStyle.normal,
                                    color: color5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isOtherCollegeSelected)
                  Column(
                    children: [
                      SizedBox(
                        height: 10,
                      ),
                      TextFormField(
                        controller: otherCollegeNameController,
                        validator: (value) {
                          if (_isOtherCollegeSelected && value!.isEmpty) {
                            return "Enter College Name";
                          }
                          return null;
                        },
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          labelStyle: TextStyle(color: Colors.grey[700]),
                          prefixIcon: Icon(Icons.school_outlined, color: Colors.grey[700]), // optional
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: color5, width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          border: OutlineInputBorder(),
                          hintMaxLines: 2,
                          labelText: "Enter College Name",
                        ),
                      ),
                    ],
                  ),
                SizedBox(height: 20),
                TextFormField(
                  controller: studentAccCreationemailController,
                  validator: (value) {
                    if (value!.isEmpty) return "Enter Email";
                    return null;
                  },
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    labelStyle: TextStyle(color: Colors.grey[700]),
                    prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[700]), // optional
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: color5, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    border: OutlineInputBorder(),
                    labelText: "Enter Email",
                  ),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: studentAccCreationYearDivController,
                  validator: (value) {
                    if (value!.isEmpty) return "Enter Class-Div";
                    return null;
                  },
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    labelStyle: TextStyle(color: Colors.grey[700]),
                    prefixIcon: Icon(Icons.class_outlined, color: Colors.grey[700]), // optional
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: color5, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),

                    border: OutlineInputBorder(),
                    labelText: "Enter Class-Div",
                    hintText: "Enter like Eg. FE-9",
                  ),
                ),
                SizedBox(height: 20),
                TextFormField(
                  focusNode: passwordFocusNode,
                  controller: studentAccCreationpasswordController,
                  validator: (value) {
                    if (value!.isEmpty) return "Enter Password";
                    return null;
                  },
                  onChanged: (value) {
                    checkPasswordStrength(value); // Real-time check
                  },
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    labelStyle: TextStyle(color: Colors.grey[700]),
                    prefixIcon: Icon(Icons.lock_outline_rounded, color: Colors.grey[700]), // optional
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: color5, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),

                    border: const OutlineInputBorder(),
                    labelText: "Enter Password",
                    hintText: 'Enter your password',
                    // Adjusting the suffix icon for consistent height
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
                          buildPasswordCheckConditions(),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                if (isPasswordFieldFocused)
                  Column(
                    children: [
                      Row(
                        children: [
                          buildPasswordCriteriaIcon(hasUppercase),
                          SizedBox(width: 10),
                          Text("At least 1 uppercase letter"),
                        ],
                      ),
                      Row(
                        children: [
                          buildPasswordCriteriaIcon(hasSpecialChar),
                          SizedBox(width: 10),
                          Text("At least 1 special character"),
                        ],
                      ),
                      Row(
                        children: [
                          buildPasswordCriteriaIcon(hasNumber),
                          SizedBox(width: 10),
                          Text("At least 1 number"),
                        ],
                      ),
                      Row(
                        children: [
                          buildPasswordCriteriaIcon(hasMinLength),
                          SizedBox(width: 10),
                          Text("8-20 characters long"),
                        ],
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                TextFormField(
                  validator: (value) {
                    if (value!.isEmpty) return "Enter Confirm Password";
                    return null;
                  },
                  obscureText: !_isConfPasswordVisible,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    labelStyle: TextStyle(color: Colors.grey[700]),
                    prefixIcon: Icon(Icons.lock_outline_rounded, color: Colors.grey[700]), // optional
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: color5, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Row(
                        mainAxisSize:
                            MainAxisSize.min, // Use min to avoid extra width
                        children: [
                          IconButton(
                            icon: Icon(
                              _isConfPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _isConfPasswordVisible =
                                    !_isConfPasswordVisible; // Toggle visibility
                              });
                            },
                          ),
                          buildPasswordCriteriaIcon(isPasswordMatching),
                        ],
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    checkPasswordMatch(value);
                  },
                ),
                SizedBox(height: 20),
                isLoading
                    ? SpinKitFadingCircle(
                        color: color5,
                        size: 30.0,
                      )
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              vertical: 10, horizontal: 30),
                          backgroundColor: color5,
                        ),
                        onPressed: () {
                          checkValidation();
                        },
                        child: Text(
                          'Register',
                          style: TextStyle(fontSize: 18, color: color1),
                        ),
                      ),
                SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "A Google account selection popup will appear. If you don't want to link your Google account, kindly tap outside the popup to cancel.",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
