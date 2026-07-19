import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dawakti/app.dart';

void main() {
  testWidgets('App boots and shows the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: DawaktiApp()));

    // The splash screen renders immediately; give the first frame a chance
    // to settle without waiting for async routing (which needs a real
    // sqflite database and isn't available under the widget-test harness).
    await tester.pump();

    expect(find.text('دعواتي'), findsWidgets);
  });
}
