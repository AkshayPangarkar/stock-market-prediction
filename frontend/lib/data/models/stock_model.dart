class Candle {
  final DateTime date;
  final double open, high, low, close, volume;
  final double? predicted;

  const Candle({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    this.predicted,
  });

  Candle withPredicted(double? p) => Candle(
        date: date,
        open: open,
        high: high,
        low: low,
        close: close,
        volume: volume,
        predicted: p,
      );
}

class DashboardData {
  final String ticker;
  final double currentPrice;
  final double change;
  final double changePct;
  final double predictedPrice;
  final double difference;
  final double differencePct;
  final List<Candle> candles;

  /// True for the "Today" view (5-minute candles of the latest session).
  final bool isIntraday;
  final bool marketOpen;
  final double? previousClose;
  final DateTime updatedAt;

  /// Average daily miss (in %) over the last 60 days, for the model and for the
  /// plain guess "tomorrow = today". Null when not measured.
  final double? modelErrorPct;
  final double? naiveErrorPct;

  const DashboardData({
    required this.ticker,
    required this.currentPrice,
    required this.change,
    required this.changePct,
    required this.predictedPrice,
    required this.difference,
    required this.differencePct,
    required this.candles,
    required this.updatedAt,
    this.isIntraday = false,
    this.marketOpen = false,
    this.previousClose,
    this.modelErrorPct,
    this.naiveErrorPct,
  });
}