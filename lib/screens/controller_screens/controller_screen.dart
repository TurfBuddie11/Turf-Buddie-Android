import 'package:flutter/material.dart';
import 'package:tb_web/screens/home_screens/booking_screen.dart' as bk;
import 'package:tb_web/screens/home_screens/home_screen.dart';
import 'package:tb_web/screens/home_screens/profile_screen.dart';
import 'package:tb_web/screens/home_screens/turf_pooling_screen.dart';
import 'package:tb_web/screens/home_screens/turfs_list_screen.dart';
import 'package:tb_web/widgets/bottom_nav_item.dart';

class ControllerScreen extends StatefulWidget {
  const ControllerScreen({super.key});

  @override
  State<ControllerScreen> createState() => _ControllerScreenState();
}

class _ControllerScreenState extends State<ControllerScreen> {
  int selectedIndex = 2;

  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  final List<Widget> screens = [
    const TurfsListScreen(),
    const bk.BookingScreen(),
    const HomeScreen(),
    const TurfPoolingScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: screens[selectedIndex],
      bottomNavigationBar: SafeArea(
        child: Container(
          height: size.height * 0.07,
          color: Colors.grey[100],
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: BottomNavItem(
                    onTap: () => onItemTapped(0),
                    title: 'Turfs',
                    image: 'assets/images/turf_logo.png',
                    isSelected: selectedIndex == 0,
                  ),
                ),
                Expanded(
                  child: BottomNavItem(
                    onTap: () => onItemTapped(1),
                    title: 'Booking',
                    image: 'assets/images/booking_logo.png',
                    isSelected: selectedIndex == 1,
                  ),
                ),
                Expanded(
                  child: BottomNavItem(
                    onTap: () => onItemTapped(2),
                    title: 'Home',
                    image: 'assets/images/home_logo.png',
                    isSelected: selectedIndex == 2,
                  ),
                ),
                Expanded(
                  child: BottomNavItem(
                    onTap: () => onItemTapped(3),
                    title: 'Tournament',
                    image: 'assets/images/tournament.png',
                    isSelected: selectedIndex == 3,
                  ),
                ),
                Expanded(
                  child: BottomNavItem(
                    onTap: () => onItemTapped(4),
                    title: 'Profile',
                    image: 'assets/images/profile_logo.png',
                    isSelected: selectedIndex == 4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}