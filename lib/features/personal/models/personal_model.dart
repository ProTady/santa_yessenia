class PersonalModel {
  final String id;
  final String nombre;
  final String cargo;
  final double sueldoDiario;
  final bool activo;

  const PersonalModel({
    required this.id,
    required this.nombre,
    required this.cargo,
    required this.sueldoDiario,
    this.activo = true,
  });

  PersonalModel copyWith({
    String? nombre,
    String? cargo,
    double? sueldoDiario,
    bool? activo,
  }) {
    return PersonalModel(
      id: id,
      nombre: nombre ?? this.nombre,
      cargo: cargo ?? this.cargo,
      sueldoDiario: sueldoDiario ?? this.sueldoDiario,
      activo: activo ?? this.activo,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'cargo': cargo,
        'sueldo_diario': sueldoDiario,
        'activo': activo,
      };

  factory PersonalModel.fromMap(Map map) => PersonalModel(
        id: map['id'] as String,
        nombre: map['nombre'] as String,
        cargo: map['cargo'] as String,
        sueldoDiario: (map['sueldo_diario'] as num).toDouble(),
        activo: map['activo'] as bool? ?? true,
      );

  // Sueldo mensual estimado (26 días laborables)
  double get sueldoMensual => sueldoDiario * 26;
}
