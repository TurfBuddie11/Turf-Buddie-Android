import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tb_web/screens/authentication_screens/signup_details_screens/edit_profile_screen.dart';
import 'package:tb_web/screens/authentication_screens/signup_details_screens/email_password_screen.dart';
import 'package:tb_web/screens/authentication_screens/signup_details_screens/email_verification_checker_screen.dart';
import 'package:tb_web/screens/authentication_screens/signup_details_screens/user_detail_screen.dart';
import 'package:tb_web/widgets/custom_circular_progress.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  String? name;
  String? gender;
  String? dob;
  String? mobile;
  String? state;
  String? city;
  String? pincode;
  String? email;
  String? password;
  int index = 0;
  void onContinue1(Map<String, String> data) {
    setState(() {
      name = data['name'];
      gender = data['gender'];
      dob = data['dob'];
      mobile = data['mobile'];
      index++;
    });
  }

  void onContinue2(Map<String, String> data) {
    setState(() {
      state = data['state'];
      city = data['city'];
      pincode = data['pinCode'];
      index++;
    });
  }

  void onContinue3(Map<String, String> data) async {
    setState(() {
      email = data['email'];
      password = data['password'];
    });

    try {
      final auth = FirebaseAuth.instance;
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: email!,
        password: data['password']!,
      );

      await userCredential.user!.sendEmailVerification();

      String uid = userCredential.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': name,
        'gender': gender,
        'dob': dob,
        'mobile': mobile,
        'state': state,
        'city': city,
        'pincode': pincode,
        'email': email,
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => EmailVerificationCheckerScreen(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error: ${e.toString()}"),
        backgroundColor: Colors.red,
      ));
      print("Error during signup: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Signup'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: size.height * 0.04,
            ),
            SizedBox(
                height: size.height * 0.18,
                child: CustomCircularProgress(
                    progress: index == 0 ? 0 : (index == 1 ? 50 : 75))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: SizedBox(
                child: Divider(
                  color: Colors.black,
                  thickness: 1,
                ),
              ),
            ),
            SizedBox(height: size.height * 0.02),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: index == 0
                  ? SizedBox(
                      child: UserDetailScreen(
                        onContinue: onContinue1,
                      ),
                    )
                  : (index == 1
                      ? SizedBox(
                          child: EditProfileScreen(
                            profileDetails: onContinue2,
                          ),
                        )
                      : SizedBox(
                          child: EmailPasswordScreen(
                            emailPassword: onContinue3,
                          ),
                        )),
            ),
          ],
        ),
      ),
    );
  }
}
