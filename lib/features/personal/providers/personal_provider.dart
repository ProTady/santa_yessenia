import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/supabase/sync_service.dart';
import '../../../core/wifi_sync/wifi_events.dart';
import '../models/personal_model.dart';

class PersonalNotifier extends Notifier<List<PersonalModel>> {
  Box get _box => Hive.box(AppConstants.personalBox);
  static const _table = 'personal';

  @override
  List<PersonalModel> build() {
    // Real-time: actualiza al recibir cambios de otros dispositivos
    final channel = SyncService.subscribe(_table, _pullFromSupabase);
    ref.onDispose(() => Supabase.instance.client.removeChannel(channel));
    final wifiSub = WifiEvents.tableUpdated
        .where((t) => t == _table)
        .listen((_) => state = _cargar());
    ref.onDispose(wifiSub.cancel);
    _pullFromSupabase();
    return _cargar();
  }

  List<PersonalModel> _cargar() {
    return _box.values
        .whereType<Map>()
        .map((m) => PersonalModel.fromMap(m))
        .toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
  }

  Future<void> _pullFromSupabase() async {
    final rows = await SyncService.pull(_table);
    if (rows.isEmpty) {
      // Supabase vacío → sube datos locales (primera sincronización)
      final local = _box.values.whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m)).toList();
      SyncService.pushAll(_table, local);
      return;
    }
    final remoteIds = rows.map((r) => r['id'] as String).toSet();
    // Eliminar del local los que ya no están en Supabase
    for (final id in _box.keys.cast<String>().toSet().difference(remoteIds)) {
      await _box.delete(id);
    }
    for (final row in rows) {
      await _box.put(row['id'], Map<String, dynamic>.from(row));
    }
    state = _cargar();
  }

  Future<void> agregar(PersonalModel p) async {
    await _box.put(p.id, p.toMap());
    state = _cargar();
    SyncService.upsert(_table, p.toMap());
  }

  Future<void> actualizar(PersonalModel p) async {
    await _box.put(p.id, p.toMap());
    state = _cargar();
    SyncService.upsert(_table, p.toMap());
  }

  Future<void> eliminar(String id) async {
    await _box.delete(id);
    state = _cargar();
    SyncService.delete(_table, id);
  }

  Future<void> toggleActivo(PersonalModel p) async {
    await actualizar(p.copyWith(activo: !p.activo));
  }
}

final personalProvider =
    NotifierProvider<PersonalNotifier, List<PersonalModel>>(PersonalNotifier.new);

final personalActivoProvider = Provider<List<PersonalModel>>((ref) {
  return ref.watch(personalProvider).where((p) => p.activo).toList();
});

final gastoPersonalMensualProvider = Provider<double>((ref) {
  return ref
      .watch(personalActivoProvider)
      .fold(0.0, (sum, p) => sum + p.sueldoMensual);
});
