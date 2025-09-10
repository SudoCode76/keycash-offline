import 'package:flutter/foundation.dart';
import '../data/models/transaction.dart';
import '../data/repositories/transaction_repository.dart';

class TransactionProvider extends ChangeNotifier {
  final _repo = TransactionRepository();

  bool _loading = false;
  String? _error;
  List<TransactionModel> _today = [];
  double _ingresos = 0;
  double _gastos = 0;

  DateTime _lastMutationTs = DateTime.now();
  DateTime get lastMutationTimestamp => _lastMutationTs;

  bool get isLoading => _loading;
  String? get error => _error;
  List<TransactionModel> get today => _today;
  double get ingresosHoy => _ingresos;
  double get gastosHoy => _gastos;
  double get balanceHoy => _ingresos - _gastos;

  Future<void> loadToday() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final now = DateTime.now();
      _today = await _repo.listByDate(now);
      _calcTotals();
    } catch (e) {
      _error = 'Error al cargar transacciones: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> add({
    required double monto,
    required String descripcion,
    required String tipo,
    required String categoriaId,
    required DateTime fecha,
  }) async {
    try {
      await _repo.create(
        monto: monto,
        descripcion: descripcion,
        fecha: fecha,
        tipo: tipo,
        categoriaId: categoriaId,
      );
      _touchMutation();
      await loadToday();
      return true;
    } catch (e) {
      _error = 'No se pudo guardar: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> update({
    required String id,
    required double monto,
    required String descripcion,
    required String tipo,
    required String categoriaId,
    required DateTime fecha,
  }) async {
    try {
      final existing = await _repo.getById(id);
      final updated = TransactionModel(
        id: existing.id,
        monto: monto,
        descripcion: descripcion,
        fecha:
        '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}',
        tipo: tipo,
        categoriaId: categoriaId,
        created: existing.created,
      );
      await _repo.update(updated);
      _touchMutation();
      await loadToday();
      return true;
    } catch (e) {
      _error = 'No se pudo actualizar: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await _repo.delete(id);
      _touchMutation();
      await loadToday();
      return true;
    } catch (e) {
      _error = 'No se pudo eliminar: $e';
      notifyListeners();
      return false;
    }
  }

  void _calcTotals() {
    double i = 0, g = 0;
    for (final t in _today) {
      if (t.tipo == 'ingreso') i += t.monto;
      if (t.tipo == 'gasto') g += t.monto;
    }
    _ingresos = i;
    _gastos = g;
  }

  void _touchMutation() {
    _lastMutationTs = DateTime.now();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}