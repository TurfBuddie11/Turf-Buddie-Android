import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/services/firebase_service.dart';

class UpdateDialog extends StatelessWidget {
  const UpdateDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Available'),
      content: Text(FirebaseService.getUpdateMessage()),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Later'),
        ),
        ElevatedButton(
          onPressed: () async {
            String updateUrl = FirebaseService.getUpdateUrl();
            if (updateUrl.isNotEmpty) {
              if (await canLaunchUrl(Uri.parse(updateUrl))) {
                await launchUrl(Uri.parse(updateUrl));
              }
            }
            if (!context.mounted) return;
            Navigator.of(context).pop();
          },
          child: const Text('Update'),
        ),
      ],
    );
  }
}