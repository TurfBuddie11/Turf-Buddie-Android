// lib/services/app_update_service.dart
import 'package:flutter/material.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._internal();
  factory AppUpdateService() => _instance;
  AppUpdateService._internal();

  static const String _latestVersionKey = 'latest_app_version';
  static const String _downloadUrlKey = 'app_download_url';
  static const String _forceUpdateKey = 'force_update_required';
  static const String _minVersionKey = 'minimum_supported_version';
  static const String _updateMessageKey = 'update_message';
  static const String _updateTitleKey = 'update_title';
  static const String _changelogKey = 'changelog';
  static const String _updatePriorityKey = 'update_priority';

  Future<void> checkForUpdates(BuildContext context, {bool showNoUpdateDialog = false}) async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(minutes: 5),
      ));

      await remoteConfig.fetchAndActivate();

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = 'v${packageInfo.version}';
      final latestVersion = remoteConfig.getString(_latestVersionKey);
      final forceUpdate = remoteConfig.getBool(_forceUpdateKey);
      final minVersion = remoteConfig.getString(_minVersionKey);

      print('Current version: $currentVersion');
      print('Latest version: $latestVersion');
      print('Force update: $forceUpdate');

      // Check if current version is below minimum supported
      if (_isVersionLower(currentVersion, minVersion)) {
        _showForceUpdateDialog(context, remoteConfig, isUnsupported: true);
        return;
      }

      // Check if update is available
      if (_isVersionLower(currentVersion, latestVersion)) {
        if (forceUpdate) {
          _showForceUpdateDialog(context, remoteConfig);
        } else {
          _showOptionalUpdateDialog(context, remoteConfig);
        }
      } else if (showNoUpdateDialog) {
        _showNoUpdateDialog(context);
      }
    } catch (e) {
      print('Error checking for updates: $e');
      if (showNoUpdateDialog) {
        _showErrorDialog(context, 'Failed to check for updates: ${e.toString()}');
      }
    }
  }

  bool _isVersionLower(String current, String latest) {
    if (current.isEmpty || latest.isEmpty) return false;

    // Remove 'v' prefix if present
    current = current.replaceFirst('v', '');
    latest = latest.replaceFirst('v', '');

    final currentParts = current.split('.').map(int.parse).toList();
    final latestParts = latest.split('.').map(int.parse).toList();

    // Ensure both lists have the same length
    while (currentParts.length < latestParts.length) {
      currentParts.add(0);
    }
    while (latestParts.length < currentParts.length) {
      latestParts.add(0);
    }

    for (int i = 0; i < currentParts.length; i++) {
      if (currentParts[i] < latestParts[i]) return true;
      if (currentParts[i] > latestParts[i]) return false;
    }

    return false;
  }

  void _showForceUpdateDialog(BuildContext context, FirebaseRemoteConfig config, {bool isUnsupported = false}) {
    final title = isUnsupported ? 'Update Required' : config.getString(_updateTitleKey);
    final message = isUnsupported
        ? 'Your app version is no longer supported. Please update to continue using the app.'
        : config.getString(_updateMessageKey);
    final changelog = config.getString(_changelogKey);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.system_update, color: Colors.red),
                const SizedBox(width: 8),
                Text(title),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message),
                  const SizedBox(height: 16),
                  if (changelog.isNotEmpty) ...[
                    const Text(
                      'What\'s New:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      changelog.replaceAll('\\n', '\n'),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              ElevatedButton.icon(
                onPressed: () => _downloadAndInstallUpdate(context, config),
                icon: const Icon(Icons.download),
                label: const Text('Update Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showOptionalUpdateDialog(BuildContext context, FirebaseRemoteConfig config) {
    final title = config.getString(_updateTitleKey);
    final message = config.getString(_updateMessageKey);
    final changelog = config.getString(_changelogKey);
    final priority = config.getString(_updatePriorityKey);

    Color priorityColor = Colors.blue;
    IconData priorityIcon = Icons.info;

    switch (priority.toLowerCase()) {
      case 'high':
      case 'critical':
        priorityColor = Colors.red;
        priorityIcon = Icons.priority_high;
        break;
      case 'medium':
        priorityColor = Colors.orange;
        priorityIcon = Icons.update;
        break;
      case 'low':
        priorityColor = Colors.blue;
        priorityIcon = Icons.info;
        break;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(priorityIcon, color: priorityColor),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message),
                const SizedBox(height: 16),
                if (changelog.isNotEmpty) ...[
                  const Text(
                    'What\'s New:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    changelog.replaceAll('\\n', '\n'),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _downloadAndInstallUpdate(context, config);
              },
              icon: const Icon(Icons.download),
              label: const Text('Update'),
              style: ElevatedButton.styleFrom(
                backgroundColor: priorityColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showNoUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Up to Date'),
            ],
          ),
          content: const Text('You are using the latest version of Turf Buddie!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('Error'),
            ],
          ),
          content: Text(error),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _downloadAndInstallUpdate(BuildContext context, FirebaseRemoteConfig config) async {
    final downloadUrl = config.getString(_downloadUrlKey);

    if (downloadUrl.isEmpty) {
      _showErrorDialog(context, 'Download URL not found');
      return;
    }

    // Check if we should use direct download or browser
    if (Platform.isAndroid && await _hasStoragePermission()) {
      _showDownloadDialog(context, downloadUrl);
    } else {
      // Fallback to browser
      _launchUrl(downloadUrl);
    }
  }

  Future<bool> _hasStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      if (status != PermissionStatus.granted) {
        final result = await Permission.storage.request();
        return result == PermissionStatus.granted;
      }
      return true;
    }
    return false;
  }

  void _showDownloadDialog(BuildContext context, String downloadUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _DownloadDialog(downloadUrl: downloadUrl);
      },
    );
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _DownloadDialog extends StatefulWidget {
  final String downloadUrl;

  const _DownloadDialog({required this.downloadUrl});

  @override
  State<_DownloadDialog> createState() => _DownloadDialogState();
}

class _DownloadDialogState extends State<_DownloadDialog> {
  double _progress = 0.0;
  bool _isDownloading = true;
  String _status = 'Preparing download...';
  String? _filePath;

  @override
  void initState() {
    super.initState();
    _downloadFile();
  }

  Future<void> _downloadFile() async {
    try {
      final dio = Dio();
      final dir = await getExternalStorageDirectory();
      final fileName = 'turf_buddie_update.apk';
      final filePath = '${dir?.path}/$fileName';

      setState(() {
        _status = 'Downloading update...';
      });

      await dio.download(
        widget.downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _progress = received / total;
              _status = 'Downloaded ${(received / 1024 / 1024).toStringAsFixed(1)} MB of ${(total / 1024 / 1024).toStringAsFixed(1)} MB';
            });
          }
        },
      );

      setState(() {
        _isDownloading = false;
        _status = 'Download completed! Tap to install.';
        _filePath = filePath;
      });
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _status = 'Download failed: ${e.toString()}';
      });
    }
  }

  Future<void> _installApk() async {
    if (_filePath != null) {
      final result = await OpenFilex.open(_filePath!);
      print('Install result: ${result.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDownloading,
      child: AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.download),
            SizedBox(width: 8),
            Text('Downloading Update'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isDownloading) ...[
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 16),
            ],
            Text(_status),
            const SizedBox(height: 16),
            if (!_isDownloading && _filePath != null)
              ElevatedButton.icon(
                onPressed: _installApk,
                icon: const Icon(Icons.install_mobile),
                label: const Text('Install Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
        actions: [
          if (!_isDownloading)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
        ],
      ),
    );
  }
}

// Extension to easily access the update service
extension AppUpdateExtension on BuildContext {
  Future<void> checkForUpdates({bool showNoUpdateDialog = false}) {
    return AppUpdateService().checkForUpdates(this, showNoUpdateDialog: showNoUpdateDialog);
  }
}