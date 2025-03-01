import 'dart:async';
import 'package:ephysicsapp/globals/colors.dart';
import 'package:ephysicsapp/services/authentication.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:no_screenshot/no_screenshot.dart';

class PDFScreen extends StatefulWidget {
  final String path, title;

  PDFScreen({Key? key, required this.path, required this.title})
      : super(key: key);

  _PDFScreenState createState() => _PDFScreenState();
}

class _PDFScreenState extends State<PDFScreen> with WidgetsBindingObserver {
  final Completer<PDFViewController> _controller =
      Completer<PDFViewController>();
  int pages = 0;
  int currentPage = 0;
  bool isReady = false;
  String errorMessage = '';
  bool isLandscape = false;

  // pdf time storinng :
  late DateTime pdfTimeStart;
  Duration totalPdfUsedDuration = Duration();

  String? userId = prefs.getString('studentUUID');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NoScreenshot.instance.screenshotOff();
    pdfTimeStart = DateTime.now();

    // Allow all orientations for this screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NoScreenshot.instance.screenshotOn(); // Allow screenshots when disposing.

    // Reset orientation back to portrait only when leaving this screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // pdf time calc and setting in db:
    DateTime pdfTimeEnd = DateTime.now();
    if (pdfTimeStart != null) {
      _logPdfUsageTime(pdfTimeStart!, DateTime.now());
    }
    super.dispose();
  }

  Future<void> _logPdfUsageTime(DateTime startTime, DateTime endTime) async {
    print("PDF TIme Saving Start");
    if (userId != null) {
      if (startTime.day == endTime.day) {
        // Simple case, same day session
        Duration sessionDuration = endTime.difference(startTime);
        print("Logging same day PDF usage from $startTime to $endTime");
        await _updatePdfUsageInFirebase(startTime, sessionDuration);
      } else {
        // Spans across midnight
        print("PDF usage spanned across midnight from $startTime to $endTime");
        DateTime midnight = DateTime(
          startTime.year,
          startTime.month,
          startTime.day,
          23,
          59,
          59,
        );

        // Duration up to midnight
        Duration beforeMidnight = midnight.difference(startTime).abs();
        print("Logging X-day usage: $startTime to midnight ($beforeMidnight)");
        await _updatePdfUsageInFirebase(startTime, beforeMidnight);

        // Duration from midnight to end time
        DateTime nextDayStart = midnight.add(Duration(seconds: 1));
        Duration afterMidnight = endTime.difference(nextDayStart);
        print(
            "Logging (X+1)-day usage: $nextDayStart to $endTime ($afterMidnight)");
        await _updatePdfUsageInFirebase(nextDayStart, afterMidnight);
      }
    }
  }

  Future<void> _updatePdfUsageInFirebase(
      DateTime usageDate, Duration sessionDuration) async {
    String currentMonth = DateFormat('MMM yyyy').format(usageDate);
    String dateKey = DateFormat('dd-MM-yyyy').format(usageDate);

    DatabaseReference dbRef = FirebaseDatabase.instance.ref();
    DatabaseReference userUsageRef = dbRef
        .child('Users')
        .child(userId!)
        .child('PdfUsage')
        .child(currentMonth)
        .child(dateKey);

    DataSnapshot snapshot =
        await userUsageRef.once().then((event) => event.snapshot);
    Duration totalUsage = Duration();

    if (snapshot.exists) {
      totalUsage = _parseDuration(snapshot.value as String);
      print("Existing PDF usage for $dateKey: ${_formatDuration(totalUsage)}");
    } else {
      print("No existing PDF usage found for $dateKey. Creating new entry.");
    }

    totalUsage += sessionDuration;
    String formattedUsage = _formatDuration(totalUsage);

    print("Total PDF usage for $dateKey updated: $formattedUsage");
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

  // Function to go to the previous page
  void goToPreviousPage() {
    if (currentPage > 0) {
      setState(() {
        currentPage--;
      });
      _controller.future.then((pdfViewController) {
        pdfViewController.setPage(currentPage);
      });
    }
  }

  // Function to go to the next page
  void goToNextPage() {
    if (currentPage < pages - 1) {
      setState(() {
        currentPage++;
      });
      _controller.future.then((pdfViewController) {
        pdfViewController.setPage(currentPage);
      });
    }
  }

  // Toggle orientation between landscape and portrait
  void toggleOrientation() {
    setState(() {
      isLandscape = !isLandscape;
      if (isLandscape) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } else {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          // Row for positioning the arrows
          Padding(
            padding:
                EdgeInsets.only(right: MediaQuery.of(context).size.width / 50),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.end, // Align buttons to the right
              children: [
                // Left arrow button (previous page)
                IconButton(
                  icon: Icon(FontAwesomeIcons.rotate), // Rotate icon
                  onPressed: toggleOrientation,
                  iconSize: 18,
                ),
                IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded, // Arrow for page back
                    color: currentPage == 0
                        ? Colors.grey
                        : Colors.black, // Disable when on the first page
                  ),
                  onPressed: currentPage == 0
                      ? null
                      : goToPreviousPage, // Disable action when on the first page
                ),

                // Add some spacing between the arrows
                SizedBox(
                    width: MediaQuery.of(context).size.width /
                        300), // You can adjust the width to control the gap
                // Right arrow button (next page)
                IconButton(
                  icon: Icon(
                    Icons.arrow_forward_rounded, // Arrow for page forward
                    color: currentPage == pages - 1 || pages == 1
                        ? Colors.grey
                        : Colors.black, // Disable when on the last page
                  ),
                  onPressed: currentPage == pages - 1 || pages == 1
                      ? null
                      : goToNextPage, // Disable action when on the last page
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          PDFView(
            filePath: widget.path,
            enableSwipe: true,
            swipeHorizontal: false,
            autoSpacing: true,
            pageFling: true,
            pageSnap: true,
            fitEachPage: true,
            defaultPage: currentPage,
            fitPolicy: FitPolicy.BOTH,
            preventLinkNavigation: false,
            onRender: (_pages) {
              setState(() {
                pages = _pages!;
                isReady = true;
              });
            },
            onError: (error) {
              setState(() {
                errorMessage = error.toString();
              });
              print(error.toString());
            },
            onPageError: (page, error) {
              setState(() {
                errorMessage = '$page: ${error.toString()}';
              });
              print('$page: ${error.toString()}');
            },
            onViewCreated: (PDFViewController pdfViewController) async {
              _controller.complete(pdfViewController);

              await Future.delayed(Duration(milliseconds: 300));
              setState(() {
                print("VIEW CREATED : PDF");
              });
              pdfViewController.setPage(currentPage);
            },
            onLinkHandler: (String? uri) {
              print('goto uri: $uri');
            },
            onPageChanged: (int? page, int? total) {
              print('page change: $page/$total');
              setState(() {
                currentPage = page!;
              });
            },
          ),
          errorMessage.isEmpty
              ? !isReady
                  ? Center(
                      child: CircularProgressIndicator(),
                    )
                  : Container()
              : Center(
                  child: Text(errorMessage),
                )
        ],
      ),
      floatingActionButton: FutureBuilder<PDFViewController>(
        future: _controller.future,
        builder: (context, AsyncSnapshot<PDFViewController> snapshot) {
          if (snapshot.hasData) {
            return FloatingActionButton.extended(
              backgroundColor: color5,
              label: Text(
                "Page ${currentPage + 1}/$pages",
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () async {
                // Optional: Uncomment if you want to navigate to the middle of the PDF.
                // await snapshot.data.setPage(pages ~/ 2);
              },
            );
          }
          return Container();
        },
      ),
    );
  }
}
