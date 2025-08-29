import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class FirebaseService {
  static FirebaseRemoteConfig? _remoteConfig;

  static Future<void> initialize() async {
    await Firebase.initializeApp();
    _remoteConfig = FirebaseRemoteConfig.instance;

    await _remoteConfig!.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 1),
    ));

    // Set default values (Android only)
    await _remoteConfig!.setDefaults({
      'force_update_version': '1.0.0',
      'update_url_android': '',
      'update_message': 'A new version is available. Please update.',
    });
  }

  static Future<bool> checkForUpdate() async {
    try {
      await _remoteConfig!.fetchAndActivate();

      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;
      String remoteVersion = _remoteConfig!.getString('force_update_version');

      return _isVersionGreater(remoteVersion, currentVersion);
    } catch (e) {
      debugPrint('Error checking for update: $e');
      return false;
    }
  }

  static bool _isVersionGreater(String newVersion, String currentVersion) {
    List<int> newV = newVersion.split('.').map(int.parse).toList();
    List<int> currentV = currentVersion.split('.').map(int.parse).toList();

    for (int i = 0; i < newV.length; i++) {
      if (i >= currentV.length) return true;
      if (newV[i] > currentV[i]) return true;
      if (newV[i] < currentV[i]) return false;
    }
    return false;
  }

  static String getUpdateMessage() {
    return _remoteConfig?.getString('update_message') ?? 'Please update the app.';
  }

  static String getUpdateUrl() {
    return _remoteConfig?.getString('update_url_android') ?? '';
  }
}