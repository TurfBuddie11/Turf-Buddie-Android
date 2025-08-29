import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controller_screens/controller_screen.dart';

class EmailVerificationCheckerScreen extends StatefulWidget {
  const EmailVerificationCheckerScreen({super.key});

  @override
  State<EmailVerificationCheckerScreen> createState() =>
      _EmailVerificationCheckerScreenState();
}

class _EmailVerificationCheckerScreenState
    extends State<EmailVerificationCheckerScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  bool _isEmailVerified = false;
  bool _isChecking = true;
  Timer? _verificationCheckTimer;
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _checkEmailVerified();
    _startVerificationCheckTimer();
  }

  @override
  void dispose() {
    _verificationCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkEmailVerified() async {
    await _user?.reload();
    _user = _auth.currentUser;
    setState(() {
      _isEmailVerified = _user?.emailVerified ?? false;
      _isChecking = false;
    });

    if (_isEmailVerified) {
      _verificationCheckTimer?.cancel();
      try {
        setState(() {
          if (_isEmailVerified) {
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser != null) {
              _storage.write(key: 'login', value: 'true');
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ControllerScreen(),
                ),
              );
            }
          }
        });
      } catch (e) {
        print(e);
      }
    }
  }

  void _startVerificationCheckTimer() {
    _verificationCheckTimer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) => _checkEmailVerified(),
    );
  }

  Future<void> _sendVerificationEmail() async {
    await _user?.sendEmailVerification();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Verification email sent.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Center(
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          children: [
            _isChecking
                ? Center(
                    child: Image.asset(
                      'assets/images/verification_in_progress.png',
                      height: size.height * 0.3,
                    ),
                  )
                : _isEmailVerified
                    ? const Center(child: Text('Your email is verified.'))
                    : Center(
                        child: Column(
                          spacing: 16,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'We have sent\nyou a link in your email.',
                              style: GoogleFonts.poppins(
                                fontSize: 40,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Container(
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Image.asset(
                                    'assets/images/verify_email.png',
                                    width: size.width * 0.8)),
                            Text(
                              'Please verify your email address.',
                              style: GoogleFonts.poppins(fontSize: 20),
                            ),
                            const SizedBox(height: 5),
                            ElevatedButton(
                              onPressed: _sendVerificationEmail,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                'Resend Verification Email',
                                style: GoogleFonts.poppins(
                                    fontSize: 17, color: Colors.white),
                              ),
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
