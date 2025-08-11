import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class VLabWeeklyUsageGraph extends StatefulWidget {
  @override
  _VLabWeeklyUsageGraphState createState() => _VLabWeeklyUsageGraphState();
}

class _VLabWeeklyUsageGraphState extends State<VLabWeeklyUsageGraph> {
  bool isLoading = true;
  List<Duration> dayUsage = List.filled(7, Duration.zero); // Monday to Sunday
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

  // Set this to your test user's UID for focused debug
  final String debugUserId = '7Kf491BPCJVtgDlyOt5I0CDGHBF2';

  @override
  void initState() {
    super.initState();
    fetchWeeklyVLabUsage();
  }

  Future<void> fetchWeeklyVLabUsage() async {
    setState(() => isLoading = true);
    final dbRef = FirebaseDatabase.instance.ref().child('Users');
    List<Duration> tempDayUsage = List.filled(7, Duration.zero);

    DateTime startOfWeek = _selectedWeek;
    List<String> days = List.generate(
        7,
        (i) => DateFormat('dd-MM-yyyy')
            .format(startOfWeek.add(Duration(days: i))));
    String monthYear = DateFormat('MMM yyyy').format(startOfWeek);

    print('Selected week starts: $startOfWeek');
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
          if (vlabUsageNode.child(day).exists) {
            var dayValue = vlabUsageNode.child(day).value;
            print(
                'DATA FOUND: user=${userSnapshot.key}, day=$day, value=$dayValue');
            if (dayValue is Map) {
              Map<dynamic, dynamic> dayMap = dayValue;
              dayMap.forEach((expId, timeStr) {
                Duration d = _parseDuration(timeStr);
                tempDayUsage[i] += d;
              });
            } else if (dayValue is List) {
              for (var timeStr in dayValue) {
                if (timeStr != null) {
                  Duration d = _parseDuration(timeStr);
                  tempDayUsage[i] += d;
                }
              }
            }
          }
        }
      }
    }

    print('dayUsage: $tempDayUsage');

    setState(() {
      dayUsage = tempDayUsage;
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
    double maxMinutes = dayUsage.isEmpty
        ? 10.0
        : dayUsage.fold(0, (max, d) => math.max(max, d.inMinutes.toDouble()));
    return (maxMinutes / 5).ceil() * 5.0;
  }

  int calculateYAxisInterval(double maxY) {
    return maxY > 0 ? (maxY / 5).ceil() : 1;
  }

  List<BarChartGroupData> getChartData() {
    return List.generate(
      7,
      (index) {
        double minutes = dayUsage[index].inMinutes.toDouble();
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
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: GestureDetector(
                      onTap: _showWeekPicker,
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
                                Duration d = dayUsage[group.x];
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
                                    weekdays[value.toInt()],
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
        isLoading = true;
      });
      fetchWeeklyVLabUsage();
    }
  }
}
