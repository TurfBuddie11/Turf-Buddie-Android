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

  bool isLoggedIn = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseService.initialize();

    final FlutterSecureStorage storage = const FlutterSecureStorage();
    await _requestPermissions();
    String? loggedIn = await storage.read(key: 'login');
    isLoggedIn = loggedIn == 'true';
  } catch (e) {
    debugPrint('Initialization error: $e');
  } finally {
    FlutterNativeSplash.remove();
    runApp(MyApp(isLoggedIn: isLoggedIn));
  }
}

Future<void> _requestPermissions() async {
  try {
    var status = await Permission.location.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      await Permission.location.request();
    }
  } catch (e) {
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

  Future<void> _checkForUpdates() async {
    await Future.delayed(const Duration(seconds: 2));

    try {
      bool updateAvailable = await FirebaseService.checkForUpdate();
      if (updateAvailable && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const UpdateDialog(),
        );
      }
    } catch (e) {
      debugPrint('Update check error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: Sizer(builder: (context, orientation, deviceType) {
        return MaterialApp(
          title: 'TurfBuddie',
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