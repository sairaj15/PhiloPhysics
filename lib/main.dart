import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ephysicsapp/dataBase/models/pdfFileModel.dart';
import 'package:ephysicsapp/screens/users/home.dart';
import 'package:ephysicsapp/screens/users/splash_screen.dart';
import 'package:ephysicsapp/services/authentication.dart';
import 'package:ephysicsapp/widgets/noInternetScreen.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'globals/colors.dart';
import 'package:http/http.dart' as http;

import 'globals/constants.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print("Firebase initialization error: $e");
  }
  await initializePreferences();
  FirebaseDatabase.instance.setPersistenceEnabled(true);
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    // appleProvider: AppleProvider.appAttest,
  );
  await Hive.initFlutter();
  Hive.registerAdapter(PDFFileAdapter());
  await Hive.openBox<PDFFile>(Hive_Pdf_key);
  runApp(MaterialApp(
    navigatorKey: navigatorKey,
    debugShowCheckedModeBanner: false,
    title: 'Philo Physics',
    theme: ThemeData(
      primarySwatch: createMaterialColor(color5),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    ),
    home: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late DateTime _startTime;
  bool _isLoggedIn = false;
  String? _userId;

  final Connectivity connectivity = Connectivity();
  bool isFirstListener = true;
  bool isConnected = true;
  bool isDialogShowing = false;
  late StreamSubscription<List<ConnectivityResult>> connectivitySubscription;
  bool hadConnectionLoss = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    checkForUpdate();
    _checkLoggedInStatus();
    initConnectivity();
    connectivitySubscription = connectivity.onConnectivityChanged.listen(updateConnectionStatus);
  }

  /// No Internet
  Future<void> initConnectivity() async {
    List<ConnectivityResult> result;

    try {
      result = await connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      print('Couldn\'t check connectivity status: ${e.message}');
      return;
    }

    if (!mounted) {
      return;
    }
    updateConnectionStatus(result);
  }

  void updateConnectionStatus(List<ConnectivityResult> result) {
    bool wasConnected = isConnected;
    bool isNowConnected = result.contains(ConnectivityResult.mobile) || result.contains(ConnectivityResult.wifi) || result.contains(ConnectivityResult.ethernet);
    print('Connectivity changed: $result, isConnected: $isNowConnected');

    if (wasConnected != isNowConnected) {
      setState(() {
        isConnected = isNowConnected;
      });

      if (isNowConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Internet Connection Restored', style: TextStyle(color: Colors.white),),backgroundColor: Colors.green,),
        );
      }
    }
  }

  /// Clearin video and pdf caches
  Future<void> clearAppCache() async {
    print("App Cache Clear");
    try {
      final tempDir = await getTemporaryDirectory();
      final appDocDir = await getApplicationDocumentsDirectory();

      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
        print("Temporary cache cleared.");
      }

      if (appDocDir.existsSync()) {
        for (var file in appDocDir.listSync()) {
          if (file is File) {
            print(file.path);
            file.deleteSync();
          }
        }
        print("App document directory cache cleared.");
      }

      print("✅ All cached files cleared successfully.");
    } catch (e) {
      print("⚠️ Error while clearing cache: $e");
    }
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

  Future<bool> fetchForceUpdateFlag() async {
    final ref = FirebaseDatabase.instance.ref('AppConfig/force_update');
    final snapshot = await ref.get();
    return snapshot.value == true;
  }

  void checkForUpdate() async {
    try {
      bool updateAvailable = false;
      String? storeVersion;
      String? currentVersion;

      // Android: Use in_app_update
      if (Platform.isAndroid) {
        print("App Version check being performed (Android)");
        final AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();
        updateAvailable =
            updateInfo.updateAvailability == UpdateAvailability.updateAvailable;
        // You can get the version from your backend or Play Store API if needed
      }

      // iOS: Check App Store version
      if (Platform.isIOS) {
        final packageInfo = await PackageInfo.fromPlatform();
        currentVersion = packageInfo.version;

        // Replace with your app's App Store ID
        const appStoreId = 'YOUR_APP_STORE_ID_HERE';
        final url = 'https://itunes.apple.com/lookup?id=$appStoreId';
        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          if (json['results'] != null && json['results'].isNotEmpty) {
            storeVersion = json['results'][0]['version'];
            updateAvailable = _isVersionNewer(storeVersion!, currentVersion);
          }
        }
      }

      // Fetch force update flag from Firebase
      final forceUpdate = await fetchForceUpdateFlag();

      if (updateAvailable) {
        if (forceUpdate) {
          print("Force update is ON. Forcing update.");
          if (Platform.isAndroid) {
            await InAppUpdate.performImmediateUpdate();
          } else if (Platform.isIOS) {
            // Open App Store directly
            const appStoreUrl =
                'https://apps.apple.com/app/idYOUR_APP_STORE_ID';
            if (await canLaunchUrl(Uri.parse(appStoreUrl))) {
              launchUrl(Uri.parse(appStoreUrl),
                  mode: LaunchMode.externalApplication);
            }
          }
        } else {
          print("Force update is OFF. Showing suggestion dialog.");
          _promptUserToUpdate(context);
        }
      } else {
        print("No update available.");
      }
    } catch (e) {
      print("Error checking for updates: $e");
    }
  }

  bool _isVersionNewer(String storeVersion, String localVersion) {
    List<int> storeParts =
        storeVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> localParts =
        localVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < storeParts.length; i++) {
      if (i >= localParts.length || storeParts[i] > localParts[i]) {
        return true;
      } else if (storeParts[i] < localParts[i]) {
        return false;
      }
    }
    return false;
  }

  void _promptUserToUpdate(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text("Update Available"),
          content: Text(
            "A new version of the app is available. Please update to continue using the app smoothly.",
          ),
          actions: <CupertinoDialogAction>[
            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text("Update"),
              onPressed: () async {
                const appStoreUrl =
                    'https://apps.apple.com/app/idYOUR_APP_STORE_ID';
                if (await canLaunchUrl(Uri.parse(appStoreUrl))) {
                  launchUrl(Uri.parse(appStoreUrl),
                      mode: LaunchMode.externalApplication);
                }
              },
            ),
            CupertinoDialogAction(
              child: Text("Later"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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

  Future<void> onUserLogout() async {
    if (_isLoggedIn) {
      await _logAppUsageTime();
      _isLoggedIn = false;
      _userId = null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      initConnectivity();
      if (_isLoggedIn) {
        print('Starting Time Recording');
        _startTime = DateTime.now();
      }
    } else if (_isLoggedIn && (state == AppLifecycleState.paused || state == AppLifecycleState.inactive)) {
      print("App Not in Foreground");
      _logAppUsageTime();
    } else if (_isLoggedIn && state == AppLifecycleState.detached) {
      clearAppCache();
      if (Hive.isBoxOpen(Hive_Pdf_key)) {
        Hive.box(Hive_Pdf_key).close();
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

  Future<void> _updateUsageInFirebase(DateTime usageDate, Duration sessionDuration) async {
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
    clearAppCache();
    if (Hive.isBoxOpen(Hive_Pdf_key)) {
      Hive.box(Hive_Pdf_key).close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    Widget mainScreen = (prefs.getBool("isStudentLoggedIn") == true ||
        prefs.getBool("isLogged") == true)
        ? MyHomePage()
        : SplashScreen();

    return Stack(
      children: [
        mainScreen,
        if (!isConnected) const NoInternetScreen(),
      ],
    );
  }
}
