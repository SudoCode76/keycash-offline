import 'package:uuid/uuid.dart';
import '../local/local_db.dart';
import '../models/transaction.dart';

class TransactionRepository {
  final _uuid = const Uuid();

  String _toDateOnly(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<List<TransactionModel>> listByDate(DateTime date) async {
    final db = await LocalDb().database;
    final only = _toDateOnly(date);
    final rows = await db.query(
      'transacciones',
      where: 'substr(fecha, 1, 10) = ?',
      whereArgs: [only],
      orderBy: 'created DESC',
    );
    return rows.map((m) => TransactionModel.fromMap(m)).toList();
  }

  Future<List<TransactionModel>> listByMonth(int year, int month) async {
    final db = await LocalDb().database;
    final key = '$year-${month.toString().padLeft(2, '0')}';
    final rows = await db.query(
      'transacciones',
      where: 'substr(fecha, 1, 7) = ?',
      whereArgs: [key],
      orderBy: 'fecha DESC, created DESC',
    );
    return rows.map((m) => TransactionModel.fromMap(m)).toList();
  }

  Future<TransactionModel> create({
    required double monto,
    required String descripcion,
    required DateTime fecha,
    required String tipo, // ingreso | gasto
    required String categoriaId,
  }) async {
    final db = await LocalDb().database;
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    final dateOnly = _toDateOnly(fecha);

    final tx = TransactionModel(
      id: id,
      monto: monto,
      descripcion: descripcion.trim(),
      fecha: dateOnly,
      tipo: tipo,
      categoriaId: categoriaId,
      created: now,
    );

    // Enviar usuario_id para esquemas con NOT NULL
    await db.insert('transacciones', {
      ...tx.toMap(),
      'usuario_id': 'local',
    });

    return tx;
  }

  Future<void> update(TransactionModel tx) async {
    final db = await LocalDb().database;
    await db.update('transacciones', tx.toMap(), where: 'id = ?', whereArgs: [tx.id]);
  }

  Future<void> delete(String id) async {
    final db = await LocalDb().database;
    await db.delete('transacciones', where: 'id = ?', whereArgs: [id]);
  }
}