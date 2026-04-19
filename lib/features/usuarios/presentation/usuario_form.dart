import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../models/usuario_model.dart';
import '../providers/usuarios_provider.dart';

class UsuarioForm extends ConsumerStatefulWidget {
  final UsuarioApp? usuario;
  const UsuarioForm({super.key, this.usuario});

  @override
  ConsumerState<UsuarioForm> createState() => _UsuarioFormState();
}

class _UsuarioFormState extends ConsumerState<UsuarioForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombre;
  late TextEditingController _pin;
  late TextEditingController _pinConfirm;
  late RolUsuario _rol;
  late Set<String> _modulos;

  bool _obscurePin = true;
  bool _obscureConfirm = true;

  bool get _esNuevo => widget.usuario == null;
  bool get _esAdmin => _rol == RolUsuario.admin;

  @override
  void initState() {
    super.initState();
    final u = widget.usuario;
    _nombre = TextEditingController(text: u?.nombre ?? '');
    _pin = TextEditingController();
    _pinConfirm = TextEditingController();
    _rol = u?.rol ?? RolUsuario.usuario;
    _modulos = Set.from(u?.modulos ?? []);
  }

  @override
  void dispose() {
    _nombre.dispose();
    _pin.dispose();
    _pinConfirm.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(usuariosProvider.notifier);

    if (_esNuevo) {
      final nuevo = UsuarioApp(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nombre: _nombre.text.trim(),
        pin: _pin.text,
        rol: _rol,
        modulos: _esAdmin ? [] : _modulos.toList(),
      );
      await notifier.agregar(nuevo);
    } else {
      final u = widget.usuario!;
      final actualizado = u.copyWith(
        nombre: _nombre.text.trim(),
        pin: _pin.text.isNotEmpty ? _pin.text : null,
        rol: _rol,
        modulos: _esAdmin ? [] : _modulos.toList(),
      );
      await notifier.actualizar(actualizado);
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final navBar = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset + navBar),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Handle bar ─────────────────────────────────────────
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text(
                _esNuevo ? 'Nuevo usuario' : 'Editar usuario',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryGreen),
              ),
              const SizedBox(height: 20),

              // ── Nombre ─────────────────────────────────────────────
              TextFormField(
                controller: _nombre,
                decoration: _deco('Nombre', Icons.person_rounded),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Ingresa el nombre' : null,
              ),
              const SizedBox(height: 14),

              // ── PIN ────────────────────────────────────────────────
              TextFormField(
                controller: _pin,
                obscureText: _obscurePin,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: _deco(
                  _esNuevo ? 'PIN (4 dígitos)' : 'Nuevo PIN (dejar vacío = sin cambio)',
                  Icons.lock_rounded,
                ).copyWith(
                  counterText: '',
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscurePin ? Icons.visibility_off : Icons.visibility),
                    onPressed: () =>
                        setState(() => _obscurePin = !_obscurePin),
                  ),
                ),
                validator: (v) {
                  if (_esNuevo) {
                    if (v == null || v.isEmpty) return 'Ingresa un PIN';
                    if (v.length != 4) return 'El PIN debe tener 4 dígitos';
                    if (!RegExp(r'^\d{4}$').hasMatch(v))
                      return 'Solo números';
                  } else {
                    if (v != null && v.isNotEmpty) {
                      if (v.length != 4) return 'El PIN debe tener 4 dígitos';
                      if (!RegExp(r'^\d{4}$').hasMatch(v))
                        return 'Solo números';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // ── Confirmar PIN ──────────────────────────────────────
              TextFormField(
                controller: _pinConfirm,
                obscureText: _obscureConfirm,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: _deco('Confirmar PIN', Icons.lock_outline_rounded)
                    .copyWith(
                  counterText: '',
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (v) {
                  final pinVal = _pin.text;
                  if (pinVal.isEmpty && !_esNuevo) return null;
                  if (v != pinVal) return 'Los PINs no coinciden';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ── Rol ────────────────────────────────────────────────
              const Text('Rol',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppConstants.primaryGreen)),
              const SizedBox(height: 8),
              Row(
                children: RolUsuario.values.map((rol) {
                  final selected = _rol == rol;
                  final color = rol == RolUsuario.admin
                      ? AppConstants.primaryGreen
                      : AppConstants.asistenciaColor;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _rol = rol),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: EdgeInsets.only(
                            right: rol == RolUsuario.admin ? 8 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selected ? color : Colors.transparent,
                          border: Border.all(
                              color: selected ? color : Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            rol.label,
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // ── Módulos (solo si no es admin) ──────────────────────
              if (!_esAdmin) ...[
                const Text('Módulos permitidos',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppConstants.primaryGreen)),
                const SizedBox(height: 4),
                Text('Selecciona a qué secciones tendrá acceso',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500)),
                const SizedBox(height: 8),
                ...AppConstants.modulosDisponibles.entries.map((e) {
                  final ruta = e.key;
                  final nombre = e.value;
                  final checked = _modulos.contains(ruta);
                  return CheckboxListTile(
                    value: checked,
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _modulos.add(ruta);
                        } else {
                          _modulos.remove(ruta);
                        }
                      });
                    },
                    title: Text(nombre),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: AppConstants.asistenciaColor,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  );
                }),
                const SizedBox(height: 8),
              ],

              // ── Guardar ────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _guardar,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppConstants.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.save_rounded),
                  label: Text(_esNuevo ? 'Crear usuario' : 'Guardar cambios'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _deco(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppConstants.primaryGreen),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppConstants.primaryGreen, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}
