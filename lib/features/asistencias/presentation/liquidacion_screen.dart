import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../personal/models/personal_model.dart';
import '../../personal/providers/personal_provider.dart';
import '../models/asistencia_model.dart';
import '../providers/asistencias_provider.dart';
import '../providers/beneficios_provider.dart';

// ── Modelo de resultado por trabajador ────────────────────────────────────────

class _LiquidacionTrabajador {
  final PersonalModel persona;
  final int diasPresente;
  final int diasMedioDia;
  final int diasFalta;
  final int diasDescanso;
  final BeneficiosConfig beneficios;

  const _LiquidacionTrabajador({
    required this.persona,
    required this.diasPresente,
    required this.diasMedioDia,
    required this.diasFalta,
    required this.diasDescanso,
    required this.beneficios,
  });

  double get diasEfectivos => diasPresente + diasMedioDia * 0.5;
  double get sueldoBase => diasEfectivos * persona.sueldoDiario;

  bool get esGeneral => persona.regimen == Regimen.general;

  double get gratificacion =>
      esGeneral ? sueldoBase * beneficios.gratificacionFactor : 0;
  double get cts =>
      esGeneral ? sueldoBase * beneficios.ctsFactor : 0;
  double get vacaciones =>
      esGeneral ? sueldoBase * beneficios.vacacionesFactor : 0;
  double get essalud =>
      esGeneral ? sueldoBase * beneficios.essaludFactor : 0;

  double get totalBeneficios => gratificacion + cts + vacaciones + essalud;
  double get costoTotal => sueldoBase + totalBeneficios;
}

// ── Pantalla ──────────────────────────────────────────────────────────────────

class LiquidacionScreen extends ConsumerStatefulWidget {
  const LiquidacionScreen({super.key});

  @override
  ConsumerState<LiquidacionScreen> createState() =>
      _LiquidacionScreenState();
}

class _LiquidacionScreenState extends ConsumerState<LiquidacionScreen> {
  late DateTime _desde;
  late DateTime _hasta;

  final _fmt = NumberFormat.currency(
    locale: AppConstants.localeCode,
    symbol: '${AppConstants.currencySymbol} ',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _desde = DateTime(now.year, now.month, 1);
    _hasta = DateTime(now.year, now.month, now.day);
  }

  Future<void> _elegirDesde() async {
    final d = await _pickDate(_desde, lastDate: _hasta);
    if (d != null) setState(() => _desde = d);
  }

  Future<void> _elegirHasta() async {
    final d = await _pickDate(_hasta, firstDate: _desde);
    if (d != null) setState(() => _hasta = d);
  }

  Future<DateTime?> _pickDate(DateTime initial,
      {DateTime? firstDate, DateTime? lastDate}) {
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? DateTime.now(),
      locale: const Locale('es', 'PE'),
    );
  }

  void _mostrarConfigBeneficios(BuildContext ctx, WidgetRef ref) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BeneficiosDialog(ref: ref),
    );
  }

  List<_LiquidacionTrabajador> _calcular(
      List<PersonalModel> personal,
      List<AsistenciaModel> todas,
      BeneficiosConfig beneficios) {
    final result = <_LiquidacionTrabajador>[];
    for (final p in personal) {
      final asistencias = todas
          .where((a) => a.personalId == p.id)
          .where((a) {
            final d = a.fechaDate;
            return !d.isBefore(_desde) && !d.isAfter(_hasta);
          }).toList();

      result.add(_LiquidacionTrabajador(
        persona: p,
        diasPresente: asistencias
            .where((a) => a.estado == EstadoAsistencia.presente).length,
        diasMedioDia: asistencias
            .where((a) => a.estado == EstadoAsistencia.medioDia).length,
        diasFalta: asistencias
            .where((a) => a.estado == EstadoAsistencia.falta).length,
        diasDescanso: asistencias
            .where((a) => a.estado == EstadoAsistencia.descanso).length,
        beneficios: beneficios,
      ));
    }
    result.sort((a, b) => a.persona.nombre.compareTo(b.persona.nombre));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final personal    = ref.watch(personalProvider).where((p) => p.activo).toList();
    final todas       = ref.watch(asistenciasProvider);
    final beneficios  = ref.watch(beneficiosProvider);
    final resultados  = _calcular(personal, todas, beneficios);

    final totalGeneral = resultados.fold(0.0, (s, r) => s + r.costoTotal);
    final totalBase    = resultados.fold(0.0, (s, r) => s + r.sueldoBase);
    final totalBenef   = resultados.fold(0.0, (s, r) => s + r.totalBeneficios);

    final fmtFecha = DateFormat('dd/MM/yyyy', 'es');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Liquidación de Haberes'),
        backgroundColor: AppConstants.asistenciaColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Configurar beneficios',
            onPressed: () => _mostrarConfigBeneficios(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // ── Selector de período ───────────────────────────────────
            Container(
              color: AppConstants.asistenciaColor,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: _FechaBtn(
                      label: 'Desde',
                      fecha: fmtFecha.format(_desde),
                      onTap: _elegirDesde,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('→',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 20)),
                  ),
                  Expanded(
                    child: _FechaBtn(
                      label: 'Hasta',
                      fecha: fmtFecha.format(_hasta),
                      onTap: _elegirHasta,
                    ),
                  ),
                ],
              ),
            ),

            // ── Resumen global ────────────────────────────────────────
            _ResumenGlobal(
              fmt: _fmt,
              totalBase: totalBase,
              totalBeneficios: totalBenef,
              totalGeneral: totalGeneral,
              trabajadores: resultados.length,
            ),

            // ── Lista ─────────────────────────────────────────────────
            Expanded(
              child: resultados.isEmpty
                  ? Center(
                      child: Text(
                        'Sin trabajadores activos',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: resultados.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 10),
                      itemBuilder: (_, i) =>
                          _TrabajadorCard(r: resultados[i], fmt: _fmt),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets ────────────────────────────────────────────────────────────────────

class _FechaBtn extends StatelessWidget {
  final String label;
  final String fecha;
  final VoidCallback onTap;

  const _FechaBtn(
      {required this.label, required this.fecha, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(25),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white30),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 10)),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text(fecha,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumenGlobal extends StatelessWidget {
  final NumberFormat fmt;
  final double totalBase;
  final double totalBeneficios;
  final double totalGeneral;
  final int trabajadores;

  const _ResumenGlobal({
    required this.fmt,
    required this.totalBase,
    required this.totalBeneficios,
    required this.totalGeneral,
    required this.trabajadores,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConstants.asistenciaColor,
            AppConstants.asistenciaColor.withAlpha(200),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppConstants.asistenciaColor.withAlpha(60),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$trabajadores trabajador${trabajadores == 1 ? '' : 'es'}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const Icon(Icons.people_rounded,
                  color: Colors.white54, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Sueldos base:',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              Text(fmt.format(totalBase),
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13)),
            ],
          ),
          if (totalBeneficios > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Beneficios (Reg. General):',
                    style:
                        TextStyle(color: Colors.white70, fontSize: 13)),
                Text(fmt.format(totalBeneficios),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13)),
              ],
            ),
          ],
          const Divider(color: Colors.white30, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL A PAGAR:',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              Text(
                fmt.format(totalGeneral),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrabajadorCard extends StatelessWidget {
  final _LiquidacionTrabajador r;
  final NumberFormat fmt;

  const _TrabajadorCard({required this.r, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final esGeneral = r.persona.regimen == Regimen.general;

    return Card(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding:
              const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: CircleAvatar(
            backgroundColor: AppConstants.asistenciaColor,
            child: Text(
              r.persona.nombre.isNotEmpty
                  ? r.persona.nombre[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(r.persona.nombre,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Row(
            children: [
              Text(r.persona.cargo,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: esGeneral
                      ? AppConstants.asistenciaColor.withAlpha(20)
                      : Colors.orange.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  esGeneral ? 'Gral.' : 'Eventual',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: esGeneral
                        ? AppConstants.asistenciaColor
                        : Colors.orange.shade800,
                  ),
                ),
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                fmt.format(r.costoTotal),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppConstants.asistenciaColor),
              ),
              Text(
                '${r.diasEfectivos.toStringAsFixed(1)} días ef.',
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
          children: [
            const Divider(),
            // Asistencia
            _Row('Días presentes', '${r.diasPresente}',
                icon: Icons.check_circle_rounded, color: Colors.green),
            _Row('Días ½ jornada', '${r.diasMedioDia}',
                icon: Icons.timelapse_rounded, color: Colors.orange),
            _Row('Faltas', '${r.diasFalta}',
                icon: Icons.cancel_rounded,
                color: AppConstants.errorRed),
            _Row('Descansos', '${r.diasDescanso}',
                icon: Icons.weekend_outlined, color: Colors.blueGrey),
            const Divider(height: 16),
            // Montos
            _Row('Días efectivos', r.diasEfectivos.toStringAsFixed(1)),
            _Row(
              'Sueldo diario',
              fmt.format(r.persona.sueldoDiario),
            ),
            _Row(
              'Sueldo base',
              fmt.format(r.sueldoBase),
              bold: true,
            ),
            if (esGeneral) ...[
              const Divider(height: 16),
              const Text('Provisión de beneficios (empleador):',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              _Row('Gratificación (${r.beneficios.gratificacionPct.toStringAsFixed(2)}%)',
                  fmt.format(r.gratificacion),
                  color: AppConstants.asistenciaColor),
              _Row('CTS (${r.beneficios.ctsPct.toStringAsFixed(2)}%)',
                  fmt.format(r.cts),
                  color: AppConstants.asistenciaColor),
              _Row('Vacaciones (${r.beneficios.vacacionesPct.toStringAsFixed(2)}%)',
                  fmt.format(r.vacaciones),
                  color: AppConstants.asistenciaColor),
              _Row('EsSalud (${r.beneficios.essaludPct.toStringAsFixed(2)}%)',
                  fmt.format(r.essalud),
                  color: AppConstants.asistenciaColor),
              _Row('Total beneficios',
                  fmt.format(r.totalBeneficios),
                  bold: true,
                  color: AppConstants.asistenciaColor),
            ],
            const Divider(height: 16),
            _Row('COSTO TOTAL EMPLEADOR', fmt.format(r.costoTotal),
                bold: true,
                color: AppConstants.asistenciaColor,
                large: true),
          ],
        ),
      ),
    );
  }
}

// ── Diálogo de configuración de beneficios ────────────────────────────────────

class _BeneficiosDialog extends StatefulWidget {
  final WidgetRef ref;
  const _BeneficiosDialog({required this.ref});

  @override
  State<_BeneficiosDialog> createState() => _BeneficiosDialogState();
}

class _BeneficiosDialogState extends State<_BeneficiosDialog> {
  late TextEditingController _gratiCtrl;
  late TextEditingController _ctsCtrl;
  late TextEditingController _vacacCtrl;
  late TextEditingController _essaludCtrl;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final cfg = widget.ref.read(beneficiosProvider);
    _gratiCtrl   = TextEditingController(text: cfg.gratificacionPct.toStringAsFixed(2));
    _ctsCtrl     = TextEditingController(text: cfg.ctsPct.toStringAsFixed(2));
    _vacacCtrl   = TextEditingController(text: cfg.vacacionesPct.toStringAsFixed(2));
    _essaludCtrl = TextEditingController(text: cfg.essaludPct.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _gratiCtrl.dispose(); _ctsCtrl.dispose();
    _vacacCtrl.dispose(); _essaludCtrl.dispose();
    super.dispose();
  }

  double _parse(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.')) ?? 0;

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    await widget.ref.read(beneficiosProvider.notifier).actualizar(
      gratificacion: _parse(_gratiCtrl),
      cts:           _parse(_ctsCtrl),
      vacaciones:    _parse(_vacacCtrl),
      essalud:       _parse(_essaludCtrl),
    );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _restaurar() async {
    await widget.ref.read(beneficiosProvider.notifier).restaurarDefectos();
    if (mounted) Navigator.pop(context);
  }

  Widget _campo(String label, TextEditingController ctrl, String ayuda) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*[,.]?\d{0,2}')),
        ],
        decoration: InputDecoration(
          labelText: label,
          helperText: ayuda,
          suffixText: '%',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final navBar = MediaQuery.of(context).viewPadding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom + navBar),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.tune_rounded,
                  color: AppConstants.asistenciaColor),
              const SizedBox(width: 8),
              const Text('Tasas de Beneficios — Régimen General',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppConstants.asistenciaColor)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Se aplican sobre el sueldo base del período. '
            'Actualízalos si el gobierno cambia las tasas.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          _campo('Gratificación', _gratiCtrl, 'Ej: 16.67 (2 sueldos/año)'),
          _campo('CTS', _ctsCtrl, 'Ej: 9.72'),
          _campo('Vacaciones', _vacacCtrl, 'Ej: 8.33 (30 días/año)'),
          _campo('EsSalud', _essaludCtrl, 'Ej: 9.00 (aporte empleador)'),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: _restaurar,
                icon: const Icon(Icons.restore_rounded, size: 18),
                label: const Text('Restaurar defecto'),
                style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade600),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _guardando ? null : _guardar,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.asistenciaColor),
                child: _guardando
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Guardar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final bool large;
  final Color? color;
  final IconData? icon;

  const _Row(
    this.label,
    this.value, {
    this.bold = false,
    this.large = false,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Colors.black87;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: effectiveColor),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: large ? 13 : 12,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                color: effectiveColor,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: large ? 15 : 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              color: effectiveColor,
            ),
          ),
        ],
      ),
    );
  }
}
