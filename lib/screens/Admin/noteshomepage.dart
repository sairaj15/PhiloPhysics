import 'package:ephysicsapp/globals/colors.dart';
import 'package:ephysicsapp/screens/Admin/addModule.dart';
import 'package:ephysicsapp/screens/authentication/adminLogin.dart';
import 'package:ephysicsapp/services/authentication.dart';

import 'package:flutter/material.dart';
import 'package:bubble_tab_indicator/bubble_tab_indicator.dart';
import 'package:google_fonts/google_fonts.dart';

import 'modulesMaster.dart';

class NotesHomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new HomeWidgetState();
  }
}

class HomeWidgetState extends State<NotesHomePage> with TickerProviderStateMixin {
  final List<Tab> tabs = <Tab>[
    new Tab(text: "AP"),
    new Tab(text: "EP1"),
    new Tab(text: "EP2"),
  ];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = new TabController(vsync: this, length: tabs.length);
    print(prefs.get("studentUUID"));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color1,
      appBar: new AppBar(
        // title: Text("Homepage"),
        // actions: [
        //   isLoggedIn()
        //       ? IconButton(
        //           icon: Icon(Icons.exit_to_app),
        //           onPressed: () {
        //             onLogout(context);
        //           },
        //         )
        //       : IconButton(
        //           icon: Icon(Icons.person),
        //           onPressed: () async {
        //             Navigator.push(context,
        //                 MaterialPageRoute(builder: (context) => AdminLogin()));
        //           })
        // ],
        backgroundColor: color1,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: new TabBar(
          isScrollable: false,
          unselectedLabelColor: color5,
          labelColor: color2,

          labelPadding: EdgeInsets.symmetric(
            //   horizontal: (MediaQuery.of(context).size.width / 12)
          ),
          indicatorPadding: EdgeInsets.symmetric(horizontal: 5.0), // Adjust the padding as needed,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: new BubbleTabIndicator(
            indicatorHeight:40.0,
            indicatorColor:color5,
            indicatorRadius: 10,
            tabBarIndicatorSize: TabBarIndicatorSize.label,
          ),
          tabs: tabs,
          controller: _tabController,
        ),
      ),
      body: isLoggedIn() || isStudentLoggedIn() ? new TabBarView(
        controller: _tabController,
        children: tabs.map((Tab tab) {
          String section = "1";
          if (tab.text == tabs[1].text)
            section = "2";
          else if(tab.text == tabs[2].text)
            section = "3";
          else
            section = "1";
          return ModuleMaster(section: section);
        }).toList(),
      ) : Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: MediaQuery.of(context).size.height * 0.03), // Added vertical padding for balance
              height: MediaQuery.of(context).size.height / 2.5,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: Colors.white, // Background color to contrast with border
                border: Border.all(color: Colors.black.withOpacity(0.6), width: 2), // Softer black
                borderRadius: BorderRadius.circular(20), // More rounded corners for modern look
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3), // Subtle shadow for depth
                    blurRadius: 8,
                    spreadRadius: 3,
                    offset: const Offset(0, 4), // Shadow offset
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
                children: [
                  Text(
                    'Welcome!',
                    style: GoogleFonts.poppins(
                      fontSize: MediaQuery.of(context).size.width * 0.065,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87, // Darker text color for contrast
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.width * 0.03), // Space between texts
                  Text(
                    'Login or create an account to access complete content',
                    style: GoogleFonts.lato(
                      fontSize: MediaQuery.of(context).size.width * 0.0425,
                      fontWeight: FontWeight.w400,
                      color: Colors.black, // Softer text for secondary message
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.width * 0.03), // Space between texts
                  Text(
                    'Click below to navigate to the login/register section',
                    style: GoogleFonts.lato(
                      fontSize: MediaQuery.of(context).size.width * 0.0425,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.width * 0.05), // Space between texts
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical : MediaQuery.of(context).size.height * 0.02, horizontal: 40),
                      backgroundColor: color5, // More vibrant button color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30), // Rounded button
                      ),
                      elevation: 5, // Elevated button for depth
                    ),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => AdminLogin()));
                    },
                    child: const Text(
                      'Login/Register',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      // floatingActionButton: isLoggedIn()? FloatingActionButton(
      //   backgroundColor: color4,
      //   onPressed: () {
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute(builder: (context) => AddModule()),
      //     );
      //   }
      //   child: Icon(Icons.add,),
      // ):Container(),
    );
  }
}
