import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/supabase/sync_service.dart';
import '../../../core/wifi_sync/wifi_events.dart';
import '../models/ingreso_model.dart';

class IngresosNotifier extends Notifier<List<IngresoModel>> {
  Box get _box => Hive.box(AppConstants.ingresosBox);
  static const _table = 'ingresos';

  @override
  List<IngresoModel> build() {
    final channel = SyncService.subscribe(_table, _pullFromSupabase);
    ref.onDispose(() => Supabase.instance.client.removeChannel(channel));
    final wifiSub = WifiEvents.tableUpdated
        .where((t) => t == _table)
        .listen((_) => state = _cargar());
    ref.onDispose(wifiSub.cancel);
    _pullFromSupabase();
    return _cargar();
  }

  List<IngresoModel> _cargar() {
    return _box.values
        .whereType<Map>()
        .map((m) => IngresoModel.fromMap(m))
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

  Future<void> agregar(IngresoModel i) async {
    await _box.put(i.id, i.toMap());
    state = _cargar();
    SyncService.upsert(_table, i.toMap());
  }

  Future<void> actualizar(IngresoModel i) async {
    await _box.put(i.id, i.toMap());
    state = _cargar();
    SyncService.upsert(_table, i.toMap());
  }

  Future<void> eliminar(String id) async {
    await _box.delete(id);
    state = _cargar();
    SyncService.delete(_table, id);
  }
}

final ingresosProvider =
    NotifierProvider<IngresosNotifier, List<IngresoModel>>(
        IngresosNotifier.new);

final totalIngresosMesProvider = Provider<double>((ref) {
  final now = DateTime.now();
  final primerDia = DateTime(now.year, now.month, 1);
  return ref.watch(ingresosProvider).fold(0.0, (sum, i) {
    if (!i.fecha.isBefore(primerDia)) return sum + i.monto;
    return sum;
  });
});
