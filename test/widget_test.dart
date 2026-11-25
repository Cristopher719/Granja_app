import 'package:flutter_test/flutter_test.dart';
import 'package:app_granja/main.dart';

void main() {
  testWidgets('Prueba básica de carga de la granja', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(MyApp), findsOneWidget);
  });
}
