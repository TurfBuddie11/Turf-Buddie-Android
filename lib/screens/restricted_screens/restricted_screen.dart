import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RestrictedScreen extends StatelessWidget {
  const RestrictedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Restricted Screen', style: GoogleFonts.poppins(fontSize: 41, fontWeight: FontWeight.bold),),
            Text('You are not authorized to view this screen\nPlease open it on your mobile phone', style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.bold),textAlign: TextAlign.center,),
          ],
        ),
      ),
    );
  }
}
