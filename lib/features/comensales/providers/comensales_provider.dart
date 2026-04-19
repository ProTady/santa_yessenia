import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/supabase/sync_service.dart';
import '../../../core/wifi_sync/wifi_events.dart';
import '../models/comensal_model.dart';

// ── Fecha activa ──────────────────────────────────────────────────────────────

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

// ── Comensales ────────────────────────────────────────────────────────────────

class ComensalesNotifier extends Notifier<List<ComensalModel>> {
  Box get _box => Hive.box(AppConstants.comensalesBox);
  static const _table = 'comensales';

  @override
  List<ComensalModel> build() {
    final channel = SyncService.subscribe(_table, _pullFromSupabase);
    ref.onDispose(() => Supabase.instance.client.removeChannel(channel));
    final wifiSub = WifiEvents.tableUpdated
        .where((t) => t == _table)
        .listen((_) => state = _cargar());
    ref.onDispose(wifiSub.cancel);
    _pullFromSupabase();
    return _cargar();
  }

  List<ComensalModel> _cargar() {
    return _box.values
        .whereType<Map>()
        .map((m) => ComensalModel.fromMap(m))
        .toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
  }

  Future<void> _pullFromSupabase() async {
    final rows = await SyncService.pull(_table);
    if (rows.isEmpty) {
      final local = _box.values.whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m)).toList();
      SyncService.pushAll(_table, local);
      return;
    }
    final remoteIds = rows.map((r) => r['id'] as String).toSet();
    for (final id in _box.keys.cast<String>().toSet().difference(remoteIds)) {
      await _box.delete(id);
    }
    for (final row in rows) {
      await _box.put(row['id'], Map<String, dynamic>.from(row));
    }
    state = _cargar();
  }

  Future<void> agregar(ComensalModel c) async {
    await _box.put(c.id, c.toMap());
    state = _cargar();
    SyncService.upsert(_table, c.toMap());
  }

  Future<void> actualizar(ComensalModel c) async {
    await _box.put(c.id, c.toMap());
    state = _cargar();
    SyncService.upsert(_table, c.toMap());
  }

  Future<void> eliminar(String id) async {
    await _box.delete(id);
    state = _cargar();
    SyncService.delete(_table, id);
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
  final double totalEmpresa;
  final double totalAdicional;
  final double grandTotal;

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
  final normales = lista.where((c) => c.tipoPlato == TipoPlato.normal).length;
  final dietas   = lista.where((c) => c.tipoPlato == TipoPlato.dieta).length;
  final conExtra = lista.where((c) => c.tieneExtra).length;
  final totalBase      = lista.fold(0.0, (s, c) => s + c.costoPlato);
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
