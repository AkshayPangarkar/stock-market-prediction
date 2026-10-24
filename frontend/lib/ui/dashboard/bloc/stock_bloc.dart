import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/core/constants/app_constants.dart';
import 'package:frontend/data/repository/stock_repository.dart';

import 'package:frontend/ui/dashboard/bloc/stock_event.dart';

import 'package:frontend/ui/dashboard/bloc/stock_state.dart';

class StockBloc extends Bloc<StockEvent, StockState> {
  StockBloc(this._repo) : super(StockInitial()) {
    on<StockRequested>(_onRequested);
    on<StockRangeChanged>(_onRangeChanged);
    on<StockTicked>(_onTicked);
  }

  final StockRepository _repo;
  Timer? _timer;

  void _setPolling(bool enabled) {
    _timer?.cancel();
    _timer = null;
    if (enabled) {
      _timer = Timer.periodic(kLiveRefresh, (_) {
        if (!isClosed) add(StockTicked());
      });
    }
  }

  Future<void> _onRequested(
      StockRequested e, Emitter<StockState> emit) async {
    _setPolling(false);
    if (e.ticker.trim().isEmpty) {
      emit(StockFailure('Enter a ticker, e.g. RELIANCE.NS'));
      return;
    }
    emit(StockLoading());
    try {
      final r = await _repo.load(e.ticker);
      // Open on Today when live intraday data exists, otherwise on 3M.
      final range = r.intraday != null ? ChartRange.today : ChartRange.m3;
      emit(StockLoaded(r.daily, range, intraday: r.intraday));
      _setPolling(range.isToday);
    } catch (err) {
      emit(StockFailure(err.toString().replaceFirst('Exception: ', '')));
    }
  }

  void _onRangeChanged(StockRangeChanged e, Emitter<StockState> emit) {
    final s = state;
    if (s is! StockLoaded) return;
    emit(StockLoaded(s.daily, e.range, intraday: s.intraday));
    // Only poll while the Today view is open.
    _setPolling(e.range.isToday && s.intraday != null);
  }

  Future<void> _onTicked(StockTicked e, Emitter<StockState> emit) async {
    final s = state;
    if (s is! StockLoaded || !s.range.isToday) return;
    try {
      final fresh = await _repo.refreshIntraday(s.daily.ticker);
      // The user may have switched range or ticker while we waited.
      final cur = state;
      if (cur is StockLoaded &&
          cur.range.isToday &&
          cur.daily.ticker == s.daily.ticker) {
        emit(StockLoaded(cur.daily, cur.range, intraday: fresh));
      }
    } catch (_) {
      // Keep showing the last good data; the next tick tries again.
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}