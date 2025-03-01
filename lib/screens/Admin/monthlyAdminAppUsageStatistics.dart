import 'dart:async';
import 'package:ephysicsapp/widgets/graphContainer.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:semaphore/semaphore.dart';

class MonthlyAdminAppUsageStatistics extends StatefulWidget {
  const MonthlyAdminAppUsageStatistics({Key? key}) : super(key: key);

  @override
  _MonthlyAdminAppUsageStatisticsState createState() =>
      _MonthlyAdminAppUsageStatisticsState();
}

class _MonthlyAdminAppUsageStatisticsState
    extends State<MonthlyAdminAppUsageStatistics> with WidgetsBindingObserver {


  bool isLoading = true;
  final List<String> months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  final List<String> years = [
    '2023', '2024', '2025', '2026', '2027', '2028',
    '2029', '2030', '2031', '2032', '2033', '2034', '2035'
  ];

  Map<String, Map<int, int>> cachedData = {}; // Cache for month-year combinations
  Map<int, int> weeklyUsage = {};
  String selectedYear = DateTime.now().year.toString();
  int selectedMonthIndex = DateTime.now().month - 1;

  late Semaphore semaphore;
  StreamSubscription<List<ConnectivityResult>>? _networkSubscription;

  @override
  void initState() {
    super.initState();
    _networkSubscription = Connectivity().onConnectivityChanged.listen((results) {
      if (results.contains(ConnectivityResult.wifi)) {
        print("Switched to WiFi: Allowing (50) concurrent requests");
        semaphore = LocalSemaphore(70); // Increase limit for WiFi
      } else {
        print("Switched to mobile data: Limiting to 10 concurrent requests");
        semaphore = LocalSemaphore(10); // Decrease limit for mobile data
      }
    });
    fetchAppUsageData();
  }

  Future<void> fetchAppUsageData() async {
    final networkType = await Connectivity().checkConnectivity();

    // Adjust semaphore limit based on network type
    if (networkType.contains(ConnectivityResult.wifi)) {
      print("WiFi detected: Allowing 50 concurrent requests");
      semaphore = LocalSemaphore(70);
    } else {
      print("Mobile data detected: Limiting to 10 concurrent requests");
      semaphore = LocalSemaphore(10); // Limit to 10 concurrent requests on mobile data
    }

    final String monthYearKey = "${months[selectedMonthIndex]} $selectedYear";
    debugPrint("Fetching data for: $monthYearKey");

    if (cachedData.containsKey(monthYearKey)) {
      setState(() {
        weeklyUsage = cachedData[monthYearKey]!;
        isLoading = false;
      });
      return;
    }

    setState(() => isLoading = true);
    try {
      DatabaseReference dbRef = FirebaseDatabase.instance.ref().child('Users');
      DatabaseEvent event = await dbRef.once();
      DataSnapshot snapshot = event.snapshot;
      Map<int, int> tempWeeklyUsage = {};

      if (snapshot.exists) {
        List<Future<Map<int, int>>> futures = [];

        for (DataSnapshot userSnapshot in snapshot.children) {
          await semaphore.acquire(); // Acquire a permit
          String userId = userSnapshot.key ?? '';
          debugPrint("Starting fetch for user: $userId");
          print("----------------");
          futures.add(
            getTotalMonthlyUsage(userId, monthYearKey).then((dailyUsageMap) {
              semaphore.release(); // Release the permit
              debugPrint("Fetched data for user: $userId");
              return groupUsageByCalendarWeeks(dailyUsageMap);
            }),
          );
        }

        List<Map<int, int>> userWeeklyUsages = await Future.wait(futures);
        debugPrint("All user data fetched successfully");

        for (var userWeeklyUsage in userWeeklyUsages) {
          userWeeklyUsage.forEach((week, usage) {
            tempWeeklyUsage[week] = (tempWeeklyUsage[week] ?? 0) + usage;
          });
        }

        cachedData[monthYearKey] = tempWeeklyUsage;

        setState(() {
          weeklyUsage = tempWeeklyUsage;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching app usage data: $e');
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
    }
  }

  Future<Map<String, int>> getTotalMonthlyUsage(String userId, String monthYear) async {
    final DatabaseReference ref = FirebaseDatabase.instance.ref();
    final userAppUsageRef = ref.child('Users').child(userId).child('AppUsage').child(monthYear);

    Map<String, int> dailyUsageMap = {};
    DataSnapshot snapshot = await userAppUsageRef.get();

    if (snapshot.exists) {
      snapshot.children.forEach((dateSnapshot) {
        String dateKey = dateSnapshot.key ?? '';
        String timeStr = dateSnapshot.value as String;
        int totalSeconds = convertTimeToSeconds(timeStr);
        dailyUsageMap[dateKey] = totalSeconds;
      });
    }

    return dailyUsageMap;
  }

  int convertTimeToSeconds(String time) {
    List<String> parts = time.split(':');
    return int.parse(parts[0]) * 3600 + int.parse(parts[1]) * 60 + int.parse(parts[2]);
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

  Map<int, int> groupUsageByCalendarWeeks(Map<String, int> dailyUsageMap) {
    Map<int, int> weeklyUsage = {};
    int year = int.parse(selectedYear);
    int month = selectedMonthIndex + 1;

    // Initialize all weeks with 0
    int totalWeeks = getTotalWeeks(year, month);
    for (int i = 1; i <= totalWeeks; i++) {
      weeklyUsage[i] = 0;
    }

    // Iterate through days with data
    dailyUsageMap.forEach((dateKey, usage) {
      List<String> dateParts = dateKey.split('-');
      if (dateParts.length == 3) {
        int day = int.parse(dateParts[0]);
        DateTime date = DateTime(year, month, day);
        int weekNum = getWeekNumber(date);
        weeklyUsage[weekNum] = (weeklyUsage[weekNum] ?? 0) + usage;
      }
    });

    return weeklyUsage;
  }

  void onMonthYearChanged(String newYear, int newMonthIndex) {
    setState(() {
      selectedYear = newYear;
      selectedMonthIndex = newMonthIndex;
    });
    fetchAppUsageData();
  }

  double getMaxY() {
    double maxUsage = weeklyUsage.values.isEmpty
        ? 10.0
        : weeklyUsage.values.fold(0, (max, value) => math.max(max, value / 60.0));
    return (maxUsage / 5).ceil() * 5.0;
  }

  int calculateYAxisInterval(double maxY) {
    return maxY > 0 ? (maxY / 5).ceil() : 1;
  }

  List<BarChartGroupData> getWeeklyChartData() {
    int totalWeeks = getTotalWeeks(int.parse(selectedYear), selectedMonthIndex + 1);

    return List.generate(
      totalWeeks,
          (index) {
        int weekNumber = index + 1;
        double usage = (weeklyUsage[weekNumber] ?? 0) / 60.0;
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: usage,
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
          child: Column(
            children: [
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: buildDropdown<String>(
                        selectedYear,
                        years,
                            (value) => onMonthYearChanged(value!, selectedMonthIndex),
                      ),
                    ),
                    Expanded(
                      child: buildDropdown<String>(
                        months[selectedMonthIndex],
                        months,
                            (value) {
                          if (value != null) {
                            int newMonthIndex = months.indexOf(value); // Get the index of the selected month
                            onMonthYearChanged(selectedYear, newMonthIndex); // Pass the new month index
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              weeklyUsage.isEmpty
                  ? Center(child: Text('No data available for ${months[selectedMonthIndex]} $selectedYear'))
                  : GraphContainer(
                maxY: getMaxY(),
                yInterval: calculateYAxisInterval(getMaxY()),
                getChartData: getWeeklyChartData,
                title: 'Weekly Usage for ${months[selectedMonthIndex]} $selectedYear',
                selectedMonthIndex: selectedMonthIndex,
                selectedYear: selectedYear,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildDropdown<T>(T selectedValue, List<T> items, ValueChanged<T?> onChanged) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButton<T>(
        value: selectedValue,
        isExpanded: true,
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
        style: GoogleFonts.poppins(fontSize: 16, color: Colors.black),
        items: items.map((e) => DropdownMenuItem(
          value: e,
          child: Text(e.toString()),
        )).toList(),
        onChanged: onChanged,
      ),
    );
  }

  @override
  void dispose() {
    print("Disposing");
    WidgetsBinding.instance.removeObserver(this);
    _networkSubscription?.cancel();
    cachedData.clear();
    super.dispose();
  }

}