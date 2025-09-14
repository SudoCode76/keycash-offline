import 'package:flutter/material.dart';

class BalanceCard extends StatelessWidget {
  final double balance;
  final VoidCallback? onTap;
  const BalanceCard({super.key, required this.balance, this.onTap});

  // Gradiente “positivo” por defecto (morado moderno)
  static const List<Color> _primaryGradient = [
    Color(0xFF6C63FF),
    Color(0xFF5A55EA),
    Color(0xFF512DA8),
  ];

  BoxShadow _softShadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxShadow(
      color:
      (isDark ? Colors.black : Colors.black54).withValues(alpha: isDark ? 0.35 : 0.08),
      blurRadius: 18,
      offset: const Offset(0, 10),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final positive = balance >= 0;

    final gradientColors = positive
        ? _primaryGradient
        : [const Color(0xFFFF8A65), const Color(0xFFFF7043), const Color(0xFFF4511E)];

    final content = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
        ),
        boxShadow: [_softShadow(context)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tu balance',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Bs. ${balance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: content,
    );
  }
}