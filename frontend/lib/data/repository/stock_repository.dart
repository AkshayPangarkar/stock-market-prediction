import 'package:frontend/data/models/stock_model.dart';
import 'package:frontend/data/services/lstm_predictor.dart';
import 'package:frontend/data/services/yahoo_finance_service.dart';

typedef DashboardBundle = ({DashboardData daily, DashboardData? intraday});

class StockRepository {
  StockRepository({YahooFinanceService? api, LstmPredictor? predictor})
      : _api = api ?? YahooFinanceService(),
        _predictor = predictor ?? LstmPredictor();

  final YahooFinanceService _api;
  final LstmPredictor _predictor;

  static const int _biasDays = 60;

  List<double> _closes = const [];
  DateTime? _lastDailyDate;
  double _biasRatio = 1.0;
  final Map<int, double> _intradayCache = {};

  Future<DashboardBundle> load(String ticker) async {
    await _predictor.load();
    final candles = await _api.fetchDaily(ticker, range: '2y');
    final closes = candles.map((c) => c.close).toList();
    _closes = closes;
    _lastDailyDate = candles.last.date;
    _intradayCache.clear();

    // let the loading spinner paint before the model runs
    await Future<void>.delayed(const Duration(milliseconds: 80));
    final result = _predictor.run(closes);

    _biasRatio = _measureBias(closes, result.predictions);

    final start = candles.length > 260 ? candles.length - 260 : 0;
    final shown = <Candle>[
      for (var i = start; i < candles.length; i++)
        candles[i].withPredicted(_adjust(result.predictions[i])),
    ];

    final last = candles.last.close;
    final prev = candles[candles.length - 2].close;
    final next = result.next * _biasRatio;
    final diff = next - last;
    final name = ticker.trim().toUpperCase();
    final errors = _recentErrors(shown);

    final daily = DashboardData(
      ticker: name,
      currentPrice: last,
      change: last - prev,
      changePct: (last - prev) / prev * 100,
      predictedPrice: next,
      difference: diff,
      differencePct: diff / last * 100,
      candles: shown,
      updatedAt: DateTime.now(),
      modelErrorPct: errors?.model,
      naiveErrorPct: errors?.naive,
    );

    IntradayQuote? quote;
    try {
      quote = await _api.fetchIntraday(ticker);
    } catch (_) {
      quote = null;
    }
    final intraday = quote == null ? null : _fromQuote(name, quote);
    return (daily: daily, intraday: intraday);
  }

  Future<DashboardData> refreshIntraday(String ticker) async {
    final q = await _api.fetchIntraday(ticker);
    return _fromQuote(ticker.trim().toUpperCase(), q);
  }

  double? _adjust(double? p) => p == null ? null : p * _biasRatio;

  ({double model, double naive})? _recentErrors(List<Candle> shown) {
    var m = 0.0, b = 0.0;
    var n = 0;
    for (var i = shown.length - 1; i > 0 && n < _biasDays; i--) {
      final p = shown[i].predicted;
      if (p == null) continue;
      final actual = shown[i].close;
      m += (p - actual).abs() / actual;
      b += (shown[i - 1].close - actual).abs() / actual;
      n++;
    }
    return n == 0 ? null : (model: m / n * 100, naive: b / n * 100);
  }

  double _measureBias(List<double> closes, List<double?> preds) {
    var sum = 0.0;
    var n = 0;
    for (var i = closes.length - 1; i >= 0 && n < _biasDays; i--) {
      final p = preds[i];
      if (p != null && p > 0) {
        sum += closes[i] / p;
        n++;
      }
    }
    if (n == 0) return 1.0;
    final r = sum / n;
    return r < 0.8 ? 0.8 : (r > 1.25 ? 1.25 : r);
  }

  DashboardData _fromQuote(String ticker, IntradayQuote q) {
    final sameSession = _lastDailyDate != null &&
        q.candles.first.date.difference(_lastDailyDate!).abs() <
            const Duration(hours: 12);

    final base = (sameSession && _closes.isNotEmpty)
        ? _closes.sublist(0, _closes.length - 1)
        : List<double>.of(_closes);

    double forecast(double lastClose) =>
        _predictor.predictNext([...base, lastClose]) * _biasRatio;

    final withForecast = <Candle>[];
    for (var i = 0; i < q.candles.length; i++) {
      final c = q.candles[i];
      final isLast = i == q.candles.length - 1;
      final key = c.date.millisecondsSinceEpoch;
      final p = isLast
          ? forecast(q.price)
          : (_intradayCache[key] ??= forecast(c.close));
      withForecast.add(c.withPredicted(p));
    }

    final next = withForecast.last.predicted!;
    final change = q.price - q.previousClose;
    final diff = next - q.price;

    return DashboardData(
      ticker: ticker,
      currentPrice: q.price,
      change: change,
      changePct: change / q.previousClose * 100,
      predictedPrice: next,
      difference: diff,
      differencePct: diff / q.price * 100,
      candles: withForecast,
      isIntraday: true,
      marketOpen: q.marketOpen,
      previousClose: q.previousClose,
      updatedAt: DateTime.now(),
    );
  }
}