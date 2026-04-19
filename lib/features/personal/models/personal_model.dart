enum Regimen { general, eventual }

extension RegimenExt on Regimen {
  String get label => switch (this) {
        Regimen.general  => 'Régimen General',
        Regimen.eventual => 'Eventual',
      };
  String get key => switch (this) {
        Regimen.general  => 'general',
        Regimen.eventual => 'eventual',
      };
  static Regimen fromKey(String? k) =>
      k == 'general' ? Regimen.general : Regimen.eventual;
}

class PersonalModel {
  final String id;
  final String nombre;
  final String cargo;
  final double sueldoDiario;
  final bool activo;
  final Regimen regimen;

  const PersonalModel({
    required this.id,
    required this.nombre,
    required this.cargo,
    required this.sueldoDiario,
    this.activo = true,
    this.regimen = Regimen.eventual,
  });

  PersonalModel copyWith({
    String? nombre,
    String? cargo,
    double? sueldoDiario,
    bool? activo,
    Regimen? regimen,
  }) {
    return PersonalModel(
      id: id,
      nombre: nombre ?? this.nombre,
      cargo: cargo ?? this.cargo,
      sueldoDiario: sueldoDiario ?? this.sueldoDiario,
      activo: activo ?? this.activo,
      regimen: regimen ?? this.regimen,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'cargo': cargo,
        'sueldo_diario': sueldoDiario,
        'activo': activo,
        'regimen': regimen.key,
      };

  factory PersonalModel.fromMap(Map map) => PersonalModel(
        id: map['id'] as String,
        nombre: map['nombre'] as String,
        cargo: map['cargo'] as String,
        sueldoDiario: (map['sueldo_diario'] as num).toDouble(),
        activo: map['activo'] as bool? ?? true,
        regimen: RegimenExt.fromKey(map['regimen'] as String?),
      );

  // Sueldo mensual estimado (26 días laborables)
  double get sueldoMensual => sueldoDiario * 26;
}
