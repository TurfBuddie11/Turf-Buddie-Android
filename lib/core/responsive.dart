import 'package:flutter/material.dart';

class Responsive {
  static double _baseWidth = 375.0; // Reference width (e.g., iPhone 8)

  static double scale(BuildContext context, double size) {
    final width = MediaQuery.of(context).size.width;
    return size * (width / _baseWidth);
  }

  static double fontScale(BuildContext context, double fontSize) {
    final width = MediaQuery.of(context).size.width;
    double scaleFactor = width / _baseWidth;
    if (width < 350) scaleFactor *= 0.9; // Slightly reduce for small screens
    if (width > 500) scaleFactor *= 1.1; // Slightly increase for large screens
    return fontSize * scaleFactor;
  }

  static double screenWidth(BuildContext context) => MediaQuery.of(context).size.width;
  static double screenHeight(BuildContext context) => MediaQuery.of(context).size.height;

  static bool isSmallScreen(BuildContext context) => screenWidth(context) < 350;
  static bool isMediumScreen(BuildContext context) => screenWidth(context) >= 350 && screenWidth(context) < 500;
  static bool isLargeScreen(BuildContext context) => screenWidth(context) >= 500;
}