import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sizer/sizer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tb_web/core/services/app_update_service.dart';
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

    // Initialize Remote Config with defaults
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(minutes: 5),
    ));

    await remoteConfig.setDefaults({
      'latest_app_version': 'v1.0.0',
      'app_download_url': '',
      'force_update_required': false,
      'minimum_supported_version': 'v1.0.0',
      'update_message': 'A new version is available!',
      'update_title': 'Update Available',
      'changelog': 'Bug fixes and improvements',
      'update_priority': 'medium',
    });

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
    // Request location permission
    var locationStatus = await Permission.location.status;
    if (locationStatus.isDenied || locationStatus.isPermanentlyDenied) {
      await Permission.location.request();
    }

    // Request storage permission for APK downloads (Android)
    var storageStatus = await Permission.storage.status;
    if (storageStatus.isDenied) {
      await Permission.storage.request();
    }

    // For Android 11+ (API 30+), request manage external storage if needed
    if (await Permission.manageExternalStorage.isDenied) {
      await Permission.manageExternalStorage.request();
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

    // Check for updates after app initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          debugPrint('🔍 Checking for app updates...');
          context.checkForUpdates();
        }
      });
    });
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