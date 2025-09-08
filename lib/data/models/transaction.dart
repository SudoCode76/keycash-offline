class TransactionModel {
  final String id;
  final double monto;
  final String descripcion;
  final String fecha; // YYYY-MM-DD
  final String tipo;  // ingreso | gasto
  final String categoriaId;
  final String created;

  TransactionModel({
    required this.id,
    required this.monto,
    required this.descripcion,
    required this.fecha,
    required this.tipo,
    required this.categoriaId,
    required this.created,
  });

  factory TransactionModel.fromMap(Map<String, Object?> map) => TransactionModel(
    id: map['id'] as String,
    monto: (map['monto'] as num).toDouble(),
    descripcion: map['descripcion'] as String,
    fecha: map['fecha'] as String,
    tipo: map['tipo'] as String,
    categoriaId: map['categoria_id'] as String,
    created: map['created'] as String,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'monto': monto,
    'descripcion': descripcion,
    'fecha': fecha,
    'tipo': tipo,
    'categoria_id': categoriaId,
    'created': created,
  };
}