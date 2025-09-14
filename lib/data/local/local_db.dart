import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class LocalDb {
  static final LocalDb _instance = LocalDb._internal();
  factory LocalDb() => _instance;
  LocalDb._internal();

  Database? _db;
  final _uuid = const Uuid();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'keycash_offline.db');

    return await openDatabase(
      dbPath,
      version: 3, // bump a v3 para columna 'orden'
      onCreate: (db, version) async {
        // Categorías (con user_id y default 'local' + orden)
        await db.execute('''
          CREATE TABLE categorias(
            id TEXT PRIMARY KEY,
            nombre TEXT NOT NULL,
            tipo TEXT NOT NULL,          -- ingreso | gasto
            color TEXT NOT NULL,         -- #RRGGBB
            icono TEXT NOT NULL,         -- nombre de icono Material/FA (con o sin prefijo)
            activo INTEGER NOT NULL,     -- 1/0
            user_id TEXT NOT NULL DEFAULT 'local',
            created TEXT NOT NULL,
            orden INTEGER NOT NULL
          )
        ''');

        // Transacciones (con usuario_id y default 'local')
        await db.execute('''
          CREATE TABLE transacciones(
            id TEXT PRIMARY KEY,
            monto REAL NOT NULL,
            descripcion TEXT NOT NULL,
            fecha TEXT NOT NULL,         -- YYYY-MM-DD
            tipo TEXT NOT NULL,          -- ingreso | gasto
            categoria_id TEXT NOT NULL,
            usuario_id TEXT NOT NULL DEFAULT 'local',
            created TEXT NOT NULL,
            FOREIGN KEY(categoria_id) REFERENCES categorias(id)
          )
        ''');

        await _seedDefaultCategories(db);
      },
      onUpgrade: (db, oldV, newV) async {
        // Migración a v2 (ya existente)
        if (oldV < 2) {
          final colsCat = await db.rawQuery("PRAGMA table_info(categorias)");
          final hasUserId = colsCat.any((c) => (c['name'] as String) == 'user_id');
          if (!hasUserId) {
            await db.execute("ALTER TABLE categorias ADD COLUMN user_id TEXT");
            await db.update('categorias', {'user_id': 'local'});
          }

          final colsTx = await db.rawQuery("PRAGMA table_info(transacciones)");
          final hasUsuarioId = colsTx.any((c) => (c['name'] as String) == 'usuario_id');
          if (!hasUsuarioId) {
            await db.execute("ALTER TABLE transacciones ADD COLUMN usuario_id TEXT");
            await db.update('transacciones', {'usuario_id': 'local'});
          }
        }

        // Migración a v3: columna 'orden' y rellenado incremental por created ASC
        if (oldV < 3) {
          final cols = await db.rawQuery("PRAGMA table_info(categorias)");
          final hasOrden = cols.any((c) => (c['name'] as String) == 'orden');
          if (!hasOrden) {
            await db.execute("ALTER TABLE categorias ADD COLUMN orden INTEGER");
            final rows = await db.query('categorias', orderBy: 'created ASC');
            int i = 1;
            final batch = db.batch();
            for (final r in rows) {
              final id = r['id'] as String;
              batch.update('categorias', {'orden': i}, where: 'id = ?', whereArgs: [id]);
              i++;
            }
            await batch.commit(noResult: true);
          }
        }
      },
    );
  }

  Future<void> _seedDefaultCategories(Database db) async {
    final now = DateTime.now().toIso8601String();
    final rows = await db.query('categorias', limit: 1);
    if (rows.isNotEmpty) return;

    final defaults = <Map<String, String>>[
      {'nombre': 'Alimentación', 'tipo': 'gasto', 'color': '#FF5722', 'icono': 'restaurant'},
      {'nombre': 'Transporte',   'tipo': 'gasto', 'color': '#2196F3', 'icono': 'directions_car'},
      {'nombre': 'Entretenimiento','tipo': 'gasto','color': '#9C27B0','icono': 'movie'},
      {'nombre': 'Servicios',    'tipo': 'gasto', 'color': '#FF9800', 'icono': 'receipt'},
      {'nombre': 'Salud',        'tipo': 'gasto', 'color': '#F44336', 'icono': 'local_hospital'},
      {'nombre': 'Salario',      'tipo': 'ingreso','color': '#4CAF50','icono': 'work'},
      {'nombre': 'Freelance',    'tipo': 'ingreso','color': '#00BCD4','icono': 'computer'},
      {'nombre': 'Inversiones',  'tipo': 'ingreso','color': '#795548','icono': 'trending_up'},
    ];

    final batch = db.batch();
    int orden = 1;
    for (final c in defaults) {
      batch.insert('categorias', {
        'id': const Uuid().v4(),
        'nombre': c['nombre'],
        'tipo': c['tipo'],
        'color': c['color'],
        'icono': c['icono'],
        'activo': 1,
        'user_id': 'local',
        'created': now,
        'orden': orden++,
      });
    }
    await batch.commit(noResult: true);
  }
}