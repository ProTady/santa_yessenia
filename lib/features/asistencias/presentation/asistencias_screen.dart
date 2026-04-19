import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../personal/models/personal_model.dart';
import '../../personal/providers/personal_provider.dart';
import '../models/asistencia_model.dart';
import '../providers/asistencias_provider.dart';

class AsistenciasScreen extends ConsumerStatefulWidget {
  const AsistenciasScreen({super.key});

  @override
  ConsumerState<AsistenciasScreen> createState() => _AsistenciasScreenState();
}

class _AsistenciasScreenState extends ConsumerState<AsistenciasScreen> {
  late DateTime _fecha;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fecha = DateTime(now.year, now.month, now.day);
  }

  void _cambiarDia(int delta) =>
      setState(() => _fecha = _fecha.add(Duration(days: delta)));

  Future<void> _elegirFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('es', 'PE'),
    );
    if (picked != null) setState(() => _fecha = picked);
  }

  @override
  Widget build(BuildContext context) {
    final personal = ref.watch(personalProvider)
        .where((p) => p.activo)
        .toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));

    final asistenciasDia = ref.watch(asistenciasDiaProvider(_fecha));
    final presentes = asistenciasDia
        .where((a) => a.estado == EstadoAsistencia.presente)
        .length;
    final medioDia = asistenciasDia
        .where((a) => a.estado == EstadoAsistencia.medioDia)
        .length;
    final faltas = asistenciasDia
        .where((a) => a.estado == EstadoAsistencia.falta)
        .length;

    final hoy = DateTime.now();
    final esHoy = _fecha.year == hoy.year &&
        _fecha.month == hoy.month &&
        _fecha.day == hoy.day;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistencias'),
        backgroundColor: AppConstants.asistenciaColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate_rounded),
            tooltip: 'Liquidación',
            onPressed: () => context.push('/liquidacion'),
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/asistencias'),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // ── Selector de fecha ─────────────────────────────────────
            _DateNavigator(
              fecha: _fecha,
              esHoy: esHoy,
              onPrev: () => _cambiarDia(-1),
              onNext: esHoy ? null : () => _cambiarDia(1),
              onTap: _elegirFecha,
            ),

            // ── Resumen del día ───────────────────────────────────────
            if (asistenciasDia.isNotEmpty)
              _ResumenDia(
                  presentes: presentes, medioDia: medioDia, faltas: faltas),

            // ── Lista de trabajadores ─────────────────────────────────
            Expanded(
              child: personal.isEmpty
                  ? _EmptyPersonal()
                  : ListView.separated(
                      padding:
                          const EdgeInsets.fromLTRB(16, 12, 16, 90),
                      itemCount: personal.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 10),
                      itemBuilder: (ctx, i) {
                        final p = personal[i];
                        final asistencia = ref.watch(
                          asistenciaWorkerDiaProvider(
                              (personalId: p.id, fecha: _fecha)),
                        );
                        return _WorkerAsistenciaCard(
                          persona: p,
                          asistencia: asistencia,
                          fecha: _fecha,
                          onMarcar: (estado) {
                            final a = AsistenciaModel.crear(
                              personalId: p.id,
                              fecha: _fecha,
                              estado: estado,
                            );
                            ref
                                .read(asistenciasProvider.notifier)
                                .marcar(a);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      // Botón para marcar todos como presentes
      floatingActionButton: personal.isNotEmpty
          ? FloatingActionButton.extended(
              backgroundColor: AppConstants.asistenciaColor,
              onPressed: () => _marcarTodosPresentes(personal),
              icon: const Icon(Icons.done_all_rounded),
              label: const Text('Todos presentes'),
            )
          : null,
    );
  }

  void _marcarTodosPresentes(List<PersonalModel> personal) {
    for (final p in personal) {
      final a = AsistenciaModel.crear(
        personalId: p.id,
        fecha: _fecha,
        estado: EstadoAsistencia.presente,
      );
      ref.read(asistenciasProvider.notifier).marcar(a);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Todos marcados como presentes')),
    );
  }
}

// ── Date Navigator ─────────────────────────────────────────────────────────────

class _DateNavigator extends StatelessWidget {
  final DateTime fecha;
  final bool esHoy;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  final VoidCallback onTap;

  const _DateNavigator({
    required this.fecha,
    required this.esHoy,
    required this.onPrev,
    required this.onNext,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat("EEEE d 'de' MMMM, yyyy", 'es');
    return Container(
      color: AppConstants.asistenciaColor,
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded,
                color: Colors.white, size: 32),
            onPressed: onPrev,
          ),
          GestureDetector(
            onTap: onTap,
            child: Column(
              children: [
                Text(
                  esHoy ? 'HOY' : fmt.format(fecha).toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
                if (!esHoy)
                  const SizedBox.shrink()
                else
                  Text(
                    fmt.format(fecha),
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12),
                  ),
                const Icon(Icons.calendar_today_rounded,
                    color: Colors.white54, size: 14),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right_rounded,
                color: onNext != null
                    ? Colors.white
                    : Colors.white30,
                size: 32),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

// ── Resumen del día ────────────────────────────────────────────────────────────

class _ResumenDia extends StatelessWidget {
  final int presentes;
  final int medioDia;
  final int faltas;

  const _ResumenDia(
      {required this.presentes,
      required this.medioDia,
      required this.faltas});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppConstants.asistenciaColor.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppConstants.asistenciaColor.withAlpha(40)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ResumenChip(Icons.check_circle_rounded, Colors.green, '$presentes presentes'),
          _ResumenChip(Icons.timelapse_rounded, Colors.orange, '$medioDia ½ día'),
          _ResumenChip(Icons.cancel_rounded, AppConstants.errorRed, '$faltas faltas'),
        ],
      ),
    );
  }
}

class _ResumenChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  const _ResumenChip(this.icon, this.color, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}

// ── Card de trabajador ─────────────────────────────────────────────────────────

class _WorkerAsistenciaCard extends StatelessWidget {
  final PersonalModel persona;
  final AsistenciaModel? asistencia;
  final DateTime fecha;
  final void Function(EstadoAsistencia) onMarcar;

  const _WorkerAsistenciaCard({
    required this.persona,
    required this.asistencia,
    required this.fecha,
    required this.onMarcar,
  });

  @override
  Widget build(BuildContext context) {
    final estado = asistencia?.estado;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _colorEstado(estado),
                  child: Text(
                    persona.nombre.isNotEmpty
                        ? persona.nombre[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(persona.nombre,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      Row(
                        children: [
                          Text(persona.cargo,
                              style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: persona.regimen == Regimen.general
                                  ? AppConstants.asistenciaColor
                                      .withAlpha(20)
                                  : Colors.orange.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              persona.regimen == Regimen.general
                                  ? 'Gral.'
                                  : 'Eventual',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: persona.regimen == Regimen.general
                                    ? AppConstants.asistenciaColor
                                    : Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Estado actual
                if (estado != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _colorEstado(estado),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      estado.label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // Botones de marcado
            Row(
              children: [
                _EstadoBtn(
                  label: 'Presente',
                  icon: Icons.check_circle_outline_rounded,
                  color: Colors.green,
                  activo: estado == EstadoAsistencia.presente,
                  onTap: () => onMarcar(EstadoAsistencia.presente),
                ),
                const SizedBox(width: 6),
                _EstadoBtn(
                  label: '½ Día',
                  icon: Icons.timelapse_rounded,
                  color: Colors.orange,
                  activo: estado == EstadoAsistencia.medioDia,
                  onTap: () => onMarcar(EstadoAsistencia.medioDia),
                ),
                const SizedBox(width: 6),
                _EstadoBtn(
                  label: 'Falta',
                  icon: Icons.cancel_outlined,
                  color: AppConstants.errorRed,
                  activo: estado == EstadoAsistencia.falta,
                  onTap: () => onMarcar(EstadoAsistencia.falta),
                ),
                const SizedBox(width: 6),
                _EstadoBtn(
                  label: 'Descanso',
                  icon: Icons.weekend_outlined,
                  color: Colors.blueGrey,
                  activo: estado == EstadoAsistencia.descanso,
                  onTap: () => onMarcar(EstadoAsistencia.descanso),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _colorEstado(EstadoAsistencia? e) => switch (e) {
        EstadoAsistencia.presente  => Colors.green,
        EstadoAsistencia.medioDia  => Colors.orange,
        EstadoAsistencia.falta     => AppConstants.errorRed,
        EstadoAsistencia.descanso  => Colors.blueGrey,
        null                       => Colors.grey.shade400,
      };
}

class _EstadoBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool activo;
  final VoidCallback onTap;

  const _EstadoBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: activo ? color : color.withAlpha(18),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: activo ? color : color.withAlpha(60),
              width: activo ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 18,
                  color: activo ? Colors.white : color),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: activo ? Colors.white : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyPersonal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded,
              size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text('Sin personal activo registrado',
              style:
                  TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Agrega trabajadores en el módulo Personal',
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 13)),
        ],
      ),
    );
  }
}
