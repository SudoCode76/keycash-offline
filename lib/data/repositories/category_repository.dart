import 'package:uuid/uuid.dart';
import '../local/local_db.dart';
import '../models/category.dart';

class CategoryRepository {
  final _uuid = const Uuid();

  Future<List<Category>> getAll({bool? activo, String? tipo}) async {
    final db = await LocalDb().database;

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
      orderBy: 'tipo, nombre',
    );

    return rows.map((m) => Category.fromMap(m)).toList();
  }

  Future<Category> create({
    required String nombre,
    required String tipo,
    required String color,
    required String icono,
  }) async {
    final db = await LocalDb().database;
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    final cat = Category(
      id: id,
      nombre: nombre.trim(),
      tipo: tipo,
      color: color.trim(),
      icono: icono.trim(),
      activo: true,
      created: now,
    );

    // Enviar user_id para satisfacer NOT NULL en dispositivos con esquema viejo
    await db.insert('categorias', {
      ...cat.toMap(),
      'user_id': 'local',
    });

    return cat;
  }

  Future<void> update(Category category) async {
    final db = await LocalDb().database;
    await db.update('categorias', category.toMap(), where: 'id = ?', whereArgs: [category.id]);
  }

  Future<void> toggleActivo(String id, bool activo) async {
    final db = await LocalDb().database;
    await db.update('categorias', {'activo': activo ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(String id) async {
    final db = await LocalDb().database;
    await db.delete('categorias', where: 'id = ?', whereArgs: [id]);
  }
}