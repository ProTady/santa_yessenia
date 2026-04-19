import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/supabase/sync_service.dart';
import '../../../core/wifi_sync/wifi_events.dart';
import '../models/venta_model.dart';

class VentasNotifier extends Notifier<List<VentaModel>> {
  Box get _box => Hive.box(AppConstants.ventasBox);
  static const _table = 'ventas';

  @override
  List<VentaModel> build() {
    final channel = SyncService.subscribe(_table, _pullFromSupabase);
    ref.onDispose(() => Supabase.instance.client.removeChannel(channel));
    final wifiSub = WifiEvents.tableUpdated
        .where((t) => t == _table)
        .listen((_) => state = _cargar());
    ref.onDispose(wifiSub.cancel);
    _pullFromSupabase();
    return _cargar();
  }

  List<VentaModel> _cargar() {
    return _box.values
        .whereType<Map>()
        .map((m) => VentaModel.fromMap(m))
        .toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
  }

  Future<void> _pullFromSupabase() async {
    final rows = await SyncService.pull(_table);
    if (rows.isEmpty) {
      final local = _box.values
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
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

  Future<void> agregar(VentaModel v) async {
    await _box.put(v.id, v.toMap());
    state = _cargar();
    SyncService.upsert(_table, v.toMap());
  }

  Future<void> actualizar(VentaModel v) async {
    await _box.put(v.id, v.toMap());
    state = _cargar();
    SyncService.upsert(_table, v.toMap());
  }

  Future<void> eliminar(String id) async {
    await _box.delete(id);
    state = _cargar();
    SyncService.delete(_table, id);
  }
}

final ventasProvider =
    NotifierProvider<VentasNotifier, List<VentaModel>>(VentasNotifier.new);

// ── Derived providers ──────────────────────────────────────────────────────────

final totalVentasMesProvider = Provider<double>((ref) {
  final now = DateTime.now();
  final primerDia = DateTime(now.year, now.month, 1);
  return ref.watch(ventasProvider).fold(0.0, (sum, v) {
    if (!v.fecha.isBefore(primerDia)) return sum + v.total;
    return sum;
  });
});

final totalFiadoMesProvider = Provider<double>((ref) {
  final now = DateTime.now();
  final primerDia = DateTime(now.year, now.month, 1);
  return ref.watch(ventasProvider).fold(0.0, (sum, v) {
    if (!v.fecha.isBefore(primerDia) && v.estadoPago == EstadoPago.fiado) {
      return sum + v.total;
    }
    return sum;
  });
});

/// Total de ventas pendientes (fiado) de todos los tiempos
final totalFiadoPendienteProvider = Provider<double>((ref) {
  return ref.watch(ventasProvider).fold(0.0, (sum, v) {
    return v.estadoPago == EstadoPago.fiado ? sum + v.total : sum;
  });
});
