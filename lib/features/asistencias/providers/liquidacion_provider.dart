import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../personal/models/personal_model.dart';
import '../../personal/providers/personal_provider.dart';
import '../models/asistencia_model.dart';
import 'asistencias_provider.dart';
import 'beneficios_provider.dart';

/// Costo real del personal en el mes actual, basado en asistencias marcadas.
/// Si no hay asistencias marcadas para un trabajador, su aporte es 0.
final gastoPersonalRealMesProvider = Provider<double>((ref) {
  final now = DateTime.now();
  final primerDia = DateTime(now.year, now.month, 1);
  final ultimoDia = DateTime(now.year, now.month + 1, 1);

  final personal    = ref.watch(personalActivoProvider);
  final asistencias = ref.watch(asistenciasProvider);
  final beneficios  = ref.watch(beneficiosProvider);

  double total = 0;

  for (final p in personal) {
    final asMes = asistencias.where((a) {
      if (a.personalId != p.id) return false;
      final d = a.fechaDate;
      return !d.isBefore(primerDia) && d.isBefore(ultimoDia);
    });

    final diasEf = asMes.fold(0.0, (s, a) => s + a.estado.fraccion);
    final base   = diasEf * p.sueldoDiario;

    if (p.regimen == Regimen.general && base > 0) {
      total += base +
          base * beneficios.gratificacionFactor +
          base * beneficios.ctsFactor +
          base * beneficios.vacacionesFactor +
          base * beneficios.essaludFactor;
    } else {
      total += base;
    }
  }

  return total;
});

/// ¿Hay asistencias registradas en el mes actual?
final tieneAsistenciasMesProvider = Provider<bool>((ref) {
  final now = DateTime.now();
  final primerDia = DateTime(now.year, now.month, 1);
  final ultimoDia = DateTime(now.year, now.month + 1, 1);
  return ref.watch(asistenciasProvider).any((a) {
    final d = a.fechaDate;
    return !d.isBefore(primerDia) && d.isBefore(ultimoDia);
  });
});
