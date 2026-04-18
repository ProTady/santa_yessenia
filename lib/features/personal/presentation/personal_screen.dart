import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../models/personal_model.dart';
import '../providers/personal_provider.dart';

class PersonalScreen extends ConsumerWidget {
  const PersonalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lista = ref.watch(personalProvider);
    final gastoMensual = ref.watch(gastoPersonalMensualProvider);
    final fmt = NumberFormat.currency(
        locale: AppConstants.localeCode,
        symbol: '${AppConstants.currencySymbol} ',
        decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal'),
        actions: [
          if (lista.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  '${lista.length} trabajador${lista.length == 1 ? '' : 'es'}',
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ),
            ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/personal'),
      body: SafeArea(
        top: false,
        child: lista.isEmpty
          ? _EmptyState(onAdd: () => _mostrarFormulario(context, ref))
          : Column(
              children: [
                // ── Resumen mensual ───────────────────────────────────
                _ResumenBanner(gastoMensual: gastoMensual, fmt: fmt),

                // ── Lista ─────────────────────────────────────────────
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                    itemCount: lista.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _PersonalCard(
                      persona: lista[i],
                      fmt: fmt,
                      onEdit: () => _mostrarFormulario(context, ref, lista[i]),
                      onDelete: () => _confirmarEliminar(context, ref, lista[i]),
                      onToggle: () =>
                          ref.read(personalProvider.notifier).toggleActivo(lista[i]),
                    ),
                  ),
                ),
              ],
            ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormulario(context, ref),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Agregar'),
      ),
    );
  }

  void _mostrarFormulario(BuildContext context, WidgetRef ref,
      [PersonalModel? persona]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PersonalForm(persona: persona, ref: ref),
    );
  }

  void _confirmarEliminar(
      BuildContext context, WidgetRef ref, PersonalModel p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar trabajador'),
        content: Text('¿Eliminar a ${p.nombre}? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.errorRed),
            onPressed: () {
              ref.read(personalProvider.notifier).eliminar(p.id);
              Navigator.pop(context);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

// ── Resumen mensual ────────────────────────────────────────────────────────────

class _ResumenBanner extends StatelessWidget {
  final double gastoMensual;
  final NumberFormat fmt;

  const _ResumenBanner({required this.gastoMensual, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppConstants.primaryGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_rounded,
              color: Colors.white70, size: 20),
          const SizedBox(width: 10),
          const Text('Costo mensual estimado (26 días):',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          const Spacer(),
          Text(
            fmt.format(gastoMensual),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

// ── Card de trabajador ─────────────────────────────────────────────────────────

class _PersonalCard extends StatelessWidget {
  final PersonalModel persona;
  final NumberFormat fmt;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const _PersonalCard({
    required this.persona,
    required this.fmt,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar con inicial
                CircleAvatar(
                  radius: 22,
                  backgroundColor: persona.activo
                      ? AppConstants.primaryGreen
                      : Colors.grey.shade400,
                  child: Text(
                    persona.nombre.isNotEmpty
                        ? persona.nombre[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        persona.nombre,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        persona.cargo,
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                // Badge activo/inactivo
                GestureDetector(
                  onTap: onToggle,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: persona.activo
                          ? AppConstants.incomeColor.withAlpha(25)
                          : Colors.grey.withAlpha(30),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      persona.activo ? 'Activo' : 'Inactivo',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: persona.activo
                            ? AppConstants.incomeColor
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Sueldos
            Row(
              children: [
                _SueldoChip(
                  label: 'Diario',
                  value: fmt.format(persona.sueldoDiario),
                  icon: Icons.today_rounded,
                ),
                const SizedBox(width: 10),
                _SueldoChip(
                  label: 'Mensual (×26)',
                  value: fmt.format(persona.sueldoMensual),
                  icon: Icons.calendar_month_rounded,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  color: AppConstants.primaryGreen,
                  onPressed: onEdit,
                  tooltip: 'Editar',
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: AppConstants.errorRed,
                  onPressed: onDelete,
                  tooltip: 'Eliminar',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SueldoChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SueldoChip(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
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
              color: AppConstants.primaryGreen.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people_outline_rounded,
                size: 56, color: AppConstants.primaryGreen),
          ),
          const SizedBox(height: 20),
          const Text('Sin trabajadores registrados',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Agrega al personal del servicio',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.person_add_rounded),
            label: const Text('Agregar trabajador'),
          ),
        ],
      ),
    );
  }
}

// ── Formulario (bottom sheet) ──────────────────────────────────────────────────

class _PersonalForm extends StatefulWidget {
  final PersonalModel? persona;
  final WidgetRef ref;

  const _PersonalForm({this.persona, required this.ref});

  @override
  State<_PersonalForm> createState() => _PersonalFormState();
}

class _PersonalFormState extends State<_PersonalForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _cargoCtrl;
  late final TextEditingController _sueldoCtrl;
  bool _guardando = false;

  bool get _esEdicion => widget.persona != null;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.persona?.nombre ?? '');
    _cargoCtrl = TextEditingController(text: widget.persona?.cargo ?? '');
    _sueldoCtrl = TextEditingController(
        text: widget.persona?.sueldoDiario.toStringAsFixed(2) ?? '');
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _cargoCtrl.dispose();
    _sueldoCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    final sueldo = double.parse(_sueldoCtrl.text.replaceAll(',', '.'));
    final notifier = widget.ref.read(personalProvider.notifier);

    if (_esEdicion) {
      await notifier.actualizar(widget.persona!.copyWith(
        nombre: _nombreCtrl.text.trim(),
        cargo: _cargoCtrl.text.trim(),
        sueldoDiario: sueldo,
      ));
    } else {
      await notifier.agregar(PersonalModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nombre: _nombreCtrl.text.trim(),
        cargo: _cargoCtrl.text.trim(),
        sueldoDiario: sueldo,
      ));
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
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

            Text(
              _esEdicion ? 'Editar trabajador' : 'Nuevo trabajador',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryGreen),
            ),
            const SizedBox(height: 20),

            // Nombre
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
            const SizedBox(height: 14),

            // Cargo
            TextFormField(
              controller: _cargoCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Cargo / Puesto *',
                prefixIcon: Icon(Icons.work_outline_rounded),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ingresa el cargo' : null,
            ),
            const SizedBox(height: 14),

            // Sueldo diario
            TextFormField(
              controller: _sueldoCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*[,.]?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Sueldo diario (S/.) *',
                prefixIcon: Icon(Icons.payments_outlined),
                prefixText: 'S/. ',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Ingresa el sueldo';
                final d = double.tryParse(v.replaceAll(',', '.'));
                if (d == null || d <= 0) return 'Sueldo inválido';
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Botón guardar
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
                    : Text(_esEdicion ? 'Guardar cambios' : 'Agregar trabajador'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
