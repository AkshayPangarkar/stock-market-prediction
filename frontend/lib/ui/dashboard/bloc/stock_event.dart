import 'package:frontend/core/constants/app_constants.dart';

sealed class StockEvent {}

class StockRequested extends StockEvent {
  StockRequested(this.ticker);
  final String ticker;
}

class StockRangeChanged extends StockEvent {
  StockRangeChanged(this.range);
  final ChartRange range;
}

class StockTicked extends StockEvent {}