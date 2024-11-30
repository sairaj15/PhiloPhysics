import 'dart:collection';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:bubble_tab_indicator/bubble_tab_indicator.dart';
import 'package:ephysicsapp/globals/colors.dart';
import 'package:ephysicsapp/screens/Admin/adminUserUsageStatistics.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class AdminStatistics extends StatefulWidget {
  const AdminStatistics({super.key});

  @override
  _AdminStatisticsState createState() => _AdminStatisticsState();
}

class _AdminStatisticsState extends State<AdminStatistics>
    with TickerProviderStateMixin {
  int userCount = 0;
  int totalPdfsViewed = 0;
  int totalVideosViewed = 0;
  int uniqueCollegesCount = 0;
  int pdfViewersCount = 0;
  double totalPdfUsageTime = 0;
  bool isLoading = true;
  int totalUserofApp = 0;
  int hour = 0;
  int mins = 0;

  List<String> availableYears = [];
  Map<String, List<Map<String, dynamic>>> topUsers = {};
  List<Map<String, dynamic>> overallTopUsers = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = new TabController(vsync: this, length: 1);
    initializeData();
  }

  @override
  void dispose() {
    // Dispose of the TabController to free resources
    _tabController.dispose();
    super.dispose();
  }

  Future<void> initializeData() async {
    await Future.wait([
      getUserStatsAndCount(),
      _initializeDatatoLists(),
    ]);
  }

  Future<void> _initializeDatatoLists() async {
    setState(() {
      isLoading = true;
    });

    final data = await getTopUsersAndYears(); // Fetch data from backend
    setState(() {
      availableYears = data['availableYears'] as List<String>;
      topUsers = data['topUsers'] as Map<String, List<Map<String, dynamic>>>;
      overallTopUsers = topUsers['overall'] ?? [];
    });
    setState(() {
      _tabController =
          TabController(vsync: this, length: availableYears.length + 1);
    });
  }

  Future<Map<String, dynamic>> getTopUsersAndYears() async {
    final databaseRef = FirebaseDatabase.instance.ref('Users');
    final usersSnapshot = await databaseRef.get();

    Map<String, Map<String, Duration>> yearWiseUsage = {};
    Map<String, Duration> overallUsage = {};
    Set<String> availableYears = {};

    if (usersSnapshot.exists) {
      final usersData = usersSnapshot.value as Map;

      usersData.forEach((userId, userData) {
        final appUsage = userData['AppUsage'] as Map<dynamic, dynamic>?;
        if (appUsage == null) return;

        appUsage.forEach((monthYear, dates) {
          final year = monthYear.split(' ')[1]; // Extract year from "Nov 2024"
          availableYears.add(year);

          if (!yearWiseUsage.containsKey(year)) {
            yearWiseUsage[year] = {};
          }

          (dates as Map<dynamic, dynamic>).forEach((day, timeStr) {
            final timeParts = (timeStr as String).split(':');
            final usageDuration = Duration(
              hours: int.parse(timeParts[0]),
              minutes: int.parse(timeParts[1]),
              seconds: int.parse(timeParts[2]),
            );

            // Add to year-wise usage
            yearWiseUsage[year]![userId] =
                (yearWiseUsage[year]![userId] ?? Duration.zero) + usageDuration;

            // Add to overall usage
            overallUsage[userId] =
                (overallUsage[userId] ?? Duration.zero) + usageDuration;
          });
        });
      });
    }

    // Sort users by usage for each year and overall
    Map<String, List<Map<String, dynamic>>> topUsersByYear = {};
    yearWiseUsage.forEach((year, usage) {
      final sortedEntries = usage.entries.toList(); // Convert to mutable list
      sortedEntries.sort(
          (a, b) => b.value.compareTo(a.value)); // Sort in descending order

      topUsersByYear[year] = sortedEntries
          .take(3) // Take top 3 users
          .map((entry) => {
                'userId': entry.key,
                'name': usersSnapshot.child('${entry.key}/name').value,
                'email': usersSnapshot.child('${entry.key}/email').value,
                'classDiv': usersSnapshot.child('${entry.key}/classDiv').value,
                'usage': entry.value,
              })
          .toList();
    });

    // Overall top users
    List<Map<String, dynamic>> overallTopUsers = [];
    final sortedOverallEntries =
        overallUsage.entries.toList(); // Convert to mutable list
    sortedOverallEntries
        .sort((a, b) => b.value.compareTo(a.value)); // Sort in descending order

    overallTopUsers = sortedOverallEntries
        .take(3) // Take top 3 users
        .map((entry) => {
              'userId': entry.key,
              'name': usersSnapshot.child('${entry.key}/name').value,
              'email': usersSnapshot.child('${entry.key}/email').value,
              'classDiv': usersSnapshot.child('${entry.key}/classDiv').value,
              'usage': entry.value,
            })
        .toList();

    print("Overall Top Usage : \n ${overallTopUsers}");
    print("Year Wise Usage : \n ${topUsersByYear}");

    return {
      'availableYears': availableYears.toList()..sort(),
      'topUsers': {'overall': overallTopUsers, ...topUsersByYear},
    };
  }

  Future<void> getUserStatsAndCount() async {
    DatabaseReference dbRef = FirebaseDatabase.instance.ref().child('Users');

    try {
      // Get the data snapshot from Firebase
      DataSnapshot snapshot =
          await dbRef.get(); // Use .get() instead of .once()

      // Log the snapshot to verify data structure
      print('Snapshot data: ${snapshot.value}'); // Log the entire snapshot

      totalUserofApp = snapshot.children.length;
      print("Total USers of App : ${totalUserofApp}");

      if (snapshot.exists) {
        Set<String> uniqueColleges = HashSet<String>();

        int pdfsViewedTemp = 0;
        int videosViewedTemp = 0;
        int pdfViewersTemp = 0;
        double pdfUsageTimeTempInMinutes = 0; // Time in minutes

        // Fetch data in parallel for efficiency
        for (var userSnapshot in snapshot.children) {
          // Type-safe access to user data
          Map<dynamic, dynamic> userData =
              userSnapshot.value as Map<dynamic, dynamic>;

          if (userData.containsKey('pdfsViewed')) {
            pdfsViewedTemp += (userData['pdfsViewed'] as num).toInt();
            pdfViewersTemp++;
          }
          if (userData.containsKey('videosViewed')) {
            videosViewedTemp += (userData['videosViewed'] as num).toInt();
          }

          if (userData.containsKey('PdfUsage')) {
            Map<dynamic, dynamic> pdfUsage = userData['PdfUsage'];

            // Debug log to check the pdfUsage structure
            print(
                'pdfUsage for ${userSnapshot.key}: $pdfUsage'); // Log the pdfUsage structure

            pdfUsage.forEach((monYear, dateMap) {
              // Log the month-year and its corresponding date map
              print('Mon-Year: $monYear, DateMap: $dateMap'); // Debug log

              dateMap.forEach((date, timeSpent) {
                // Log each date and the time spent on that date
                print('Date: $date, TimeSpent: $timeSpent'); // Debug log

                // Check if the timeSpent is a valid string before proceeding
                if (timeSpent is String) {
                  print('Valid timeSpent string: $timeSpent');
                  double timeInMinutes = convertTimeToMinutes(timeSpent);
                  print(
                      'Converted Time (minutes): $timeInMinutes'); // Log converted time
                  pdfUsageTimeTempInMinutes += timeInMinutes;
                } else {
                  print('Invalid time format for date: $date');
                }
              });
            });
          }

          if (userData.containsKey('college')) {
            uniqueColleges.add(userData['college']);
          }
        }

        setState(() {
          userCount = snapshot.children.length;
          totalPdfsViewed = pdfsViewedTemp;
          totalVideosViewed = videosViewedTemp;
          pdfViewersCount = pdfViewersTemp;
          totalPdfUsageTime =
              pdfUsageTimeTempInMinutes; // Time is in minutes now
          uniqueCollegesCount = uniqueColleges.length;
          isLoading = false;

          hours(pdfUsageTimeTempInMinutes);
          minutes(pdfUsageTimeTempInMinutes);
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

// Helper function to convert "HH:mm:ss" to total minutes
  double convertTimeToMinutes(String timeString) {
    List<String> parts = timeString.split(":");
    if (parts.length == 3) {
      int hours = int.parse(parts[0]);
      int minutes = int.parse(parts[1]);
      int seconds = int.parse(parts[2]);

      // Convert time to minutes
      return (hours * 60 + minutes + seconds / 60.0);
    }
    return 0.0; // Return 0.0 if the format is incorrect
  }

  void hours(double totalMinutes) {
    hour = totalMinutes ~/ 60; // Get the integer part for hours
  }

  void minutes(double totalMinutes) {
    mins = totalMinutes.toInt() % 60; // Get the remainder for minutes
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Admin Statistics',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent, // Updated app bar color
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Container(
                color: Colors.grey.shade100, // Background color for entire page
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    // Stat Box Grid
                    GridView.count(
                      crossAxisCount: 3,
                      crossAxisSpacing: 20.0,
                      mainAxisSpacing: 20.0,
                      childAspectRatio: 0.7,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildStatBox(
                          Icons.people,
                          'Total Users',
                          userCount.toString(),
                          Colors.blue,
                          context,
                          AdminUserAppUsageStats(),
                        ),
                        _buildStatBox(
                          Icons.picture_as_pdf,
                          'PDFs Viewed',
                          totalPdfsViewed.toString(),
                          Colors.green,
                          context,
                          null,
                        ),
                        _buildStatBox(
                          Icons.video_library,
                          'Videos Viewed',
                          totalVideosViewed.toString(),
                          Colors.orange,
                          context,
                          null,
                        ),
                      ],
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height / 30),
                    // Top Users Container
                    _buildTopUsersContainer(),
                    SizedBox(height: MediaQuery.of(context).size.height / 25),
                    // Usage Stats Box
                    _buildUsageStatsBox(
                      context,
                      pdfViewersCount,
                      totalUserofApp,
                      hour,
                      mins,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatBox(
    IconData icon,
    String label,
    String value,
    Color color,
    BuildContext context,
    Widget? pageToNavigate,
  ) {
    return GestureDetector(
      onTap: () {
        if (pageToNavigate != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => pageToNavigate),
          );
        }
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: MediaQuery.of(context).size.width / 14,
                backgroundColor: Colors.white.withOpacity(0.3),
                child: Icon(icon, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours > 0 ? '${hours}Hr' : ''}${minutes}Min';
  }

  String _formatCompleteDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '$hours Hours $minutes Minutes';
  }

  String _getMedalAsset(int index) {
    switch (index) {
      case 0:
        return '1'; // Gold medal
      case 1:
        return '2'; // Silver medal
      case 2:
        return '3'; // Bronze medal
      default:
        return 'None'; // Fallback asset
    }
  }

  Widget _buildTopUsersList(List<Map<String, dynamic>> users) {
    if (users.isEmpty) {
      return Center(child: Text('No data available.'));
    }

    return Column(
      children: List.generate(3, (index) {
        if (index >= users.length)
          return SizedBox.shrink(); // Prevent excess list tiles if less than 3

        final user = users[index];
        final medalAsset = _getMedalAsset(index);
        final usageDuration = user['usage'] as Duration;

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 4,
          margin: const EdgeInsets.symmetric(
              vertical: 4), // Reduced margin between tiles
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
            leading: Text(
              medalAsset,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 30, // Increased font size for medal text
                color: medalAsset == '1'
                    ? Color(0xFFFFD700) // Gold
                    : medalAsset == '2'
                        ? Color(0xFFC0C0C0) // Silver
                        : Color(0xFFCD7F32), // Bronze
              ),
            ),
            title: Row(
              children: [
                // User name with ellipsis if it is too long
                Expanded(
                  child: Text(
                    user['name'],
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                // Usage time: x Hr y Min
                Text(
                  _formatDuration(usageDuration),
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            trailing: Tooltip(
              message:
                  'Email: ${user['email']}\nClass: ${user['classDiv']}\nUsage: ${_formatCompleteDuration(usageDuration)}',
              child: Icon(
                Icons.info_outline,
                color: Colors.blue,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTopUsersContainer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade200,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Top Users',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DefaultTabController(
              length: availableYears.length + 1,
              child: Column(
                children: [
                  TabBar(
                    isScrollable: true,
                    unselectedLabelColor: Colors.grey,
                    labelColor: Colors.black,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.blueAccent,
                    ),
                    tabs: [
                      Tab(text: 'Overall'),
                      ...availableYears.take(3).map((year) => Tab(text: year)),
                    ],
                  ),
                  SizedBox(
                    height: 200,
                    child: TabBarView(
                      children: [
                        _buildTopUsersList(overallTopUsers),
                        ...availableYears.map(
                          (year) => _buildTopUsersList(topUsers[year] ?? []),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageStatsBox(
    BuildContext context,
    int pdfViewersCount,
    int totalUsers,
    int hours,
    int minutes,
  ) {
    // Calculate the material usage percentage
    double materialUsagePercent = totalUsers > 0
        ? (pdfViewersCount / totalUsers).clamp(0, 1).toDouble()
        : 0.0;

    return Container(
      height: MediaQuery.of(context).size.height / 5.5,
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // **Left Side**: "Study Material Usage" Title
          SizedBox(
            width: MediaQuery.of(context).size.width / 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Study Material Usage',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Insights into material consumption',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // **Center**: Circular Progress Indicator
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularPercentIndicator(
                  radius: MediaQuery.of(context).size.width / 10,
                  lineWidth: 8.0,
                  percent: materialUsagePercent,
                  center: Text(
                    "${(materialUsagePercent * 100).toInt()}%",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  progressColor: Colors.blue,
                  backgroundColor: Colors.grey.shade300,
                  circularStrokeCap: CircularStrokeCap.round,
                ),
                const SizedBox(height: 8),
                Text(
                  'Materials Used by Students',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),

          // **Right Side**: Total Time Information
          SizedBox(
            width: MediaQuery.of(context).size.width / 3.5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "$hours Hr $minutes Min",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total Material Usage Time',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
