enum RolUsuario { admin, usuario }

extension RolExt on RolUsuario {
  String get key   => this == RolUsuario.admin ? 'admin' : 'usuario';
  String get label => this == RolUsuario.admin ? 'Administrador' : 'Usuario';
  static RolUsuario fromKey(String? k) =>
      k == 'admin' ? RolUsuario.admin : RolUsuario.usuario;
}

class UsuarioApp {
  final String id;
  final String nombre;
  final String pin;
  final RolUsuario rol;
  /// Rutas permitidas: '/personal', '/ingredientes', etc.
  /// Si esAdmin → acceso total (ignora esta lista)
  final List<String> modulos;

  const UsuarioApp({
    required this.id,
    required this.nombre,
    required this.pin,
    this.rol = RolUsuario.usuario,
    this.modulos = const [],
  });

  bool get esAdmin => rol == RolUsuario.admin;

  bool tieneAcceso(String ruta) => esAdmin || modulos.contains(ruta);

  UsuarioApp copyWith({
    String? nombre,
    String? pin,
    RolUsuario? rol,
    List<String>? modulos,
  }) =>
      UsuarioApp(
        id: id,
        nombre: nombre ?? this.nombre,
        pin: pin ?? this.pin,
        rol: rol ?? this.rol,
        modulos: modulos ?? this.modulos,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'pin': pin,
        'rol': rol.key,
        'modulos': modulos.join(','),
      };

  factory UsuarioApp.fromMap(Map map) => UsuarioApp(
        id: map['id'] as String,
        nombre: map['nombre'] as String,
        pin: map['pin'] as String,
        rol: RolExt.fromKey(map['rol'] as String?),
        modulos: ((map['modulos'] as String?) ?? '')
            .split(',')
            .where((s) => s.isNotEmpty)
            .toList(),
      );
}
