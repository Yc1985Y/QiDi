import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders Chinese app title smoke test', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Text('织时')));
    expect(find.text('织时'), findsOneWidget);
  });
}
