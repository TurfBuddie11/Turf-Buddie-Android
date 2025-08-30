import 'package:flutter/material.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';

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
        minimumFetchInterval: const Duration(seconds: 0), // Set to 0 for testing
      ));

      debugPrint('🔍 Fetching Remote Config...');
      bool activated = await remoteConfig.fetchAndActivate();
      debugPrint('Remote Config fetchAndActivate: ${activated ? "Success" : "Failed or used cached values"}');

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = 'v${packageInfo.version}';
      final latestVersion = remoteConfig.getString(_latestVersionKey);
      final forceUpdate = remoteConfig.getBool(_forceUpdateKey);
      final minVersion = remoteConfig.getString(_minVersionKey);

      debugPrint('Current version: $currentVersion');
      debugPrint('Latest version: $latestVersion');
      debugPrint('Minimum supported version: $minVersion');
      debugPrint('Force update: $forceUpdate');
      debugPrint('All Remote Config values: ${remoteConfig.getAll().map((key, value) => MapEntry(key, value.asString()))}');

      // Check if current version is below minimum supported
      if (_isVersionLower(currentVersion, minVersion)) {
        debugPrint('Triggering force update dialog (below minimum supported version)');
        if (!context.mounted) return;
        _showForceUpdateDialog(context, remoteConfig, isUnsupported: true);
        return;
      }

      if (_isVersionLower(currentVersion, latestVersion)) {
        debugPrint('Update available');
        if (forceUpdate) {
          debugPrint('Triggering force update dialog');
          if (!context.mounted) return;
          _showForceUpdateDialog(context, remoteConfig);
        } else {
          debugPrint('Triggering optional update dialog');
          if (!context.mounted) return;
          _showOptionalUpdateDialog(context, remoteConfig);
        }
      } else if (showNoUpdateDialog) {
        debugPrint('No update needed, showing no-update dialog');
        if (!context.mounted) return;
        _showNoUpdateDialog(context);
      } else {
        debugPrint('No update needed, no dialog shown');
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      if (showNoUpdateDialog) {
        if (!context.mounted) return;
        _showErrorDialog(context, 'Failed to check for updates: ${e.toString()}');
      }
    }
  }

  bool _isVersionLower(String current, String latest) {
    if (current.isEmpty || latest.isEmpty) return false;

    current = current.replaceFirst(RegExp(r'^v'), '');
    latest = latest.replaceFirst(RegExp(r'^v'), '');

    final currentParts = current.split('.').map((part) => int.tryParse(part) ?? 0).toList();
    final latestParts = latest.split('.').map((part) => int.tryParse(part) ?? 0).toList();

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
        ? 'Your app version is no longer supported. Please update to continue using Turf Buddie.'
        : config.getString(_updateMessageKey);
    final changelog = config.getString(_changelogKey);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.transparent,
            content: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF2ECC71), const Color(0xFF27AE60)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sports_soccer, color: Colors.white, size: 30),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  if (changelog.isNotEmpty) ...[
                    Text(
                      'What\'s New:',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      changelog.replaceAll('\\n', '\n'),
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              ElevatedButton.icon(
                onPressed: () => _downloadAndInstallUpdate(context, config),
                icon: const Icon(Icons.download, color: Colors.white),
                label: Text(
                  'Update Now',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  elevation: 5,
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

    Color priorityColor;
    IconData priorityIcon;

    switch (priority.toLowerCase()) {
      case 'high':
      case 'critical':
        priorityColor = Colors.red;
        priorityIcon = Icons.priority_high;
        break;
      case 'medium':
        priorityColor = const Color(0xFFFFA726);
        priorityIcon = Icons.update;
        break;
      case 'low':
      default:
        priorityColor = const Color(0xFF2ECC71);
        priorityIcon = Icons.info;
        break;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.transparent,
          content: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF2ECC71), const Color(0xFF27AE60)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(priorityIcon, color: Colors.white, size: 30),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 16),
                if (changelog.isNotEmpty) ...[
                  Text(
                    'What\'s New:',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    changelog.replaceAll('\\n', '\n'),
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Later',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _downloadAndInstallUpdate(context, config);
              },
              icon: const Icon(Icons.download, color: Colors.white),
              label: Text(
                'Update',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                elevation: 5,
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.transparent,
          content: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF2ECC71), const Color(0xFF27AE60)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white, size: 30),
                    const SizedBox(width: 8),
                    Text(
                      'Up to Date',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'You are using the latest version of Turf Buddie!',
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.transparent,
          content: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF2ECC71), const Color(0xFF27AE60)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.error, color: Colors.white, size: 30),
                    const SizedBox(width: 8),
                    Text(
                      'Error',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  error,
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                checkForUpdates(context, showNoUpdateDialog: true);
              },
              child: Text(
                'Retry',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
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

    if (Platform.isAndroid && await _hasStoragePermission()) {
      if (!context.mounted) return;
      _showDownloadDialog(context, downloadUrl);
    } else {
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
    } else {
      debugPrint('Could not launch $url');
    }
  }
}

class _DownloadDialog extends StatefulWidget {
  final String downloadUrl;

  const _DownloadDialog({required this.downloadUrl});

  @override
  State<_DownloadDialog> createState() => _DownloadDialogState();
}

class _DownloadDialogState extends State<_DownloadDialog> with SingleTickerProviderStateMixin {
  double _progress = 0.0;
  bool _isDownloading = true;
  String _status = 'Preparing download...';
  String? _filePath;
  late AnimationController _animationController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _bounceAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _downloadFile();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
      debugPrint('Install result: ${result.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDownloading,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.transparent,
        content: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF2ECC71), const Color(0xFF27AE60)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _bounceAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _bounceAnimation.value),
                        child: const Icon(Icons.download, color: Colors.white, size: 30),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Downloading Update',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isDownloading) ...[
                LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
              ],
              Text(
                _status,
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
              ),
              const SizedBox(height: 16),
              if (!_isDownloading && _filePath != null)
                ElevatedButton.icon(
                  onPressed: _installApk,
                  icon: const Icon(Icons.install_mobile, color: Colors.white),
                  label: Text(
                    'Install Now',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    elevation: 5,
                  ),
                ),
            ],
          ),
        ),
        actions: [
          if (!_isDownloading)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
            ),
        ],
      ),
    );
  }
}

extension AppUpdateExtension on BuildContext {
  Future<void> checkForUpdates({bool showNoUpdateDialog = false}) {
    return AppUpdateService().checkForUpdates(this, showNoUpdateDialog: showNoUpdateDialog);
  }
}