import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/wifi_sync/wifi_sync_client.dart';
import '../../usuarios/models/usuario_model.dart';
import '../../usuarios/providers/usuarios_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  UsuarioApp? _usuarioSeleccionado;
  String _pin = '';
  late AnimationController _shakeCtrl;
  late Animation<Offset> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
        duration: const Duration(milliseconds: 400), vsync: this);
    _shakeAnim = TweenSequence<Offset>([
      TweenSequenceItem(
          tween: Tween(begin: Offset.zero, end: const Offset(0.05, 0)),
          weight: 1),
      TweenSequenceItem(
          tween: Tween(
              begin: const Offset(0.05, 0), end: const Offset(-0.05, 0)),
          weight: 2),
      TweenSequenceItem(
          tween: Tween(
              begin: const Offset(-0.05, 0), end: const Offset(0.05, 0)),
          weight: 2),
      TweenSequenceItem(
          tween: Tween(begin: const Offset(0.05, 0), end: Offset.zero),
          weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _sincronizarUsuarios(BuildContext context) async {
    final ipCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final ip = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.wifi_rounded, color: AppConstants.primaryGreen),
            SizedBox(width: 8),
            Text('IP del Admin', style: TextStyle(fontSize: 17)),
          ],
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: ipCtrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'ej. 192.168.1.5',
              prefixIcon: const Icon(Icons.router_rounded,
                  color: AppConstants.primaryGreen),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: AppConstants.primaryGreen, width: 2),
              ),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Ingresa la IP' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppConstants.primaryGreen),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, ipCtrl.text.trim());
              }
            },
            child: const Text('Conectar'),
          ),
        ],
      ),
    );

    if (ip == null || !context.mounted) return;

    // Mostrar cargando
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Obteniendo usuarios...'),
          ],
        ),
      ),
    );

    final client = WifiSyncClient(ip);
    final ok = await client.ping();

    if (!context.mounted) return;

    if (!ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'No se pudo conectar. Verifica la IP y que el servidor esté activo.'),
          backgroundColor: AppConstants.errorRed,
        ),
      );
      return;
    }

    final resultados = await client.pull(['usuarios']);
    if (!context.mounted) return;
    Navigator.of(context).pop(); // cierra cargando

    final error = resultados['usuarios'];
    if (error == null) {
      // Recargar lista de usuarios
      ref.invalidate(usuariosProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Usuarios sincronizados correctamente'),
          backgroundColor: AppConstants.primaryGreen,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: AppConstants.errorRed,
        ),
      );
    }
  }

  void _seleccionarUsuario(UsuarioApp u) {
    setState(() {
      _usuarioSeleccionado = u;
      _pin = '';
    });
    ref.read(authProvider.notifier).clearError();
  }

  void _volver() {
    setState(() {
      _usuarioSeleccionado = null;
      _pin = '';
    });
    ref.read(authProvider.notifier).clearError();
  }

  void _addDigit(String digit) {
    if (_pin.length >= 4) return;
    setState(() => _pin += digit);
    if (_pin.length == 4) _verificar();
  }

  void _removeDigit() {
    if (_pin.isEmpty) return;
    ref.read(authProvider.notifier).clearError();
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _verificar() async {
    final usuario = _usuarioSeleccionado;
    if (usuario == null) return;
    final ok = ref.read(authProvider.notifier).login(usuario, _pin);
    if (!ok) {
      await _shakeCtrl.forward(from: 0);
      setState(() => _pin = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuarios = ref.watch(usuariosProvider);
    final error = ref.watch(authProvider).error;

    return Scaffold(
      backgroundColor: AppConstants.primaryGreen,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────
            Expanded(
              flex: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(60),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.restaurant,
                        size: 46, color: AppConstants.primaryGreen),
                  ),
                  const SizedBox(height: 16),
                  const Text(AppConstants.appName,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8)),
                  const SizedBox(height: 4),
                  const Text(AppConstants.appSubtitle,
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),

            // ── Card blanca ───────────────────────────────────────────
            Expanded(
              flex: 6,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(32, 28, 32, 8),
                child: Column(
                  children: [
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _usuarioSeleccionado == null
                            ? _SelectorUsuarios(
                                key: const ValueKey('selector'),
                                usuarios: usuarios,
                                onSelect: _seleccionarUsuario,
                              )
                            : _PinInput(
                                key: const ValueKey('pin'),
                                usuario: _usuarioSeleccionado!,
                                pin: _pin,
                                error: error,
                                shakeAnim: _shakeAnim,
                                onDigit: _addDigit,
                                onDelete: _removeDigit,
                                onVolver: _volver,
                              ),
                      ),
                    ),

                    // ── Botón sincronizar usuarios por WiFi ───────────
                    if (_usuarioSeleccionado == null)
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: TextButton.icon(
                            onPressed: () =>
                                _sincronizarUsuarios(context),
                            icon: const Icon(Icons.wifi_rounded, size: 16),
                            label: const Text(
                                'Obtener usuarios desde el Admin (WiFi)'),
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  AppConstants.primaryGreen.withAlpha(160),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Selector de usuario ────────────────────────────────────────────────────────

class _SelectorUsuarios extends StatelessWidget {
  final List<UsuarioApp> usuarios;
  final void Function(UsuarioApp) onSelect;

  const _SelectorUsuarios(
      {super.key, required this.usuarios, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Selecciona tu usuario',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppConstants.primaryGreen)),
        const SizedBox(height: 20),
        Expanded(
          child: usuarios.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  itemCount: usuarios.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final u = usuarios[i];
                    return ListTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      tileColor: AppConstants.primaryGreen.withAlpha(12),
                      leading: CircleAvatar(
                        backgroundColor: u.esAdmin
                            ? AppConstants.primaryGreen
                            : AppConstants.asistenciaColor,
                        child: Text(
                          u.nombre.isNotEmpty
                              ? u.nombre[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(u.nombre,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(u.rol.label,
                          style: TextStyle(
                              fontSize: 12,
                              color: u.esAdmin
                                  ? AppConstants.primaryGreen
                                  : AppConstants.asistenciaColor)),
                      trailing: const Icon(Icons.chevron_right_rounded,
                          color: Colors.grey),
                      onTap: () => onSelect(u),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ── Entrada de PIN ─────────────────────────────────────────────────────────────

class _PinInput extends StatelessWidget {
  final UsuarioApp usuario;
  final String pin;
  final String? error;
  final Animation<Offset> shakeAnim;
  final void Function(String) onDigit;
  final VoidCallback onDelete;
  final VoidCallback onVolver;

  const _PinInput({
    super.key,
    required this.usuario,
    required this.pin,
    required this.error,
    required this.shakeAnim,
    required this.onDigit,
    required this.onDelete,
    required this.onVolver,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
              onPressed: onVolver,
              color: AppConstants.primaryGreen,
            ),
            CircleAvatar(
              radius: 18,
              backgroundColor: usuario.esAdmin
                  ? AppConstants.primaryGreen
                  : AppConstants.asistenciaColor,
              child: Text(
                usuario.nombre.isNotEmpty
                    ? usuario.nombre[0].toUpperCase()
                    : '?',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(usuario.nombre,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppConstants.primaryGreen)),
                  Text(usuario.rol.label,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text('Ingresa tu PIN',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppConstants.primaryGreen)),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: error != null
              ? Text(error!,
                  key: ValueKey(error),
                  style: const TextStyle(
                      color: AppConstants.errorRed, fontSize: 13))
              : const SizedBox(height: 18),
        ),
        const SizedBox(height: 16),
        SlideTransition(
          position: shakeAnim,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final filled = i < pin.length;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled
                      ? AppConstants.primaryGreen
                      : Colors.transparent,
                  border: Border.all(
                    color: filled
                        ? AppConstants.primaryGreen
                        : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
            child: _Keypad(onDigit: onDigit, onDelete: onDelete)),
      ],
    );
  }
}

class _Keypad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onDelete;

  const _Keypad({required this.onDigit, required this.onDelete});

  static const _keys = [
    '1','2','3','4','5','6','7','8','9','','0','⌫'
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      childAspectRatio: 1.7,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      physics: const NeverScrollableScrollPhysics(),
      children: _keys.map((k) {
        if (k.isEmpty) return const SizedBox();
        final isDelete = k == '⌫';
        return Material(
          color: isDelete
              ? Colors.grey.shade100
              : AppConstants.primaryGreen.withAlpha(18),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => isDelete ? onDelete() : onDigit(k),
            child: Center(
              child: isDelete
                  ? Icon(Icons.backspace_outlined,
                      color: Colors.grey.shade600, size: 22)
                  : Text(k,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.primaryGreen)),
            ),
          ),
        );
      }).toList(),
    );
  }
}
