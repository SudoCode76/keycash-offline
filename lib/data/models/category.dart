class Category {
  final String id;
  final String nombre;
  final String tipo;   // ingreso | gasto
  final String color;  // #RRGGBB
  final String icono;  // nombre ícono Material
  final bool activo;
  final String created;

  Category({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.color,
    required this.icono,
    required this.activo,
    required this.created,
  });

  factory Category.fromMap(Map<String, Object?> map) => Category(
    id: map['id'] as String,
    nombre: map['nombre'] as String,
    tipo: map['tipo'] as String,
    color: map['color'] as String,
    icono: map['icono'] as String,
    activo: (map['activo'] as int) == 1,
    created: map['created'] as String,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'nombre': nombre,
    'tipo': tipo,
    'color': color,
    'icono': icono,
    'activo': activo ? 1 : 0,
    'created': created,
  };
}