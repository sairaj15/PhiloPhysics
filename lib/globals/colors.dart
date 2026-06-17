import 'package:flutter/material.dart';

Color color1 = Color(0xffffffff);
Color color2 = Color(0xffe1e5f2);
Color color3 = Color(0xffbfdbf7);
Color color4 = Color(0xff1f7a8c);
Color color5 = Color(0xff022b3a);

// Function to create a material color swatch from a given color
MaterialColor createMaterialColor(Color color) {
  // Initial strengths and swatch
  List<double> strengths = [0.05];
  Map<int, Color> swatch = {};

  final int r = color.red, g = color.green, b = color.blue;

  // Generate color swatch based on strengths
  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }

  strengths.forEach((strength) {
    final double ds = 0.5 - strength;
    final int index = (strength * 1000).round();
    swatch[index] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  });

  return MaterialColor(color.toARGB32(), swatch);
}
