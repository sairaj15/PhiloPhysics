import 'package:ephysicsapp/screens/users/home.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(
          seconds: 1, milliseconds: 50), // Total duration of 4 seconds
      vsync: this,
    );

    // Fade-in animation for the first 0.5 seconds
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // Navigate after 3.5 seconds
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => MyHomePage()), // Navigate to home page
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnimation, // The fade-in effect
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // College Header Section
            Padding(
              padding: EdgeInsets.symmetric(
                  vertical: MediaQuery.of(context).size.height / 12.5,
                  horizontal: 2.0),
              child: Image.asset(
                'assets/SakecLogoFull.png',
                height: MediaQuery.of(context).size.height / 12, // Adjust size
                width: MediaQuery.of(context).size.width,
                fit: BoxFit.contain,
              ),
            ),
            // App Branding Section
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(20), // 15 circular border radius
                  child: Image.asset(
                    'assets/icon.png',
                    height:
                        MediaQuery.of(context).size.height / 6, // Adjust size
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height / 40),
                Text(
                  'Philo Physics',
                  style: GoogleFonts.merriweather(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height / 200),
                Text(
                  'Learn the smarter way',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),

            // Research Cell Section
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Column(
                children: [
                  Image.asset(
                    'assets/rc.png',
                    height: 70, // Adjust size
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 5),
                  Text.rich(
                    TextSpan(
                      text: 'This app was developed under the guidance of\n',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      children: [
                        TextSpan(
                          text: 'SAKEC Research Cell',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight:
                                FontWeight.bold, // Highlighted with bold
                            color: Colors.grey, // Consistent grey color
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
