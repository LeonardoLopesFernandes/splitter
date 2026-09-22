import 'package:flutter_test/flutter_test.dart';

import 'package:filesplitter_flutter/main.dart';

void main() {
  testWidgets('App inicia com as 4 abas', (WidgetTester tester) async {
    await tester.pumpWidget(const DivisorDeArquivosApp());

    expect(find.text('Dividir'), findsWidgets);
    expect(find.text('Unir'), findsOneWidget);
    expect(find.text('Visualizar'), findsOneWidget);
    expect(find.text('Premium'), findsOneWidget);
  });
}