// BottomNavItem.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BottomNavItem extends StatefulWidget {
  final GestureTapCallback onTap;
  final String title;
  final String image;
  final bool isSelected;
  const BottomNavItem(
      {super.key,
      required this.onTap,
      required this.title,
      required this.image,
      required this.isSelected});

  @override
  State<BottomNavItem> createState() => _BottomNavItemState();
}

class _BottomNavItemState extends State<BottomNavItem> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            widget.image,
            color: widget.isSelected ? Colors.green : Colors.black,
            height: 24,
          ),
          Text(
            widget.title,
            style: GoogleFonts.poppins(
                color: widget.isSelected ? Colors.green : Colors.black,
                fontSize: size.width > 400 ? 8.6 : 12),
          ),
        ],
      ),
    );
  }
}
