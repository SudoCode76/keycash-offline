import 'package:flutter/foundation.dart';
import '../data/models/transaction.dart';
import '../data/repositories/transaction_repository.dart';

class ReportProvider extends ChangeNotifier {
  final _repo = TransactionRepository();

  int _year = DateTime.now().year;
  int _month = DateTime.now().month;

  bool _loading = false;
  String? _error;

  // Datos crudos del mes
  List<TransactionModel> _txs = [];

  // Totales
  double _ingresos = 0;
  double _gastos = 0;

  // Series diarias (1..daysInMonth) indexado por día-1
  late List<double> _ingresosSerie;
  late List<double> _gastosSerie;

  // Totales por categoría (id -> monto)
  final Map<String, double> _ingresosPorCategoria = {};
  final Map<String, double> _gastosPorCategoria = {};

  // Getters
  int get year => _year;
  int get month => _month;
  bool get isLoading => _loading;
  String? get error => _error;
  List<TransactionModel> get txs => _txs;

  double get totalIngresos => _ingresos;
  double get totalGastos => _gastos;
  double get balance => _ingresos - _gastos;

  List<double> get ingresosSerie => _ingresosSerie;
  List<double> get gastosSerie => _gastosSerie;

  Map<String, double> get ingresosPorCategoria => _ingresosPorCategoria;
  Map<String, double> get gastosPorCategoria => _gastosPorCategoria;

  int get daysInMonth => DateTime(_year, _month + 1, 0).day;

  Future<void> init() async {
    await load();
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

    final dCount = daysInMonth;
    _gastosSerie = List<double>.filled(dCount, 0.0);
    _ingresosSerie = List<double>.filled(dCount, 0.0);

    _ingresosPorCategoria.clear();
    _gastosPorCategoria.clear();

    for (final t in _txs) {
      // fecha 'YYYY-MM-DD' -> día 1..31
      final dayStr = t.fecha.length >= 10 ? t.fecha.substring(8, 10) : '01';
      final day = int.tryParse(dayStr) ?? 1;
      final int idx = ((day - 1).clamp(0, dCount - 1)).toInt();

      if (t.tipo == 'ingreso') {
        _ingresos += t.monto;
        _ingresosSerie[idx] = _ingresosSerie[idx] + t.monto;
        _ingresosPorCategoria.update(
          t.categoriaId,
              (v) => v + t.monto,
          ifAbsent: () => t.monto,
        );
      } else {
        _gastos += t.monto;
        _gastosSerie[idx] = _gastosSerie[idx] + t.monto;
        _gastosPorCategoria.update(
          t.categoriaId,
              (v) => v + t.monto,
          ifAbsent: () => t.monto,
        );
      }
    }
  }
}