import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../models/suministro_model.dart';
import '../providers/suministros_provider.dart';

class SuministrosScreen extends ConsumerWidget {
  const SuministrosScreen({super.key});

  static const _colorCategoria = {
    'Gas': Color(0xFFE65100),
    'Utensilios': Color(0xFF6A1B9A),
    'Limpieza': Color(0xFF00838F),
    'Menaje': Color(0xFF4527A0),
    'Electricidad': Color(0xFFF9A825),
    'Agua': Color(0xFF0277BD),
    'Otros': Color(0xFF37474F),
  };

  static const _iconCategoria = {
    'Gas': Icons.propane_tank_rounded,
    'Utensilios': Icons.kitchen_rounded,
    'Limpieza': Icons.cleaning_services_rounded,
    'Menaje': Icons.soup_kitchen_rounded,
    'Electricidad': Icons.bolt_rounded,
    'Agua': Icons.water_drop_rounded,
    'Otros': Icons.inventory_2_rounded,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lista = ref.watch(suministrosProvider);
    final gastoMes = ref.watch(gastoSuministrosMesProvider);
    final fmt = _fmtCurrency();

    // Agrupar por categoría para las tabs
    final fijos = lista.where((s) => s.tipo == TipoSuministro.fijo).toList();
    final variables =
        lista.where((s) => s.tipo == TipoSuministro.variable).toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Suministros'),
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(text: 'Todos (${lista.length})'),
              Tab(text: 'Fijos (${fijos.length})'),
              Tab(text: 'Variables (${variables.length})'),
            ],
          ),
        ),
        drawer: const AppDrawer(currentRoute: '/suministros'),
        body: SafeArea(
          top: false,
          child: lista.isEmpty
            ? _EmptyState(onAdd: () => _mostrarFormulario(context, ref))
            : Column(
                children: [
                  _ResumenBanner(gastoMes: gastoMes, fmt: fmt, lista: lista),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _ListaSuministros(
                          items: lista,
                          fmt: fmt,
                          colorMap: _colorCategoria,
                          iconMap: _iconCategoria,
                          onEdit: (s) => _mostrarFormulario(context, ref, s),
                          onDelete: (s) =>
                              _confirmarEliminar(context, ref, s),
                        ),
                        _ListaSuministros(
                          items: fijos,
                          fmt: fmt,
                          colorMap: _colorCategoria,
                          iconMap: _iconCategoria,
                          onEdit: (s) => _mostrarFormulario(context, ref, s),
                          onDelete: (s) =>
                              _confirmarEliminar(context, ref, s),
                        ),
                        _ListaSuministros(
                          items: variables,
                          fmt: fmt,
                          colorMap: _colorCategoria,
                          iconMap: _iconCategoria,
                          onEdit: (s) => _mostrarFormulario(context, ref, s),
                          onDelete: (s) =>
                              _confirmarEliminar(context, ref, s),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _mostrarFormulario(context, ref),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Agregar'),
        ),
      ),
    );
  }

  void _mostrarFormulario(BuildContext context, WidgetRef ref,
      [SuministroModel? s]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SuministroForm(suministro: s, ref: ref),
    );
  }

  void _confirmarEliminar(
      BuildContext context, WidgetRef ref, SuministroModel s) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar suministro'),
        content: Text('¿Eliminar "${s.nombre}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.errorRed),
            onPressed: () {
              ref.read(suministrosProvider.notifier).eliminar(s.id);
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
  final List<SuministroModel> lista;

  const _ResumenBanner(
      {required this.gastoMes, required this.fmt, required this.lista});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final primerDia = DateTime(now.year, now.month, 1);
    final fijos = lista.where((s) =>
        s.tipo == TipoSuministro.fijo && !s.fecha.isBefore(primerDia));
    final variables = lista.where((s) =>
        s.tipo == TipoSuministro.variable && !s.fecha.isBefore(primerDia));
    final totalFijos = fijos.fold(0.0, (s, e) => s + e.costo);
    final totalVariables = variables.fold(0.0, (s, e) => s + e.costo);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF6A1B9A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_rounded,
                  color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              const Text('Total suministros este mes:',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              const Spacer(),
              Text(fmt.format(gastoMes),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _MiniChip(
                  label: 'Fijos',
                  valor: fmt.format(totalFijos),
                  color: Colors.white24),
              const SizedBox(width: 8),
              _MiniChip(
                  label: 'Variables',
                  valor: fmt.format(totalVariables),
                  color: Colors.white24),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final String valor;
  final Color color;
  const _MiniChip(
      {required this.label, required this.valor, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ',
              style:
                  const TextStyle(color: Colors.white70, fontSize: 11)),
          Text(valor,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 11)),
        ],
      ),
    );
  }
}

// ── Lista ──────────────────────────────────────────────────────────────────────

class _ListaSuministros extends StatelessWidget {
  final List<SuministroModel> items;
  final NumberFormat fmt;
  final Map<String, Color> colorMap;
  final Map<String, IconData> iconMap;
  final void Function(SuministroModel) onEdit;
  final void Function(SuministroModel) onDelete;

  const _ListaSuministros({
    required this.items,
    required this.fmt,
    required this.colorMap,
    required this.iconMap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text('Sin registros',
            style: TextStyle(color: Colors.grey.shade400)),
      );
    }
    final fmtFecha = DateFormat('dd/MM/yyyy', 'es');
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final s = items[i];
        final color =
            colorMap[s.categoria] ?? const Color(0xFF37474F);
        final icon =
            iconMap[s.categoria] ?? Icons.inventory_2_rounded;
        return Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.nombre,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          _Badge(
                              label: s.categoria,
                              color: color),
                          const SizedBox(width: 6),
                          _Badge(
                            label: s.tipo == TipoSuministro.fijo
                                ? 'Fijo'
                                : 'Variable',
                            color: s.tipo == TipoSuministro.fijo
                                ? AppConstants.primaryGreen
                                : Colors.orange,
                          ),
                        ],
                      ),
                      if (s.descripcion != null &&
                          s.descripcion!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(s.descripcion!,
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                      const SizedBox(height: 2),
                      Text(fmtFecha.format(s.fecha),
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade400)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(fmt.format(s.costo),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF6A1B9A))),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          color: AppConstants.primaryGreen,
                          onPressed: () => onEdit(s),
                          visualDensity: VisualDensity.compact,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          color: AppConstants.errorRed,
                          onPressed: () => onDelete(s),
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
      },
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600)),
    );
  }
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
              color: const Color(0xFF6A1B9A).withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.propane_tank_outlined,
                size: 56, color: Color(0xFF6A1B9A)),
          ),
          const SizedBox(height: 20),
          const Text('Sin suministros registrados',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Registra gas, utensilios y otros gastos',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Agregar suministro'),
          ),
        ],
      ),
    );
  }
}

// ── Formulario ─────────────────────────────────────────────────────────────────

class _SuministroForm extends StatefulWidget {
  final SuministroModel? suministro;
  final WidgetRef ref;
  const _SuministroForm({this.suministro, required this.ref});

  @override
  State<_SuministroForm> createState() => _SuministroFormState();
}

class _SuministroFormState extends State<_SuministroForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _costoCtrl;
  late final TextEditingController _descCtrl;
  late String _categoria;
  late TipoSuministro _tipo;
  late DateTime _fecha;
  bool _guardando = false;

  bool get _esEdicion => widget.suministro != null;

  @override
  void initState() {
    super.initState();
    final s = widget.suministro;
    _nombreCtrl = TextEditingController(text: s?.nombre ?? '');
    _costoCtrl = TextEditingController(
        text: s != null ? s.costo.toStringAsFixed(2) : '');
    _descCtrl = TextEditingController(text: s?.descripcion ?? '');
    _categoria = s?.categoria ?? 'Gas';
    _tipo = s?.tipo ?? TipoSuministro.variable;
    _fecha = s?.fecha ?? DateTime.now();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
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
    final notifier = widget.ref.read(suministrosProvider.notifier);

    if (_esEdicion) {
      await notifier.actualizar(widget.suministro!.copyWith(
        nombre: _nombreCtrl.text.trim(),
        categoria: _categoria,
        tipo: _tipo,
        costo: costo,
        descripcion: _descCtrl.text.trim(),
        fecha: _fecha,
      ));
    } else {
      await notifier.agregar(SuministroModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nombre: _nombreCtrl.text.trim(),
        categoria: _categoria,
        tipo: _tipo,
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
                _esEdicion ? 'Editar suministro' : 'Nuevo suministro',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6A1B9A)),
              ),
              const SizedBox(height: 20),

              // Nombre
              TextFormField(
                controller: _nombreCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                  hintText: 'Ej: Gas doméstico 10kg',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Ingresa el nombre' : null,
              ),
              const SizedBox(height: 14),

              // Categoría
              DropdownButtonFormField<String>(
                key: ValueKey(_categoria),
                initialValue: _categoria,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: SuministroModel.categorias
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _categoria = v!),
              ),
              const SizedBox(height: 14),

              // Tipo: Fijo / Variable
              const Text('Tipo de gasto',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _TipoBtn(
                      label: 'Fijo',
                      sublabel: 'Se repite cada mes',
                      icon: Icons.repeat_rounded,
                      selected: _tipo == TipoSuministro.fijo,
                      color: AppConstants.primaryGreen,
                      onTap: () =>
                          setState(() => _tipo = TipoSuministro.fijo),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TipoBtn(
                      label: 'Variable',
                      sublabel: 'Compra puntual',
                      icon: Icons.swap_horiz_rounded,
                      selected: _tipo == TipoSuministro.variable,
                      color: Colors.orange,
                      onTap: () =>
                          setState(() => _tipo = TipoSuministro.variable),
                    ),
                  ),
                ],
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
                  labelText: 'Costo (S/.) *',
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

              // Descripción (opcional)
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
                  onPressed: _guardando ? null : _guardar,
                  child: _guardando
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(_esEdicion
                          ? 'Guardar cambios'
                          : 'Registrar suministro'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipoBtn extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TipoBtn({
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(25) : Colors.grey.shade50,
          border: Border.all(
              color: selected ? color : Colors.grey.shade300, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? color : Colors.grey, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: selected ? color : Colors.grey.shade700)),
                Text(sublabel,
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey.shade500)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
