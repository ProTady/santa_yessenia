import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/wifi_sync/wifi_sync_client.dart';
import '../../../features/auth/providers/auth_provider.dart';

class WifiClientScreen extends ConsumerStatefulWidget {
  const WifiClientScreen({super.key});

  @override
  ConsumerState<WifiClientScreen> createState() => _WifiClientScreenState();
}

class _WifiClientScreenState extends ConsumerState<WifiClientScreen> {
  static const _color = Color(0xFF1565C0);

  final _ipCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _conectando = false;
  bool _sincronizando = false;
  bool _conectado = false;
  String? _error;
  Map<String, String?> _resultados = {};

  @override
  void dispose() {
    _ipCtrl.dispose();
    super.dispose();
  }

  // ── Módulos permitidos para el usuario actual ──────────────────────────────

  List<String> _tablasPermitidas() {
    final auth = ref.read(authProvider);
    // Admin sincroniza todo; usuarios solo sus módulos
    const todasLasTablas = [
      'personal', 'ingredientes', 'suministros', 'transporte',
      'ingresos', 'comensales', 'directorio', 'asistencias', 'ventas',
    ];
    if (auth.esAdmin) return todasLasTablas;
    final rutas = auth.usuarioActual?.modulos ?? [];
    return rutas
        .map((r) => r.replaceAll('/', '')) // '/ventas' → 'ventas'
        .where(todasLasTablas.contains)
        .toList();
  }

  // ── Ping / verificar conexión ──────────────────────────────────────────────

  Future<void> _conectar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _conectando = true;
      _error = null;
      _conectado = false;
    });
    final client = WifiSyncClient(_ipCtrl.text.trim());
    final ok = await client.ping();
    setState(() {
      _conectando = false;
      _conectado = ok;
      _error = ok ? null : 'No se pudo conectar. Verifica la IP y que el servidor esté activo.';
    });
  }

  // ── Sincronización ─────────────────────────────────────────────────────────

  Future<void> _sincronizar() async {
    setState(() {
      _sincronizando = true;
      _resultados = {};
      _error = null;
    });

    final client = WifiSyncClient(_ipCtrl.text.trim());
    final tablas = _tablasPermitidas();

    // 1. Push: sube datos locales al admin
    final pushRes = await client.push(tablas);

    // 2. Pull: descarga datos del admin (personal, usuarios, etc.)
    //    Los usuarios necesitan ver el catálogo de personal para asistencias
    final pullTablas = ref.read(authProvider).esAdmin
        ? tablas
        : [...tablas, 'personal', 'usuarios'];
    final pullRes = await client.pull(pullTablas.toSet().toList());

    // Combinar resultados
    final todos = <String, String?>{};
    for (final t in {
      ...pushRes.keys,
      ...pullRes.keys,
    }) {
      final pe = pushRes[t];
      final pu = pullRes[t];
      todos[t] = (pe != null || pu != null)
          ? 'push: ${pe ?? 'OK'}  pull: ${pu ?? 'OK'}'
          : null;
    }

    setState(() {
      _sincronizando = false;
      _resultados = todos;
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final navBar = MediaQuery.of(context).viewPadding.bottom;
    final tablas = _tablasPermitidas();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sincronizar por WiFi'),
        backgroundColor: _color,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + navBar),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Info ──────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _color.withAlpha(12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _color.withAlpha(40)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: _color, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Conecta al Admin para sincronizar tus datos. '
                        'Asegúrate de estar en la misma red WiFi.',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── IP del admin ──────────────────────────────────────
              const Text('IP del dispositivo Admin',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: _color)),
              const SizedBox(height: 8),
              Form(
                key: _formKey,
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ipCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'ej. 192.168.1.5',
                          prefixIcon: const Icon(Icons.router_rounded,
                              color: _color),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: _color, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Ingresa la IP'
                                : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: _conectando ? null : _conectar,
                      style: FilledButton.styleFrom(
                        backgroundColor: _color,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _conectando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white))
                          : const Text('Conectar'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Estado conexión ───────────────────────────────────
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppConstants.errorRed.withAlpha(12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppConstants.errorRed, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!,
                            style: const TextStyle(
                                color: AppConstants.errorRed,
                                fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              if (_conectado)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: Colors.green.shade700, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Conectado al Admin (${_ipCtrl.text.trim()})',
                        style: TextStyle(
                            color: Colors.green.shade700, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // ── Módulos que se sincronizarán ──────────────────────
              if (_conectado) ...[
                const Text('Módulos a sincronizar',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: _color)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: tablas.map((t) {
                    return Chip(
                      label: Text(t,
                          style: const TextStyle(fontSize: 12)),
                      backgroundColor: _color.withAlpha(12),
                      side: BorderSide(color: _color.withAlpha(40)),
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // ── Botón sincronizar ─────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _sincronizando ? null : _sincronizar,
                    style: FilledButton.styleFrom(
                      backgroundColor: _color,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: _sincronizando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white))
                        : const Icon(Icons.sync_rounded),
                    label: Text(_sincronizando
                        ? 'Sincronizando...'
                        : 'Sincronizar ahora'),
                  ),
                ),
              ],

              // ── Resultados ────────────────────────────────────────
              if (_resultados.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text('Resultado',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: _color)),
                const SizedBox(height: 10),
                ..._resultados.entries.map((e) {
                  final ok = e.value == null;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(
                          ok
                              ? Icons.check_circle_rounded
                              : Icons.warning_rounded,
                          size: 18,
                          color: ok
                              ? Colors.green.shade600
                              : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(e.key,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500)),
                        const Spacer(),
                        Text(
                          ok ? 'OK' : 'Error',
                          style: TextStyle(
                              color: ok
                                  ? Colors.green.shade600
                                  : Colors.orange,
                              fontWeight: FontWeight.w600,
                              fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 10),
                if (_resultados.values.every((v) => v == null))
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.celebration_rounded,
                            color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        const Text('¡Sincronización exitosa!'),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
