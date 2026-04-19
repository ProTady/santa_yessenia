import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/supabase/sync_service.dart';
import '../../../core/wifi_sync/wifi_events.dart';
import '../models/asistencia_model.dart';

// ── Notifier ──────────────────────────────────────────────────────────────────

class AsistenciasNotifier extends Notifier<List<AsistenciaModel>> {
  Box get _box => Hive.box(AppConstants.asistenciasBox);
  static const _table = 'asistencias';

  @override
  List<AsistenciaModel> build() {
    final channel = SyncService.subscribe(_table, _pullFromSupabase);
    ref.onDispose(() => Supabase.instance.client.removeChannel(channel));
    final wifiSub = WifiEvents.tableUpdated
        .where((t) => t == _table)
        .listen((_) => state = _cargar());
    ref.onDispose(wifiSub.cancel);
    _pullFromSupabase();
    return _cargar();
  }

  List<AsistenciaModel> _cargar() {
    return _box.values
        .whereType<Map>()
        .map((m) => AsistenciaModel.fromMap(m))
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

  /// Marcar/actualizar asistencia de un trabajador en una fecha
  Future<void> marcar(AsistenciaModel a) async {
    await _box.put(a.id, a.toMap());
    state = _cargar();
    SyncService.upsert(_table, a.toMap());
  }

  /// Eliminar asistencia (solo si existe)
  Future<void> eliminar(String id) async {
    await _box.delete(id);
    state = _cargar();
    SyncService.delete(_table, id);
  }
}

final asistenciasProvider =
    NotifierProvider<AsistenciasNotifier, List<AsistenciaModel>>(
        AsistenciasNotifier.new);

// ── Providers derivados ───────────────────────────────────────────────────────

/// Asistencias de un día específico
final asistenciasDiaProvider =
    Provider.family<List<AsistenciaModel>, DateTime>((ref, fecha) {
  final fechaStr =
      '${fecha.year.toString().padLeft(4, '0')}-'
      '${fecha.month.toString().padLeft(2, '0')}-'
      '${fecha.day.toString().padLeft(2, '0')}';
  return ref
      .watch(asistenciasProvider)
      .where((a) => a.fecha == fechaStr)
      .toList();
});

/// Asistencia de un trabajador en un día (puede ser null si no marcada)
final asistenciaWorkerDiaProvider =
    Provider.family<AsistenciaModel?, ({String personalId, DateTime fecha})>(
        (ref, args) {
  final lista = ref.watch(asistenciasDiaProvider(args.fecha));
  try {
    return lista.firstWhere((a) => a.personalId == args.personalId);
  } catch (_) {
    return null;
  }
});
