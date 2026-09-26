import 'package:flutter_test/flutter_test.dart';
import 'package:law_app/core/theme/app_theme.dart';

void main() {
  test('Theme smoke test', () {
    expect(AppTheme.navyBlue, isNotNull);
    expect(AppTheme.goldAccent, isNotNull);
    expect(AppColors.primaryNavy, isNotNull);
  });
}
