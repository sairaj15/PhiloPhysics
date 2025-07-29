// import 'dart:ui';

// import 'package:ephysicsapp/globals/colors.dart';
// import 'package:ephysicsapp/screens/authentication/adminLogin.dart';
// import 'package:ephysicsapp/screens/users/v-labs/vlabs_screen.dart';
// import 'package:ephysicsapp/services/authentication.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';

// class VlabsHomeScreen extends StatefulWidget {
//   @override
//   State<VlabsHomeScreen> createState() => _VlabsHomeScreenState();
// }

// class _VlabsHomeScreenState extends State<VlabsHomeScreen> {
//   bool _isLoading = false;

//   void _navigateToVlabs(BuildContext context) async {
//     if (isLoggedIn() || isStudentLoggedIn()) {
//       setState(() => _isLoading = true);

//       await Future.delayed(Duration(seconds: 2));

//       if (!mounted) return;
//       Navigator.push(
//         context,
//         PageRouteBuilder(
//           pageBuilder: (context, animation, secondaryAnimation) =>
//               VlabsScreen(),
//           transitionsBuilder: (context, animation, secondaryAnimation, child) {
//             return FadeTransition(
//               opacity: animation,
//               child: child,
//             );
//           },
//           transitionDuration: Duration(milliseconds: 500),
//         ),
//       ).then((_) => setState(() => _isLoading = false));
//     } else {
//       showDialog(
//         context: context,
//         builder: (context) {
//           return Dialog(
//             insetPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(20),
//               side: BorderSide(color: color5, width: 2),
//             ),
//             backgroundColor: Colors.white,
//             child: Padding(
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Stack(
//                     children: [
//                       Center(
//                         child: Text(
//                           'Welcome!',
//                           style: GoogleFonts.poppins(
//                             fontSize: 20,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.black87,
//                           ),
//                         ),
//                       ),
//                       Positioned(
//                         right: 0,
//                         child: GestureDetector(
//                           onTap: () => Navigator.pop(context),
//                           child: Icon(Icons.close, color: Colors.black),
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 12),
//                   Text(
//                     'Login or create an account to access complete content',
//                     style: GoogleFonts.lato(
//                       fontSize: 15,
//                       fontWeight: FontWeight.w400,
//                       color: Colors.black,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                   SizedBox(height: 8),
//                   Text(
//                     'Click below to navigate to the login/register section',
//                     style: GoogleFonts.lato(
//                       fontSize: 15,
//                       fontWeight: FontWeight.w400,
//                       color: Colors.black,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                   SizedBox(height: 20),
//                   Center(
//                     child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         padding:
//                         EdgeInsets.symmetric(vertical: 12, horizontal: 32),
//                         backgroundColor: color5,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(30),
//                         ),
//                         elevation: 3,
//                       ),
//                       onPressed: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(builder: (context) => AdminLogin()),
//                         );
//                       },
//                       child: Text(
//                         'Login / Register',
//                         style: TextStyle(fontSize: 16, color: Colors.white),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;

//     return Stack(
//       children: [
//         SafeArea(
//           child: Scaffold(
//             backgroundColor: Colors.white,
//             body: Center(
//               child: Padding(
//                 padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
//                 child: IntrinsicHeight(
//                   child: Center(
//                     child: Container(
//                       padding: EdgeInsets.all(screenWidth * 0.04),
//                       decoration: BoxDecoration(
//                         color: Colors.grey.shade200,
//                         borderRadius: BorderRadius.circular(screenWidth * 0.04),
//                         border: Border.all(color: Colors.black, width: 1),
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Container(
//                             padding: EdgeInsets.all(screenWidth * 0.025),
//                             decoration: BoxDecoration(
//                               color: Colors.black,
//                               borderRadius:
//                               BorderRadius.circular(screenWidth * 0.045),
//                             ),
//                             child: ClipRRect(
//                               borderRadius:
//                               BorderRadius.circular(screenWidth * 0.037),
//                               child: Image.asset(
//                                 "assets/virtualLabs.gif",
//                                 height: screenHeight * 0.18,
//                                 width: double.infinity,
//                                 fit: BoxFit.fitWidth,
//                               ),
//                             ),
//                           ),
//                           SizedBox(height: screenHeight * 0.02),
//                           Text(
//                             "Applied Physics\nVirtual Laboratory",
//                             style: GoogleFonts.poppins(
//                               color: Colors.black,
//                               fontSize: screenWidth * 0.05,
//                               fontWeight: FontWeight.w700,
//                             ),
//                           ),
//                           SizedBox(height: screenHeight * 0.015),
//                           Text(
//                             "Experience physics experiments in an interactive virtual environment. Learn, explore, and discover the laws of physics from anywhere.",
//                             style: TextStyle(
//                               fontSize: screenWidth * 0.035,
//                               color: Colors.black.withOpacity(0.5),
//                               fontWeight: FontWeight.w400,
//                             ),
//                           ),
//                           SizedBox(height: screenHeight * 0.02),
//                           Row(
//                             children: [
//                               ElevatedButton.icon(
//                                 onPressed: () => _navigateToVlabs(context),
//                                 iconAlignment: IconAlignment.end,
//                                 icon: Icon(Icons.arrow_forward_rounded,
//                                     color: Colors.white),
//                                 label: Text("Explore Experiments  "),
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: Colors.blue,
//                                   foregroundColor: Colors.white,
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(
//                                         screenWidth * 0.037),
//                                   ),
//                                   padding: EdgeInsets.symmetric(
//                                     horizontal: screenWidth * 0.05,
//                                     vertical: screenHeight * 0.015,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//         if (_isLoading)
//           BackdropFilter(
//             filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
//             child: AnimatedOpacity(
//               opacity: _isLoading ? 1.0 : 0.0,
//               duration: Duration(milliseconds: 300),
//               child: Container(
//                 color: Colors.black.withOpacity(0.5),
//                 width: double.infinity,
//                 height: double.infinity,
//                 child: Center(
//                   child: Material(
//                     borderRadius: BorderRadius.circular(16),
//                     elevation: 4,
//                     child: Container(
//                       width: screenWidth * 0.7,
//                       padding: EdgeInsets.all(24),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(16),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black12,
//                             blurRadius: 10,
//                             spreadRadius: 2,
//                           ),
//                         ],
//                       ),
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           SpinKitFadingCircle(
//                             color: color5,
//                             size: 30.0,
//                           ),
//                           SizedBox(height: 12),
//                           Text(
//                             'Taking you to the world of virtual labs',
//                             textAlign: TextAlign.center,
//                             style: GoogleFonts.poppins(
//                               color: Colors.black,
//                               fontSize: 14,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//       ],
//     );
//   }
// }
