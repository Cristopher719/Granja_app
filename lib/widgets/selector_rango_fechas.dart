import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'form_helpers.dart';

class _FormateadorFecha extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var soloDigitos = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (soloDigitos.length > 8) soloDigitos = soloDigitos.substring(0, 8);

    final buffer = StringBuffer();
    for (var i = 0; i < soloDigitos.length; i++) {
      buffer.write(soloDigitos[i]);
      if ((i == 1 || i == 3) && i != soloDigitos.length - 1) {
        buffer.write('/');
      }
    }

    final texto = buffer.toString();
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

Future<DateTimeRange?> mostrarSelectorRangoFechas({
  required BuildContext context,
  required DateTime fechaDesdeActual,
  required DateTime fechaHastaActual,
  DateTime? primeraFecha,
}) {
  return showModalBottomSheet<DateTimeRange>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ModalRangoFechas(
      fechaDesdeActual: fechaDesdeActual,
      fechaHastaActual: fechaHastaActual,
      primeraFecha: primeraFecha ?? DateTime(2020),
    ),
  );
}

class _ModalRangoFechas extends StatefulWidget {
  final DateTime fechaDesdeActual;
  final DateTime fechaHastaActual;
  final DateTime primeraFecha;

  const _ModalRangoFechas({
    required this.fechaDesdeActual,
    required this.fechaHastaActual,
    required this.primeraFecha,
  });

  @override
  State<_ModalRangoFechas> createState() => _ModalRangoFechasState();
}

class _ModalRangoFechasState extends State<_ModalRangoFechas> {
  bool _modoCalendario = true;

  DateTime? _desde;
  DateTime? _hasta;

  final _desdeController = TextEditingController();
  final _hastaController = TextEditingController();
  String? _errorTexto;

  @override
  void initState() {
    super.initState();
    _desde = widget.fechaDesdeActual;
    _hasta = widget.fechaHastaActual;
    _desdeController.text = _fmt(widget.fechaDesdeActual);
    _hastaController.text = _fmt(widget.fechaHastaActual);
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  DateTime? _parsear(String texto) {
    final partes = texto.split('/');
    if (partes.length != 3) return null;
    final dia = int.tryParse(partes[0]);
    final mes = int.tryParse(partes[1]);
    final anio = int.tryParse(partes[2]);
    if (dia == null || mes == null || anio == null) return null;
    if (anio < 1900 || anio > 2100) return null;
    if (mes < 1 || mes > 12) return null;
    if (dia < 1 || dia > 31) return null;
    try {
      final fecha = DateTime(anio, mes, dia);
      if (fecha.day != dia || fecha.month != mes || fecha.year != anio) {
        return null;
      }
      return fecha;
    } catch (_) {
      return null;
    }
  }

  Future<void> _abrirCalendario({required bool esDesde}) async {
    final inicial = esDesde
        ? (_desde ?? DateTime.now())
        : (_hasta ?? DateTime.now());
    final seleccionada = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: widget.primeraFecha,
      lastDate: DateTime.now(),
      helpText: esDesde
          ? 'Selecciona la fecha inicial'
          : 'Selecciona la fecha final',
      cancelText: 'Cancelar',
      confirmText: 'Listo',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: colorPrimario,
            onPrimary: Colors.white,
            onSurface: Colors.black87,
          ),
        ),
        child: child!,
      ),
    );

    if (seleccionada != null) {
      setState(() {
        if (esDesde) {
          _desde = seleccionada;
          _desdeController.text = _fmt(seleccionada);
        } else {
          _hasta = seleccionada;
          _hastaController.text = _fmt(seleccionada);
        }
      });
    }
  }

  void _confirmar() {
    DateTime? desde = _desde;
    DateTime? hasta = _hasta;

    if (!_modoCalendario) {
      desde = _parsear(_desdeController.text);
      hasta = _parsear(_hastaController.text);

      if (desde == null || hasta == null) {
        setState(
          () => _errorTexto = 'Ingresa fechas válidas en formato DD/MM/AAAA.',
        );
        return;
      }
    }

    if (desde == null || hasta == null) {
      setState(() => _errorTexto = 'Selecciona ambas fechas.');
      return;
    }

    if (desde.isAfter(hasta)) {
      setState(
        () =>
            _errorTexto = 'La fecha inicial no puede ser posterior a la final.',
      );
      return;
    }

    Navigator.pop(context, DateTimeRange(start: desde, end: hasta));
  }

  @override
  Widget build(BuildContext context) {
    return hojaModal(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          manijaModal(),
          encabezadoModal(
            'Seleccionar rango de fechas',
            Icons.date_range_outlined,
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _botonModo(
                    'Calendario',
                    Icons.calendar_month_outlined,
                    activo: _modoCalendario,
                    onTap: () => setState(() {
                      _modoCalendario = true;
                      _errorTexto = null;
                    }),
                  ),
                ),
                Expanded(
                  child: _botonModo(
                    'Escribir',
                    Icons.edit_calendar_outlined,
                    activo: !_modoCalendario,
                    onTap: () => setState(() {
                      _modoCalendario = false;
                      _errorTexto = null;
                    }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (_modoCalendario) ...[
            _campoFechaCalendario(
              etiqueta: 'Fecha inicial',
              fecha: _desde,
              onTap: () => _abrirCalendario(esDesde: true),
            ),
            const SizedBox(height: 12),
            _campoFechaCalendario(
              etiqueta: 'Fecha final',
              fecha: _hasta,
              onTap: () => _abrirCalendario(esDesde: false),
            ),
          ] else ...[
            TextField(
              controller: _desdeController,
              keyboardType: TextInputType.number,
              inputFormatters: [_FormateadorFecha()],
              decoration: decoracionCampo(
                'Fecha inicial (DD/MM/AAAA)',
                Icons.event_outlined,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _hastaController,
              keyboardType: TextInputType.number,
              inputFormatters: [_FormateadorFecha()],
              decoration: decoracionCampo(
                'Fecha final (DD/MM/AAAA)',
                Icons.event_outlined,
              ),
            ),
          ],

          if (_errorTexto != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, size: 16, color: Colors.red[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorTexto!,
                      style: TextStyle(fontSize: 12, color: Colors.red[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),
          botonGuardar(
            cargando: false,
            onPressed: _confirmar,
            texto: 'Aplicar rango',
          ),
        ],
      ),
    );
  }

  Widget _botonModo(
    String texto,
    IconData icono, {
    required bool activo,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: activo ? colorPrimario : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icono,
              size: 16,
              color: activo ? Colors.white : Colors.grey[500],
            ),
            const SizedBox(width: 6),
            Text(
              texto,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: activo ? Colors.white : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campoFechaCalendario({
    required String etiqueta,
    required DateTime? fecha,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 18, color: colorPrimario),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etiqueta,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
                Text(
                  fecha != null ? _fmt(fecha) : 'Toca para seleccionar',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: fecha != null ? Colors.black87 : Colors.grey[400],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _desdeController.dispose();
    _hastaController.dispose();
    super.dispose();
  }
}
