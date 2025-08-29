import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sizer/sizer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tb_web/screens/authentication_screens/set_started_screen.dart';
import 'package:tb_web/screens/controller_screens/controller_screen.dart';
import 'package:tb_web/widgets/update_dialog.dart';
import 'core/services/firebase_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsBinding widgetsFlutterBinding =
      WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsFlutterBinding);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final FlutterSecureStorage storage = const FlutterSecureStorage();
    await _requestPermissions(); // Request permissions before checking login status
    String? loggedIn = await storage.read(key: 'login');

    FlutterNativeSplash.remove();

    runApp(
      MyApp(isLoggedIn: loggedIn == 'true'),
    );
  } catch (e) {
    // Handle initialization errors
    FlutterNativeSplash.remove();
    runApp(
      MyApp(isLoggedIn: false), // Default to not logged in on error
    );
  }
}

Future<void> _requestPermissions() async {
  try {
    // Request location permission
    var status = await Permission.location.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      // If permission is denied or permanently denied, request it
      await Permission.location.request();
    }
    // You can add more permission requests here if needed
    // For example, to request camera permission:
    // await Permission.camera.request();
  } catch (e) {
    // Handle permission request errors silently
    debugPrint('Permission request error: $e');
  }
}

class MyApp extends StatefulWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }

  _checkForUpdates() async {
    await Future.delayed(Duration(seconds: 2));

    bool updateAvailable = await FirebaseService.checkForUpdate();
    if (updateAvailable && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => UpdateDialog(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: Sizer(builder: (context, orientation, deviceType) {
        return MaterialApp(
          title: 'My App',
          theme: ThemeData(
            scaffoldBackgroundColor: const Color(0xFFF5F5F5),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFF5F5F5),
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.black),
            ),
          ),
          debugShowCheckedModeBanner: false,
          home: widget.isLoggedIn
              ? const ControllerScreen()
              : const SetStartedScreen(),
        );
      }),
    );
  }
}
