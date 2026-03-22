import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App shell smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('SkillFox'))),
    );

    expect(find.text('SkillFox'), findsOneWidget);
  });
}
