import 'package:flutter_test/flutter_test.dart';

import 'package:flutter/material.dart';

import 'package:elearn_app/screens/login_page.dart';

void main() {
  testWidgets('App starts and shows login screen', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.pumpAndSettle();

    expect(find.text('Your gateway to infinite stories'), findsOneWidget);
  });
}
