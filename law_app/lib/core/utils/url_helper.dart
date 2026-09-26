import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlHelper {
  static Future<void> openInAppUrl(BuildContext context, String? url) async {
    if (url == null || url.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No source URL available for this item.')),
      );
      return;
    }

    final trimmed = url.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid URL format.')),
      );
      return;
    }

    try {
      // First attempt: In-App Browser View (Chrome Custom Tab / Safari Controller)
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.inAppBrowserView,
      );

      if (!launched) {
        // Second attempt: In-App WebView
        final webViewLaunched = await launchUrl(
          uri,
          mode: LaunchMode.inAppWebView,
        );

        if (!webViewLaunched) {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        }
      }
    } catch (e) {
      try {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (err) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open page: ${err.toString()}')),
          );
        }
      }
    }
  }
}
