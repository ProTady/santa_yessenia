import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/supabase/sync_service.dart';
import '../../../core/wifi_sync/wifi_events.dart';
import '../models/directorio_model.dart';

class DirectorioNotifier extends Notifier<List<DirectorioComensal>> {
  Box get _box => Hive.box(AppConstants.directorioBox);
  static const _table = 'directorio';

  @override
  List<DirectorioComensal> build() {
    final channel = SyncService.subscribe(_table, _pullFromSupabase);
    ref.onDispose(() => Supabase.instance.client.removeChannel(channel));
    final wifiSub = WifiEvents.tableUpdated
        .where((t) => t == _table)
        .listen((_) => state = _cargar());
    ref.onDispose(wifiSub.cancel);
    _pullFromSupabase();
    return _cargar();
  }

  List<DirectorioComensal> _cargar() {
    return _box.values
        .whereType<Map>()
        .map((m) => DirectorioComensal.fromMap(m))
        .toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
  }

  Future<void> _pullFromSupabase() async {
    final rows = await SyncService.pull(_table);
    if (rows.isEmpty) {
      final local = _box.values.whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m)).toList();
      SyncService.pushAll(_table, local);
      return;
    }
    final remoteDnis = rows.map((r) => r['dni'] as String).toSet();
    for (final dni in _box.keys.cast<String>().toSet().difference(remoteDnis)) {
      await _box.delete(dni);
    }
    for (final row in rows) {
      await _box.put(row['dni'], Map<String, dynamic>.from(row));
    }
    state = _cargar();
  }

  Future<void> agregar(DirectorioComensal d) async {
    await _box.put(d.dni, d.toMap());
    state = _cargar();
    SyncService.upsert(_table, d.toMap());
  }

  Future<void> eliminar(String dni) async {
    await _box.delete(dni);
    state = _cargar();
    SyncService.delete(_table, dni, key: 'dni');
  }

  Future<int> importar(List<DirectorioComensal> lista) async {
    int count = 0;
    for (final d in lista) {
      if (d.dni.length == 8) {
        await _box.put(d.dni, d.toMap());
        SyncService.upsert(_table, d.toMap());
        count++;
      }
    }
    state = _cargar();
    return count;
  }
}

final directorioProvider =
    NotifierProvider<DirectorioNotifier, List<DirectorioComensal>>(
        DirectorioNotifier.new);

final directorioPorDniProvider =
    Provider.family<DirectorioComensal?, String>((ref, dni) {
  final lista = ref.watch(directorioProvider);
  for (final d in lista) {
    if (d.dni == dni) return d;
  }
  return null;
});
