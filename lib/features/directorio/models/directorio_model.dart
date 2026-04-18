class DirectorioComensal {
  final String dni;
  final String nombre;

  const DirectorioComensal({required this.dni, required this.nombre});

  Map<String, dynamic> toMap() => {'dni': dni, 'nombre': nombre};

  factory DirectorioComensal.fromMap(Map m) => DirectorioComensal(
        dni: m['dni'] as String,
        nombre: m['nombre'] as String,
      );

  DirectorioComensal copyWith({String? nombre}) =>
      DirectorioComensal(dni: dni, nombre: nombre ?? this.nombre);
}
