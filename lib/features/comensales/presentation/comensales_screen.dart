import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../models/comensal_model.dart';
import '../providers/comensales_provider.dart';
import 'comensal_form.dart';
import 'costos_config_dialog.dart';

class ComensalesScreen extends ConsumerWidget {
  const ComensalesScreen({super.key});

  static const _color = Color(0xFF00838F);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fecha = ref.watch(fechaActivaProvider);
    final lista = ref.watch(comensalesDiaProvider);
    final resumen = ref.watch(resumenDiaProvider);
    final fmt = _fmt();
    final fmtFecha = DateFormat('EEEE, dd/MM/yyyy', 'es');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comensales'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configurar precios',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const CostosConfigDialog(),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/comensales'),
      body: Column(
        children: [
          // ── Selector de fecha ─────────────────────────────────────
          _DateBar(fecha: fecha, fmtFecha: fmtFecha, ref: ref),

          // ── Resumen del día ───────────────────────────────────────
          _ResumenDia(resumen: resumen, fmt: fmt),

          const SizedBox(height: 8),

          // ── Lista ─────────────────────────────────────────────────
          Expanded(
            child: lista.isEmpty
                ? _EmptyState(
                    onAdd: () => _abrirFormulario(context, ref))
                : _ListaComensales(
                    lista: lista,
                    fmt: fmt,
                    onEdit: (c) => _abrirFormulario(context, ref, c),
                    onDelete: (c) => _confirmarEliminar(context, ref, c),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _color,
        onPressed: () => _abrirFormulario(context, ref),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Registrar'),
      ),
    );
  }

  void _abrirFormulario(BuildContext context, WidgetRef ref,
      [ComensalModel? comensal]) {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => ComensalForm(comensal: comensal, providerRef: ref),
    ));
  }

  void _confirmarEliminar(
      BuildContext context, WidgetRef ref, ComensalModel c) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar comensal'),
        content: Text('¿Eliminar el registro de ${c.nombre}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.errorRed),
            onPressed: () {
              ref.read(comensalesProvider.notifier).eliminar(c.id);
              Navigator.pop(context);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  NumberFormat _fmt() => NumberFormat.currency(
      locale: AppConstants.localeCode,
      symbol: '${AppConstants.currencySymbol} ',
      decimalDigits: 2);
}

// ── Date bar ───────────────────────────────────────────────────────────────────

class _DateBar extends StatelessWidget {
  final DateTime fecha;
  final DateFormat fmtFecha;
  final WidgetRef ref;
  const _DateBar(
      {required this.fecha, required this.fmtFecha, required this.ref});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isHoy = fecha.year == now.year &&
        fecha.month == now.month &&
        fecha.day == now.day;

    return Container(
      color: const Color(0xFF00838F),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded,
                color: Colors.white, size: 28),
            onPressed: () => ref
                .read(fechaActivaProvider.notifier)
                .cambiar(fecha.subtract(const Duration(days: 1))),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: fecha,
                  firstDate: DateTime(2020),
                  lastDate: now,
                  locale: const Locale('es', 'PE'),
                );
                if (picked != null) {
                  ref.read(fechaActivaProvider.notifier).cambiar(
                      DateTime(picked.year, picked.month, picked.day));
                }
              },
              child: Column(
                children: [
                  Text(
                    _capitalize(fmtFecha.format(fecha)),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                  if (isHoy)
                    const Text('Hoy',
                        style:
                            TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right_rounded,
                color: isHoy ? Colors.white38 : Colors.white, size: 28),
            onPressed: isHoy
                ? null
                : () => ref
                    .read(fechaActivaProvider.notifier)
                    .cambiar(fecha.add(const Duration(days: 1))),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ── Resumen del día ────────────────────────────────────────────────────────────

class _ResumenDia extends StatelessWidget {
  final ResumenDia resumen;
  final NumberFormat fmt;
  const _ResumenDia({required this.resumen, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF00838F).withAlpha(15),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        children: [
          // Fila 1: contadores
          Row(
            children: [
              _Counter(
                label: 'Total',
                valor: resumen.totalComensales,
                icon: Icons.people_rounded,
                color: const Color(0xFF00838F),
              ),
              _Counter(
                label: 'Normal',
                valor: resumen.normales,
                icon: Icons.restaurant_rounded,
                color: AppConstants.primaryGreen,
              ),
              _Counter(
                label: 'Dieta',
                valor: resumen.dietas,
                icon: Icons.eco_rounded,
                color: Colors.teal,
              ),
              _Counter(
                label: 'Extra',
                valor: resumen.conExtra,
                icon: Icons.add_circle_rounded,
                color: Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Fila 2: montos
          Row(
            children: [
              Expanded(
                child: _MontoChip(
                  label: 'Platos empresa',
                  valor: fmt.format(resumen.totalEmpresa),
                  color: AppConstants.primaryGreen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MontoChip(
                  label: 'Adicionales',
                  valor: fmt.format(resumen.totalAdicional),
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MontoChip(
                  label: 'Total',
                  valor: fmt.format(resumen.grandTotal),
                  color: const Color(0xFF00838F),
                  bold: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  final String label;
  final int valor;
  final IconData icon;
  final Color color;
  const _Counter(
      {required this.label,
      required this.valor,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          Text('$valor',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: color)),
          Text(label,
              style:
                  const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _MontoChip extends StatelessWidget {
  final String label;
  final String valor;
  final Color color;
  final bool bold;
  const _MontoChip(
      {required this.label,
      required this.valor,
      required this.color,
      this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(fontSize: 10, color: color),
              textAlign: TextAlign.center),
          Text(valor,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      bold ? FontWeight.bold : FontWeight.w600,
                  color: color),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Lista de comensales ────────────────────────────────────────────────────────

class _ListaComensales extends StatelessWidget {
  final List<ComensalModel> lista;
  final NumberFormat fmt;
  final void Function(ComensalModel) onEdit;
  final void Function(ComensalModel) onDelete;

  const _ListaComensales({
    required this.lista,
    required this.fmt,
    required this.onEdit,
    required this.onDelete,
  });

  // Separar en dos grupos: base y adicionales
  @override
  Widget build(BuildContext context) {
    final base = lista;
    final conExtra = lista.where((c) => c.tieneExtra).toList();

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: const Color(0xFF00838F),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF00838F),
            tabs: [
              Tab(text: 'Empresa (${base.length})'),
              Tab(text: 'Adicionales (${conExtra.length})'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Tab 1: todos los platos (cargo empresa)
                _TabEmpresa(lista: base, fmt: fmt, onEdit: onEdit, onDelete: onDelete),
                // Tab 2: solo extras
                _TabAdicionales(lista: conExtra, fmt: fmt, onEdit: onEdit, onDelete: onDelete),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabEmpresa extends StatelessWidget {
  final List<ComensalModel> lista;
  final NumberFormat fmt;
  final void Function(ComensalModel) onEdit;
  final void Function(ComensalModel) onDelete;
  const _TabEmpresa(
      {required this.lista,
      required this.fmt,
      required this.onEdit,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
      itemCount: lista.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _ComensalCard(
        comensal: lista[i],
        fmt: fmt,
        onEdit: () => onEdit(lista[i]),
        onDelete: () => onDelete(lista[i]),
      ),
    );
  }
}

class _TabAdicionales extends StatelessWidget {
  final List<ComensalModel> lista;
  final NumberFormat fmt;
  final void Function(ComensalModel) onEdit;
  final void Function(ComensalModel) onDelete;
  const _TabAdicionales(
      {required this.lista,
      required this.fmt,
      required this.onEdit,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (lista.isEmpty) {
      return Center(
        child: Text('Sin adicionales hoy',
            style: TextStyle(color: Colors.grey.shade400)),
      );
    }
    final total = lista.fold(0.0, (s, c) => s + c.costoExtra);
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total adicionales:',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              Text(fmt.format(total),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.orange)),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
            itemCount: lista.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: 8),
            itemBuilder: (context, i) => _AdicionalCard(
              comensal: lista[i],
              fmt: fmt,
              onEdit: () => onEdit(lista[i]),
              onDelete: () => onDelete(lista[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _ComensalCard extends StatelessWidget {
  final ComensalModel comensal;
  final NumberFormat fmt;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ComensalCard(
      {required this.comensal,
      required this.fmt,
      required this.onEdit,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final esNormal = comensal.tipoPlato == TipoPlato.normal;
    final color =
        esNormal ? AppConstants.primaryGreen : Colors.teal;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Firma thumbnail o avatar
            _FirmaAvatar(
                firmaBytes: comensal.firmaBytes, nombre: comensal.nombre),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(comensal.nombre,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('DNI: ${comensal.dni}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _Badge(
                        label: esNormal ? 'Normal' : 'Dieta',
                        color: color,
                      ),
                      if (comensal.tieneExtra) ...[
                        const SizedBox(width: 4),
                        _Badge(label: '+Extra', color: Colors.orange),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(fmt.format(comensal.costoPlato),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: color)),
                if (comensal.tieneExtra)
                  Text('+${fmt.format(comensal.costoExtra)}',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.orange)),
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

class _AdicionalCard extends StatelessWidget {
  final ComensalModel comensal;
  final NumberFormat fmt;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _AdicionalCard(
      {required this.comensal,
      required this.fmt,
      required this.onEdit,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange.withAlpha(12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Colors.orange, width: 0.5),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.withAlpha(40),
          child: Text(
            comensal.nombre.isNotEmpty
                ? comensal.nombre[0].toUpperCase()
                : '?',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.orange),
          ),
        ),
        title: Text(comensal.nombre,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('DNI: ${comensal.dni}',
            style: const TextStyle(fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(fmt.format(comensal.costoExtra),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.orange)),
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
      ),
    );
  }
}

class _FirmaAvatar extends StatelessWidget {
  final Uint8List? firmaBytes;
  final String nombre;
  const _FirmaAvatar({this.firmaBytes, required this.nombre});

  @override
  Widget build(BuildContext context) {
    if (firmaBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(firmaBytes!,
            width: 48, height: 48, fit: BoxFit.contain),
      );
    }
    return CircleAvatar(
      radius: 24,
      backgroundColor: const Color(0xFF00838F).withAlpha(30),
      child: Text(
        nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
        style: const TextStyle(
            color: Color(0xFF00838F),
            fontWeight: FontWeight.bold,
            fontSize: 18),
      ),
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
              color: const Color(0xFF00838F).withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people_outline_rounded,
                size: 56, color: Color(0xFF00838F)),
          ),
          const SizedBox(height: 20),
          const Text('Sin comensales registrados hoy',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Registra el primer comensal',
              style:
                  TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00838F)),
            onPressed: onAdd,
            icon: const Icon(Icons.person_add_rounded),
            label: const Text('Registrar comensal'),
          ),
        ],
      ),
    );
  }
}
