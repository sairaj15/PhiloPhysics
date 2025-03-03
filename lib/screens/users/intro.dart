import 'package:ephysicsapp/globals/colors.dart';
import 'package:ephysicsapp/globals/labels.dart';
import 'package:ephysicsapp/screens/users/aboutUs.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IntroPage extends StatefulWidget {
  @override
  _IntroPageState createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  bool isLoggedIn = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color1,
      body: SafeArea(
        child: Container(
          //margin: EdgeInsets.only(top:MediaQuery.of(context).size.height / 10),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: 20),
                Text(
                  appName,
                  style: GoogleFonts.merriweather(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      color: color5),
                ),
                SizedBox(height: 10),
                Text(
                  tagline,
                  style: GoogleFonts.merriweather(
                      fontSize: 16, fontStyle: FontStyle.italic, color: color5),
                ),
                SizedBox(height: 20),
                FloatingActionButton.extended(
                  label: Text(
                    "About Us",
                    style: TextStyle(color: Colors.white),
                  ),
                  heroTag: "btn1",
                  backgroundColor: color5,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AboutUs()),
                    );
                  },
                  icon: new Icon(
                    Icons.info,
                    color: Colors.white,
                  ),
                ),
                Center(
                    child: Image.asset(
                  'assets/intro.png',
                  height: MediaQuery.of(context).size.height / 2,
                  width: MediaQuery.of(context).size.width - 50,
                )),
              ],
            ),
          ),
        ),
      ),
      // floatingActionButton: new Padding(
      //   padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
      //   child: new Row(
      //     mainAxisAlignment: MainAxisAlignment.end,
      //     children: <Widget>[

      //        FloatingActionButton.extended(
      //         label: Text("About Us"),
      //         heroTag: "btn1",
      //         backgroundColor: color5,
      //         onPressed: () {
      //           Navigator.push(
      //             context,
      //             MaterialPageRoute(builder: (context) => AboutUs()),
      //           );
      //         },
      //         icon: new Icon(Icons.info),
      //       ),
      //       new Padding(
      //         padding: new EdgeInsets.symmetric(
      //           horizontal: 15.0,
      //         ),
      //       ),
      //       FloatingActionButton.extended(
      //         label: Text("Home"),
      //         heroTag: "btn2",
      //         backgroundColor: color5,
      //         onPressed: () {
      //           Navigator.push(
      //             context,
      //             MaterialPageRoute(builder: (context) => MyHomePage()),
      //           );
      //         },
      //         icon: new Icon(Icons.home),
      //       ),
      //     ],
      //   ),
      // ),
    );
  }
}
