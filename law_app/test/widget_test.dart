import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Rishikesh Law Hub smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('Rishikesh Law Hub'),
        ),
      ),
    );

    expect(find.text('Rishikesh Law Hub'), findsOneWidget);
  });
}
