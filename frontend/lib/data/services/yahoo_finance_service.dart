import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:frontend/data/models/stock_model.dart';
import 'package:http/http.dart' as http;

/// Browsers block direct calls to Yahoo Finance (no CORS headers). Run with:
///   flutter run -d chrome --dart-define=CORS_PROXY=https://corsproxy.io/?url=
const String kCorsProxy = String.fromEnvironment('CORS_PROXY');

class IntradayQuote {
  const IntradayQuote({
    required this.candles,
    required this.price,
    required this.previousClose,
    required this.marketOpen,
  });
  final List<Candle> candles;
  final double price;
  final double previousClose;
  final bool marketOpen;
}

class YahooFinanceService {
  YahooFinanceService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Future<List<Candle>> fetchDaily(String ticker, {String range = '2y'}) async {
    final result = await _fetchResult(ticker, range, '1d');
    final out = _parseCandles(result);
    if (out.length < 120) {
      throw Exception('Not enough history for "$ticker" to run the model.');
    }
    return out;
  }

  Future<IntradayQuote> fetchIntraday(String ticker) async {
    final result = await _fetchResult(ticker, '1d', '5m');
    final candles = _parseCandles(result);
    if (candles.isEmpty) {
      throw Exception('No intraday data for "$ticker".');
    }

    final meta = (result['meta'] as Map?)?.cast<String, dynamic>() ?? const {};
    final price =
        (meta['regularMarketPrice'] as num?)?.toDouble() ?? candles.last.close;
    final prev = (meta['chartPreviousClose'] as num?)?.toDouble() ??
        (meta['previousClose'] as num?)?.toDouble() ??
        candles.first.open;

    final period = (meta['currentTradingPeriod'] as Map?)?['regular'] as Map?;
    final start = (period?['start'] as num?)?.toInt();
    final end = (period?['end'] as num?)?.toInt();
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final open = start != null && end != null && nowSec >= start && nowSec <= end;

    return IntradayQuote(
      candles: candles,
      price: price,
      previousClose: prev,
      marketOpen: open,
    );
  }

  Future<Map<String, dynamic>> _fetchResult(
      String ticker, String range, String interval) async {
    var uri = Uri.https(
      'query1.finance.yahoo.com',
      '/v8/finance/chart/${ticker.trim().toUpperCase()}',
      {'range': range, 'interval': interval},
    );
    if (kCorsProxy.isNotEmpty) {
      uri = Uri.parse('$kCorsProxy${Uri.encodeComponent(uri.toString())}');
    }

    http.Response res;
    try {
      res = await _client.get(
        uri,
        headers: kIsWeb ? null : {'User-Agent': 'Mozilla/5.0'},
      );
    } catch (_) {
      throw Exception(kIsWeb
          ? "Couldn't reach Yahoo Finance. The browser may be blocking it (CORS). Run with the CORS_PROXY option."
          : "Couldn't reach Yahoo Finance. Check your connection.");
    }

    if (res.statusCode == 404) {
      throw Exception('No data found for "$ticker".');
    }
    if (res.statusCode != 200) {
      throw Exception('Yahoo Finance error (${res.statusCode}).');
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final results = body['chart']?['result'] as List?;
    if (results == null || results.isEmpty) {
      throw Exception('No data found for "$ticker".');
    }
    return results.first as Map<String, dynamic>;
  }

  List<Candle> _parseCandles(Map<String, dynamic> r) {
    final ts = (r['timestamp'] as List?)?.cast<int>() ?? const <int>[];
    if (ts.isEmpty) return const [];
    final q = (r['indicators']['quote'] as List).first as Map<String, dynamic>;

    List<num?> col(String k) => (q[k] as List).cast<num?>();
    final o = col('open'), h = col('high'), l = col('low');
    final c = col('close'), v = col('volume');

    final out = <Candle>[];
    for (var i = 0; i < ts.length; i++) {
      if (o[i] == null || h[i] == null || l[i] == null || c[i] == null) continue;
      out.add(Candle(
        date: DateTime.fromMillisecondsSinceEpoch(ts[i] * 1000),
        open: o[i]!.toDouble(),
        high: h[i]!.toDouble(),
        low: l[i]!.toDouble(),
        close: c[i]!.toDouble(),
        volume: (v[i] ?? 0).toDouble(),
      ));
    }
    return out;
  }
}