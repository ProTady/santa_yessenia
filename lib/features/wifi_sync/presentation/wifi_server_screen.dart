import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/wifi_sync/wifi_sync_provider.dart';

class WifiServerScreen extends ConsumerWidget {
  const WifiServerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wifiServerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Servidor WiFi'),
        backgroundColor: AppConstants.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Explicación ──────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppConstants.primaryGreen.withAlpha(12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppConstants.primaryGreen.withAlpha(40)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppConstants.primaryGreen, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('¿Cómo funciona?',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppConstants.primaryGreen)),
                          const SizedBox(height: 6),
                          Text(
                            '1. Activa el servidor en este dispositivo (Admin).\n'
                            '2. Asegúrate que todos los dispositivos estén en la misma red WiFi.\n'
                            '3. Comparte la IP con los usuarios.\n'
                            '4. En cada dispositivo de usuario: Menú → Sincronizar por WiFi → ingresar IP.',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Toggle servidor ──────────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: () =>
                      ref.read(wifiServerProvider.notifier).toggle(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: state.isRunning
                          ? AppConstants.primaryGreen
                          : Colors.grey.shade200,
                      boxShadow: state.isRunning
                          ? [
                              BoxShadow(
                                color: AppConstants.primaryGreen
                                    .withAlpha(80),
                                blurRadius: 24,
                                spreadRadius: 4,
                              )
                            ]
                          : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          state.isRunning
                              ? Icons.wifi_rounded
                              : Icons.wifi_off_rounded,
                          size: 52,
                          color: state.isRunning
                              ? Colors.white
                              : Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.isRunning ? 'ACTIVO' : 'INACTIVO',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: state.isRunning
                                ? Colors.white
                                : Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Toca para ${state.isRunning ? 'detener' : 'iniciar'}',
                          style: TextStyle(
                            fontSize: 11,
                            color: state.isRunning
                                ? Colors.white70
                                : Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── IP y puerto ──────────────────────────────────────
              if (state.isRunning && state.ip != null) ...[
                const Text('Dirección para los usuarios',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppConstants.primaryGreen)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withAlpha(10),
                          blurRadius: 8)
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('IP del servidor',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500)),
                            const SizedBox(height: 4),
                            Text(
                              state.ip!,
                              style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppConstants.primaryGreen,
                                  fontFamily: 'monospace'),
                            ),
                            Text('Puerto: 8765',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: state.ip!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('IP copiada al portapapeles'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded),
                        color: AppConstants.primaryGreen,
                        tooltip: 'Copiar IP',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
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
                        'Servidor activo — esperando conexiones...',
                        style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ] else if (!state.isRunning) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.circle_outlined,
                          color: Colors.grey.shade400, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Servidor detenido — toca el botón para iniciar',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 13),
                      ),
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
