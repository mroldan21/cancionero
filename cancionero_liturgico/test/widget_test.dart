// test/widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cancionero_liturgico/app.dart'; // ← Importa desde app.dart

void main() {
  testWidgets('App loads without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp()); // ← No MyApp, sino CancioneroApp
    expect(find.text('Categorías'), findsOneWidget);
  });
}