import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppVersionText extends StatelessWidget {
  final TextStyle? style;
  final bool includePrefix;

  const AppVersionText({
    super.key,
    this.style,
    this.includePrefix = false,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final info = snapshot.data;
        final text = info == null
            ? 'Version'
            : '${includePrefix ? 'Version ' : 'v'}${info.version} (Build ${info.buildNumber})';

        return Text(
          text,
          style: style,
        );
      },
    );
  }
}
