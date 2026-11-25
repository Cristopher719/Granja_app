import 'package:flutter_test/flutter_test.dart';
import 'package:app_granja/utils/clasificacion_ntc1240.dart';

void main() {
  group('Categoría por peso', () {
    test('valores centrales de cada categoría', () {
      expect(categoriaPorPeso(80.0), 'Jumbo');
      expect(categoriaPorPeso(70.0), 'AAA');
      expect(categoriaPorPeso(63.0), 'AA');
      expect(categoriaPorPeso(56.0), 'A');
      expect(categoriaPorPeso(49.0), 'B');
      expect(categoriaPorPeso(40.0), 'C');
    });

    test('límites exactos de la norma', () {
      expect(categoriaPorPeso(78.0), 'Jumbo');
      expect(categoriaPorPeso(77.9), 'AAA');
      expect(categoriaPorPeso(67.0), 'AAA');
      expect(categoriaPorPeso(66.9), 'AA');
      expect(categoriaPorPeso(60.0), 'AA');
      expect(categoriaPorPeso(59.9), 'A');
      expect(categoriaPorPeso(53.0), 'A');
      expect(categoriaPorPeso(52.9), 'B');
      expect(categoriaPorPeso(46.0), 'B');
      expect(categoriaPorPeso(45.9), 'C');
    });

    test('redondea a una cifra decimal', () {
      expect(categoriaPorPeso(66.96), 'AAA');
      expect(categoriaPorPeso(66.94), 'AA');
    });

    test('rechaza pesos fuera del rango válido', () {
      expect(categoriaPorPeso(10.0), isNull);
      expect(categoriaPorPeso(150.0), isNull);
    });

    test('alcance del sistema: B, A, AA y AAA', () {
      expect(categoriaEnAlcance('AAA'), isTrue);
      expect(categoriaEnAlcance('B'), isTrue);
      expect(categoriaEnAlcance('Jumbo'), isFalse);
      expect(categoriaEnAlcance('C'), isFalse);
    });
  });
}
