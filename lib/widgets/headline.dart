import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Headline extends StatelessWidget {
  const Headline(
      {super.key,
      required this.name,
      required this.fontSize,
      required this.fontWeight});
  final String name;
  final double fontSize;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 13.0, top: 6),
        child: Text(
          name,
          style: GoogleFonts.poppins(
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: const Color(0xFF888888)),
        ),
      ),
    );
  }
}
