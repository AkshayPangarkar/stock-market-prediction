import 'package:frontend/core/constants/app_constants.dart';
import 'package:frontend/data/models/stock_model.dart';

sealed class StockState {}

class StockInitial extends StockState {}

class StockLoading extends StockState {}

class StockLoaded extends StockState {
  StockLoaded(this.daily, this.range, {this.intraday});

  final DashboardData daily;
  final DashboardData? intraday;
  final ChartRange range;

  bool get showingToday => range.isToday && intraday != null;

  /// What the cards and chart show right now.
  DashboardData get data => showingToday ? intraday! : daily;

  List<Candle> get visibleCandles {
    if (showingToday) return intraday!.candles;
    final all = daily.candles;
    // "Today" without intraday data falls back to 3 months.
    final days = range.isToday ? ChartRange.m3.days : range.days;
    final n = days > all.length ? all.length : days;
    return all.sublist(all.length - n);
  }
}

class StockFailure extends StockState {
  StockFailure(this.message);
  final String message;
}