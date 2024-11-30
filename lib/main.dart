import 'package:ephysicsapp/screens/users/splash_screen.dart';
import 'package:ephysicsapp/services/authentication.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'globals/colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializePreferences();
  // Enable offline persistence for Firebase Realtime Database
  FirebaseDatabase.instance.setPersistenceEnabled(true);
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    // appleProvider: AppleProvider.appAttest,
  );
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late DateTime _startTime;
  bool _isLoggedIn = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    checkForUpdate();
    _checkLoggedInStatus();
  }

  Future<void> _checkLoggedInStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('studentUUID');

    if (userId != null) {
      print("User Id Found : ${userId}");
      _isLoggedIn = true;
      _userId = userId;
      _startTime = DateTime.now();
    } else {
      print("No User Logged In / Admin Logged In");
    }
  }

  // Check for updates
  void checkForUpdate() async {
    try {
      print("App Version check been performed");
      final AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        print("Update found");
        // Start the immediate update process
        await InAppUpdate.performImmediateUpdate();
      }
      print("No Update found");
      print(updateInfo);
    } catch (e) {
      print("Error checking for updates: $e");
    }
  }

  Future<void> onUserLogin(String userId) async {
    print("Started Recording time on login");
    _isLoggedIn = true;
    _userId = userId;
    // Start tracking after the splash screen duration
    Future.delayed(Duration(seconds: 3), () {
      _startTime = DateTime.now();
    });
  }

  // Method to stop tracking when user logs out
  Future<void> onUserLogout() async {
    if (_isLoggedIn) {
      await _logAppUsageTime();
      _isLoggedIn = false;
      _userId = null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isLoggedIn) {
      if (state == AppLifecycleState.resumed) {
        // App brought to foreground i.e., in use
        print('Starting Time Recording');
        _startTime = DateTime.now();
      } else if (state == AppLifecycleState.paused ||
          state == AppLifecycleState.inactive) {
        print("App Not in Foreground");
        _logAppUsageTime();
      }
    }
  }

  Future<void> _logAppUsageTime() async {
    if (_isLoggedIn && _userId != null) {
      DateTime endTime = DateTime.now();
      if (_startTime.day == endTime.day) {
        // Simple case, same day session
        Duration sessionDuration = endTime.difference(_startTime);
        print("Logging same day session from ${_startTime} to ${endTime}");
        await _updateUsageInFirebase(_startTime, sessionDuration);
      } else {
        // Spans across midnight
        print(
            "Session spanned across midnight from ${_startTime} to ${endTime}");
        DateTime midnight = DateTime(
          _startTime.year,
          _startTime.month,
          _startTime.day,
          23,
          59,
          59,
        );

        // Duration up to   midnight
        Duration beforeMidnight = midnight.difference(_startTime).abs();
        print("Passing X-day : ${_startTime} and ${beforeMidnight}");
        await _updateUsageInFirebase(_startTime, beforeMidnight);

        // Duration from midnight to end time
        DateTime nextDayStart = midnight.add(Duration(seconds: 1));
        Duration afterMidnight = endTime.difference(nextDayStart);
        print("Passing (X+1)-day : ${nextDayStart} and ${afterMidnight}");
        await _updateUsageInFirebase(nextDayStart, afterMidnight);
      }
    }
  }

  Future<void> _updateUsageInFirebase(
      DateTime usageDate, Duration sessionDuration) async {
    String userId = _userId!;
    String currentMonth = DateFormat('MMM yyyy').format(usageDate);
    String dateKey = DateFormat('dd-MM-yyyy').format(usageDate);

    DatabaseReference dbRef = FirebaseDatabase.instance.ref();
    DatabaseReference userUsageRef = dbRef
        .child('Users')
        .child(userId)
        .child('AppUsage')
        .child(currentMonth)
        .child(dateKey);

    DataSnapshot snapshot =
        await userUsageRef.once().then((event) => event.snapshot);
    Duration totalUsage = Duration();

    if (snapshot.exists) {
      totalUsage = _parseDuration(snapshot.value as String);
      print("Existing usage for $dateKey: ${_formatDuration(totalUsage)}");
    } else {
      print("No existing usage found for $dateKey. Creating new entry.");
    }

    totalUsage += sessionDuration;
    String formattedUsage = _formatDuration(totalUsage);

    print("Total usage for $dateKey updated: $formattedUsage");
    await userUsageRef.set(formattedUsage);
  }

  Duration _parseDuration(String durationStr) {
    List<String> parts = durationStr.split(':');
    return Duration(
      hours: int.parse(parts[0]),
      minutes: int.parse(parts[1]),
      seconds: int.parse(parts[2]),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(duration.inHours)}:${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}";
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Philo Physics',
      theme: ThemeData(
        primarySwatch: createMaterialColor(color5),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SplashScreen(), // Initial screen of the app
    );
  }
}
