import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class VLabYearlyUsageGraph extends StatefulWidget {
  @override
  _VLabYearlyUsageGraphState createState() => _VLabYearlyUsageGraphState();
}

class _VLabYearlyUsageGraphState extends State<VLabYearlyUsageGraph> {
  bool isLoading = true;
  List<Duration> monthUsage = List.filled(12, Duration.zero); // Jan to Dec
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

  // Set this to your test user's UID for focused debug
  final String debugUserId = '7Kf491BPCJVtgDlyOt5I0CDGHBF2';

  @override
  void initState() {
    super.initState();
    fetchYearlyVLabUsage();
  }

  Future<void> fetchYearlyVLabUsage() async {
    setState(() => isLoading = true);
    final dbRef = FirebaseDatabase.instance.ref().child('Users');
    List<Duration> tempMonthUsage = List.filled(12, Duration.zero);

    print('Looking for year: $selectedYear');

    DatabaseEvent event = await dbRef.once();
    DataSnapshot snapshot = event.snapshot;

    if (snapshot.exists) {
      for (DataSnapshot userSnapshot in snapshot.children) {
        if (userSnapshot.key != debugUserId) continue; // Only debug this user
        for (int m = 0; m < 12; m++) {
          String monthYear = "${months[m]} $selectedYear";
          DataSnapshot vlabUsageNode =
              userSnapshot.child('VLabUsage').child(monthYear);
          for (DataSnapshot dayNode in vlabUsageNode.children) {
            var dayValue = dayNode.value;
            if (dayValue is Map) {
              Map<dynamic, dynamic> dayMap = dayValue;
              dayMap.forEach((expId, timeStr) {
                Duration d = _parseDuration(timeStr);
                tempMonthUsage[m] += d;
              });
            } else if (dayValue is List) {
              for (var timeStr in dayValue) {
                if (timeStr != null) {
                  Duration d = _parseDuration(timeStr);
                  tempMonthUsage[m] += d;
                }
              }
            }
          }
        }
      }
    }

    print('monthUsage: $tempMonthUsage');

    setState(() {
      monthUsage = tempMonthUsage;
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
    double maxMinutes = monthUsage.isEmpty
        ? 10.0
        : monthUsage.fold(0, (max, d) => math.max(max, d.inMinutes.toDouble()));
    return (maxMinutes / 5).ceil() * 5.0;
  }

  int calculateYAxisInterval(double maxY) {
    return maxY > 0 ? (maxY / 5).ceil() : 1;
  }

  List<BarChartGroupData> getChartData() {
    return List.generate(
      12,
      (index) {
        double minutes = monthUsage[index].inMinutes.toDouble();
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
                                fetchYearlyVLabUsage();
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
                            color: Colors.grey.withOpacity(0.1),
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
                                Duration d = monthUsage[group.x];
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
                                    months[value.toInt()],
                                    style: GoogleFonts.poppins(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
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
