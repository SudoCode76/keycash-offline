import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../local/local_db.dart';
import '../models/category.dart';

class CategoryRepository {
  final _uuid = const Uuid();
  Future<Database> get _db async => LocalDb().database;

  Future<List<Category>> getAll({bool? activo, String? tipo}) async {
    final db = await _db;
    final where = <String>[];
    final args = <Object?>[];

    if (activo != null) {
      where.add('activo = ?');
      args.add(activo ? 1 : 0);
    }
    if (tipo != null) {
      where.add('tipo = ?');
      args.add(tipo);
    }

    final rows = await db.query(
      'categorias',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'orden ASC, created ASC',
    );
    return rows.map((m) => Category.fromMap(m)).toList();
  }

  Future<Category?> getById(String id) async {
    final db = await _db;
    final rows = await db.query('categorias', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Category.fromMap(rows.first);
  }

  Future<int> _nextOrden(Database db) async {
    final res = await db.rawQuery('SELECT MAX(orden) AS maxo FROM categorias');
    final maxo = (res.first['maxo'] as int?) ?? 0;
    return maxo + 1;
  }

  Future<Category> create({
    required String nombre,
    required String tipo,
    required String color,
    required String icono,
  }) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    final id = _uuid.v4();
    final orden = await _nextOrden(db);
    final cat = Category(
      id: id,
      nombre: nombre.trim(),
      tipo: tipo,
      color: color.trim(),
      icono: icono.trim(),
      activo: true,
      created: now,
      orden: orden,
    );
    await db.insert('categorias', cat.toMap());
    return cat;
  }

  Future<void> update(Category c) async {
    final db = await _db;
    await db.update('categorias', c.toMap(), where: 'id = ?', whereArgs: [c.id]);
  }

  Future<void> toggleActivo(String id, bool activo) async {
    final db = await _db;
    await db.update('categorias', {'activo': activo ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<String> ensureDefaultCategory(String tipo) async {
    final db = await _db;
    final defaultId = 'default-$tipo';
    final existing =
    await db.query('categorias', where: 'id = ?', whereArgs: [defaultId], limit: 1);
    if (existing.isNotEmpty) return defaultId;

    final now = DateTime.now().toIso8601String();
    final orden = await _nextOrden(db);
    await db.insert('categorias', {
      'id': defaultId,
      'nombre': 'Sin categoría',
      'tipo': tipo,
      'color': '#9E9E9E',
      'icono': 'mi:category',
      'activo': 1,
      'user_id': 'local',
      'created': now,
      'orden': orden,
    });
    return defaultId;
  }

  Future<void> saveOrder(List<String> orderedIds) async {
    final db = await _db;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (int i = 0; i < orderedIds.length; i++) {
        batch.update(
          'categorias',
          {'orden': i + 1},
          where: 'id = ?',
          whereArgs: [orderedIds[i]],
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> delete(String id) async {
    final db = await _db;
    final cat = await getById(id);
    if (cat == null) return;
    if (id.startsWith('default-')) {
      return; // no eliminar por defecto
    }
    final defaultId = await ensureDefaultCategory(cat.tipo);

    await db.update(
      'transacciones',
      {'categoria_id': defaultId},
      where: 'categoria_id = ?',
      whereArgs: [id],
    );

    await db.delete('categorias', where: 'id = ?', whereArgs: [id]);
  }
}