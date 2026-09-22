import 'package:flutter_test/flutter_test.dart';

import 'package:filesplitter_flutter/main.dart';

void main() {
  testWidgets('App inicia e mostra o título', (WidgetTester tester) async {
    await tester.pumpWidget(const DivisorDeArquivosApp());

    expect(find.text('Divisor de Arquivos'), findsOneWidget);
    expect(find.text('Dividir arquivos grandes'), findsOneWidget);
    expect(find.text('Juntar múltiplos arquivos'), findsOneWidget);
    expect(find.text('Visualizar conteúdo'), findsOneWidget);
  });
}