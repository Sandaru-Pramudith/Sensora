import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/main.dart';
import 'package:app/loading_page.dart';

void main() {
  testWidgets('Sensora app shows loading screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SensoraApp());
    await tester.pump();

    expect(find.byType(LoadingPage), findsOneWidget);
    expect(find.textContaining('Loading'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
