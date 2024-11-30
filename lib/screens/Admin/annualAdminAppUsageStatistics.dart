import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'dart:math' as math;

const List<String> months = [
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

class AnnualAdminAppUsageStatistics extends StatefulWidget {
  const AnnualAdminAppUsageStatistics({Key? key}) : super(key: key);

  @override
  _AdminStatisticsState createState() => _AdminStatisticsState();
}

class _AdminStatisticsState extends State<AnnualAdminAppUsageStatistics> {
  Map<String, Map<String, int>> yearlyUsage = {};
  bool isLoading = true;
  List<String> availableAcademicYears = [];
  int currentYearIndex = 0;
  final PageController _pageController = PageController();
  String? currentAcademicYear;

  @override
  void initState() {
    super.initState();
    getAppUsageData();
  }

  Future<void> getAppUsageData() async {
    DatabaseReference dbRef = FirebaseDatabase.instance.ref().child('Users');

    try {
      DataSnapshot snapshot = await dbRef.get();

      if (snapshot.exists && snapshot.value is Map) {
        Map<String, dynamic> usersData;
        try {
          usersData = Map<String, dynamic>.from(snapshot.value as Map);
        } catch (e) {
          print('Casting failed, using JSON workaround: $e');
          final jsonString = jsonEncode(snapshot.value);
          usersData = Map<String, dynamic>.from(jsonDecode(jsonString));
        }

        for (var userEntry in usersData.entries) {
          String userId = userEntry.key;
          Map<String, dynamic> userData =
              Map<String, dynamic>.from(userEntry.value as Map);

          if (userData.containsKey('AppUsage')) {
            Map<String, dynamic> appUsage =
                Map<String, dynamic>.from(userData['AppUsage'] as Map);

            appUsage.forEach((key, value) {
              List<String> parts = key.split(' ');
              String month = parts[0];
              String year = parts[1];
              int monthIndex = months.indexOf(month);

              if (monthIndex != -1) {
                if (value is String) {
                  int totalSeconds = convertTimeToSeconds(value);
                  yearlyUsage[year] ??= {};
                  yearlyUsage[year]![months[monthIndex]] =
                      (yearlyUsage[year]![months[monthIndex]] ?? 0) +
                          totalSeconds;
                } else if (value is Map<Object?, Object?>) {
                  value.forEach((dateKey, timeStr) {
                    try {
                      String dateKeyStr = dateKey as String;
                      if (RegExp(r'^\d{2}-\d{2}-\d{4}$').hasMatch(dateKeyStr)) {
                        if (timeStr is String) {
                          int totalSeconds = convertTimeToSeconds(timeStr);
                          yearlyUsage[year] ??= {};
                          yearlyUsage[year]![months[monthIndex]] =
                              (yearlyUsage[year]![months[monthIndex]] ?? 0) +
                                  totalSeconds;
                        } else {
                          print(
                              'Expected timeStr to be a String but got: ${timeStr.runtimeType}');
                        }
                      } else {
                        print('Invalid date format for $dateKeyStr');
                      }
                    } catch (e) {
                      print('Error parsing time for $dateKey: $e');
                    }
                  });
                } else {
                  print(
                      'Unexpected format for $month $year: ${value.runtimeType} - $value');
                }
              } else {
                print('Invalid month: $month');
              }
            });
          } else {
            print('User $userId has no app usage data');
          }
        }

        // Determine available academic years
        Set<String> availableAcademicYearsSet = {};
        yearlyUsage.forEach((year, monthsData) {
          int yearInt = int.parse(year);
          for (String month in monthsData.keys) {
            int monthIndex = months.indexOf(month);
            if (monthIndex >= 0) {
              if (monthIndex >= 6) {
                // July-Dec
                availableAcademicYearsSet.add('$year-${yearInt + 1}');
              } else {
                // Jan-June
                availableAcademicYearsSet.add('${yearInt - 1}-$year');
              }
            }
          }
        });

        // Get current academic year
        DateTime now = DateTime.now();
        int currentYear = now.year;
        int currentMonth = now.month;

        String currentAcademicYear;
        if (currentMonth >= 7) {
          // July to December
          currentAcademicYear = '$currentYear-${currentYear + 1}';
        } else {
          // January to June
          currentAcademicYear = '${currentYear - 1}-$currentYear';
        }

        // Update state
        setState(() {
          availableAcademicYears = availableAcademicYearsSet.toList()..sort();
          currentYearIndex =
              availableAcademicYears.indexOf(currentAcademicYear);
          isLoading = false;
          this.currentAcademicYear = currentAcademicYear;
        });

        print('Available Academic Years: $availableAcademicYears');
        print('Current Academic Year: $currentAcademicYear');
      } else {
        print('No users found in the database');
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error: $e');
      setState(() => isLoading = false);
    }
  }

  int convertTimeToSeconds(dynamic time) {
    if (time is String) {
      List<String> parts = time.split(':');
      return int.parse(parts[0]) * 3600 +
          int.parse(parts[1]) * 60 +
          int.parse(parts[2]);
    } else if (time is Map<Object?, Object?>) {
      // Adjusted type check
      int totalSeconds = 0;
      time.forEach((dateKey, timeStr) {
        List<String> timeParts = timeStr.toString().split(':');
        totalSeconds += int.parse(timeParts[0]) * 3600 +
            int.parse(timeParts[1]) * 60 +
            int.parse(timeParts[2]);
      });
      return totalSeconds;
    } else {
      throw Exception('Unexpected time format: $time');
    }
  }

  double getMaxY(String year) {
    Map<String, int> monthlyUsage = yearlyUsage[year] ?? {};
    double maxUsage =
        monthlyUsage.values.fold(0, (max, value) => math.max(max, value / 60));
    return (maxUsage / 5).ceil() * 5.0;
  }

  int calculateYAxisInterval(double maxY) {
    return (maxY / 5).ceil();
  }

  String formatYAxisLabel(double value) {
    if (value >= 60) {
      int hours = value ~/ 60;
      int minutes = (value % 60).toInt();
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    } else {
      return '${value.toInt()}m';
    }
  }

  List<BarChartGroupData> getSemesterChartData(
      String year, bool isOddSemester) {
    Map<String, int> monthlyUsage = yearlyUsage[year] ?? {};

    return List.generate(
      6, // Always 6 months for each semester
      (index) {
        int monthIndex = isOddSemester ? index + 6 : index; // Adjusted here
        double usage = (monthlyUsage[months[monthIndex]] ?? 0) / 60;
        return BarChartGroupData(
          x: monthIndex,
          barsSpace: 8,
          barRods: [
            BarChartRodData(
              toY: usage.toDouble(),
              gradient: const LinearGradient(
                colors: [Color(0xFFff7e5f), Color(0xFFfeb47b)],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              width: 14,
              borderRadius: BorderRadius.circular(8),
            ),
          ],
        );
      },
    );
  }

  List<BarChartGroupData> getOddSemesterChartData(String year) {
    return getSemesterChartData(year, true);
  }

  List<BarChartGroupData> getEvenSemesterChartData(String year) {
    int nextyrhelp = int.parse(year);
    int nextyear = nextyrhelp + 1;
    return getSemesterChartData(nextyear.toString(), false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blueAccent, Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SingleChildScrollView(
                child: availableAcademicYears.isNotEmpty
                    ? Column(
                        children: [
                          SizedBox(
                              height: MediaQuery.of(context).size.height / 100),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Usage Statistics :  ',
                                  style: GoogleFonts.poppins(
                                    fontSize:
                                        MediaQuery.of(context).size.width < 360
                                            ? 18
                                            : MediaQuery.of(context)
                                                        .size
                                                        .width <
                                                    600
                                                ? 22
                                                : 24,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 10.0,
                                        color: Colors.black.withOpacity(0.3),
                                        offset: const Offset(2.0, 2.0),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 2.0),
                                  child: SizedBox(
                                    width: MediaQuery.of(context).size.width /
                                        2.72,
                                    child: DropdownButton<String>(
                                      value: availableAcademicYears[
                                          currentYearIndex],
                                      underline:
                                          SizedBox(), // Removing the default underline
                                      icon: Icon(
                                        Icons.arrow_drop_down,
                                        color: Colors.white,
                                        size:
                                            30, // Increase the icon size to make it a little bigger
                                      ),
                                      dropdownColor: Colors.white,
                                      // menuWidth:
                                      //     MediaQuery.of(context).size.width /
                                      //         2.72,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: Colors
                                            .black, // Default style for items
                                      ),
                                      items: availableAcademicYears.map((year) {
                                        return DropdownMenuItem<String>(
                                          value: year,
                                          child: Text(
                                            year,
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              color: Colors
                                                  .black, // Normal style for each dropdown item
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          currentYearIndex =
                                              availableAcademicYears
                                                  .indexOf(value!);
                                        });
                                      },
                                      selectedItemBuilder:
                                          (BuildContext context) {
                                        return availableAcademicYears
                                            .map<Widget>((String item) {
                                          return Center(
                                            child: Text(
                                              item,
                                              style: GoogleFonts.poppins(
                                                decoration:
                                                    TextDecoration.underline,
                                                decorationColor: Colors.white,
                                                fontSize: MediaQuery.of(context)
                                                            .size
                                                            .width <
                                                        360
                                                    ? 18
                                                    : MediaQuery.of(context)
                                                                .size
                                                                .width <
                                                            600
                                                        ? 22
                                                        : 24,
                                                color: Colors
                                                    .transparent, // Apply custom style for selected item
                                                fontWeight: FontWeight.w600,
                                                shadows: [
                                                  Shadow(
                                                    color: Colors.white,
                                                    offset: Offset(0, -2),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList();
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GraphContainer(
                            year: availableAcademicYears[currentYearIndex]
                                .split('-')[0],
                            maxY: getMaxY(
                                availableAcademicYears[currentYearIndex]
                                    .split('-')[0]),
                            yInterval: calculateYAxisInterval(getMaxY(
                                availableAcademicYears[currentYearIndex]
                                    .split('-')[0])),
                            getChartData: getOddSemesterChartData,
                            title: 'Odd Semester Usage',
                          ),
                          const SizedBox(height: 16),
                          GraphContainer(
                            year: availableAcademicYears[currentYearIndex]
                                .split('-')[0],
                            maxY: getMaxY(
                                availableAcademicYears[currentYearIndex]
                                    .split('-')[0]),
                            yInterval: calculateYAxisInterval(getMaxY(
                                availableAcademicYears[currentYearIndex]
                                    .split('-')[0])),
                            getChartData: getEvenSemesterChartData,
                            title: 'Even Semester Usage',
                          ),
                          const SizedBox(height: 16),
                        ],
                      )
                    : const Center(
                        child: Text(
                          'No data available',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
              ),
            ),
    );
  }
}

class GraphContainer extends StatelessWidget {
  final String year;
  final double maxY;
  final int yInterval;
  final List<BarChartGroupData> Function(String year) getChartData;
  final String title;

  const GraphContainer({
    required this.year,
    required this.maxY,
    required this.yInterval,
    required this.getChartData,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
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
        height: MediaQuery.of(context).size.height / 3.5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 5.0),
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height / 80),
            Expanded(
              child: BarChart(
                BarChartData(
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        double totalSeconds = rod.toY * 60;
                        String formattedTime = formatSeconds(totalSeconds);
                        return BarTooltipItem(
                          formattedTime,
                          TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  minY: 0,
                  groupsSpace: 18,
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: yInterval.toDouble(),
                        getTitlesWidget: (value, meta) => Text(
                          formatYAxisLabel(value),
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
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            months[value.toInt()],
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    drawVerticalLine: true,
                    horizontalInterval: yInterval.toDouble(),
                    verticalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.3),
                        strokeWidth: 2,
                      );
                    },
                  ),
                  borderData: FlBorderData(
                      show: true,
                      border: Border(
                          left: BorderSide(
                            color: Colors.black,
                            width: 2,
                          ),
                          bottom: BorderSide(
                            color: Colors.black,
                            width: 2,
                          ))),
                  barGroups: getChartData(year),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String formatYAxisLabel(double value) {
    double hours = value / 60;
    return '${hours.toStringAsFixed(1)}h'; // Display hours with one decimal
  }

  String formatSeconds(double totalSeconds) {
    int hours = (totalSeconds / 3600).floor();
    int minutes = ((totalSeconds % 3600) / 60).floor();
    int seconds = (totalSeconds % 60).floor();

    return '$hours hours $minutes minutes $seconds seconds';
  }
}
