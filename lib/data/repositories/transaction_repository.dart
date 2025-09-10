import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../local/local_db.dart';
import '../models/transaction.dart';

class TransactionRepository {
  final _uuid = const Uuid();
  Future<Database> get _db async => LocalDb().database;

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<List<TransactionModel>> listByDate(DateTime date) async {
    final db = await _db;
    final day = _fmt(date);
    final rows = await db.query(
      'transacciones',
      where: 'fecha = ?',
      whereArgs: [day],
      orderBy: 'fecha DESC, created DESC',
    );
    return rows.map(TransactionModel.fromMap).toList();
  }

  Future<List<TransactionModel>> listByMonth(int year, int month) async {
    final db = await _db;
    final start = '${year.toString()}-${month.toString().padLeft(2, '0')}-01';
    final lastDay = DateTime(year, month + 1, 0).day;
    final end =
        '${year.toString()}-${month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';

    final rows = await db.query(
      'transacciones',
      where: 'fecha BETWEEN ? AND ?',
      whereArgs: [start, end],
      orderBy: 'fecha ASC, created ASC',
    );
    return rows.map(TransactionModel.fromMap).toList();
  }

  Future<List<TransactionModel>> listRecent(int limit) async {
    final db = await _db;
    final rows = await db.query(
      'transacciones',
      orderBy: 'fecha DESC, created DESC',
      limit: limit,
    );
    return rows.map(TransactionModel.fromMap).toList();
  }

  Future<TransactionModel> getById(String id) async {
    final db = await _db;
    final rows =
    await db.query('transacciones', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) throw Exception('Transacción no encontrada');
    return TransactionModel.fromMap(rows.first);
  }

  Future<TransactionModel> create({
    required double monto,
    required String descripcion,
    required DateTime fecha,
    required String tipo,
    required String categoriaId,
  }) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    final t = TransactionModel(
      id: _uuid.v4(),
      monto: monto,
      descripcion: descripcion.trim(),
      fecha: _fmt(fecha),
      tipo: tipo,
      categoriaId: categoriaId,
      created: now,
    );
    await db.insert('transacciones', t.toMap());
    return t;
  }

  Future<void> update(TransactionModel t) async {
    final db = await _db;
    await db.update('transacciones', t.toMap(),
        where: 'id = ?', whereArgs: [t.id]);
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('transacciones', where: 'id = ?', whereArgs: [id]);
  }
}