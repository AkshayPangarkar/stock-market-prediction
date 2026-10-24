import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:frontend/data/models/stock_model.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

const _up = Color(0xFF1FA04F);
const _down = Color(0xFFE5484D);

class PriceChart extends StatelessWidget {
  const PriceChart({
    super.key,
    required this.candles,
    this.intraday = false,
    this.previousClose,
  });

  final List<Candle> candles;
  final bool intraday;
  final double? previousClose;

  @override
  Widget build(BuildContext context) {
    final maxVol =
        candles.map((c) => c.volume).fold<double>(0, (a, b) => a > b ? a : b);
    final predicted = candles.where((c) => c.predicted != null).toList();

    var lows = candles.map((c) => c.low).reduce((a, b) => a < b ? a : b);
    var highs = candles.map((c) => c.high).reduce((a, b) => a > b ? a : b);
    for (final c in predicted) {
      lows = math.min(lows, c.predicted!);
      highs = math.max(highs, c.predicted!);
    }
    if (intraday && previousClose != null) {
      lows = math.min(lows, previousClose!);
      highs = math.max(highs, previousClose!);
    }
    final pad = (highs - lows) * 0.05;

    return SfCartesianChart(
      legend: const Legend(
        isVisible: true,
        position: LegendPosition.top,
        overflowMode: LegendItemOverflowMode.wrap,
      ),
      trackballBehavior: TrackballBehavior(
        enable: true,
        activationMode: ActivationMode.singleTap,
        tooltipSettings: const InteractiveTooltip(format: 'point.x : point.y'),
      ),
      zoomPanBehavior: ZoomPanBehavior(enablePinching: true, enablePanning: true),
      primaryXAxis: DateTimeCategoryAxis(
        majorGridLines: const MajorGridLines(width: 0),
        dateFormat: intraday ? DateFormat.Hm() : DateFormat('d MMM'),
      ),
      primaryYAxis: NumericAxis(
        minimum: (lows - pad).floorToDouble(),
        maximum: (highs + pad).ceilToDouble(),
        title: const AxisTitle(text: 'Price (₹)'),
      ),
      axes: <ChartAxis>[
        NumericAxis(
          name: 'volume',
          opposedPosition: true,
          maximum: maxVol * 5,
          minimum: 0,
          title: const AxisTitle(text: 'Volume'),
          majorGridLines: const MajorGridLines(width: 0),
          axisLabelFormatter: (a) => ChartAxisLabel(
            a.value >= maxVol * 1.05 ? '' : _compact(a.value),
            a.textStyle,
          ),
        ),
      ],
      series: <CartesianSeries<Candle, DateTime>>[
        ColumnSeries<Candle, DateTime>(
          name: 'Volume',
          yAxisName: 'volume',
          dataSource: candles,
          xValueMapper: (c, _) => c.date,
          yValueMapper: (c, _) => c.volume,
          pointColorMapper: (c, _) =>
              (c.close >= c.open ? _up : _down).withValues(alpha: 0.35),
          width: 0.8,
        ),
        CandleSeries<Candle, DateTime>(
          name: intraday ? 'Price (5-min candles)' : 'Actual Price (Candlestick)',
          dataSource: candles,
          xValueMapper: (c, _) => c.date,
          lowValueMapper: (c, _) => c.low,
          highValueMapper: (c, _) => c.high,
          openValueMapper: (c, _) => c.open,
          closeValueMapper: (c, _) => c.close,
          bullColor: _up,
          bearColor: _down,
          enableSolidCandles: true,
        ),
        LineSeries<Candle, DateTime>(
          name: 'Actual Close (Line)',
          dataSource: candles,
          xValueMapper: (c, _) => c.date,
          yValueMapper: (c, _) => c.close,
          color: const Color(0xFF0B6CFF),
          width: 2,
        ),
        if (intraday && previousClose != null)
          LineSeries<Candle, DateTime>(
            name: 'Previous close',
            dataSource: candles,
            xValueMapper: (c, _) => c.date,
            yValueMapper: (c, _) => previousClose,
            color: Colors.grey,
            width: 1.2,
            dashArray: const <double>[2, 3],
          ),
        LineSeries<Candle, DateTime>(
          name: intraday ? 'Predicted next close (LSTM)' : 'Predicted Close (LSTM)',
          dataSource: predicted,
          xValueMapper: (c, _) => c.date,
          yValueMapper: (c, _) => c.predicted,
          color: const Color(0xFFD6336C),
          width: 2.5,
          dashArray: const <double>[6, 4],
        ),
      ],
    );
  }

  static String _compact(num v) {
    if (v >= 1e7) return '${(v / 1e7).toStringAsFixed(1)}Cr';
    if (v >= 1e5) return '${(v / 1e5).toStringAsFixed(1)}L';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}