import 'package:flutter/material.dart';
import '../../utils/clasificacion_ntc1240.dart';
import '../../widgets/form_helpers.dart';

class ClasificadorPorPeso extends StatefulWidget {
  final ValueChanged<String> onSumar;

  const ClasificadorPorPeso({super.key, required this.onSumar});

  @override
  State<ClasificadorPorPeso> createState() => _ClasificadorPorPesoState();
}

class _ClasificadorPorPesoState extends State<ClasificadorPorPeso> {
  final _pesoController = TextEditingController();
  final _focus = FocusNode();
  String? _categoria;
  String? _error;
  bool _verTabla = false;

  static const _colores = {
    'Jumbo': Colors.grey,
    'AAA': colorPrimario,
    'AA': Colors.amber,
    'A': Colors.orange,
    'B': Colors.brown,
    'C': Colors.grey,
  };

  void _calcular(String texto) {
    final t = texto.trim().replaceAll(',', '.');
    if (t.isEmpty) {
      setState(() {
        _categoria = null;
        _error = null;
      });
      return;
    }
    final peso = double.tryParse(t);
    final cat = peso == null ? null : categoriaPorPeso(peso);
    setState(() {
      _categoria = cat;
      _error = cat == null
          ? 'Ingresa un peso válido entre ${pesoMinimoValido.toInt()} y ${pesoMaximoValido.toInt()} g'
          : null;
    });
  }

  void _sumar() {
    final cat = _categoria;
    if (cat == null || !categoriaEnAlcance(cat)) return;
    widget.onSumar(cat);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('+1 huevo tipo $cat'),
        duration: const Duration(milliseconds: 900),
      ),
    );
    _pesoController.clear();
    setState(() => _categoria = null);
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final cat = _categoria;
    final enAlcance = cat != null && categoriaEnAlcance(cat);
    final color = cat != null
        ? (_colores[cat] ?? colorPrimario)
        : colorPrimario;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Digita el peso de un huevo y la app sugiere su categoría según la NTC 1240. '
            'Con "Sumar" se agrega al conteo de abajo.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _pesoController,
                  focusNode: _focus,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: decoracionCampo(
                    'Peso (g)',
                    Icons.scale_outlined,
                  ).copyWith(errorText: _error, errorMaxLines: 2),
                  onChanged: _calcular,
                  onSubmitted: (_) => _sumar(),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 92,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cat == null
                      ? Colors.grey[100]
                      : color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: cat == null ? Colors.grey[300]! : color,
                  ),
                ),
                child: Text(
                  cat ?? '—',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: cat == null ? Colors.grey[400] : color,
                  ),
                ),
              ),
            ],
          ),
          if (cat != null && !enAlcance) ...[
            const SizedBox(height: 8),
            Text(
              'Categoría $cat: está fuera del alcance del sistema (solo B, A, AA y AAA), no se suma al conteo.',
              style: TextStyle(fontSize: 12, color: Colors.orange[800]),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: enAlcance ? _sumar : null,
              icon: const Icon(Icons.add),
              label: Text(enAlcance ? 'Sumar 1 huevo tipo $cat' : 'Sumar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorPrimario,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: () => setState(() => _verTabla = !_verTabla),
            icon: Icon(_verTabla ? Icons.expand_less : Icons.expand_more),
            label: Text(
              _verTabla
                  ? 'Ocultar rangos de la NTC 1240'
                  : 'Ver rangos de la NTC 1240',
            ),
          ),
          if (_verTabla)
            ...rangosNtc1240.map((r) {
              final dentro = categoriaEnAlcance(r.categoria);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    SizedBox(
                      width: 56,
                      child: Text(
                        r.categoria,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: dentro ? Colors.black87 : Colors.grey,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        r.descripcion,
                        style: TextStyle(
                          color: dentro ? Colors.black87 : Colors.grey,
                        ),
                      ),
                    ),
                    if (!dentro)
                      Text(
                        'fuera de alcance',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pesoController.dispose();
    _focus.dispose();
    super.dispose();
  }
}
