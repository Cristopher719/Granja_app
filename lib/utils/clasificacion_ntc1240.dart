class RangoNtc1240 {
  final String categoria;
  final double minimo;
  final double? maximo;

  const RangoNtc1240(this.categoria, this.minimo, this.maximo);

  String get descripcion {
    if (maximo == null) return 'más de ${_g(minimo)}';
    if (minimo == 0) return 'menos de ${_g(maximo! + 0.1)}';
    return '${_g(minimo)} a ${_g(maximo!)}';
  }

  static String _g(double v) =>
      '${v.toStringAsFixed(1).replaceAll('.', ',')} g';
}

const List<RangoNtc1240> rangosNtc1240 = [
  RangoNtc1240('Jumbo', 78.0, null),
  RangoNtc1240('AAA', 67.0, 77.9),
  RangoNtc1240('AA', 60.0, 66.9),
  RangoNtc1240('A', 53.0, 59.9),
  RangoNtc1240('B', 46.0, 52.9),
  RangoNtc1240('C', 0, 45.9),
];

const List<String> categoriasDelSistema = ['B', 'A', 'AA', 'AAA'];

const double pesoMinimoValido = 20.0;
const double pesoMaximoValido = 120.0;

String? categoriaPorPeso(double pesoGramos) {
  if (pesoGramos.isNaN ||
      pesoGramos < pesoMinimoValido ||
      pesoGramos > pesoMaximoValido) {
    return null;
  }
  final peso = (pesoGramos * 10).round() / 10;
  if (peso >= 78.0) return 'Jumbo';
  if (peso >= 67.0) return 'AAA';
  if (peso >= 60.0) return 'AA';
  if (peso >= 53.0) return 'A';
  if (peso >= 46.0) return 'B';
  return 'C';
}

bool categoriaEnAlcance(String categoria) =>
    categoriasDelSistema.contains(categoria);
