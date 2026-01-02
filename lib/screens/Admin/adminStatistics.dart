import 'dart:collection';
import 'dart:convert';
import 'package:ephysicsapp/globals/constants.dart';
import 'package:ephysicsapp/screens/Admin/adminControlPanel.dart';
import 'package:ephysicsapp/screens/Admin/adminUserUsageStatistics.dart';
import 'package:ephysicsapp/screens/Admin/developerControlPanel.dart';
import 'package:ephysicsapp/screens/Admin/vlabs_view_stats_page.dart';
import 'package:ephysicsapp/services/dataAutomateService.dart';
import 'package:ephysicsapp/shimmer/adminStatisticsShimmer.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:http/http.dart' as http;

class AdminStatistics extends StatefulWidget {
  const AdminStatistics({Key? key}) : super(key: key);

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
  int totalVLabViews = 0;

  List<String> availableYears = [];
  Map<String, List<Map<String, dynamic>>> topUsers = {};
  List<Map<String, dynamic>> overallTopUsers = [];
  List<String> fetchedColleges = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = new TabController(vsync: this, length: 1);
    initializeData();
    getAllColleges();
  }

  @override
  void dispose() {
    // Dispose of the TabController to free resources
    _tabController.dispose();
    super.dispose();
  }

  Future<void> getAllColleges() async {
    final url = Uri.parse("$apiUrl/api/unique-colleges");

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      fetchedColleges = List<String>.from(data['uniqueColleges']);
      print(fetchedColleges);
    }
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

          if (userData.containsKey('VLabViews')) {
            Map<dynamic, dynamic> vlabViews = userData['VLabViews'];
            vlabViews.forEach((monthYear, dateMap) {
              (dateMap as Map<dynamic, dynamic>).forEach((date, count) {
                if (count is int) {
                  totalVLabViews += count;
                } else if (count is String) {
                  totalVLabViews += int.tryParse(count) ?? 0;
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

  void showUpdateConfirmationDialog(BuildContext context) {
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 35, 20, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Are you sure you want to update data?',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: isLoading
                              ? null
                              : () async {
                                  setState(() => isLoading = true);
                                  try {
                                    await DataAutomateService()
                                        .updateGoogleSheetData();
                                    Navigator.pop(dialogContext);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              "Sheet updated successfully")),
                                    );
                                  } catch (e) {
                                    Navigator.pop(dialogContext);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text("Failed to update sheet")),
                                    );
                                  }
                                },
                          child: Container(
                            constraints: BoxConstraints(minWidth: 100),
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.blue, Colors.indigo],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Center(
                                child: isLoading
                                    ? SpinKitFadingCircle(
                                        color: Colors.white,
                                        size: 15.0,
                                      )
                                    : Text(
                                        'Update',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed:
                          isLoading ? null : () => Navigator.pop(dialogContext),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'Admin Statistics',
          style: TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: InkWell(
                onTap: () => showUpdateConfirmationDialog(context),
                child: Icon(Icons.refresh_rounded)),
          ),
        ],
      ),
      body: isLoading
          ? AdminStatisticsShimmer()
          : SingleChildScrollView(
              child: Container(
                color: Colors.grey.shade100,
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    SizedBox(height: 20),

// First row: three stat boxes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _buildStatBox(
                            Icons.people,
                            'Total\nUsers',
                            userCount.toString(),
                            Colors.blue,
                            context,
                            AdminUserAppUsageStats(),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildStatBox(
                            Icons.picture_as_pdf,
                            'PDFs Viewed',
                            totalPdfsViewed.toString(),
                            Colors.green,
                            context,
                            null,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildStatBox(
                            Icons.video_library,
                            'Videos Viewed',
                            totalVideosViewed.toString(),
                            Colors.orange,
                            context,
                            null,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height / 40),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatBox(
                            Icons.science,
                            'V-Labs\nViewed',
                            '', // Pass empty string for value
                            Colors.purple,
                            context,
                            VLabUsageStatsPage(),
                          ),
                        ),
                      ],
                    ),

                    /// Top Users Container
                    _buildTopUsersContainer(),
                    SizedBox(height: MediaQuery.of(context).size.height / 50),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => AdminControlPanel()),
                        );
                      },
                      child: const Text(
                        "Go to Admin Panel",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => DeveloperControlPanel()),
                        );
                      },
                      child: const Text(
                        "Go to Developer Panel",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),

                    SizedBox(height: MediaQuery.of(context).size.height / 50),
                    // Usage Stats Box
                    _buildUsageStatsBox(
                      context,
                      pdfViewersCount,
                      totalUserofApp,
                      hour,
                      mins,
                    ),

                    SizedBox(height: MediaQuery.of(context).size.height / 50),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: () {
                        showSemesterDialog(context);
                      },
                      child: const Text(
                        "End Semester / Academic Year",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),

                    SizedBox(height: MediaQuery.of(context).size.height / 30),
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
    Widget? pageToNavigate, [
    bool showValue = true, // Add this optional parameter
  ]) {
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
            CircleAvatar(
              radius: MediaQuery.of(context).size.width / 17,
              backgroundColor: Colors.white.withOpacity(0.3),
              child: Icon(icon,
                  size: MediaQuery.of(context).size.width / 14,
                  color: Colors.white),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: MediaQuery.of(context).size.width * 0.0475,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.005),
            if (showValue && value.isNotEmpty)
              Text(
                formatNumber(int.tryParse(value) ?? 0),
                style: GoogleFonts.poppins(
                  fontSize: MediaQuery.of(context).size.width * 0.0575,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
          ],
        ),
      ),
    );
  }

  String formatNumber(int number) {
    if (number >= 100000) {
      return "${(number / 100000).toStringAsFixed(1)}L"; // 1.0L, 10.1L
    } else if (number >= 10000) {
      return "${(number / 1000).toStringAsFixed(1)}K"; // 10.0K, 99.9K
    } else {
      return number.toString(); // Return as is if less than 10K
    }
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
        if (index >= users.length) return SizedBox.shrink();

        final user = users[index];
        final medalAsset = _getMedalAsset(index);
        final usageDuration = user['usage'] as Duration;

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 5,
          margin: const EdgeInsets.symmetric(
              vertical: 4), // Reduced margin between tiles
          child: ListTile(
            dense: true,
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
            trailing: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('User Info'),
                    content: Text(
                      'Email: ${user['email']}\n'
                      'Class: ${user['classDiv']}\n'
                      'Usage: ${_formatCompleteDuration(usageDuration)}',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('OK'),
                      ),
                    ],
                  ),
                );
              },
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
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8),
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
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
              child: Text(
                'Top Users',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DefaultTabController(
              length: availableYears.length + 1,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TabBar(
                    physics: const BouncingScrollPhysics(),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 18),
                    dividerColor: Colors.transparent,
                    isScrollable: true,
                    unselectedLabelColor: Colors.grey,
                    labelColor: Colors.white,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.blueAccent,
                    ),
                    tabs: [
                      const Tab(height: 32, text: 'Overall'),
                      ...availableYears
                          .take(3)
                          .map((year) => Tab(height: 32, text: year)),
                    ],
                  ),

                  // Fix #1: Use a SizedBox with a dynamic height calculation instead of LimitedBox
                  SizedBox(
                    height: MediaQuery.of(context).size.height / 4,
                    child: TabBarView(
                      // Fix #2: Adding physics to prevent additional scrolling constraints
                      physics: NeverScrollableScrollPhysics(),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12.0, vertical: 2.0),
                          // Fix #3: Wrap the list in a SingleChildScrollView to handle potential overflow
                          child: SingleChildScrollView(
                            child: _buildTopUsersList(overallTopUsers),
                          ),
                        ),
                        ...availableYears.take(3).map(
                              (year) => Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0, vertical: 2.0),
                                // Fix #3 applied to each year tab as well
                                child: SingleChildScrollView(
                                  child:
                                      _buildTopUsersList(topUsers[year] ?? []),
                                ),
                              ),
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
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height / 6,
      ),
      margin: const EdgeInsets.symmetric(vertical: 12),
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
          // Left Side: "Study Material Usage" Title
          SizedBox(
            width: MediaQuery.of(context).size.width / 4.65,
            child: Text(
              'Study\nMaterial\nUsage',
              style: GoogleFonts.poppins(
                fontSize: MediaQuery.of(context).size.width * 0.045,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              softWrap: true,
            ),
          ),

          // Middle section with circular indicator and its label
          Expanded(
            flex: 3,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularPercentIndicator(
                  radius: MediaQuery.of(context).size.width / 12,
                  lineWidth: 8.0,
                  percent: materialUsagePercent,
                  center: Text(
                    "${(materialUsagePercent * 100).toInt()}%",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  progressColor: Colors.blue,
                  backgroundColor: Colors.grey.shade300,
                  circularStrokeCap: CircularStrokeCap.round,
                ),
                SizedBox(height: 8),
                Text(
                  'Materials Used\nby Students',
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

          // Right Side: Time display with its label
          Expanded(
            flex: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "$hours Hr\n$minutes Min",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
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

  void showSemesterDialog(BuildContext context) {
    DateTime? startDate;
    DateTime? endDate;
    bool isLoading = false; // Loader state

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.all(16),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text("Select Semester Duration",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text("Pick the start and end month/year for this semester",
                                style: TextStyle(fontSize: 13, color: Colors.black54)),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Start Date Picker
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Start Month & Year"),
                    subtitle: Text(
                      startDate != null
                          ? "${_monthName(startDate!.month)} ${startDate!.year}"
                          : "Select start date",
                    ),
                    trailing: const Icon(Icons.calendar_today, size: 20),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        helpText: "Select Start Date",
                        initialDatePickerMode: DatePickerMode.year,
                      );
                      if (picked != null) {
                        setState(() => startDate = picked);
                      }
                    },
                  ),

                  // End Date Picker
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("End Month & Year"),
                    subtitle: Text(
                      endDate != null
                          ? "${_monthName(endDate!.month)} ${endDate!.year}"
                          : "Select end date",
                    ),
                    trailing: const Icon(Icons.calendar_today, size: 20),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: endDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        helpText: "Select End Date",
                        initialDatePickerMode: DatePickerMode.year,
                      );
                      if (picked != null) {
                        setState(() => endDate = picked);
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  // Confirm Button
                  SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: isLoading
                          ? null
                          : () async {
                        if (startDate != null && endDate != null) {
                          setState(() => isLoading = true);
                          try {
                            await DataAutomateService()
                                .updateGoogleSheetDataForSpecificTime(startDate!, endDate!);
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Semester sheet created successfully")),
                            );
                          } catch (e) {
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Failed to create semester sheet")),
                            );
                          } finally {
                            setState(() => isLoading = false);
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: isLoading
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : const Text(
                            "Confirm",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

}
