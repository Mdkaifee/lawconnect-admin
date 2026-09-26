import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlHelper {
  static Future<void> openInAppUrl(BuildContext context, String? value) async {
    if (value == null || value.trim().isEmpty) return;
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasScheme) return;

    var opened = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    if (!opened) opened = await launchUrl(uri, mode: LaunchMode.inAppWebView);
    if (!opened) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open the official source')),
        );
      }
    }
  }
}
