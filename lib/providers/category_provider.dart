import 'package:flutter/foundation.dart' hide Category;
import '../data/models/category.dart';
import '../data/repositories/category_repository.dart';

class CategoryProvider extends ChangeNotifier {
  final _repo = CategoryRepository();

  List<Category> _items = [];
  bool _loading = false;
  String? _error;

  List<Category> get items => _items;
  bool get isLoading => _loading;
  String? get error => _error;

  Future<void> load({bool? activo, String? tipo}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _repo.getAll(activo: activo, tipo: tipo);
    } catch (e) {
      _error = 'Error al cargar categorías: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> add({
    required String nombre,
    required String tipo,
    required String color,
    required String icono,
  }) async {
    try {
      await _repo.create(nombre: nombre, tipo: tipo, color: color, icono: icono);
      await load();
      return true;
    } catch (e) {
      _error = 'No se pudo crear: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleActivo(String id, bool activo) async {
    await _repo.toggleActivo(id, activo);
    await load();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await load();
  }
}