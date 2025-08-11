import 'package:ephysicsapp/globals/colors.dart';
import 'package:ephysicsapp/main.dart';
import 'package:ephysicsapp/screens/Admin/adminStatistics.dart';
import 'package:ephysicsapp/screens/Admin/noteshomepage.dart';
import 'package:ephysicsapp/screens/users/intro.dart';
import 'package:ephysicsapp/screens/authentication/adminLogin.dart';
import 'package:ephysicsapp/screens/users/queryScreen.dart';
import 'package:ephysicsapp/screens/users/quiz/quizHomePage.dart';
import 'package:ephysicsapp/screens/users/sidebar.dart';
import 'package:ephysicsapp/services/authentication.dart';
import 'package:ephysicsapp/widgets/bottom_navy_bar.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;
  late PageController _pageController;
  String appbarText = "Home";
  List titles = [
    "Home",
    "Notes",
    "Play Quiz",
  ];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    checkForProfileUpdate(context);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> checkForProfileUpdate(BuildContext context) async {
    final dbRef = FirebaseDatabase.instance.ref('Push_User_Update');

    try {
      String todaysDate = DateFormat('dd/MM/yyyy').format(DateTime.now());

      DatabaseEvent event = await dbRef.once();

      if (event.snapshot.exists) {
        bool dateFound = false;

        for (var child in event.snapshot.children) {
          String? value = child.value?.toString();
          if (value == todaysDate) {
            dateFound = true;
            break;
          }
        }

        if (dateFound) {
          showDialog(
            context: context,
            barrierDismissible: false, // non-dismissible
            builder: (ctx) {
              return AlertDialog(
                title: Text("Update Profile"),
                content: Text("Please update your profile to continue."),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                    },
                    child: Text("OK"),
                  ),
                ],
              );
            },
          );
        }
      }
    } catch (e) {
      print("Error: ${e.toString()}");
    }
  }

  void _onSidebarItemSelected(int index) {
    setState(() {
      _currentIndex = index;
      appbarText = titles[index];
    });
    _pageController.jumpToPage(index);
  }

  bool get isAdmin => isLoggedIn();
  bool get isStudent => isStudentLoggedIn();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          appbarText,
          style: TextStyle(color: color5),
        ),
        backgroundColor: color1,
        iconTheme: IconThemeData(color: color5),
        elevation: 0,
        actions: [
          isLoggedIn() || isStudentLoggedIn()
              ? IconButton(
                  icon: Icon(Icons.menu_outlined),
                  onPressed: () {
                    _scaffoldKey.currentState?.openEndDrawer();
                  },
                )
              : IconButton(
                  icon: Icon(Icons.person),
                  onPressed: () async {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => AdminLogin()));
                  }),
        ],
      ),
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              appbarText = titles[_currentIndex];
              _currentIndex = index;
            });
          },
          children: <Widget>[
            IntroPage(),
            NotesHomePage(),
            QuizHomePage(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavyBar(
        backgroundColor: color1,
        itemCornerRadius: 12,
        selectedIndex: _currentIndex,
        onItemSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
          _pageController.animateToPage(
            index,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        items: <BottomNavyBarItem>[
          BottomNavyBarItem(
            activeColor: color2,
            title: Text('Home', style: TextStyle(color: color5)),
            icon: Icon(Icons.home, color: color5),
            inactiveColor: Colors.white,
            textAlign: TextAlign.center,
          ),
          BottomNavyBarItem(
            activeColor: color2,
            inactiveColor: Colors.white,
            textAlign: TextAlign.center,
            title: Text('Notes', style: TextStyle(color: color5)),
            icon: Icon(Icons.book, color: color5),
          ),
          BottomNavyBarItem(
            activeColor: color2,
            inactiveColor: Colors.white,
            textAlign: TextAlign.center,
            title: Text('Quizzes', style: TextStyle(color: color5)),
            icon: Icon(Icons.timer, color: color5),
          ),
        ],
      ),
      endDrawer: isLoggedIn() || isStudentLoggedIn()
          ? ProfileSidebarDrawer(
              selectedIndex: _currentIndex,
              onItemSelected: _onSidebarItemSelected,
              isAdmin: isLoggedIn(),
              isStudent: isStudentLoggedIn(),
              onLogout: () => onLogout(context),
              onLogin: () {
                // Navigate to your login page
                navigatorKey.currentState?.push(
                    MaterialPageRoute(builder: (context) => AdminLogin()));
              },
              onAdminLogin: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => AdminLogin()));
              },
              onQuery: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => QueryFormScreen()));
              },
              onAdminStats: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => AdminStatistics()));
              },
            )
          : null,
    );
  }
}
