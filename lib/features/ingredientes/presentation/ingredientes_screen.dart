import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../models/ingrediente_model.dart';
import '../providers/ingredientes_provider.dart';

class IngredientesScreen extends ConsumerWidget {
  const IngredientesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lista = ref.watch(ingredientesProvider);
    final gastoMes = ref.watch(gastoIngredientesMesProvider);
    final fmt = _fmtCurrency();
    final fmtFecha = DateFormat('dd/MM/yyyy', 'es');

    // Agrupar por fecha
    final grupos = <String, List<IngredienteModel>>{};
    for (final ing in lista) {
      final key = fmtFecha.format(ing.fecha);
      grupos.putIfAbsent(key, () => []).add(ing);
    }
    final fechas = grupos.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingredientes'),
        actions: [
          if (lista.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text('${lista.length} registros',
                    style:
                        const TextStyle(fontSize: 13, color: Colors.white70)),
              ),
            ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/ingredientes'),
      body: lista.isEmpty
          ? _EmptyState(onAdd: () => _mostrarFormulario(context, ref))
          : Column(
              children: [
                _ResumenBanner(gastoMes: gastoMes, fmt: fmt),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                    itemCount: fechas.length,
                    itemBuilder: (context, i) {
                      final fecha = fechas[i];
                      final items = grupos[fecha]!;
                      final totalDia = items.fold(0.0, (s, e) => s + e.subtotal);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Encabezado de fecha
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 6),
                            child: Row(
                              children: [
                                Text(fecha,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: AppConstants.primaryGreen)),
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
                          // Items del día
                          ...items.map((ing) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _IngredienteCard(
                                  ing: ing,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormulario(context, ref),
        icon: const Icon(Icons.add_shopping_cart_rounded),
        label: const Text('Agregar'),
      ),
    );
  }

  void _mostrarFormulario(BuildContext context, WidgetRef ref,
      [IngredienteModel? ing]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _IngredienteForm(ingrediente: ing, ref: ref),
    );
  }

  void _confirmarEliminar(
      BuildContext context, WidgetRef ref, IngredienteModel ing) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar ingrediente'),
        content: Text('¿Eliminar "${ing.producto}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.errorRed),
            onPressed: () {
              ref.read(ingredientesProvider.notifier).eliminar(ing.id);
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

// ── Banner resumen ─────────────────────────────────────────────────────────────

class _ResumenBanner extends StatelessWidget {
  final double gastoMes;
  final NumberFormat fmt;
  const _ResumenBanner({required this.gastoMes, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.kitchen_rounded, color: Colors.white70, size: 20),
          const SizedBox(width: 10),
          const Text('Gasto en ingredientes este mes:',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          const Spacer(),
          Text(fmt.format(gastoMes),
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
        ],
      ),
    );
  }
}

// ── Card de ingrediente ────────────────────────────────────────────────────────

class _IngredienteCard extends StatelessWidget {
  final IngredienteModel ing;
  final NumberFormat fmt;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _IngredienteCard({
    required this.ing,
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
            // Ícono
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.kitchen_rounded,
                  color: Color(0xFF1565C0), size: 22),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ing.producto,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    '${_fmtCantidad(ing.cantidad)} ${ing.unidad}  ×  ${fmt.format(ing.precioUnitario)}',
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  if (ing.proveedor.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.store_outlined,
                            size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 3),
                        Text(ing.proveedor,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500)),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Subtotal + acciones
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(fmt.format(ing.subtotal),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppConstants.primaryGreen)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      color: AppConstants.primaryGreen,
                      onPressed: onEdit,
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Editar',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      color: AppConstants.errorRed,
                      onPressed: onDelete,
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Eliminar',
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

  String _fmtCantidad(double v) =>
      v == v.truncate() ? v.toInt().toString() : v.toStringAsFixed(2);
}

// ── Empty state ────────────────────────────────────────────────────────────────

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
              color: const Color(0xFF1565C0).withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.kitchen_outlined,
                size: 56, color: Color(0xFF1565C0)),
          ),
          const SizedBox(height: 20),
          const Text('Sin ingredientes registrados',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Registra las compras de ingredientes',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_shopping_cart_rounded),
            label: const Text('Agregar ingrediente'),
          ),
        ],
      ),
    );
  }
}

// ── Formulario ─────────────────────────────────────────────────────────────────

class _IngredienteForm extends StatefulWidget {
  final IngredienteModel? ingrediente;
  final WidgetRef ref;
  const _IngredienteForm({this.ingrediente, required this.ref});

  @override
  State<_IngredienteForm> createState() => _IngredienteFormState();
}

class _IngredienteFormState extends State<_IngredienteForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _productoCtrl;
  late final TextEditingController _cantidadCtrl;
  late final TextEditingController _precioCtrl;
  late final TextEditingController _proveedorCtrl;
  late String _unidad;
  late DateTime _fecha;
  bool _guardando = false;

  bool get _esEdicion => widget.ingrediente != null;

  @override
  void initState() {
    super.initState();
    final ing = widget.ingrediente;
    _productoCtrl = TextEditingController(text: ing?.producto ?? '');
    _cantidadCtrl = TextEditingController(
        text: ing != null ? _fmtNum(ing.cantidad) : '');
    _precioCtrl = TextEditingController(
        text: ing != null ? ing.precioUnitario.toStringAsFixed(2) : '');
    _proveedorCtrl = TextEditingController(text: ing?.proveedor ?? '');
    _unidad = ing?.unidad ?? 'kg';
    _fecha = ing?.fecha ?? DateTime.now();
  }

  @override
  void dispose() {
    _productoCtrl.dispose();
    _cantidadCtrl.dispose();
    _precioCtrl.dispose();
    _proveedorCtrl.dispose();
    super.dispose();
  }

  String _fmtNum(double v) =>
      v == v.truncate() ? v.toInt().toString() : v.toStringAsFixed(2);

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

    final cantidad = double.parse(_cantidadCtrl.text.replaceAll(',', '.'));
    final precio = double.parse(_precioCtrl.text.replaceAll(',', '.'));
    final notifier = widget.ref.read(ingredientesProvider.notifier);

    if (_esEdicion) {
      await notifier.actualizar(widget.ingrediente!.copyWith(
        producto: _productoCtrl.text.trim(),
        cantidad: cantidad,
        unidad: _unidad,
        precioUnitario: precio,
        proveedor: _proveedorCtrl.text.trim(),
        fecha: _fecha,
      ));
    } else {
      await notifier.agregar(IngredienteModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        producto: _productoCtrl.text.trim(),
        cantidad: cantidad,
        unidad: _unidad,
        precioUnitario: precio,
        proveedor: _proveedorCtrl.text.trim(),
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
                _esEdicion ? 'Editar ingrediente' : 'Nuevo ingrediente',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0)),
              ),
              const SizedBox(height: 20),

              // Producto
              TextFormField(
                controller: _productoCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Producto *',
                  prefixIcon: Icon(Icons.fastfood_outlined),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Ingresa el producto' : null,
              ),
              const SizedBox(height: 14),

              // Cantidad + Unidad en una fila
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _cantidadCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*[,.]?\d{0,3}')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Cantidad *',
                        prefixIcon: Icon(Icons.scale_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Requerido';
                        final d = double.tryParse(v.replaceAll(',', '.'));
                        if (d == null || d <= 0) return 'Inválido';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      key: ValueKey(_unidad),
                      initialValue: _unidad,
                      decoration: const InputDecoration(labelText: 'Unidad'),
                      items: IngredienteModel.unidades
                          .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                          .toList(),
                      onChanged: (v) => setState(() => _unidad = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Precio unitario
              TextFormField(
                controller: _precioCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*[,.]?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Precio unitario (S/.) *',
                  prefixIcon: Icon(Icons.attach_money_rounded),
                  prefixText: 'S/. ',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Ingresa el precio';
                  final d = double.tryParse(v.replaceAll(',', '.'));
                  if (d == null || d < 0) return 'Precio inválido';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Proveedor
              TextFormField(
                controller: _proveedorCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Proveedor',
                  prefixIcon: Icon(Icons.store_outlined),
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
                    labelText: 'Fecha de compra',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(fmtFecha.format(_fecha)),
                ),
              ),
              const SizedBox(height: 24),

              // Subtotal preview
              if (_cantidadCtrl.text.isNotEmpty && _precioCtrl.text.isNotEmpty)
                _SubtotalPreview(
                  cantidad: double.tryParse(
                          _cantidadCtrl.text.replaceAll(',', '.')) ??
                      0,
                  precio:
                      double.tryParse(_precioCtrl.text.replaceAll(',', '.')) ??
                          0,
                  unidad: _unidad,
                ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _guardando ? null : _guardar,
                  child: _guardando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(_esEdicion
                          ? 'Guardar cambios'
                          : 'Registrar ingrediente'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubtotalPreview extends StatelessWidget {
  final double cantidad;
  final double precio;
  final String unidad;
  const _SubtotalPreview(
      {required this.cantidad, required this.precio, required this.unidad});

  @override
  Widget build(BuildContext context) {
    final subtotal = cantidad * precio;
    final fmt = NumberFormat.currency(
        locale: AppConstants.localeCode,
        symbol: '${AppConstants.currencySymbol} ',
        decimalDigits: 2);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppConstants.primaryGreen.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppConstants.primaryGreen.withAlpha(60)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calculate_outlined,
              color: AppConstants.primaryGreen, size: 18),
          const SizedBox(width: 8),
          Text('Subtotal: ',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
          const Spacer(),
          Text(fmt.format(subtotal),
              style: const TextStyle(
                  color: AppConstants.primaryGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
        ],
      ),
    );
  }
}
