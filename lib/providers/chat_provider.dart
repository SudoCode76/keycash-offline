import 'dart:async';
import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:uuid/uuid.dart';

import '../data/models/chat_message.dart';
import '../services/ai_service.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../data/repositories/transaction_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/models/category.dart';

class ChatProvider extends ChangeNotifier {
  final _uuid = const Uuid();
  final AiService _ai;
  final TransactionRepository _txRepo;
  final CategoryRepository _catRepo;

  final List<ChatMessage> _messages = [];
  bool _sending = false;
  String? _error;
  StreamSubscription<GenerateContentResponse>? _streamSub;

  // Límite de transacciones recientes que incluimos en el snapshot.
  static const int _snapshotRecentLimit = 15;

  final String _systemPrompt = '''
Eres un asistente financiero dentro de la app KeyCash Offline.
Objetivo:
- Usa el bloque SNAPSHOT_DATOS_FINANCIEROS (y LAST_TRANSACTIONS) para responder.
- No inventes datos fuera del snapshot.
- Responde SIEMPRE en español.
Formato recomendado:
1) Resumen breve (1-3 oraciones).
2) Si procede, sección "Detalle:" con viñetas.
Moneda: siempre "Bs." (ej: Bs. 1,234.56).
Si faltan datos para algo específico, pide aclaración.
''';

  ChatProvider({
    AiService? service,
    TransactionRepository? txRepo,
    CategoryRepository? catRepo,
  })  : _ai = service ?? AiService(),
        _txRepo = txRepo ?? TransactionRepository(),
        _catRepo = catRepo ?? CategoryRepository() {
    _messages.add(ChatMessage(
      id: _uuid.v4(),
      role: 'model',
      text: '¡Hola! Soy tu asistente financiero. ¿Qué te gustaría saber?',
      createdAt: DateTime.now(),
    ));
  }

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get sending => _sending;
  String? get error => _error;

  // =============== ENVÍO PRINCIPAL (Arreglado) =================
  Future<void> sendMessage(String userText) async {
    final text = userText.trim();
    if (text.isEmpty) return;
    if (_sending) return; // evita enviar mientras hay streaming

    // 1. Agregar SIEMPRE el mensaje del usuario para que aparezca el bubble.
    final userMsg = ChatMessage(
      id: _uuid.v4(),
      role: 'user',
      text: text,
      createdAt: DateTime.now(),
    );
    _messages.add(userMsg);
    notifyListeners();

    // 2. Ver si es un intent determinístico (respuesta directa con datos locales).
    final intent = _matchIntent(text);
    if (intent != null) {
      final reply = await _buildDeterministicReply(intent);
      _messages.add(ChatMessage(
        id: _uuid.v4(),
        role: 'model',
        text: reply,
        createdAt: DateTime.now(),
      ));
      notifyListeners();
      return; // No streaming.
    }

    // 3. Para el resto se usa la API (streaming).
    if (!_ai.hasKey) {
      _error = 'La clave Gemini no está configurada.';
      _messages.add(ChatMessage(
        id: _uuid.v4(),
        role: 'model',
        text:
        'No puedo contactar al modelo porque falta la clave de API. Configúrala para respuestas más elaboradas.',
        createdAt: DateTime.now(),
        error: true,
      ));
      notifyListeners();
      return;
    }

    _error = null;
    _sending = true;
    notifyListeners();

    final responseId = _uuid.v4();
    var modelMsg = ChatMessage(
      id: responseId,
      role: 'model',
      text: '',
      createdAt: DateTime.now(),
      streaming: true,
    );
    _messages.add(modelMsg);
    notifyListeners();

    final snapshot = await _buildFinancialSnapshot();

    // Historial para el modelo
    final history = <Content>[];
    final alreadyHasSystem =
    _messages.any((m) => m.text.contains('SYSTEM_PROMPT:'));
    if (!alreadyHasSystem) {
      history.add(AiService.systemPrompt(_systemPrompt));
    }
    history.add(
      AiService.toContent('user', 'SNAPSHOT_DATOS_FINANCIEROS:\n$snapshot'),
    );
    for (final m in _messages) {
      if (m.streaming && m.role == 'model') continue;
      if (m.text.startsWith('SYSTEM_PROMPT:')) continue;
      if (m.text.startsWith('SNAPSHOT_DATOS_FINANCIEROS:')) continue;
      history.add(AiService.toContent(m.role, m.text));
    }

    try {
      await _streamSub?.cancel();
      _streamSub = _ai.streamGenerate(history).listen(
            (chunk) {
          final partText = chunk.text ?? '';
          if (partText.isEmpty) return;
          modelMsg = modelMsg.copyWith(text: modelMsg.text + partText);
          final idx = _messages.indexWhere((m) => m.id == responseId);
          if (idx != -1) {
            _messages[idx] = modelMsg;
            notifyListeners();
          }
        },
        onError: (e) {
          _error = 'Error generando respuesta: $e';
          _finishWithError(responseId);
        },
        onDone: () => _finalizeStreaming(responseId),
        cancelOnError: true,
      );
    } catch (e) {
      _error = 'Fallo al iniciar streaming: $e';
      _finishWithError(responseId);
    }
  }

  Future<void> stopGeneration() async {
    await _streamSub?.cancel();
    _streamSub = null;
    _sending = false;
    notifyListeners();
  }

  void clearChat() {
    _messages
      ..clear()
      ..add(
        ChatMessage(
          id: _uuid.v4(),
          role: 'model',
          text:
          'Conversación reiniciada. Puedo analizar tus transacciones. Pregunta algo.',
          createdAt: DateTime.now(),
        ),
      );
    notifyListeners();
  }

  // =============== INTENTS =================
  String? _matchIntent(String raw) {
    final q = raw.toLowerCase();
    if (q.contains('ultima transaccion') ||
        q.contains('última transacción') ||
        q.contains('ultima transacción') ||
        q.contains('última transaccion') ||
        q.contains('ultimo movimiento') ||
        q.contains('último movimiento')) {
      return 'last_transaction';
    }
    if (q.contains('balance de hoy') ||
        (q.contains('balance') && q.contains('hoy'))) {
      return 'today_summary';
    }
    if (q.contains('ingresos hoy')) return 'today_ingresos';
    if (q.contains('gastos hoy')) return 'today_gastos';
    if (q.contains('resumen mes') || (q.contains('resumen') && q.contains('mes'))) {
      return 'month_summary';
    }
    if (q.contains('top gastos')) return 'top_gastos';
    if (q.contains('top ingresos')) return 'top_ingresos';
    return null;
  }

  Future<String> _buildDeterministicReply(String intent) async {
    final now = DateTime.now();
    final txMonth = await _txRepo.listByMonth(now.year, now.month);
    final cats = await _catRepo.getAll();
    final catMap = {for (final c in cats) c.id: c};

    String catName(String id) => catMap[id]?.nombre ?? 'Desconocida';
    String fmt(double v) => _fmtMoney(v);

    double ingresosMes = 0, gastosMes = 0;
    double ingresosHoy = 0, gastosHoy = 0;
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final Map<String, double> catIng = {};
    final Map<String, double> catGas = {};

    for (final t in txMonth) {
      final isIng = t.tipo == 'ingreso';
      if (isIng) {
        ingresosMes += t.monto;
        catIng.update(t.categoriaId, (v) => v + t.monto, ifAbsent: () => t.monto);
      } else {
        gastosMes += t.monto;
        catGas.update(t.categoriaId, (v) => v + t.monto, ifAbsent: () => t.monto);
      }
      if (t.fecha == todayStr) {
        if (isIng) {
          ingresosHoy += t.monto;
        } else {
          gastosHoy += t.monto;
        }
      }
    }

    String topLine(Map<String, double> map, int n) {
      if (map.isEmpty) return 'Sin datos';
      final entries = map.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return entries.take(n).map((e) {
        return '${catName(e.key)} (${fmt(e.value)})';
      }).join(', ');
    }

    switch (intent) {
      case 'last_transaction':
        if (txMonth.isEmpty) {
          return 'Aún no tienes transacciones registradas este mes.';
        }
        final last = txMonth.last; // listByMonth devuelve asc -> last = más reciente
        final tipoTxt = last.tipo == 'ingreso' ? 'Ingreso' : 'Gasto';
        return 'Tu última transacción: $tipoTxt de ${fmt(last.monto)} en '
            '${catName(last.categoriaId)} el ${last.fecha}. Descripción: "${last.descripcion}".';
      case 'today_summary':
        return 'Hoy: Ingresos ${fmt(ingresosHoy)}, Gastos ${fmt(gastosHoy)}, Balance ${fmt(ingresosHoy - gastosHoy)}.';
      case 'today_ingresos':
        return 'Ingresos de hoy: ${fmt(ingresosHoy)}.';
      case 'today_gastos':
        return 'Gastos de hoy: ${fmt(gastosHoy)}.';
      case 'month_summary':
        return 'Mes actual: Ingresos ${fmt(ingresosMes)}, Gastos ${fmt(gastosMes)}, Balance ${fmt(ingresosMes - gastosMes)}.';
      case 'top_gastos':
        return 'Top categorías de gasto: ${topLine(catGas, 5)}.';
      case 'top_ingresos':
        return 'Top categorías de ingreso: ${topLine(catIng, 5)}.';
      default:
        return 'No pude resolver la solicitud.';
    }
  }

  // ================== SNAPSHOT ENRIQUECIDO PARA GEMINI ==================
  Future<String> _buildFinancialSnapshot() async {
    try {
      final now = DateTime.now();
      final currentMonthTx = await _txRepo.listByMonth(now.year, now.month);
      final prevDate = DateTime(now.year, now.month - 1, 1);
      final prevMonthTx =
      await _txRepo.listByMonth(prevDate.year, prevDate.month);
      final recent = await _txRepo.listRecent(_snapshotRecentLimit);
      final cats = await _catRepo.getAll();
      final catMap = {for (final c in cats) c.id: c};

      String catName(String id) => catMap[id]?.nombre ?? 'Desconocida';
      String fmt(double v) => _fmtMoney(v);

      double ingresosMes = 0, gastosMes = 0;
      double ingresosPrev = 0, gastosPrev = 0;
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      double ingresosHoy = 0, gastosHoy = 0;

      final Map<String, double> catIng = {};
      final Map<String, double> catGas = {};

      for (final t in currentMonthTx) {
        final isIng = t.tipo == 'ingreso';
        if (isIng) {
          ingresosMes += t.monto;
          catIng.update(t.categoriaId, (v) => v + t.monto, ifAbsent: () => t.monto);
        } else {
          gastosMes += t.monto;
          catGas.update(t.categoriaId, (v) => v + t.monto, ifAbsent: () => t.monto);
        }
        if (t.fecha == todayStr) {
          if (isIng) {
            ingresosHoy += t.monto;
          } else {
            gastosHoy += t.monto;
          }
        }
      }
      for (final t in prevMonthTx) {
        if (t.tipo == 'ingreso') {
          ingresosPrev += t.monto;
        } else {
          gastosPrev += t.monto;
        }
      }

      double pctChange(double a, double p) {
        if (p == 0) return a == 0 ? 0 : 100;
        return ((a - p) / p) * 100;
      }

      String topLine(Map<String, double> map, int n) {
        if (map.isEmpty) return 'N/A';
        final entries = map.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        return entries.take(n).map((e) {
          return '${catName(e.key)}(${fmt(e.value)})';
        }).join(', ');
      }

      final balMes = ingresosMes - gastosMes;
      final balPrev = ingresosPrev - gastosPrev;

      final sb = StringBuffer()
        ..writeln('MES_ACTUAL=${_monthNameEs(now.month)}_${now.year}')
        ..writeln(
            'INGRESOS_MES=${fmt(ingresosMes)};GASTOS_MES=${fmt(gastosMes)};BALANCE_MES=${fmt(balMes)}')
        ..writeln(
            'MES_ANTERIOR_INGRESOS=${fmt(ingresosPrev)};MES_ANTERIOR_GASTOS=${fmt(gastosPrev)};MES_ANTERIOR_BALANCE=${fmt(balPrev)}')
        ..writeln(
            'CAMBIOS_PCT=INGRESOS:${pctChange(ingresosMes, ingresosPrev).toStringAsFixed(1)}%;GASTOS:${pctChange(gastosMes, gastosPrev).toStringAsFixed(1)}%;BALANCE:${pctChange(balMes, balPrev).toStringAsFixed(1)}%')
        ..writeln(
            'HOY=$todayStr;INGRESOS_HOY=${fmt(ingresosHoy)};GASTOS_HOY=${fmt(gastosHoy)};BALANCE_HOY=${fmt(ingresosHoy - gastosHoy)}')
        ..writeln('TOP_GASTOS=${topLine(catGas, 5)}')
        ..writeln('TOP_INGRESOS=${topLine(catIng, 5)}')
        ..writeln(
            'TOTAL_TX_MES=${currentMonthTx.length};TOTAL_TX_MES_ANT=${prevMonthTx.length}')
        ..writeln('LAST_TRANSACTIONS (más reciente primero):');

      for (final t in recent) {
        sb.writeln(
            '${t.fecha}|${t.tipo}|${catName(t.categoriaId)}|${fmt(t.monto)}|${_sanitizeDesc(t.descripcion)}');
      }

      return sb.toString();
    } catch (e) {
      return 'SNAPSHOT_ERROR=$e';
    }
  }

  String _sanitizeDesc(String d) {
    final s = d.replaceAll('\n', ' ');
    return s.length > 80 ? '${s.substring(0, 77)}...' : s;
  }

  String _fmtMoney(double v) {
    final str = v.toStringAsFixed(2);
    final parts = str.split('.');
    final intPart = parts[0];
    final dec = parts[1];
    final buf = StringBuffer();
    // formatea con coma cada 3 desde la derecha
    for (int i = 0; i < intPart.length; i++) {
      final pos = intPart.length - i;
      buf.write(intPart[i]);
      if (pos > 1 && pos % 3 == 1) {
        buf.write(',');
      }
    }
    return 'Bs. ${buf.toString()}.$dec';
  }

  String _monthNameEs(int m) {
    const names = [
      '',
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    if (m < 1 || m > 12) return '$m';
    return names[m];
  }

  void _finishWithError(String responseId) {
    final idx = _messages.indexWhere((m) => m.id == responseId);
    if (idx != -1) {
      _messages[idx] = _messages[idx].copyWith(
        streaming: false,
        error: true,
        text: _messages[idx].text.isEmpty
            ? 'Ocurrió un error al generar la respuesta.'
            : _messages[idx].text,
      );
    }
    _sending = false;
    notifyListeners();
  }

  void _finalizeStreaming(String responseId) {
    final idx = _messages.indexWhere((m) => m.id == responseId);
    if (idx != -1) {
      _messages[idx] = _messages[idx].copyWith(streaming: false);
    }
    _sending = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }
}