import 'package:ephysicsapp/globals/colors.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class WeeklyAdminAppUsageStatistics extends StatefulWidget {
  const WeeklyAdminAppUsageStatistics({Key? key}) : super(key: key);

  @override
  _WeeklyAdminAppUsageStatisticsState createState() =>
      _WeeklyAdminAppUsageStatisticsState();
}

class _WeeklyAdminAppUsageStatisticsState
    extends State<WeeklyAdminAppUsageStatistics> {
  Map<String, int> weeklyUsage = {};
  bool _isLoading = true;
  DateTime _selectedWeek =
      DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
  final List<String> weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  ];

  @override
  void initState() {
    super.initState();
    getWeeklyAppUsageData(_selectedWeek).then((data) {
      setState(() {
        weeklyUsage = data;
        _isLoading = false;
      });
    });
  }

  // Optimized version of fetching data
  Future<Map<String, int>> getWeeklyAppUsageData(DateTime selectedDate) async {
    final DatabaseReference dbRef =
        FirebaseDatabase.instance.ref().child('Users');
    Map<String, int> weeklyUsage = {};
    DateTime startOfWeek =
        selectedDate.subtract(Duration(days: selectedDate.weekday - 1));

    try {
      DatabaseEvent event = await dbRef.once();
      DataSnapshot snapshot = event.snapshot;

      if (snapshot.exists) {
        List<Future> userFutures = [];

        for (DataSnapshot userSnapshot in snapshot.children) {
          String userId = userSnapshot.key ?? '';
          userFutures.add(fetchUserAppUsage(userId, startOfWeek, weeklyUsage));
        }

        await Future.wait(userFutures);
      }
    } catch (e) {
      print('Error: $e');
    }

    return weeklyUsage;
  }

  Future<void> fetchUserAppUsage(
      String userId, DateTime startOfWeek, Map<String, int> weeklyUsage) async {
    final DatabaseReference userRef = FirebaseDatabase.instance
        .ref()
        .child('Users')
        .child(userId)
        .child('AppUsage');
    String monthKey = DateFormat('MMM yyyy').format(startOfWeek);

    try {
      DataSnapshot monthSnapshot = (await userRef.child(monthKey).get());

      if (monthSnapshot.exists) {
        for (int i = 0; i < 7; i++) {
          DateTime weekday = startOfWeek.add(Duration(days: i));
          String dateKey = DateFormat('dd-MM-yyyy').format(weekday);

          if (monthSnapshot.child(dateKey).exists) {
            int totalSeconds = _convertTimeToSeconds(
                monthSnapshot.child(dateKey).value as String);
            weeklyUsage[weekdays[weekday.weekday - 1]] =
                (weeklyUsage[weekdays[weekday.weekday - 1]] ?? 0) +
                    totalSeconds;
          } else {
            weeklyUsage[weekdays[weekday.weekday - 1]] ??= 0;
          }
        }
      }
    } catch (e) {
      print('Error fetching user $userId data: $e');
    }
  }

  int _convertTimeToSeconds(String time) {
    List<String> parts = time.split(':');
    return int.parse(parts[0]) * 3600 +
        int.parse(parts[1]) * 60 +
        int.parse(parts[2]);
  }

  double getMaxY() {
    double maxUsage = weeklyUsage.isEmpty
        ? 10.0
        : weeklyUsage.values
            .fold(0, (max, value) => math.max(max, value / 60.0));

    if (maxUsage == 0) {
      return 1.0;
    }

    return (maxUsage / 5).ceil() * 5.0;
  }

  int calculateYAxisInterval(double maxY) {
    return maxY > 0 ? (maxY / 5).ceil() : 1;
  }

  List<BarChartGroupData> getWeeklyChartData() {
    return List.generate(
      7,
      (index) {
        String dayKey = weekdays[index];
        double usage = (weeklyUsage[dayKey] ?? 0) / 60.0;

        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: usage, // Directly using usage without threshold
              gradient: const LinearGradient(
                colors: [Color(0xFFff7e5f), Color(0xFFfeb47b)],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              width: 18,
              borderRadius: BorderRadius.circular(8),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(
              child: SpinKitFadingCircle(
                color: color5,
                size: 30.0,
              ),
            )
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blueAccent, Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: _showWeekPicker,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('MMM d, yyyy').format(_selectedWeek),
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const Icon(Icons.calendar_today,
                                  color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    GraphContainer(
                      maxY: getMaxY(),
                      yInterval: calculateYAxisInterval(getMaxY()),
                      getChartData: getWeeklyChartData,
                      title: 'Weekly App Usage',
                      weekdays: weekdays,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  void _showWeekPicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedWeek,
      firstDate: DateTime(2021),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4CAF50),
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedWeek = DateTime(pickedDate.year, pickedDate.month,
            pickedDate.day - (pickedDate.weekday - 1));
        _isLoading = true;
      });
      getWeeklyAppUsageData(_selectedWeek).then((data) {
        setState(() {
          weeklyUsage = data;
          _isLoading = false;
        });
      });
    }
  }
}

class GraphContainer extends StatelessWidget {
  final double maxY;
  final int yInterval;
  final List<BarChartGroupData> Function() getChartData;
  final String title;
  final List<String> weekdays;

  const GraphContainer({
    required this.maxY,
    required this.yInterval,
    required this.getChartData,
    required this.title,
    required this.weekdays,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 5,
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height / 3.4,
        child: Column(
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height / 50),
            Expanded(
              child: BarChart(
                BarChartData(
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        int totalSeconds = (rod.toY * 60).toInt();
                        int hours = totalSeconds ~/ 3600;
                        int minutes = (totalSeconds % 3600) ~/ 60;
                        int seconds = totalSeconds % 60;

                        String tooltipText =
                            '$hours hrs $minutes mins $seconds secs';

                        return BarTooltipItem(
                          tooltipText,
                          GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        );
                      },
                    ),
                  ),
                  maxY: maxY,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: MediaQuery.of(context).size.width * 0.11,
                        interval: yInterval.toDouble(),
                        getTitlesWidget: (value, meta) {
                          return Text(
                            formatYAxisLabel(value),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, _) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              weekdays[value.toInt()],
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      left: BorderSide(
                          color: Colors.black, width: 2), // Left Y-axis
                      bottom: BorderSide(
                          color: Colors.black, width: 2), // Bottom X-axis
                    ),
                  ),
                  barGroups: getChartData(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    drawHorizontalLine: true,
                    horizontalInterval: yInterval.toDouble(),
                    verticalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.3),
                        strokeWidth: 2,
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Function to format the Y-axis labels in hours

// Display hours with one decimal
String formatYAxisLabel(double value) {
  double hours = value / 60; // Convert minutes to hours

  if (hours >= 1000) {
    return '${(hours / 1000).toStringAsFixed(1)}K H'; // Example: 1800 → 1.8K H
  } else if (hours >= 100) {
    return '${hours.round()} H'; // Example: 458.5 → 459H (No decimals)
  } else if (hours >= 1) {
    return '${hours.toStringAsFixed(1)} H'; // Example: 90 → 1.5H
  } else {
    return '${value.toInt()} H'; // Example: 45 → 45M
  }
}
