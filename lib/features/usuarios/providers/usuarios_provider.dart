import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/supabase/sync_service.dart';
import '../models/usuario_model.dart';

class UsuariosNotifier extends Notifier<List<UsuarioApp>> {
  Box get _box => Hive.box(AppConstants.usuariosBox);
  static const _table = 'usuarios';

  @override
  List<UsuarioApp> build() {
    final channel = SyncService.subscribe(_table, _pullFromSupabase);
    ref.onDispose(() => Supabase.instance.client.removeChannel(channel));
    _pullFromSupabase();
    _crearAdminSiNoExiste();
    return _cargar();
  }

  List<UsuarioApp> _cargar() {
    final lista = _box.values
        .whereType<Map>()
        .map((m) => UsuarioApp.fromMap(m))
        .toList()
      ..sort((a, b) {
        if (a.esAdmin) return -1;
        if (b.esAdmin) return 1;
        return a.nombre.compareTo(b.nombre);
      });
    return lista;
  }

  Future<void> _pullFromSupabase() async {
    final rows = await SyncService.pull(_table);
    if (rows.isEmpty) {
      final local = _box.values.whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m)).toList();
      SyncService.pushAll(_table, local);
      return;
    }
    for (final row in rows) {
      await _box.put(row['id'], Map<String, dynamic>.from(row));
    }
    state = _cargar();
  }

  /// Crea el Admin por defecto si no existe ninguno
  Future<void> _crearAdminSiNoExiste() async {
    if (_cargar().any((u) => u.esAdmin)) return;
    final admin = UsuarioApp(
      id: 'admin',
      nombre: 'Administrador',
      pin: Hive.box(AppConstants.settingsBox)
          .get(AppConstants.pinKey, defaultValue: AppConstants.defaultPin)
          as String,
      rol: RolUsuario.admin,
    );
    await _box.put(admin.id, admin.toMap());
    state = _cargar();
    SyncService.upsert(_table, admin.toMap());
  }

  Future<void> agregar(UsuarioApp u) async {
    await _box.put(u.id, u.toMap());
    state = _cargar();
    SyncService.upsert(_table, u.toMap());
  }

  Future<void> actualizar(UsuarioApp u) async {
    await _box.put(u.id, u.toMap());
    state = _cargar();
    SyncService.upsert(_table, u.toMap());
  }

  Future<void> eliminar(String id) async {
    await _box.delete(id);
    state = _cargar();
    SyncService.delete(_table, id);
  }

  UsuarioApp? buscarPorId(String id) {
    try {
      return state.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }
}

final usuariosProvider =
    NotifierProvider<UsuariosNotifier, List<UsuarioApp>>(UsuariosNotifier.new);
