import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../models/comensal_model.dart';

// Fecha activa del visor (hoy por defecto)
class FechaActivaNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void cambiar(DateTime fecha) => state = fecha;
}

final fechaActivaProvider =
    NotifierProvider<FechaActivaNotifier, DateTime>(FechaActivaNotifier.new);

class ComensalesNotifier extends Notifier<List<ComensalModel>> {
  Box get _box => Hive.box(AppConstants.comensalesBox);

  @override
  List<ComensalModel> build() => _cargar();

  List<ComensalModel> _cargar() {
    return _box.values
        .whereType<Map>()
        .map((m) => ComensalModel.fromMap(m))
        .toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
  }

  Future<void> agregar(ComensalModel c) async {
    await _box.put(c.id, c.toMap());
    state = _cargar();
  }

  Future<void> actualizar(ComensalModel c) async {
    await _box.put(c.id, c.toMap());
    state = _cargar();
  }

  Future<void> eliminar(String id) async {
    await _box.delete(id);
    state = _cargar();
  }
}

final comensalesProvider =
    NotifierProvider<ComensalesNotifier, List<ComensalModel>>(
        ComensalesNotifier.new);

// Filtrado por fecha activa
final comensalesDiaProvider = Provider<List<ComensalModel>>((ref) {
  final fecha = ref.watch(fechaActivaProvider);
  final todos = ref.watch(comensalesProvider);
  return todos.where((c) {
    final d = c.fecha;
    return d.year == fecha.year && d.month == fecha.month && d.day == fecha.day;
  }).toList();
});

// Resumen del día activo
class ResumenDia {
  final int totalComensales;
  final int normales;
  final int dietas;
  final int conExtra;
  final double totalEmpresa;   // normales + dietas (sin extra)
  final double totalAdicional; // solo extras
  final double grandTotal;     // todo junto

  const ResumenDia({
    required this.totalComensales,
    required this.normales,
    required this.dietas,
    required this.conExtra,
    required this.totalEmpresa,
    required this.totalAdicional,
    required this.grandTotal,
  });
}

final resumenDiaProvider = Provider<ResumenDia>((ref) {
  final lista = ref.watch(comensalesDiaProvider);
  final normales  = lista.where((c) => c.tipoPlato == TipoPlato.normal).length;
  final dietas    = lista.where((c) => c.tipoPlato == TipoPlato.dieta).length;
  final conExtra  = lista.where((c) => c.tieneExtra).length;
  final totalBase = lista.fold(0.0, (s, c) => s + c.costoPlato);
  final totalAdicional = lista.fold(0.0, (s, c) => s + c.totalAdicional);
  return ResumenDia(
    totalComensales: lista.length,
    normales: normales,
    dietas: dietas,
    conExtra: conExtra,
    totalEmpresa: totalBase,
    totalAdicional: totalAdicional,
    grandTotal: totalBase + totalAdicional,
  );
});
