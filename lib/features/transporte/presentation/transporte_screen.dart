import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../models/transporte_model.dart';
import '../providers/transporte_provider.dart';

class TransporteScreen extends ConsumerWidget {
  const TransporteScreen({super.key});

  static const _color = Color(0xFFE65100);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lista = ref.watch(transporteProvider);
    final gastoMes = ref.watch(gastoTransporteMesProvider);
    final fmt = _fmtCurrency();
    final fmtFecha = DateFormat('dd/MM/yyyy', 'es');

    // Agrupar por fecha
    final grupos = <String, List<TransporteModel>>{};
    for (final t in lista) {
      final key = fmtFecha.format(t.fecha);
      grupos.putIfAbsent(key, () => []).add(t);
    }
    final fechas = grupos.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transporte'),
        actions: [
          if (lista.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text('${lista.length} viajes',
                    style: const TextStyle(
                        fontSize: 13, color: Colors.white70)),
              ),
            ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/transporte'),
      body: SafeArea(
        top: false,
        child: lista.isEmpty
          ? _EmptyState(onAdd: () => _mostrarFormulario(context, ref))
          : Column(
              children: [
                // Banner
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_shipping_rounded,
                          color: Colors.white70, size: 20),
                      const SizedBox(width: 10),
                      const Text('Gasto en transporte este mes:',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 12)),
                      const Spacer(),
                      Text(fmt.format(gastoMes),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
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
                          items.fold(0.0, (s, t) => s + t.costo);
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
                          ...items.map((t) => Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 8),
                                child: _TransporteCard(
                                  t: t,
                                  fmt: fmt,
                                  onEdit: () =>
                                      _mostrarFormulario(context, ref, t),
                                  onDelete: () =>
                                      _confirmarEliminar(context, ref, t),
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
        label: const Text('Agregar viaje'),
        backgroundColor: _color,
      ),
    );
  }

  void _mostrarFormulario(BuildContext context, WidgetRef ref,
      [TransporteModel? t]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TransporteForm(transporte: t, ref: ref),
    );
  }

  void _confirmarEliminar(
      BuildContext context, WidgetRef ref, TransporteModel t) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar viaje'),
        content: Text('¿Eliminar "${t.rutaCompleta}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.errorRed),
            onPressed: () {
              ref.read(transporteProvider.notifier).eliminar(t.id);
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

class _TransporteCard extends StatelessWidget {
  final TransporteModel t;
  final NumberFormat fmt;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TransporteCard({
    required this.t,
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
                color: const Color(0xFFE65100).withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.local_shipping_rounded,
                  color: Color(0xFFE65100), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(t.origen,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(Icons.arrow_forward_rounded,
                            size: 14, color: Color(0xFFE65100)),
                      ),
                      Expanded(
                        child: Text(t.destino,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE65100).withAlpha(20),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(t.motivo,
                            style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFFE65100),
                                fontWeight: FontWeight.w600)),
                      ),
                      if (t.descripcion != null &&
                          t.descripcion!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(t.descripcion!,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(fmt.format(t.costo),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFFE65100))),
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
              color: const Color(0xFFE65100).withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_shipping_outlined,
                size: 56, color: Color(0xFFE65100)),
          ),
          const SizedBox(height: 20),
          const Text('Sin viajes registrados',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Registra los gastos de transporte',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE65100)),
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Agregar viaje'),
          ),
        ],
      ),
    );
  }
}

class _TransporteForm extends StatefulWidget {
  final TransporteModel? transporte;
  final WidgetRef ref;
  const _TransporteForm({this.transporte, required this.ref});

  @override
  State<_TransporteForm> createState() => _TransporteFormState();
}

class _TransporteFormState extends State<_TransporteForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _origenCtrl;
  late final TextEditingController _destinoCtrl;
  late final TextEditingController _costoCtrl;
  late final TextEditingController _descCtrl;
  late String _motivo;
  late DateTime _fecha;
  bool _guardando = false;

  bool get _esEdicion => widget.transporte != null;

  @override
  void initState() {
    super.initState();
    final t = widget.transporte;
    _origenCtrl = TextEditingController(text: t?.origen ?? '');
    _destinoCtrl = TextEditingController(text: t?.destino ?? '');
    _costoCtrl = TextEditingController(
        text: t != null ? t.costo.toStringAsFixed(2) : '');
    _descCtrl = TextEditingController(text: t?.descripcion ?? '');
    _motivo = t?.motivo ?? 'Compras';
    _fecha = t?.fecha ?? DateTime.now();
  }

  @override
  void dispose() {
    _origenCtrl.dispose();
    _destinoCtrl.dispose();
    _costoCtrl.dispose();
    _descCtrl.dispose();
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

    final costo = double.parse(_costoCtrl.text.replaceAll(',', '.'));
    final notifier = widget.ref.read(transporteProvider.notifier);

    if (_esEdicion) {
      await notifier.actualizar(widget.transporte!.copyWith(
        origen: _origenCtrl.text.trim(),
        destino: _destinoCtrl.text.trim(),
        motivo: _motivo,
        costo: costo,
        descripcion: _descCtrl.text.trim(),
        fecha: _fecha,
      ));
    } else {
      await notifier.agregar(TransporteModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        origen: _origenCtrl.text.trim(),
        destino: _destinoCtrl.text.trim(),
        motivo: _motivo,
        costo: costo,
        descripcion: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
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
                _esEdicion ? 'Editar viaje' : 'Nuevo viaje',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE65100)),
              ),
              const SizedBox(height: 20),

              // Origen → Destino
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _origenCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Origen *',
                        prefixIcon: Icon(Icons.trip_origin_rounded,
                            color: Color(0xFFE65100)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Requerido'
                          : null,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 16, left: 8, right: 8),
                    child: Icon(Icons.arrow_forward_rounded,
                        color: Color(0xFFE65100)),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _destinoCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Destino *',
                        prefixIcon: Icon(Icons.place_rounded,
                            color: Color(0xFFE65100)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Requerido'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Motivo
              DropdownButtonFormField<String>(
                key: ValueKey(_motivo),
                initialValue: _motivo,
                decoration: const InputDecoration(
                  labelText: 'Motivo del viaje',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: TransporteModel.motivos
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) => setState(() => _motivo = v!),
              ),
              const SizedBox(height: 14),

              // Costo
              TextFormField(
                controller: _costoCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*[,.]?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Costo del viaje (S/.) *',
                  prefixIcon: Icon(Icons.attach_money_rounded),
                  prefixText: 'S/. ',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Ingresa el costo';
                  final d = double.tryParse(v.replaceAll(',', '.'));
                  if (d == null || d <= 0) return 'Costo inválido';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Descripción
              TextFormField(
                controller: _descCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  prefixIcon: Icon(Icons.notes_rounded),
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
                    labelText: 'Fecha',
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
                      backgroundColor: const Color(0xFFE65100)),
                  onPressed: _guardando ? null : _guardar,
                  child: _guardando
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(_esEdicion
                          ? 'Guardar cambios'
                          : 'Registrar viaje'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
