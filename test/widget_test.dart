// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:desk_display/main.dart';
import 'package:desk_display/widgets/robot_eyes.dart';

void main() {
  testWidgets('desk display shows the clock and v2 placeholder page', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(PageView), findsOneWidget);
    expect(find.textContaining('DESK '), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(RobotEyes), findsOneWidget);
  });
}
