import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class VLabMonthlyUsageGraph extends StatefulWidget {
  @override
  _VLabMonthlyUsageGraphState createState() => _VLabMonthlyUsageGraphState();
}

class _VLabMonthlyUsageGraphState extends State<VLabMonthlyUsageGraph> {
  bool isLoading = true;
  List<Duration> weekUsage = []; // One entry per week of the month
  final List<String> months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  String selectedYear = DateTime.now().year.toString();
  int selectedMonthIndex = DateTime.now().month - 1;

  // Set this to your test user's UID for focused debug
  final String debugUserId = '7Kf491BPCJVtgDlyOt5I0CDGHBF2';

  @override
  void initState() {
    super.initState();
    fetchMonthlyVLabUsage();
  }

  int getWeekNumber(DateTime date) {
    final firstDayOfMonth = DateTime(date.year, date.month, 1);
    final daysSinceFirstWeek = date.difference(firstDayOfMonth).inDays;
    final firstDayWeekday = firstDayOfMonth.weekday;
    return ((daysSinceFirstWeek + firstDayWeekday - 1) / 7).floor() + 1;
  }

  int getTotalWeeks(int year, int month) {
    final lastDay = DateTime(year, month + 1, 0);
    return getWeekNumber(lastDay);
  }

  Future<void> fetchMonthlyVLabUsage() async {
    setState(() => isLoading = true);
    final dbRef = FirebaseDatabase.instance.ref().child('Users');

    int year = int.parse(selectedYear);
    int month = selectedMonthIndex + 1;
    int daysInMonth = DateTime(year, month + 1, 0).day;
    int totalWeeks = getTotalWeeks(year, month);
    List<Duration> tempWeekUsage = List.filled(totalWeeks, Duration.zero);

    String monthYear = "${months[selectedMonthIndex]} $selectedYear";
    List<String> days = List.generate(daysInMonth,
        (i) => DateFormat('dd-MM-yyyy').format(DateTime(year, month, i + 1)));

    print('Looking for monthYear: $monthYear');
    print('Days: $days');

    DatabaseEvent event = await dbRef.once();
    DataSnapshot snapshot = event.snapshot;

    if (snapshot.exists) {
      for (DataSnapshot userSnapshot in snapshot.children) {
        if (userSnapshot.key != debugUserId) continue; // Only debug this user
        DataSnapshot vlabUsageNode =
            userSnapshot.child('VLabUsage').child(monthYear);
        for (int i = 0; i < days.length; i++) {
          String day = days[i];
          DateTime date = DateTime(year, month, i + 1);
          int weekNum = getWeekNumber(date) - 1; // 0-based index
          if (vlabUsageNode.child(day).exists) {
            var dayValue = vlabUsageNode.child(day).value;
            print(
                'DATA FOUND: user=${userSnapshot.key}, day=$day, value=$dayValue');
            if (dayValue is Map) {
              Map<dynamic, dynamic> dayMap = dayValue;
              dayMap.forEach((expId, timeStr) {
                Duration d = _parseDuration(timeStr);
                tempWeekUsage[weekNum] += d;
              });
            } else if (dayValue is List) {
              for (var timeStr in dayValue) {
                if (timeStr != null) {
                  Duration d = _parseDuration(timeStr);
                  tempWeekUsage[weekNum] += d;
                }
              }
            }
          }
        }
      }
    }

    print('weekUsage: $tempWeekUsage');

    setState(() {
      weekUsage = tempWeekUsage;
      isLoading = false;
    });
  }

  Duration _parseDuration(String durationStr) {
    List<String> parts = durationStr.split(':');
    return Duration(
      hours: int.parse(parts[0]),
      minutes: int.parse(parts[1]),
      seconds: int.parse(parts[2]),
    );
  }

  double getMaxY() {
    double maxMinutes = weekUsage.isEmpty
        ? 10.0
        : weekUsage.fold(0, (max, d) => math.max(max, d.inMinutes.toDouble()));
    return (maxMinutes / 5).ceil() * 5.0;
  }

  int calculateYAxisInterval(double maxY) {
    return maxY > 0 ? (maxY / 5).ceil() : 1;
  }

  List<BarChartGroupData> getChartData() {
    return List.generate(
      weekUsage.length,
      (index) {
        double minutes = weekUsage[index].inMinutes.toDouble();
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: minutes,
              gradient: const LinearGradient(
                colors: [Color(0xFF8e2de2), Color(0xFF4a00e0)],
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

  String formatDuration(Duration d) {
    int h = d.inHours;
    int m = d.inMinutes.remainder(60);
    int s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m ${s}s';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final years =
        List.generate(10, (i) => (DateTime.now().year - i).toString());

    return isLoading
        ? Center(child: CircularProgressIndicator())
        : Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purpleAccent, Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButton<String>(
                            value: selectedYear,
                            items: years
                                .map((y) => DropdownMenuItem(
                                      value: y,
                                      child: Text(y),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  selectedYear = value;
                                });
                                fetchMonthlyVLabUsage();
                              }
                            },
                          ),
                        ),
                        Expanded(
                          child: DropdownButton<String>(
                            value: months[selectedMonthIndex],
                            items: months
                                .map((m) => DropdownMenuItem(
                                      value: m,
                                      child: Text(m),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  selectedMonthIndex = months.indexOf(value);
                                });
                                fetchMonthlyVLabUsage();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 8.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.1),
                            spreadRadius: 5,
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height / 2.5,
                      child: BarChart(
                        BarChartData(
                          barGroups: getChartData(),
                          maxY: getMaxY(),
                          minY: 0,
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem:
                                  (group, groupIndex, rod, rodIndex) {
                                Duration d = weekUsage[group.x];
                                return BarTooltipItem(
                                  formatDuration(d),
                                  GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.black87,
                                  ),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                interval: calculateYAxisInterval(getMaxY())
                                    .toDouble(),
                                getTitlesWidget: (value, meta) => Text(
                                  '${value.toInt()}m',
                                  style: GoogleFonts.poppins(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) => Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    // Show week number (1-based)
                                    '${value.toInt() + 1}',
                                    style: GoogleFonts.poppins(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border(
                              left: BorderSide(color: Colors.black, width: 2),
                              bottom: BorderSide(color: Colors.black, width: 2),
                            ),
                          ),
                          gridData: FlGridData(
                            show: false,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
  }
}
