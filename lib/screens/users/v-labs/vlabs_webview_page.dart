// vlab_webview_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:webview_flutter/webview_flutter.dart';

class VLabWebViewPage extends StatefulWidget {
  final String title;
  final String url;
  final String experimentId; // Pass a unique ID for the experiment

  const VLabWebViewPage({
    required this.title,
    required this.url,
    required this.experimentId,
    Key? key,
  }) : super(key: key);

  @override
  State<VLabWebViewPage> createState() => _VLabWebViewPageState();
}

class _VLabWebViewPageState extends State<VLabWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    print("V Lab Time Recording");
    _startTime = DateTime.now();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  void dispose() {
    print("V Lab Time stop");
    _logVLabUsageTime();
    super.dispose();
  }

  Future<void> _logVLabUsageTime() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DateTime endTime = DateTime.now();
    if (_startTime.day == endTime.day) {
      // Same day session
      Duration sessionDuration = endTime.difference(_startTime);
      await _updateVLabUsageInFirebase(_startTime, sessionDuration);
    } else {
      // Spans across midnight
      DateTime midnight = DateTime(
        _startTime.year,
        _startTime.month,
        _startTime.day,
        23,
        59,
        59,
      );
      Duration beforeMidnight = midnight.difference(_startTime).abs();
      await _updateVLabUsageInFirebase(_startTime, beforeMidnight);

      DateTime nextDayStart = midnight.add(Duration(seconds: 1));
      Duration afterMidnight = endTime.difference(nextDayStart);
      await _updateVLabUsageInFirebase(nextDayStart, afterMidnight);
    }
  }

  Future<void> _updateVLabUsageInFirebase(
      DateTime usageDate, Duration sessionDuration) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String currentMonth = DateFormat('MMM yyyy').format(usageDate);
    String dateKey = DateFormat('dd-MM-yyyy').format(usageDate);

    DatabaseReference dbRef = FirebaseDatabase.instance.ref();
    DatabaseReference vlabUsageRef = dbRef
        .child('Users')
        .child(user.uid)
        .child('VLabUsage')
        .child(currentMonth)
        .child(dateKey)
        .child(widget.experimentId);

    DataSnapshot snapshot = await vlabUsageRef.get();
    Duration totalUsage = Duration();

    if (snapshot.exists) {
      totalUsage = _parseDuration(snapshot.value as String);
    }

    totalUsage += sessionDuration;
    String formattedUsage = _formatDuration(totalUsage);

    await vlabUsageRef.set(formattedUsage);
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
