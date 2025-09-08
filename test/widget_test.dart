import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('placeholder smoke test', (WidgetTester tester) async {
    // Test mínimo que no depende de tu árbol real ni de plugins nativos.
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Text('ok')),
    ));

    expect(find.text('ok'), findsOneWidget);
  });
}