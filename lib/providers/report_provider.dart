import 'package:flutter/foundation.dart';
import '../data/models/transaction.dart';
import '../data/repositories/transaction_repository.dart';

class ReportProvider extends ChangeNotifier {
  final _repo = TransactionRepository();

  int _year = DateTime.now().year;
  int _month = DateTime.now().month;

  bool _loading = false;
  String? _error;

  List<TransactionModel> _txs = [];
  double _ingresos = 0;
  double _gastos = 0;
  List<TransactionModel> get txs => _txs;

  final Map<String, double> _ingresosPorCategoria = {};
  final Map<String, double> _gastosPorCategoria = {};

  DateTime? _lastSeenMutation;

  int get year => _year;
  int get month => _month;
  bool get isLoading => _loading;
  String? get error => _error;

  double get totalIngresos => _ingresos;
  double get totalGastos => _gastos;
  double get balance => _ingresos - _gastos;

  Map<String, double> get ingresosPorCategoria => _ingresosPorCategoria;
  Map<String, double> get gastosPorCategoria => _gastosPorCategoria;

  Future<void> onTransactionsChanged(DateTime mutationTs) async {
    if (_lastSeenMutation == null || mutationTs.isAfter(_lastSeenMutation!)) {
      _lastSeenMutation = mutationTs;
      await load();
    }
  }

  Future<void> setMonth(int year, int month) async {
    _year = year;
    _month = month;
    await load();
  }

  Future<void> prevMonth() async {
    final d = DateTime(_year, _month, 1);
    final prev = DateTime(d.year, d.month - 1, 1);
    await setMonth(prev.year, prev.month);
  }

  Future<void> nextMonth() async {
    final d = DateTime(_year, _month, 1);
    final next = DateTime(d.year, d.month + 1, 1);
    await setMonth(next.year, next.month);
  }

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _txs = await _repo.listByMonth(_year, _month);
      _compute();
    } catch (e) {
      _error = 'No se pudo cargar el reporte: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void _compute() {
    _ingresos = 0;
    _gastos = 0;
    _ingresosPorCategoria.clear();
    _gastosPorCategoria.clear();

    for (final t in _txs) {
      if (t.tipo == 'ingreso') {
        _ingresos += t.monto;
        _ingresosPorCategoria.update(t.categoriaId, (v) => v + t.monto,
            ifAbsent: () => t.monto);
      } else {
        _gastos += t.monto;
        _gastosPorCategoria.update(t.categoriaId, (v) => v + t.monto,
            ifAbsent: () => t.monto);
      }
    }
  }
}