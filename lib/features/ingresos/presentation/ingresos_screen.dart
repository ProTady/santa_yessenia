import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../models/ingreso_model.dart';
import '../providers/ingresos_provider.dart';

class IngresosScreen extends ConsumerWidget {
  const IngresosScreen({super.key});

  static const _color = Color(0xFF00695C);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lista = ref.watch(ingresosProvider);
    final totalMes = ref.watch(totalIngresosMesProvider);
    final fmt = _fmtCurrency();
    final fmtFecha = DateFormat('dd/MM/yyyy', 'es');

    // Agrupar por fecha
    final grupos = <String, List<IngresoModel>>{};
    for (final i in lista) {
      final key = fmtFecha.format(i.fecha);
      grupos.putIfAbsent(key, () => []).add(i);
    }
    final fechas = grupos.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingresos del Fundo'),
        actions: [
          if (lista.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text('${lista.length} cobros',
                    style: const TextStyle(
                        fontSize: 13, color: Colors.white70)),
              ),
            ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/ingresos'),
      body: SafeArea(
        top: false,
        child: lista.isEmpty
          ? _EmptyState(onAdd: () => _mostrarFormulario(context, ref))
          : Column(
              children: [
                // Banner principal
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_rounded,
                          color: Colors.white70, size: 32),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total cobrado al fundo este mes',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text(fmt.format(totalMes),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22)),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                    itemCount: fechas.length,
                    itemBuilder: (context, i) {
                      final fecha = fechas[i];
                      final items = grupos[fecha]!;
                      final totalDia =
                          items.fold(0.0, (s, ing) => s + ing.monto);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.only(top: 8, bottom: 6),
                            child: Row(
                              children: [
                                Text(fecha,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: _color)),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Divider(
                                        color: Colors.grey.shade300,
                                        height: 1)),
                                const SizedBox(width: 8),
                                Text(fmt.format(totalDia),
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          ...items.map((ing) => Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 8),
                                child: _IngresoCard(
                                  ingreso: ing,
                                  fmt: fmt,
                                  onEdit: () =>
                                      _mostrarFormulario(context, ref, ing),
                                  onDelete: () =>
                                      _confirmarEliminar(context, ref, ing),
                                ),
                              )),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
        ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormulario(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Registrar cobro'),
        backgroundColor: _color,
      ),
    );
  }

  void _mostrarFormulario(BuildContext context, WidgetRef ref,
      [IngresoModel? ingreso]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _IngresoForm(ingreso: ingreso, ref: ref),
    );
  }

  void _confirmarEliminar(
      BuildContext context, WidgetRef ref, IngresoModel ing) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar ingreso'),
        content: Text('¿Eliminar "${ing.descripcion}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.errorRed),
            onPressed: () {
              ref.read(ingresosProvider.notifier).eliminar(ing.id);
              Navigator.pop(context);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  NumberFormat _fmtCurrency() => NumberFormat.currency(
      locale: AppConstants.localeCode,
      symbol: '${AppConstants.currencySymbol} ',
      decimalDigits: 2);
}

class _IngresoCard extends StatelessWidget {
  final IngresoModel ingreso;
  final NumberFormat fmt;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _IngresoCard({
    required this.ingreso,
    required this.fmt,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFF00695C).withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.payments_rounded,
                  color: Color(0xFF00695C), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ingreso.descripcion,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  if (ingreso.numeroBoleta != null &&
                      ingreso.numeroBoleta!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.receipt_outlined,
                            size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 3),
                        Text('Boleta/Ref: ${ingreso.numeroBoleta}',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(fmt.format(ingreso.monto),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF00695C))),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      color: AppConstants.primaryGreen,
                      onPressed: onEdit,
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      color: AppConstants.errorRed,
                      onPressed: onDelete,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF00695C).withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.account_balance_outlined,
                size: 56, color: Color(0xFF00695C)),
          ),
          const SizedBox(height: 20),
          const Text('Sin ingresos registrados',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Registra los cobros al fundo',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00695C)),
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Registrar cobro'),
          ),
        ],
      ),
    );
  }
}

class _IngresoForm extends StatefulWidget {
  final IngresoModel? ingreso;
  final WidgetRef ref;
  const _IngresoForm({this.ingreso, required this.ref});

  @override
  State<_IngresoForm> createState() => _IngresoFormState();
}

class _IngresoFormState extends State<_IngresoForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descCtrl;
  late final TextEditingController _montoCtrl;
  late final TextEditingController _boletaCtrl;
  late DateTime _fecha;
  bool _guardando = false;

  bool get _esEdicion => widget.ingreso != null;

  @override
  void initState() {
    super.initState();
    final i = widget.ingreso;
    _descCtrl = TextEditingController(
        text: i?.descripcion ?? 'Servicio de alimentación');
    _montoCtrl = TextEditingController(
        text: i != null ? i.monto.toStringAsFixed(2) : '');
    _boletaCtrl = TextEditingController(text: i?.numeroBoleta ?? '');
    _fecha = i?.fecha ?? DateTime.now();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _montoCtrl.dispose();
    _boletaCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'PE'),
    );
    if (picked != null) setState(() => _fecha = picked);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    final monto = double.parse(_montoCtrl.text.replaceAll(',', '.'));
    final notifier = widget.ref.read(ingresosProvider.notifier);

    if (_esEdicion) {
      await notifier.actualizar(widget.ingreso!.copyWith(
        descripcion: _descCtrl.text.trim(),
        monto: monto,
        numeroBoleta: _boletaCtrl.text.trim(),
        fecha: _fecha,
      ));
    } else {
      await notifier.agregar(IngresoModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        descripcion: _descCtrl.text.trim(),
        monto: monto,
        numeroBoleta: _boletaCtrl.text.trim().isEmpty
            ? null
            : _boletaCtrl.text.trim(),
        fecha: _fecha,
      ));
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final fmtFecha = DateFormat('dd/MM/yyyy', 'es');

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _esEdicion ? 'Editar ingreso' : 'Nuevo ingreso',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00695C)),
              ),
              const SizedBox(height: 20),

              // Descripción
              TextFormField(
                controller: _descCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Descripción *',
                  prefixIcon: Icon(Icons.description_outlined),
                  hintText: 'Ej: Servicio de alimentación semana 1',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingresa la descripción'
                    : null,
              ),
              const SizedBox(height: 14),

              // Monto
              TextFormField(
                controller: _montoCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*[,.]?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Monto cobrado (S/.) *',
                  prefixIcon: Icon(Icons.attach_money_rounded),
                  prefixText: 'S/. ',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Ingresa el monto';
                  final d = double.tryParse(v.replaceAll(',', '.'));
                  if (d == null || d <= 0) return 'Monto inválido';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // N° Boleta / Referencia
              TextFormField(
                controller: _boletaCtrl,
                decoration: const InputDecoration(
                  labelText: 'N° Boleta / Referencia',
                  prefixIcon: Icon(Icons.receipt_outlined),
                  hintText: 'Opcional',
                ),
              ),
              const SizedBox(height: 14),

              // Fecha
              InkWell(
                onTap: _seleccionarFecha,
                borderRadius: BorderRadius.circular(10),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha de cobro',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(fmtFecha.format(_fecha)),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00695C)),
                  onPressed: _guardando ? null : _guardar,
                  child: _guardando
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(_esEdicion
                          ? 'Guardar cambios'
                          : 'Registrar ingreso'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
