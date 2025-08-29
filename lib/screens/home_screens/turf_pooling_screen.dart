import 'package:flutter/material.dart';

class Tournament {
  final String name;
  final String date;
  final String location;

  Tournament({required this.name, required this.date, required this.location});
}

class TurfPoolingScreen extends StatefulWidget {
  const TurfPoolingScreen({super.key});

  @override
  State<TurfPoolingScreen> createState() => _TurfPoolingScreenState();
}

class _TurfPoolingScreenState extends State<TurfPoolingScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournaments'),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: Image.asset('assets/images/tournament.jpg', fit: BoxFit.cover),
      ),
    );
  }
}