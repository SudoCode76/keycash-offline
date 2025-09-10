import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/report_provider.dart';
import '../providers/category_provider.dart';
import '../data/models/category.dart';
import '../data/models/transaction.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Devuelve la vista interna con la UI real de reportes
    return const _ReportsView();
  }
}

class _ReportsView extends StatelessWidget {
  const _ReportsView();

  @override
  Widget build(BuildContext context) {
    // Obtiene el estado de reportes (mes actual, totales, etc.)
    final provider = context.watch<ReportProvider>();
    // Paleta de colores del tema actual
    final scheme = Theme.of(context).colorScheme;
    // Modo oscuro/clarito
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Lista de categorías disponibles (para etiquetar transacciones)
    final cats = context.watch<CategoryProvider>().items;

    return Scaffold(
      // Color de fondo conforme al tema
      backgroundColor: scheme.background,
      // AppBar: barra superior con título y botón de recarga
      appBar: AppBar(
        title: const Text('Reportes Mensuales'),
        centerTitle: true,
        actions: [
          // IconButton: acción para recargar datos
          IconButton(
            tooltip: 'Recargar',
            icon: const Icon(Icons.refresh),
            onPressed: provider.load,
          ),
        ],
      ),
      // body: muestra 3 estados -> cargando, error, o contenido
      body: provider.isLoading
      // Indicador de carga centrado mientras se piden los datos
          ? const Center(child: CircularProgressIndicator())
      // Vista de error con botón para reintentar
          : provider.error != null
          ? _errorState(context, provider.error!, onRetry: provider.load)
      // Contenido principal dentro de un RefreshIndicator para pull-to-refresh
          : RefreshIndicator(
        onRefresh: provider.load,
        color: scheme.primary,
        // ListView: scroll vertical para todas las secciones
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Selector de mes (con flechas prev/next)
            _monthSelector(
              context,
              year: provider.year,
              month: provider.month,
              onPrev: provider.prevMonth,
              onNext: provider.nextMonth,
            ),
            const SizedBox(height: 12),

            // Fila con dos tarjetas de totales: Ingresos y Gastos
            Row(
              children: [
                Expanded(
                  // Tarjeta: total de Ingresos (estilizada en verde)
                  child: _totalCard(
                    context,
                    title: 'Ingresos',
                    value: provider.totalIngresos,
                    color: Colors.green,
                    icon: Icons.arrow_upward_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  // Tarjeta: total de Gastos (estilizada en rojo)
                  child: _totalCard(
                    context,
                    title: 'Gastos',
                    value: provider.totalGastos,
                    color: Colors.red,
                    icon: Icons.arrow_downward_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tarjeta grande con el balance del mes (gradiente y icono)
            _totalBalanceCard(context, provider.balance),
            const SizedBox(height: 16),



            // Título de sección "Top categorías"
            Text(
              'Top categorías',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),

            // Dos columnas: desgloses por categoría (Ingresos y Gastos)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  // Card con barras de progreso por categoría (ingresos)
                  child: _categoryBreakdown(
                    context,
                    title: 'Ingresos',
                    totals: provider.ingresosPorCategoria,
                    grandTotal: provider.totalIngresos,
                    cats: cats,
                    positive: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  // Card con barras de progreso por categoría (gastos)
                  child: _categoryBreakdown(
                    context,
                    title: 'Gastos',
                    totals: provider.gastosPorCategoria,
                    grandTotal: provider.totalGastos,
                    cats: cats,
                    positive: false,
                  ),
                ),
              ],
            ),

            // SECCIÓN: lista agrupada de transacciones por día (cards por fecha)
            _transactionsByDay(
              context,
              provider.txs,
              cats,
            ),
            const SizedBox(height: 20),

            // Espacio al final para evitar que el último elemento quede pegado al borde
            const SizedBox(height: 100),


          ],
        ),
      ),
    );
  }

  // ======== SECCIÓN: Lista de transacciones agrupadas por día ========
  Widget _transactionsByDay(
      BuildContext context, List<TransactionModel> txs, List<Category> cats) {
    final scheme = Theme.of(context).colorScheme;
    if (txs.isEmpty) {
      // Mensaje vacío cuando no hay transacciones
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Text(
          'No hay transacciones este mes.',
          style: TextStyle(color: scheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Agrupa transacciones por fecha (YYYY-MM-DD) para renderizar por secciones
    final Map<String, List<TransactionModel>> grouped = {};
    for (final t in txs) {
      grouped.putIfAbsent(t.fecha, () => []).add(t);
    }
    // Ordena fechas descendente (más recientes primero)
    final sortedDates = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // descendente (más reciente arriba)

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de sección
        Text(
          'Transacciones por día',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),

        // Por cada fecha, se crea una Card contenedora de sus transacciones
        ...sortedDates.map((fecha) {
          final txsDeEseDia = grouped[fecha]!;
          return Card(
            // Card: contenedor visual con fondo y leve separación
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            color: scheme.surfaceVariant.withOpacity(
                Theme.of(context).brightness == Brightness.dark ? 0.13 : 0.94),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encabezado con la fecha
                  Text(
                    fecha,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: scheme.primary,
                        fontSize: 15),
                  ),
                  const SizedBox(height: 4),

                  // ListTile por cada transacción del día
                  ...txsDeEseDia.map((t) {
                    final isIngreso = t.tipo == 'ingreso';
                    final color = isIngreso ? Colors.green : Colors.red;
                    // Busca la categoría para mostrar nombre y color/icono
                    final cat = cats.firstWhere(
                            (c) => c.id == t.categoriaId,
                        orElse: () => Category(
                            id: '',
                            nombre: isIngreso ? 'Ingreso' : 'Gasto',
                            tipo: t.tipo,
                            color: '#9E9E9E',
                            icono: 'mi:category',
                            activo: true,
                            created: ''));
                    return ListTile(
                      // ListTile: celda compacta con leading/título/subtítulo/trailing
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      // leading: avatar circular con icono y color según tipo
                      leading: CircleAvatar(
                        backgroundColor: color.withOpacity(0.15),
                        child: Icon(Icons.category,
                            color: color, size: 18),
                      ),
                      // title: nombre de la categoría
                      title: Text(
                        cat.nombre,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // subtitle: descripción corta si existe
                      subtitle: t.descripcion.isNotEmpty
                          ? Text(
                        t.descripcion,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                        TextStyle(color: scheme.onSurfaceVariant),
                      )
                          : null,
                      // trailing: monto formateado, con signo y color por tipo
                      trailing: Text(
                        '${isIngreso ? '+' : '-'}Bs. ${t.monto.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        })
      ],
    );
  }

  // ======== SECCIÓN: Selector de mes con flechas ========
  Widget _monthSelector(
      BuildContext context, {
        required int year,
        required int month,
        required VoidCallback onPrev,
        required VoidCallback onNext,
      }) {
    final scheme = Theme.of(context).colorScheme;
    final label = _monthNameEs(month) + ' ' + '$year';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Contenedor con borde y relleno para los controles de mes
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        // Fondo se adapta a modo oscuro/claro
        color: isDark ? Colors.white.withOpacity(0.05) : scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
          isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Row(
        children: [
          // IconButton: ir al mes anterior
          IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left_rounded),
            tooltip: 'Mes anterior',
          ),
          // Texto centrado con el nombre del mes y año
          Expanded(
            child: Center(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          // IconButton: ir al mes siguiente
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
            tooltip: 'Mes siguiente',
          ),
        ],
      ),
    );
  }

  // ======== SECCIÓN: Tarjeta para totales (Ingresos/Gastos) ========
  Widget _totalCard(
      BuildContext context, {
        required String title,
        required double value,
        required Color color,
        required IconData icon,
      }) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Contenedor estilizado como "chip/mini-card" con icono y valor
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        // Usa el color base con opacidades distintas según tema
        color: isDark ? color.withOpacity(0.16) : color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? color.withOpacity(0.35) : color.withOpacity(0.22),
        ),
      ),
      child: Row(
        children: [
          // Avatar redondo con el icono correspondiente
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.08) : color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),

          // Columna con título y valor formateado
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Etiqueta pequeña (Ingresos/Gastos)
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                // Monto total destacado
                Text(
                  'Bs. ${value.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ======== SECCIÓN: Tarjeta del balance mensual con gradiente ========
  Widget _totalBalanceCard(BuildContext context, double balance) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final positive = balance >= 0;

    // Gradiente distinto si el balance es positivo o negativo
    final gradientColors = positive
        ? [
      scheme.primary.withOpacity(isDark ? 0.95 : 1.0),
      scheme.primary.withOpacity(isDark ? 0.65 : 0.75),
    ]
        : [
      Colors.orange.withOpacity(isDark ? 0.9 : 1.0),
      Colors.orange.withOpacity(isDark ? 0.6 : 0.75),
    ];

    // Contenedor grande con gradiente, icono de tendencia y monto
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Row(
        children: [
          // Icono de tendencia (up/down) según balance
          Icon(
            positive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            color: Colors.white,
          ),
          const SizedBox(width: 10),

          // Título "Balance del mes"
          Expanded(
            child: Text(
              'Balance del mes',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Monto del balance con énfasis
          Text(
            'Bs. ${balance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ======== SECCIÓN: Desglose por categoría con barra de progreso ========
  Widget _categoryBreakdown(
      BuildContext context, {
        required String title,
        required Map<String, double> totals,
        required double grandTotal,
        required List<Category> cats,
        required bool positive,
      }) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Obtiene top 5 categorías por monto
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(5).toList();

    // Card contenedora de la lista de categorías y sus barras
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
          isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera con icono (flecha arriba/abajo) y título
          Row(
            children: [
              Icon(
                positive ? Icons.north_east_rounded : Icons.south_east_rounded,
                size: 18,
                color: positive ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Mensaje si no hay datos
          if (top.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Sin datos',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            )
          else
          // Ítems: cada categoría con avatar, nombre, barra y montos
            ...top.map((e) {
              final cat = cats.where((c) => c.id == e.key);
              final category = cat.isNotEmpty ? cat.first : null;
              // Color de la categoría; fallback verde/rojo según tipo
              final color = category != null
                  ? _hexToColor(category.color)
                  : (positive ? Colors.green : Colors.red);
              // Proporción sobre el total para la barra de progreso
              final percent =
              grandTotal > 0 ? (e.value / grandTotal).clamp(0.0, 1.0).toDouble() : 0.0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  children: [
                    // Avatar con icono y color de la categoría
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: color.withOpacity(0.15),
                      child: Icon(
                        Icons.category,
                        color: color,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Columna con nombre y barra de progreso
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nombre de la categoría
                          Text(
                            category?.nombre ?? 'Categoría',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          // Barra de progreso que representa el % sobre el total
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              minHeight: 6,
                              value: percent,
                              backgroundColor: color.withOpacity(0.12),
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Columna derecha con monto y porcentaje
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Monto en bolivianos
                        Text(
                          'Bs. ${e.value.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        // Porcentaje redondeado
                        Text(
                          '${(percent * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ======== SECCIÓN: Estado de error con botón de reintento ========
  Widget _errorState(BuildContext context, String message,
      {required Future<void> Function() onRetry}) {
    final scheme = Theme.of(context).colorScheme;
    // Centro con ícono de error, texto del mensaje y botón "Reintentar"
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: scheme.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // FilledButton con icono para volver a intentar la carga
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  // ======== Utilitarios de formato ========

  // Traduce número de mes a nombre en español
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

  // Convierte string hex (#RRGGBB) a Color de Flutter
  Color _hexToColor(String hex) {
    final v = hex.replaceAll('#', '');
    if (v.length != 6) return Colors.grey;
    return Color(int.parse('FF$v', radix: 16));
  }
}
