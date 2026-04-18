import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../../../core/constants/app_constants.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  late AnimationController _shakeCtrl;
  late Animation<Offset> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnim = TweenSequence<Offset>([
      TweenSequenceItem(tween: Tween(begin: Offset.zero, end: const Offset(0.05, 0)), weight: 1),
      TweenSequenceItem(tween: Tween(begin: const Offset(0.05, 0), end: const Offset(-0.05, 0)), weight: 2),
      TweenSequenceItem(tween: Tween(begin: const Offset(-0.05, 0), end: const Offset(0.05, 0)), weight: 2),
      TweenSequenceItem(tween: Tween(begin: const Offset(0.05, 0), end: Offset.zero), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _addDigit(String digit) {
    if (_pin.length >= 4) return;
    setState(() => _pin += digit);
    if (_pin.length == 4) _verifyPin();
  }

  void _removeDigit() {
    if (_pin.isEmpty) return;
    ref.read(authProvider.notifier).clearError();
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _verifyPin() async {
    final ok = ref.read(authProvider.notifier).verifyPin(_pin);
    if (!ok) {
      await _shakeCtrl.forward(from: 0);
      setState(() => _pin = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = ref.watch(authProvider).error;

    return Scaffold(
      backgroundColor: AppConstants.primaryGreen,
      body: SafeArea(
        child: Column(
          children: [
            // ── Logo / header ──────────────────────────────────────────
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
                    child: const Icon(Icons.restaurant, size: 46,
                        color: AppConstants.primaryGreen),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    AppConstants.appName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    AppConstants.appSubtitle,
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),

            // ── PIN card ───────────────────────────────────────────────
            Expanded(
              flex: 6,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(32, 28, 32, 16),
                child: Column(
                  children: [
                    const Text(
                      'Ingresa tu PIN',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Error message
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: error != null
                          ? Text(error,
                              key: ValueKey(error),
                              style: const TextStyle(
                                  color: AppConstants.errorRed, fontSize: 13))
                          : const SizedBox(height: 18),
                    ),

                    const SizedBox(height: 16),

                    // PIN dots
                    SlideTransition(
                      position: _shakeAnim,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (i) {
                          final filled = i < _pin.length;
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

                    // Keypad
                    Expanded(child: _Keypad(onDigit: _addDigit, onDelete: _removeDigit)),

                    const SizedBox(height: 8),
                    Text(
                      'PIN por defecto: 1234',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
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

class _Keypad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onDelete;

  const _Keypad({required this.onDigit, required this.onDelete});

  static const _keys = ['1','2','3','4','5','6','7','8','9','','0','⌫'];

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
                  : Text(
                      k,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.primaryGreen,
                      ),
                    ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
