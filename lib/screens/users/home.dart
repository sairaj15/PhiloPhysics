import 'package:ephysicsapp/globals/colors.dart';
import 'package:ephysicsapp/screens/Admin/adminStatistics.dart';
import 'package:ephysicsapp/screens/Admin/noteshomepage.dart';
import 'package:ephysicsapp/screens/users/intro.dart';
import 'package:ephysicsapp/screens/authentication/adminLogin.dart';
import 'package:ephysicsapp/screens/users/quiz/quizHomePage.dart';
import 'package:ephysicsapp/services/authentication.dart';
import 'package:ephysicsapp/widgets/bottom_navy_bar.dart';
import 'package:flutter/material.dart';


class MyHomePage extends StatefulWidget {

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  int _currentIndex = 0;
  late PageController _pageController;
 String appbarText="Home";
  List titles = ["Home", "Notes", "Play Quiz"];



  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
            title: Text(appbarText,style:TextStyle(color: color5),),
            backgroundColor: color1,
            iconTheme: IconThemeData(
              color: color5
            ),
       elevation: 0,
        actions: [
          isLoggedIn() ? IconButton(
              icon: Icon(Icons.insights),
              onPressed: () async {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => AdminStatistics()));
              }) : SizedBox.shrink(),
          isLoggedIn() || isStudentLoggedIn()
              ? IconButton(
                  icon: Icon(Icons.exit_to_app),
                  onPressed: () {
                    onLogout(context);
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
      body: SizedBox.expand(
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() { 
               appbarText=titles[_currentIndex];
              _currentIndex = index;});
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
          setState((){
           
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
    );
  }
}