import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../models/usuario_model.dart';
import '../providers/usuarios_provider.dart';
import 'usuario_form.dart';

class UsuariosScreen extends ConsumerWidget {
  const UsuariosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuarios = ref.watch(usuariosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios del Sistema'),
        backgroundColor: AppConstants.primaryGreen,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(context, ref, null),
        backgroundColor: AppConstants.primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Nuevo usuario'),
      ),
      body: usuarios.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: usuarios.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final u = usuarios[i];
                return _UsuarioTile(
                  usuario: u,
                  onEdit: () => _abrirFormulario(context, ref, u),
                  onDelete: u.esAdmin
                      ? null
                      : () => _confirmarEliminar(context, ref, u),
                );
              },
            ),
    );
  }

  Future<void> _abrirFormulario(
      BuildContext context, WidgetRef ref, UsuarioApp? usuario) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UsuarioForm(usuario: usuario),
    );
  }

  Future<void> _confirmarEliminar(
      BuildContext context, WidgetRef ref, UsuarioApp usuario) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text('¿Eliminar a "${usuario.nombre}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar',
                style: TextStyle(color: AppConstants.errorRed)),
          ),
        ],
      ),
    );
    if (ok == true) {
      ref.read(usuariosProvider.notifier).eliminar(usuario.id);
    }
  }
}

// ── Tile de usuario ────────────────────────────────────────────────────────────

class _UsuarioTile extends StatelessWidget {
  final UsuarioApp usuario;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const _UsuarioTile({
    required this.usuario,
    required this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = usuario.esAdmin;
    final color =
        isAdmin ? AppConstants.primaryGreen : AppConstants.asistenciaColor;
    final modCount = usuario.modulos.length;
    final modulosLabel = isAdmin
        ? 'Acceso total'
        : modCount == 0
            ? 'Sin módulos asignados'
            : '$modCount módulo${modCount == 1 ? '' : 's'}';

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: color,
          child: Text(
            usuario.nombre.isNotEmpty ? usuario.nombre[0].toUpperCase() : '?',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(usuario.nombre,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(usuario.rol.label,
                style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500)),
            Text(modulosLabel,
                style:
                    TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_rounded, size: 20),
              color: Colors.grey.shade600,
              onPressed: onEdit,
              tooltip: 'Editar',
            ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_rounded, size: 20),
                color: AppConstants.errorRed,
                onPressed: onDelete,
                tooltip: 'Eliminar',
              ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
