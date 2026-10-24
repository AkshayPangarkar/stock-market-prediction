import 'package:flutter/material.dart';
import 'package:frontend/data/models/stock_model.dart';
import 'package:intl/intl.dart';

final _money = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ', decimalDigits: 2);

class SummaryCards extends StatelessWidget {
  const SummaryCards({super.key, required this.data});
  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _Card(
        title: 'Current Price',
        value: _money.format(data.currentPrice),
        delta: data.change,
        deltaPct: data.changePct,
        bg: const Color(0xFFE3EEFF),
        icon: Icons.show_chart,
        iconColor: const Color(0xFF0B6CFF),
      ),
      _Card(
        title: 'Predicted Price',
        value: _money.format(data.predictedPrice),
        delta: data.difference,
        deltaPct: data.differencePct,
        bg: const Color(0xFFDFF5E7),
        icon: Icons.gps_fixed,
        iconColor: const Color(0xFF1FA04F),
      ),
      _Card(
        title: 'Difference',
        value: _money.format(data.difference.abs()),
        delta: data.difference,
        deltaPct: data.differencePct,
        bg: const Color(0xFFFFEBDD),
        icon: Icons.bar_chart_rounded,
        iconColor: const Color(0xFFF08A24),
        pctOnly: true,
      ),
    ];

    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth > 720) {
        return Row(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              Expanded(child: cards[i]),
              if (i != cards.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      }
      return Column(
        children: [
          for (final card in cards) ...[card, const SizedBox(height: 10)],
        ],
      );
    });
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    required this.value,
    required this.delta,
    required this.deltaPct,
    required this.bg,
    required this.icon,
    required this.iconColor,
    this.pctOnly = false,
  });

  final String title, value;
  final double delta, deltaPct;
  final Color bg, iconColor;
  final IconData icon;
  final bool pctOnly;

  @override
  Widget build(BuildContext context) {
    final up = delta >= 0;
    final color = up ? const Color(0xFF1FA04F) : const Color(0xFFE5484D);
    final sign = up ? '+' : '';
    final text = pctOnly
        ? '($sign${deltaPct.toStringAsFixed(2)}%)'
        : '${up ? '↗' : '↘'} $sign${delta.toStringAsFixed(2)} ($sign${deltaPct.toStringAsFixed(2)}%)';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(value,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 26)),
                ),
                const SizedBox(height: 4),
                Text(text,
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
        ],
      ),
    );
  }
}