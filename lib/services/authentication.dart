import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:ephysicsapp/globals/colors.dart';
import 'package:ephysicsapp/main.dart';
import 'package:ephysicsapp/screens/users/home.dart';
import 'package:ephysicsapp/widgets/popUps.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

late SharedPreferences prefs;

Future<void> initializePreferences() async {
  prefs = await SharedPreferences.getInstance();
}

// Admin login method
Future<void> login(String email, String password, BuildContext context) async {
  try {
    final FirebaseAuth _auth = FirebaseAuth.instance;

    // Attempt to sign in with email and password
    final UserCredential result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (result.user != null) {
      print("User Exists");
      final String userId = result.user!.uid;
      final DatabaseReference dbRef =
          FirebaseDatabase.instance.ref().child('Users').child(userId);

      // Fetch user data from 'Users' node
      final DataSnapshot snapshot = await dbRef.get();
      if (!snapshot.exists) {
        print("Snapshot means no data in realtime DB");
        await prefs.setBool("isLogged", true);
        Fluttertoast.showToast(
          msg: "Logged In as: $email",
          fontSize: 14,
          timeInSecForIosWeb: 6,
          toastLength: Toast.LENGTH_LONG,
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MyHomePage()),
          (Route<dynamic> route) => false,
        );
      }
      // Check if snapshot exists and extract the role
      if (snapshot.exists) {
        final Map<dynamic, dynamic> userData =
            snapshot.value as Map<dynamic, dynamic>;
        final String role = userData['role'] ?? '';

        // If role is not 'Student', log in as admin
        if (role != 'Student') {
          await prefs.setBool("isLogged", true);
          Fluttertoast.showToast(
            msg: "Logged In as: $email",
            fontSize: 14,
            timeInSecForIosWeb: 6,
            toastLength: Toast.LENGTH_LONG,
          );

          // Navigate to the home page and clear all previous routes
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => MyHomePage()),
            (Route<dynamic> route) => false,
          );
        } else {
          // User is a student; show toast and sign out
          Fluttertoast.showToast(
            msg: "Cannot log in as Admin. User is a Student.",
            fontSize: 14,
            timeInSecForIosWeb: 6,
            toastLength: Toast.LENGTH_LONG,
          );
          await _auth.signOut();
        }
      } else {
        // No user data found in the database, treat as error
        Fluttertoast.showToast(
          msg: "User data not found.",
          fontSize: 14,
          timeInSecForIosWeb: 6,
          toastLength: Toast.LENGTH_LONG,
        );
        await _auth.signOut();
      }
    }
  } on FirebaseAuthException catch (e) {
    // Handle specific Firebase authentication errors
    if (e.code == 'user-not-found' || e.code == 'wrong-password') {
      Fluttertoast.showToast(msg: "Invalid Credentials", timeInSecForIosWeb: 6);
    } else {
      Fluttertoast.showToast(
          msg: "Login Failed: ${e.message}", timeInSecForIosWeb: 6);
    }
  } catch (e) {
    // Handle any other errors
    print('Error: $e');
    Fluttertoast.showToast(
        msg: "An error occurred. Please try again.", timeInSecForIosWeb: 6);
  }
}

Future<void> Studentregister(
  String email,
  String name,
  String classdiv,
  String password,
  String collegeName,
  BuildContext context,
) async {
  try {
    print("Registration Init");
    FirebaseAuth _auth = FirebaseAuth.instance;
    GoogleSignIn googleSignIn = GoogleSignIn();

    // Check if there's a signed-in Google account
    GoogleSignInAccount? currentUser = googleSignIn.currentUser;

    // Sign out if there's a user signed in
    if (currentUser != null) {
      print("Has currentUser ${currentUser}");
      await googleSignIn.signOut();
      await googleSignIn.disconnect();
    } else {
      print("No currentUser");
    }

    // Attempt to sign in with Google, prompting the account picker
    GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    // Start creating user with email and password
    final userCreation = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final dbRef = FirebaseDatabase.instance.ref();

    // If Google account was selected, link it with the Firebase Authentication user
    if (googleUser != null) {
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      OAuthCredential googleCredential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Check if the Google account email matches the provided email
      if (googleUser.email.toLowerCase() != email.toLowerCase()) {
        print("The Google account email does not match the provided email.");
        Fluttertoast.showToast(
          msg:
              "The Google account email does not match the provided email. Please try again.",
          timeInSecForIosWeb: 6,
        );

        // Instead of deleting the account, just sign out the user
        await userCreation.user!.delete();
        await googleSignIn.disconnect();
        await _auth.signOut();
        return;
      }

      // Link Google account with the Firebase Authentication user
      await userCreation.user!.linkWithCredential(googleCredential);
      print("Account linked with Google successfully");

      // Show a success message for Google linking
      Fluttertoast.showToast(
        msg: "User Account Created and Linked with Google Successfully",
        timeInSecForIosWeb: 6,
      );
    } else {
      // Show a success message for email/password registration only
      Fluttertoast.showToast(
        msg: "User Account Created Successfully with Email/Password",
        timeInSecForIosWeb: 6,
      );
    }

    // Save user details to the Realtime Database
    await dbRef.child('Users').child(userCreation.user!.uid).set({
      'name': name,
      'classDiv': classdiv,
      'college': collegeName,
      'email': email,
      'role': 'Student',
    });

    // Navigate back to the previous screen
    Navigator.pop(context);
  } catch (e) {
    // Handle registration errors
    print(e.toString());
    Fluttertoast.showToast(
      msg: "Error in registration: ${e.toString()}",
      timeInSecForIosWeb: 6,
    );

    // Ensure user is fully signed out on error to prevent cached accounts
    GoogleSignIn googleSignIn = GoogleSignIn();
    await googleSignIn.disconnect();
    await googleSignIn.signOut();
    FirebaseAuth.instance.signOut();
  }
}

// Optimized Student login method
Future<void> studentLogin(
    String email, String password, BuildContext context) async {
  try {
    print("Student login begins");
    FirebaseAuth _auth = FirebaseAuth.instance;
    DatabaseReference dbRef = FirebaseDatabase.instance.ref();

    // Start Firebase Authentication login
    final signInFuture =
        _auth.signInWithEmailAndPassword(email: email, password: password);

    // Execute sign-in and get user data concurrently
    UserCredential result = await signInFuture.catchError((e) {
      print("Firebase Auth Error: ${e.toString()}");
      Fluttertoast.showToast(
        msg: "Invalid Credentials",
        timeInSecForIosWeb: 6,
      );
      throw e;
    });

    // Check if user login was successful
    if (result.user == null) return;

    String userId = result.user!.uid;

    // Fetch user data from Firebase Database in parallel
    final snapshot = await dbRef.child('Users/$userId').get();

    if (snapshot.exists) {
      Map<dynamic, dynamic> userData = snapshot.value as Map<dynamic, dynamic>;
      String role = userData['role'] ?? '';

      if (role == 'Student') {
        print('Role is Student');
        await prefs.setString('studentUUID', userId);
        await prefs.setBool('isStudentLoggedIn', true);

        showToast("Logged In as Student: $email");
        print("Logged In as Student: $email");

        print(prefs.getBool("isStudentLoggedIn"));

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MyApp()),
          (Route<dynamic> route) => false,
        );

        // Notify MyAppState of user login
        final myAppState = context.findAncestorStateOfType<MyAppState>();
        myAppState?.onUserLogin(userId);
      } else {
        showToast("You are not authorized to log in as a student.");
        await _auth.signOut();
      }
    } else {
      // User not found in Realtime Database
      print("User not found in Firebase Database");
      Fluttertoast.showToast(
        msg: "You are not authorized to log in as a student.",
        timeInSecForIosWeb: 6,
      );
      await _auth.signOut();
    }
  } catch (e) {
    print("Error in studentLogin: ${e.toString()}");
    Fluttertoast.showToast(
      msg: "Incorrect Credentials! / No Account Found",
      timeInSecForIosWeb: 6,
    );
  }
}

// Logout method
Future<void> onLogout(BuildContext context) async {
  // Show confirmation dialog
  bool? confirmLogout = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        icon: CircleAvatar(
          child: Icon(
            Icons.exit_to_app,
            color: Colors.black,
          ),
          backgroundColor: Colors.grey,
          radius: 24,
        ),
        title: Text(
          'Logout',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          textAlign: TextAlign.center,
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(false); // User cancels logout
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.black,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.grey,
                ),
              ),
              SizedBox(width: 8), // Space between buttons
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(true); // User confirms logout
                },
                child: Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: color5,
                ),
              ),
            ],
          ),
        ],
      );
    },
  );

  // If user cancels, do nothing
  if (confirmLogout != true) {
    return;
  }

  // User confirmed logout; proceed with logout operations
  try {
    final myAppState = context.findAncestorStateOfType<MyAppState>();
    if (myAppState != null) {
      await myAppState.onUserLogout(); // End session and stop tracking
    }

    // Proceed with Firebase sign out
    await FirebaseAuth.instance.signOut();

    // Ensure Google Sign-In is initialized
    GoogleSignIn googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();

    // Reset login preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all preferences

    showToast("Logout Successful");

    // Navigate to the login screen and clear all routes
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (BuildContext context, Animation<double> animation,
              Animation<double> secondaryAnimation) {
            return MyApp();
          },
        ),
        (Route route) => false,
      );
    }
  } catch (e) {
    print("Error during logout: $e");
    showToast("Logout Failed. Please try again.");
  }
}

// Method to check if the user is logged in as admin
bool isLoggedIn() {
  return (prefs.getBool('isLogged') ?? false);
}

// Method to check if the student is logged in
bool isStudentLoggedIn() {
  return (prefs.getBool('isStudentLoggedIn') ?? false);
}

// Optimized Google Student Login Method
Future<void> studentLoginWithGoogle(BuildContext context) async {
  late final GoogleSignIn googleSignIn;
  late final FirebaseAuth auth;

  try {
    // Initialize services only once
    googleSignIn = GoogleSignIn();
    auth = FirebaseAuth.instance;

    // Get Google account - required step, can't be parallelized
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      Fluttertoast.showToast(msg: "Sign-in cancelled", timeInSecForIosWeb: 4);
      return;
    }

    // Run authentication tasks in parallel
    final Future<GoogleSignInAuthentication> authFuture =
        googleUser.authentication;
    final Future<List<String>> methodsFuture =
        auth.fetchSignInMethodsForEmail(googleUser.email);

    final List<dynamic> results =
        await Future.wait([authFuture, methodsFuture]);
    final GoogleSignInAuthentication googleAuth = results[0];
    final List<String> signInMethods = results[1];

    if (signInMethods.isNotEmpty && !signInMethods.contains('google.com')) {
      await Future.wait([
        googleSignIn.disconnect(),
        auth.signOut(),
      ]);
      Fluttertoast.showToast(
          msg: "Please use email login", timeInSecForIosWeb: 4);
      return;
    }

    // Sign in to Firebase
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential result = await auth.signInWithCredential(credential);
    if (result.user == null) {
      Fluttertoast.showToast(msg: "Sign-in failed", timeInSecForIosWeb: 4);
      return;
    }

    // Fetch user data and prepare navigation in parallel
    final String userId = result.user!.uid;
    final DatabaseReference dbRef = FirebaseDatabase.instance.ref();

    final DataSnapshot snapshot = await dbRef.child('Users/$userId').get();

    if (!snapshot.exists) {
      await Future.wait([
        googleSignIn.disconnect(),
        auth.signOut(),
      ]);
      Fluttertoast.showToast(msg: "No account found", timeInSecForIosWeb: 4);
      return;
    }

    final userData = snapshot.value as Map<dynamic, dynamic>;
    final String role = userData['role'] ?? '';

    if (role == 'Student') {
      // Set preferences in parallel
      await Future.wait([
        prefs.setString('studentUUID', userId),
        prefs.setBool('isStudentLoggedIn', true),
      ]);

      // Navigate and update state
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => MyApp()),
        (route) => false,
      );

      context.findAncestorStateOfType<MyAppState>()?.onUserLogin(userId);
      Fluttertoast.showToast(msg: "Login successful", timeInSecForIosWeb: 4);
    } else {
      await Future.wait([
        googleSignIn.disconnect(),
        auth.signOut(),
      ]);
      Fluttertoast.showToast(
          msg: "Not authorized as student", timeInSecForIosWeb: 4);
    }
  } catch (e) {
    print("Login error: $e");
    await Future.wait([
      googleSignIn.disconnect(),
      auth.signOut(),
    ].whereType<Future>().toList());
    Fluttertoast.showToast(msg: "Login failed", timeInSecForIosWeb: 4);
  }
}

// Optimized Admin Google Login Method
Future<void> adminLoginWithGoogle(BuildContext context) async {
  try {
    FirebaseAuth _auth = FirebaseAuth.instance;
    GoogleSignIn googleSignIn = GoogleSignIn();

    // Attempt to sign in using Google account
    GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      Fluttertoast.showToast(
          msg: "Google sign-in cancelled", timeInSecForIosWeb: 6);
      return;
    }

    GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // First, check if an account exists with this email
    String googleEmail = googleUser.email;
    List<String> signInMethods =
        await _auth.fetchSignInMethodsForEmail(googleEmail);

    // If there are sign-in methods but Google is not one of them
    if (signInMethods.isNotEmpty && !signInMethods.contains('google.com')) {
      Fluttertoast.showToast(
          msg:
              "This email is registered with email/password only. Please use email login.",
          fontSize: 14,
          timeInSecForIosWeb: 6,
          toastLength: Toast.LENGTH_LONG);
      await googleSignIn.disconnect();
      return;
    }

    // Create Google credential
    OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Sign in with the Google credential
    UserCredential result = await _auth.signInWithCredential(credential);
    if (result.user == null) {
      Fluttertoast.showToast(
          msg: "Firebase sign-in failed", timeInSecForIosWeb: 6);
      return;
    }

    print("User Exists");
    String userId = result.user!.uid;
    DatabaseReference dbRef = FirebaseDatabase.instance.ref();

    // Fetch user data from Firebase Database
    DataSnapshot snapshot = await dbRef.child('Users/$userId').get();

    // Check if the user data exists and is not a student
    if (snapshot.exists) {
      Map<dynamic, dynamic> userData = snapshot.value as Map<dynamic, dynamic>;
      String role = userData['role'] ?? '';

      if (role != 'Student') {
        print("Logged In as Admin");
        prefs.setBool("isLogged", true); // Mark as admin logged in

        Fluttertoast.showToast(
          msg: "Logged In as Admin: ${result.user!.email}",
          fontSize: 14,
          timeInSecForIosWeb: 6,
          toastLength: Toast.LENGTH_LONG,
        );

        // Navigate to the admin home page and clear navigation stack
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MyHomePage()),
          (Route<dynamic> route) => false,
        );
      } else {
        print("Cannot log in as Admin. User is a Student.");
        Fluttertoast.showToast(
          msg: "Cannot log in as Admin. User is a Student.",
          fontSize: 14,
          timeInSecForIosWeb: 6,
          toastLength: Toast.LENGTH_LONG,
        );
        await googleSignIn.disconnect(); // Log out and clear Google cache
        await _auth.signOut();
      }
    } else {
      print("No account found in the database.");
      Fluttertoast.showToast(
        msg: "No Account Found for this Google account.",
        timeInSecForIosWeb: 6,
        toastLength: Toast.LENGTH_LONG,
      );
      await googleSignIn.disconnect(); // Clear Google cache
      await _auth.signOut();
    }
  } catch (e) {
    print("Error: $e");
    Fluttertoast.showToast(
      msg: "Google login failed. Please try again.",
      timeInSecForIosWeb: 6,
    );

    // Clear Google account info to allow re-selection on retry
    GoogleSignIn googleSignIn = GoogleSignIn();
    await googleSignIn.disconnect();
    FirebaseAuth.instance.signOut();
  }
}

Future<void> studentLoginWithApple(BuildContext context) async {
  try {
    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    final oauthCredential = OAuthProvider("apple.com").credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );

    await FirebaseAuth.instance.signInWithCredential(oauthCredential);
    Navigator.pushReplacementNamed(context, '/studentHome');
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Apple sign-in failed: $e')),
    );
  }
}

// Utility functions
String _generateNonce([int length = 32]) {
  final charset =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
  final random = Random.secure();
  return List.generate(length, (_) => charset[random.nextInt(charset.length)])
      .join();
}

String _sha256ofString(String input) {
  final bytes = utf8.encode(input);
  final digest = sha256.convert(bytes);
  return digest.toString();
}
