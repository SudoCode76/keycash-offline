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
      version: 2, // <- bump de versión para aplicar onUpgrade
      onCreate: (db, version) async {
        // Categorías (con user_id y default 'local')
        await db.execute('''
          CREATE TABLE categorias(
            id TEXT PRIMARY KEY,
            nombre TEXT NOT NULL,
            tipo TEXT NOT NULL,          -- ingreso | gasto
            color TEXT NOT NULL,         -- #RRGGBB
            icono TEXT NOT NULL,         -- nombre de icono Material
            activo INTEGER NOT NULL,     -- 1/0
            user_id TEXT NOT NULL DEFAULT 'local',
            created TEXT NOT NULL
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
        // Migración suave a v2: asegurar columnas user_id / usuario_id y rellenar con 'local'
        if (oldV < 2) {
          // Asegura user_id en categorias
          final colsCat = await db.rawQuery("PRAGMA table_info(categorias)");
          final hasUserId = colsCat.any((c) => (c['name'] as String) == 'user_id');
          if (!hasUserId) {
            await db.execute("ALTER TABLE categorias ADD COLUMN user_id TEXT");
            await db.update('categorias', {'user_id': 'local'});
          }

          // Asegura usuario_id en transacciones
          final colsTx = await db.rawQuery("PRAGMA table_info(transacciones)");
          final hasUsuarioId = colsTx.any((c) => (c['name'] as String) == 'usuario_id');
          if (!hasUsuarioId) {
            await db.execute("ALTER TABLE transacciones ADD COLUMN usuario_id TEXT");
            await db.update('transacciones', {'usuario_id': 'local'});
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
    for (final c in defaults) {
      batch.insert('categorias', {
        'id': const Uuid().v4(),
        'nombre': c['nombre'],
        'tipo': c['tipo'],
        'color': c['color'],
        'icono': c['icono'],
        'activo': 1,
        'user_id': 'local', // <- importante
        'created': now,
      });
    }
    await batch.commit(noResult: true);
  }
}