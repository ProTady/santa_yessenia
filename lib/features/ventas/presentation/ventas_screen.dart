import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../models/venta_model.dart';
import '../providers/ventas_provider.dart';

class VentasScreen extends ConsumerWidget {
  const VentasScreen({super.key});

  static const _color = Color(0xFF6A1B9A); // púrpura para distinguir de ingresos
  static final _fmtFecha = DateFormat('dd/MM/yyyy', 'es');
  static final _fmtCurrency =
      NumberFormat.currency(locale: 'es_PE', symbol: 'S/. ', decimalDigits: 2);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lista = ref.watch(ventasProvider);
    final totalMes = ref.watch(totalVentasMesProvider);
    final totalFiado = ref.watch(totalFiadoPendienteProvider);

    // Agrupar por fecha
    final grupos = <String, List<VentaModel>>{};
    for (final v in lista) {
      final key = _fmtFecha.format(v.fecha);
      grupos.putIfAbsent(key, () => []).add(v);
    }
    final fechas = grupos.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventas'),
        backgroundColor: _color,
        foregroundColor: Colors.white,
        actions: [
          if (lista.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text('${lista.length} reg.',
                    style: const TextStyle(
                        fontSize: 13, color: Colors.white70)),
              ),
            ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/ventas'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormulario(context, ref, null),
        backgroundColor: _color,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_shopping_cart_rounded),
        label: const Text('Nueva venta'),
      ),
      body: SafeArea(
        top: false,
        child: lista.isEmpty
            ? _EmptyState(onAdd: () => _mostrarFormulario(context, ref, null))
            : Column(
                children: [
                  // ── Resumen ──────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ResumenCard(
                            label: 'Ventas este mes',
                            monto: totalMes,
                            icon: Icons.storefront_rounded,
                            color: _color,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ResumenCard(
                            label: 'Fiado pendiente',
                            monto: totalFiado,
                            icon: Icons.pending_actions_rounded,
                            color: totalFiado > 0
                                ? AppConstants.accentAmber
                                : Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Lista ─────────────────────────────────────────────
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      itemCount: fechas.length,
                      itemBuilder: (ctx, i) {
                        final fecha = fechas[i];
                        final ventas = grupos[fecha]!;
                        final subtotal =
                            ventas.fold(0.0, (s, v) => s + v.total);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Encabezado de fecha
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(0, 14, 0, 6),
                              child: Row(
                                children: [
                                  Text(fecha,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade600,
                                          fontSize: 13)),
                                  const Spacer(),
                                  Text(_fmtCurrency.format(subtotal),
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: _color,
                                          fontSize: 13)),
                                ],
                              ),
                            ),
                            ...ventas.map((v) => _VentaTile(
                                  venta: v,
                                  onEdit: () =>
                                      _mostrarFormulario(context, ref, v),
                                  onDelete: () =>
                                      _confirmarEliminar(context, ref, v),
                                )),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _mostrarFormulario(
      BuildContext context, WidgetRef ref, VentaModel? venta) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VentaForm(venta: venta),
    );
  }

  Future<void> _confirmarEliminar(
      BuildContext context, WidgetRef ref, VentaModel v) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar venta'),
        content: Text('¿Eliminar "${v.descripcion}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar',
                style: TextStyle(color: AppConstants.errorRed)),
          ),
        ],
      ),
    );
    if (ok == true) ref.read(ventasProvider.notifier).eliminar(v.id);
  }
}

// ── Tarjeta de resumen ─────────────────────────────────────────────────────────

class _ResumenCard extends StatelessWidget {
  final String label;
  final double monto;
  final IconData icon;
  final Color color;

  static final _fmt = NumberFormat.currency(
      locale: 'es_PE', symbol: 'S/. ', decimalDigits: 2);

  const _ResumenCard({
    required this.label,
    required this.monto,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 11)),
                const SizedBox(height: 2),
                Text(_fmt.format(monto),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tile de venta ──────────────────────────────────────────────────────────────

class _VentaTile extends StatelessWidget {
  final VentaModel venta;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static final _fmt = NumberFormat.currency(
      locale: 'es_PE', symbol: 'S/. ', decimalDigits: 2);

  const _VentaTile(
      {required this.venta, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final esFiado = venta.estadoPago == EstadoPago.fiado;
    final badgeColor =
        esFiado ? AppConstants.accentAmber : Colors.green.shade600;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícono estado
            Container(
              margin: const EdgeInsets.only(top: 2, right: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: badgeColor.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                esFiado
                    ? Icons.pending_actions_rounded
                    : Icons.check_circle_rounded,
                color: badgeColor,
                size: 20,
              ),
            ),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(venta.descripcion,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    '${_fmt.format(venta.valorUnitario)} × ${_fmtCantidad(venta.cantidad)}',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500),
                  ),
                  if (venta.comprador != null && venta.comprador!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          Icon(Icons.person_outline_rounded,
                              size: 12, color: Colors.grey.shade400),
                          const SizedBox(width: 3),
                          Text(venta.comprador!,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      venta.estadoPago.label,
                      style: TextStyle(
                          fontSize: 11,
                          color: badgeColor,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            // Total + acciones
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_fmt.format(venta.total),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: onEdit,
                      child: Icon(Icons.edit_rounded,
                          size: 18, color: Colors.grey.shade500),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: onDelete,
                      child: Icon(Icons.delete_rounded,
                          size: 18, color: Colors.red.shade300),
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

  String _fmtCantidad(double c) =>
      c == c.truncateToDouble() ? c.toInt().toString() : c.toString();
}

// ── Estado vacío ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.storefront_rounded,
              size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Sin ventas registradas',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500)),
          const SizedBox(height: 6),
          Text('Toca el botón para agregar tu primera venta',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Nueva venta'),
          ),
        ],
      ),
    );
  }
}

// ── Formulario ─────────────────────────────────────────────────────────────────

class _VentaForm extends ConsumerStatefulWidget {
  final VentaModel? venta;
  const _VentaForm({this.venta});

  @override
  ConsumerState<_VentaForm> createState() => _VentaFormState();
}

class _VentaFormState extends ConsumerState<_VentaForm> {
  static const _color = Color(0xFF6A1B9A);
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _descripcion;
  late TextEditingController _cantidad;
  late TextEditingController _valor;
  late TextEditingController _comprador;
  late DateTime _fecha;
  late EstadoPago _estadoPago;

  bool get _esEdicion => widget.venta != null;

  @override
  void initState() {
    super.initState();
    final v = widget.venta;
    _descripcion = TextEditingController(text: v?.descripcion ?? '');
    _cantidad = TextEditingController(
        text: v != null ? _fmtNum(v.cantidad) : '');
    _valor = TextEditingController(
        text: v != null ? _fmtNum(v.valorUnitario) : '');
    _comprador = TextEditingController(text: v?.comprador ?? '');
    _fecha = v?.fecha ?? DateTime.now();
    _estadoPago = v?.estadoPago ?? EstadoPago.pagado;
  }

  String _fmtNum(double n) =>
      n == n.truncateToDouble() ? n.toInt().toString() : n.toString();

  @override
  void dispose() {
    _descripcion.dispose();
    _cantidad.dispose();
    _valor.dispose();
    _comprador.dispose();
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

    final notifier = ref.read(ventasProvider.notifier);
    final cantidad = double.tryParse(_cantidad.text.replaceAll(',', '.')) ?? 0;
    final valor = double.tryParse(_valor.text.replaceAll(',', '.')) ?? 0;

    if (_esEdicion) {
      final actualizado = widget.venta!.copyWith(
        fecha: _fecha,
        descripcion: _descripcion.text.trim(),
        cantidad: cantidad,
        valorUnitario: valor,
        comprador: _comprador.text.trim().isEmpty ? null : _comprador.text.trim(),
        estadoPago: _estadoPago,
      );
      await notifier.actualizar(actualizado);
    } else {
      final nueva = VentaModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fecha: _fecha,
        descripcion: _descripcion.text.trim(),
        cantidad: cantidad,
        valorUnitario: valor,
        comprador: _comprador.text.trim().isEmpty ? null : _comprador.text.trim(),
        estadoPago: _estadoPago,
      );
      await notifier.agregar(nueva);
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final navBar = MediaQuery.of(context).viewPadding.bottom;
    final cantidad = double.tryParse(_cantidad.text.replaceAll(',', '.')) ?? 0;
    final valor = double.tryParse(_valor.text.replaceAll(',', '.')) ?? 0;
    final total = cantidad * valor;
    final fmtFecha = DateFormat('dd/MM/yyyy', 'es');
    final fmtCurrency = NumberFormat.currency(
        locale: 'es_PE', symbol: 'S/. ', decimalDigits: 2);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset + navBar),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text(
                _esEdicion ? 'Editar venta' : 'Nueva venta',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _color),
              ),
              const SizedBox(height: 20),

              // ── Fecha ────────────────────────────────────────────
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _color.withAlpha(18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.calendar_today_rounded,
                      color: _color, size: 20),
                ),
                title: const Text('Fecha',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                subtitle: Text(fmtFecha.format(_fecha),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                onTap: _seleccionarFecha,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.grey.shade300)),
              ),
              const SizedBox(height: 14),

              // ── Descripción ──────────────────────────────────────
              TextFormField(
                controller: _descripcion,
                decoration: _deco('Descripción del producto/servicio',
                    Icons.inventory_2_rounded),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Ingresa descripción' : null,
              ),
              const SizedBox(height: 14),

              // ── Cantidad + Valor ─────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cantidad,
                      decoration: _deco('Cantidad', Icons.numbers_rounded),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,3}'))
                      ],
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        if ((double.tryParse(v.replaceAll(',', '.')) ?? 0) <=
                            0) return '> 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _valor,
                      decoration: _deco('Precio unit.', Icons.attach_money_rounded),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'))
                      ],
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        if ((double.tryParse(v.replaceAll(',', '.')) ?? 0) <=
                            0) return '> 0';
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              // Total preview
              if (total > 0) ...[
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _color.withAlpha(12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calculate_rounded,
                          color: _color, size: 18),
                      const SizedBox(width: 8),
                      Text('Total: ',
                          style: TextStyle(color: Colors.grey.shade600)),
                      Text(fmtCurrency.format(total),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _color,
                              fontSize: 16)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),

              // ── Comprador (opcional) ──────────────────────────────
              TextFormField(
                controller: _comprador,
                decoration: _deco(
                    'Comprador (opcional)', Icons.person_outline_rounded),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 20),

              // ── Estado de pago ────────────────────────────────────
              const Text('Estado de pago',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: _color)),
              const SizedBox(height: 8),
              Row(
                children: EstadoPago.values.map((e) {
                  final selected = _estadoPago == e;
                  final color = e == EstadoPago.pagado
                      ? Colors.green.shade700
                      : AppConstants.accentAmber;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _estadoPago = e),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: EdgeInsets.only(
                            right: e == EstadoPago.pagado ? 8 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color:
                              selected ? color : Colors.transparent,
                          border: Border.all(
                              color: selected
                                  ? color
                                  : Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              e == EstadoPago.pagado
                                  ? Icons.check_circle_rounded
                                  : Icons.pending_actions_rounded,
                              color: selected
                                  ? Colors.white
                                  : Colors.grey.shade500,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              e.label,
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // ── Guardar ──────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _guardar,
                  style: FilledButton.styleFrom(
                    backgroundColor: _color,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.save_rounded),
                  label:
                      Text(_esEdicion ? 'Guardar cambios' : 'Registrar venta'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _deco(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _color),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _color, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}
