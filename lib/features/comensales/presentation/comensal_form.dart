import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:signature/signature.dart';

import '../../../core/constants/app_constants.dart';
import '../models/comensal_model.dart';
import '../providers/comensales_provider.dart';
import '../providers/costos_provider.dart';

class ComensalForm extends ConsumerStatefulWidget {
  final ComensalModel? comensal;
  final WidgetRef providerRef;

  const ComensalForm({super.key, this.comensal, required this.providerRef});

  @override
  ConsumerState<ComensalForm> createState() => _ComensalFormState();
}

class _ComensalFormState extends ConsumerState<ComensalForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _dniCtrl;
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _costoExtraCtrl;

  late TipoPlato _tipoPlato;
  bool _tieneExtra = false;
  Uint8List? _firmaBytes;
  late DateTime _fecha;
  bool _guardando = false;

  final SignatureController _sigCtrl = SignatureController(
    penStrokeWidth: 2.5,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  bool get _esEdicion => widget.comensal != null;

  @override
  void initState() {
    super.initState();
    final c = widget.comensal;
    _dniCtrl = TextEditingController(text: c?.dni ?? '');
    _nombreCtrl = TextEditingController(text: c?.nombre ?? '');
    _tipoPlato = c?.tipoPlato ?? TipoPlato.normal;
    _tieneExtra = c?.tieneExtra ?? false;
    _fecha = c?.fecha ?? DateTime.now();
    _firmaBytes = c?.firmaBytes;

    // Costo extra default
    final costos = ref.read(costosProvider);
    _costoExtraCtrl = TextEditingController(
        text: c != null && c.tieneExtra
            ? c.costoExtra.toStringAsFixed(2)
            : costos.costoExtra.toStringAsFixed(2));

    if (_firmaBytes != null) {
      // ya tiene firma guardada — no necesitamos el controller
    }
  }

  @override
  void dispose() {
    _dniCtrl.dispose();
    _nombreCtrl.dispose();
    _costoExtraCtrl.dispose();
    _sigCtrl.dispose();
    super.dispose();
  }

  // ── Scanner de DNI ──────────────────────────────────────────────────────────

  void _abrirScanner() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _ScannerPage(
        onScanned: (raw) {
          Navigator.pop(context);
          _parsearDni(raw);
        },
      ),
    ));
  }

  void _parsearDni(String raw) {
    // DNI peruano PDF417: empieza con el número de 8 dígitos
    final match = RegExp(r'\d{8}').firstMatch(raw);
    if (match != null) {
      _dniCtrl.text = match.group(0)!;
      // Intentar extraer nombre (después del DNI, si viene)
      final resto = raw.substring(match.end).trim();
      if (resto.isNotEmpty && _nombreCtrl.text.isEmpty) {
        // El PDF417 peruano típicamente trae apellidos y nombres separados por espacios
        _nombreCtrl.text = _limpiarTexto(resto);
      }
    } else {
      // Si no detecta formato DNI, poner lo que vino
      _dniCtrl.text = raw.replaceAll(RegExp(r'[^0-9]'), '').take8();
    }
    setState(() {});
  }

  String _limpiarTexto(String s) =>
      s.replaceAll(RegExp(r'[^a-zA-ZáéíóúÁÉÍÓÚñÑ\s]'), '').trim();

  // ── Firma ───────────────────────────────────────────────────────────────────

  Future<void> _capturarFirma(SignatureController ctrl) async {
    final bytes = await ctrl.toPngBytes();
    if (bytes != null) setState(() => _firmaBytes = bytes);
  }

  void _abrirFirmaExpandida() {
    final expandCtrl = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  const Text('Firma del comensal',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              height: 280,
              decoration: BoxDecoration(
                border:
                    Border.all(color: const Color(0xFF00838F), width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Signature(
                  controller: expandCtrl,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => expandCtrl.clear(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Limpiar'),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00838F)),
                    onPressed: () async {
                      await _capturarFirma(expandCtrl);
                      if (mounted) Navigator.pop(context);
                      expandCtrl.dispose();
                    },
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Aceptar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Guardar ─────────────────────────────────────────────────────────────────

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    // Capturar firma del controller inline si aún no se guardó
    if (_firmaBytes == null && _sigCtrl.isNotEmpty) {
      await _capturarFirma(_sigCtrl);
    }

    setState(() => _guardando = true);

    final costos = ref.read(costosProvider);
    final costoPlato = _tipoPlato == TipoPlato.normal
        ? costos.costoNormal
        : costos.costoDieta;
    final costoExtra = _tieneExtra
        ? (double.tryParse(_costoExtraCtrl.text.replaceAll(',', '.')) ??
            costos.costoExtra)
        : 0.0;

    final firmaB64 =
        _firmaBytes != null ? base64Encode(_firmaBytes!) : null;

    final notifier = widget.providerRef.read(comensalesProvider.notifier);

    if (_esEdicion) {
      await notifier.actualizar(widget.comensal!.copyWith(
        dni: _dniCtrl.text.trim(),
        nombre: _nombreCtrl.text.trim(),
        tipoPlato: _tipoPlato,
        costoPlato: costoPlato,
        tieneExtra: _tieneExtra,
        costoExtra: costoExtra,
        firmaBase64: firmaB64 ?? widget.comensal!.firmaBase64,
        fecha: _fecha,
      ));
    } else {
      await notifier.agregar(ComensalModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        dni: _dniCtrl.text.trim(),
        nombre: _nombreCtrl.text.trim(),
        tipoPlato: _tipoPlato,
        costoPlato: costoPlato,
        tieneExtra: _tieneExtra,
        costoExtra: costoExtra,
        firmaBase64: firmaB64,
        fecha: _fecha,
      ));
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final costos = ref.watch(costosProvider);
    final costoActual = _tipoPlato == TipoPlato.normal
        ? costos.costoNormal
        : costos.costoDieta;
    final fmt = NumberFormat.currency(
        locale: AppConstants.localeCode,
        symbol: '${AppConstants.currencySymbol} ',
        decimalDigits: 2);
    final fmtFecha = DateFormat('dd/MM/yyyy', 'es');

    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar comensal' : 'Registrar comensal'),
        backgroundColor: const Color(0xFF00838F),
        actions: [
          TextButton(
            onPressed: _guardando ? null : _guardar,
            child: _guardando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('GUARDAR',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── DNI ─────────────────────────────────────────────────
            _Section(label: '1. Identificación'),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _dniCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 8,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly
                    ],
                    decoration: const InputDecoration(
                      labelText: 'DNI *',
                      prefixIcon: Icon(Icons.badge_outlined),
                      counterText: '',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().length < 8) {
                        return 'DNI debe tener 8 dígitos';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                // Botón escanear
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00838F),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                    ),
                    onPressed: _abrirScanner,
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    label: const Text('Escanear'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nombreCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nombre completo *',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ingresa el nombre' : null,
            ),
            const SizedBox(height: 8),
            // Fecha
            InkWell(
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _fecha,
                  firstDate: DateTime(2020),
                  lastDate: now,
                  locale: const Locale('es', 'PE'),
                );
                if (picked != null) setState(() => _fecha = picked);
              },
              borderRadius: BorderRadius.circular(10),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(fmtFecha.format(_fecha)),
              ),
            ),

            const SizedBox(height: 20),

            // ── Tipo de plato ────────────────────────────────────────
            _Section(label: '2. Tipo de plato'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _PlateBtn(
                    label: 'Normal',
                    sublabel: fmt.format(costos.costoNormal),
                    icon: Icons.restaurant_rounded,
                    selected: _tipoPlato == TipoPlato.normal,
                    color: AppConstants.primaryGreen,
                    onTap: () =>
                        setState(() => _tipoPlato = TipoPlato.normal),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PlateBtn(
                    label: 'Dieta',
                    sublabel: fmt.format(costos.costoDieta),
                    icon: Icons.eco_rounded,
                    selected: _tipoPlato == TipoPlato.dieta,
                    color: Colors.teal,
                    onTap: () =>
                        setState(() => _tipoPlato = TipoPlato.dieta),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Precio seleccionado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppConstants.primaryGreen.withAlpha(15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.business_center_outlined,
                      color: AppConstants.primaryGreen, size: 18),
                  const SizedBox(width: 8),
                  const Text('Cargo empresa:',
                      style: TextStyle(fontSize: 13)),
                  const Spacer(),
                  Text(fmt.format(costoActual),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppConstants.primaryGreen)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Plato extra ──────────────────────────────────────────
            _Section(label: '3. Plato extra (adicional)'),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _tieneExtra,
              onChanged: (v) => setState(() => _tieneExtra = v),
              title: const Text('¿Pide plato extra?'),
              subtitle: const Text('Se suma al cargo de la empresa (tabla adicionales)',
                  style: TextStyle(fontSize: 11)),
              activeThumbColor: Colors.orange,
              contentPadding: EdgeInsets.zero,
            ),
            if (_tieneExtra) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _costoExtraCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*[,.]?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Costo adicional (S/.) *',
                  prefixIcon:
                      Icon(Icons.add_circle_outline, color: Colors.orange),
                  prefixText: 'S/. ',
                ),
                validator: (v) {
                  if (!_tieneExtra) return null;
                  final d = double.tryParse(v?.replaceAll(',', '.') ?? '');
                  if (d == null || d <= 0) return 'Ingresa el costo extra';
                  return null;
                },
              ),
            ],

            const SizedBox(height: 20),

            // ── Firma ────────────────────────────────────────────────
            _Section(label: '4. Firma del comensal'),
            const SizedBox(height: 8),

            if (_firmaBytes != null) ...[
              // Mostrar firma guardada
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: const Color(0xFF00838F), width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(_firmaBytes!,
                          fit: BoxFit.contain),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      color: AppConstants.errorRed,
                      tooltip: 'Borrar firma',
                      onPressed: () {
                        setState(() => _firmaBytes = null);
                        _sigCtrl.clear();
                      },
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Pad de firma inline
              Container(
                height: 130,
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Colors.grey.shade300, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Signature(
                    controller: _sigCtrl,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _sigCtrl.clear(),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Limpiar'),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00838F)),
                    onPressed: _abrirFirmaExpandida,
                    icon: const Icon(Icons.open_in_full_rounded, size: 18),
                    label: const Text('Ampliar firma'),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 28),

            // Botón guardar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00838F),
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: _guardando ? null : _guardar,
                child: _guardando
                    ? const SizedBox(
                        height: 22, width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(
                        _esEdicion
                            ? 'Guardar cambios'
                            : 'Registrar comensal',
                        style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sección label ──────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String label;
  const _Section({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFF00838F),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Color(0xFF00838F))),
      ],
    );
  }
}

// ── Botón tipo plato ───────────────────────────────────────────────────────────

class _PlateBtn extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _PlateBtn({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(25) : Colors.grey.shade50,
          border: Border.all(
              color: selected ? color : Colors.grey.shade300, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? color : Colors.grey, size: 28),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: selected ? color : Colors.grey.shade700)),
            Text(sublabel,
                style: TextStyle(
                    fontSize: 12,
                    color: selected ? color : Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// ── Scanner page ───────────────────────────────────────────────────────────────

class _ScannerPage extends StatefulWidget {
  final void Function(String raw) onScanned;
  const _ScannerPage({required this.onScanned});

  @override
  State<_ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<_ScannerPage> {
  final MobileScannerController _ctrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _scanned = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Escanear DNI'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded),
            onPressed: () => _ctrl.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_android_rounded),
            onPressed: () => _ctrl.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _ctrl,
            onDetect: (capture) {
              if (_scanned) return;
              final barcode = capture.barcodes.firstOrNull;
              if (barcode?.rawValue != null) {
                _scanned = true;
                widget.onScanned(barcode!.rawValue!);
              }
            },
          ),
          // Marco de escaneo centrado
          Center(
            child: Container(
              width: 260,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(
                    color: const Color(0xFF00838F), width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          // Instrucción
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Apunta al código de barras del reverso del DNI',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          // Botón entrada manual
          Positioned(
            top: 16,
            right: 16,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                backgroundColor: Colors.black45,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.keyboard_rounded, size: 18),
              label: const Text('Manual'),
            ),
          ),
        ],
      ),
    );
  }
}

extension _StringExt on String {
  String take8() => length > 8 ? substring(0, 8) : this;
}
