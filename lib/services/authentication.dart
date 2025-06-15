import 'dart:convert';
import 'dart:io';
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

// Admin login method via Email / Pass
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

// Optimized Student login method via email / pass
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

// Student Login Via Apple
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

    final UserCredential result =
    await FirebaseAuth.instance.signInWithCredential(oauthCredential);
    if (result.user == null) {
      Fluttertoast.showToast(msg: "Sign-in failed", timeInSecForIosWeb: 4);
      return;
    }

    final String userId = result.user!.uid;

    final DatabaseReference dbRef = FirebaseDatabase.instance.ref();
    final DataSnapshot snapshot = await dbRef.child('Users/$userId').get();

    if (!snapshot.exists) {
      await FirebaseAuth.instance.signOut();
      Fluttertoast.showToast(msg: "No account found", timeInSecForIosWeb: 4);
      return;
    }

    final userData = snapshot.value as Map<dynamic, dynamic>;
    final String role = userData['role'] ?? '';

    // 6. Check role
    if (role == 'Student') {
      await Future.wait([
        prefs.setString('studentUUID', userId),
        prefs.setBool('isStudentLoggedIn', true),
      ]);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => MyApp()),
            (route) => false,
      );

      context.findAncestorStateOfType<MyAppState>()?.onUserLogin(userId);
      Fluttertoast.showToast(msg: "Login successful", timeInSecForIosWeb: 4);
    } else {
      await FirebaseAuth.instance.signOut();
      Fluttertoast.showToast(
          msg: "Not authorized as student", timeInSecForIosWeb: 4);
    }
  } catch (e) {
    print("Apple Login error: $e");
    await FirebaseAuth.instance.signOut();
    Fluttertoast.showToast(msg: "Login failed", timeInSecForIosWeb: 4);
  }
}

// Admin Login Via Apple
Future<void> adminLoginWithApple(BuildContext context) async {
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

    // Create OAuth credential from Apple
    final oauthCredential = OAuthProvider("apple.com").credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );

    final FirebaseAuth _auth = FirebaseAuth.instance;

    // Check if email already exists and is not linked with Apple
    if (appleCredential.email != null) {
      List<String> signInMethods =
      await _auth.fetchSignInMethodsForEmail(appleCredential.email!);

      if (signInMethods.isNotEmpty &&
          !signInMethods.contains("apple.com")) {
        Fluttertoast.showToast(
            msg:
            "This email is registered with email/password only. Please use email login.",
            fontSize: 14,
            timeInSecForIosWeb: 6,
            toastLength: Toast.LENGTH_LONG);
        return;
      }
    }

    // Sign in with Firebase
    final UserCredential result =
    await _auth.signInWithCredential(oauthCredential);

    if (result.user == null) {
      Fluttertoast.showToast(
          msg: "Firebase sign-in failed", timeInSecForIosWeb: 6);
      return;
    }

    String userId = result.user!.uid;
    final dbRef = FirebaseDatabase.instance.ref();

    final snapshot = await dbRef.child('Users/$userId').get();

    if (snapshot.exists) {
      final userData = snapshot.value as Map<dynamic, dynamic>;
      final String role = userData['role'] ?? '';

      if (role != 'Student') {
        print("Logged In as Admin");

        prefs.setBool("isLogged", true); // Mark as admin logged in

        Fluttertoast.showToast(
          msg: "Logged In as Admin: ${result.user!.email}",
          fontSize: 14,
          timeInSecForIosWeb: 6,
          toastLength: Toast.LENGTH_LONG,
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MyHomePage()),
              (route) => false,
        );
      } else {
        print("Cannot log in as Admin. User is a Student.");
        Fluttertoast.showToast(
          msg: "Cannot log in as Admin. User is a Student.",
          fontSize: 14,
          timeInSecForIosWeb: 6,
          toastLength: Toast.LENGTH_LONG,
        );
        await _auth.signOut();
      }
    } else {
      print("No account found in the database.");
      Fluttertoast.showToast(
        msg: "No Account Found for this Apple account.",
        timeInSecForIosWeb: 6,
        toastLength: Toast.LENGTH_LONG,
      );
      await _auth.signOut();
    }
  } catch (e) {
    print("Apple login failed: $e");
    Fluttertoast.showToast(
      msg: "Apple login failed. Please try again.",
      timeInSecForIosWeb: 6,
    );
    await FirebaseAuth.instance.signOut();
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


// Register
Future<void> Studentregister(
    String email,
    String name,
    String classdiv,
    String password,
    String collegeName,
    BuildContext context,
    ) async {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final dbRef = FirebaseDatabase.instance.ref();

  try {
    await FirebaseAuth.instance.signOut();
    print("Registration Init");

    // Check if there's a signed-in Google account
    GoogleSignInAccount? currentUser = googleSignIn.currentUser;
    //Sign out if there's a user signed in
    if (currentUser != null) {
      print("Has currentUser ${currentUser}");
      await googleSignIn.signOut();
       await googleSignIn.disconnect();
    } else {
      print("No currentUser");
    }

    // Platform-specific account linking flow
    if (Platform.isAndroid) {
      // Android - Show notice about Google Sign-In
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Important Notice"),
            content: const Text(
              "A Google Sign-In popup will appear. If you don't wish to link your Google account, press the back button to skip.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Got it"),
              ),
            ],
          );
        },
      );

      // Try Google Sign-In for Android
      try {
        print("Attempting Google Sign-In for Android");
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

        if (googleUser != null) {
          print("Google user selected: ${googleUser.email}");
          if (googleUser.email.toLowerCase() != email.toLowerCase()) {
            print("Email mismatch between Google and registration");
            Fluttertoast.showToast(
              msg: "Google account email doesn't match registration email",
              timeInSecForIosWeb: 6,
            );
            return;
          }

          // Create user with email/password first
          final userCredential = await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );

          // Link Google account
          final googleAuth = await googleUser.authentication;
          final credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          await userCredential.user!.linkWithCredential(credential);
          print("Google account linked successfully");

          // Save user data
          await _saveUserData(dbRef, userCredential.user!.uid, name, classdiv, collegeName, email);

          Fluttertoast.showToast(
            msg: "Account created & linked with Google",
            timeInSecForIosWeb: 6,
          );
          Navigator.pop(context);
          return;
        }
      } catch (e) {
        print("Google Sign-In skipped or failed: $e");
        // Continue with normal email/password registration
      }
    }
    else if (Platform.isIOS) {
      // iOS - Show provider selection
      final selectedProvider = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Link Account (Optional)"),
            content: const Text("Would you like to link a Google or Apple account?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop("google"),
                child: const Text("Google"),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop("apple"),
                child: const Text("Apple"),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text("Skip"),
              ),
            ],
          );
        },
      );

      if (selectedProvider != null) {
        try {
          if (selectedProvider == "google") {
            print("Attempting Google Sign-In for iOS");
            final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

            if (googleUser != null) {
              if (googleUser.email.toLowerCase() != email.toLowerCase()) {
                Fluttertoast.showToast(
                  msg: "Google account email doesn't match registration email",
                  timeInSecForIosWeb: 6,
                );
                return;
              }

              // Create user with email/password first
              final userCredential = await _auth.createUserWithEmailAndPassword(
                email: email,
                password: password,
              );

              // Link Google account
              final googleAuth = await googleUser.authentication;
              final credential = GoogleAuthProvider.credential(
                accessToken: googleAuth.accessToken,
                idToken: googleAuth.idToken,
              );
              await userCredential.user!.linkWithCredential(credential);
              print("Google account linked successfully");

              await _saveUserData(dbRef, userCredential.user!.uid, name, classdiv, collegeName, email);

              Fluttertoast.showToast(
                msg: "Account created & linked with Google",
                timeInSecForIosWeb: 6,
              );
              Navigator.pop(context);
              return;
            }
          }
          else if (selectedProvider == "apple") {
            print("Attempting Apple Sign-In");
            final appleProvider = AppleAuthProvider();
            final userCredential = await _auth.createUserWithEmailAndPassword(
              email: email,
              password: password,
            );

            // Link Apple account
            await userCredential.user!.linkWithProvider(appleProvider);
            print("Apple account linked successfully");

            await _saveUserData(dbRef, userCredential.user!.uid, name, classdiv, collegeName, email);

            Fluttertoast.showToast(
              msg: "Account created & linked with Apple",
              timeInSecForIosWeb: 6,
            );
            Navigator.pop(context);
            return;
          }
        } catch (e) {
          print("$selectedProvider Sign-In failed: $e");
          Fluttertoast.showToast(
            msg: "Account linking failed. Creating email/password account only",
            timeInSecForIosWeb: 6,
          );
          // Continue with normal registration
        }
      }
    }

    // Fallback to normal email/password registration if linking skipped or failed
    print("Creating email/password account only");
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _saveUserData(dbRef, userCredential.user!.uid, name, classdiv, collegeName, email);

    Fluttertoast.showToast(
      msg: "Account created successfully",
      timeInSecForIosWeb: 6,
    );
    Navigator.pop(context);

  } on FirebaseAuthException catch (e) {
    print("Firebase Error: ${e.code} - ${e.message}");
    String errorMessage = _getFirebaseErrorMessage(e);

    Fluttertoast.showToast(
      msg: errorMessage,
      timeInSecForIosWeb: 6,
      toastLength: Toast.LENGTH_LONG,
    );

    // Clean up
    await googleSignIn.signOut();
    await _auth.signOut();
  } catch (e) {
    print("Unknown Error: $e");
    Fluttertoast.showToast(
      msg: "Something went wrong. Please try again.",
      timeInSecForIosWeb: 6,
      toastLength: Toast.LENGTH_LONG,
    );
    await googleSignIn.signOut();
    await _auth.signOut();
  }
}

// Helper function to save user data
Future<void> _saveUserData(
    DatabaseReference dbRef,
    String uid,
    String name,
    String classdiv,
    String collegeName,
    String email,
    ) async {
  await dbRef.child('Users').child(uid).set({
    'name': name,
    'classDiv': classdiv,
    'college': collegeName,
    'email': email,
    'role': 'Student',
  });
  print("User data saved to database");
}

// Helper function for error messages
String _getFirebaseErrorMessage(FirebaseAuthException e) {
  switch (e.code) {
    case 'email-already-in-use':
      return "This email is already registered. Try logging in instead.";
    case 'invalid-email':
      return "Invalid email address. Please check and try again.";
    case 'weak-password':
      return "Your password is too weak. Use a stronger password.";
    case 'operation-not-allowed':
      return "Email/password accounts are not enabled. Contact admin.";
    default:
      return "Registration failed: ${e.message}";
  }
}