"""Stock model service: Yahoo Finance data + LSTM predictions, no HTTP in here.

The model is the scale-free one made by train_model.py (stock_model_v2.keras):
  input  : the last 100 daily closes, each as (close / last_close - 1) * SCALE
  output : the next day's move, as (next_close / last_close - 1) * SCALE
"""
import logging
import os
import threading

import numpy as np
import pandas as pd
import yfinance as yf
from django.conf import settings
from django.core.cache import cache
from numpy.lib.stride_tricks import sliding_window_view

log = logging.getLogger(__name__)

WINDOW = 100
SCALE = 10.0
ACCURACY_DAYS = 250
RANGE_DAYS = {"1M": 22, "3M": 66, "6M": 132, "1Y": 252, "All": None}

DAILY_CACHE_SECONDS = 600     # daily candles change once a day (plus the live bar)
INTRADAY_CACHE_SECONDS = 30   # 5-minute candles
ACCURACY_CACHE_SECONDS = 600
LIVE_IF_BAR_NEWER_THAN = pd.Timedelta(minutes=20)

DISCLAIMER = (
    "Model estimates from past prices only. Next-day prices are very hard to predict; "
    "compare with the accuracy block. Not financial advice."
)


# ---------------------------------------------------------------- errors
class StockApiError(Exception):
    status_code = 500


class TickerNotFound(StockApiError):
    status_code = 404


class NotEnoughData(StockApiError):
    status_code = 422


class UpstreamError(StockApiError):
    status_code = 502


class ModelNotAvailable(StockApiError):
    status_code = 503


# ---------------------------------------------------------------- model
_model = None
_model_lock = threading.Lock()
_predict_lock = threading.Lock()


def model_path():
    default = os.path.join(str(settings.BASE_DIR), "ml_models", "stock_model_v2.keras")
    return str(getattr(settings, "STOCK_MODEL_PATH", default))


def get_model():
    """Load the Keras model once per process."""
    global _model
    if _model is None:
        with _model_lock:
            if _model is None:
                path = model_path()
                if not os.path.exists(path):
                    raise ModelNotAvailable(
                        f"Model file not found. Put stock_model_v2.keras at {path}")
                # imported here so manage.py commands that don't need TF stay fast
                from tensorflow.keras.models import load_model
                try:
                    _model = load_model(path, compile=False)
                except Exception as e:  # e.g. saved with a newer Keras than the one installed
                    raise ModelNotAvailable(f"Couldn't load the model: {e}") from e
    return _model


def model_loaded():
    return _model is not None


def _predict_moves(windows):
    """windows: (n, WINDOW) raw closes -> predicted next-day move (fraction) for each row."""
    w = np.asarray(windows, dtype="float64")
    x = (w / w[:, -1:] - 1.0) * SCALE
    model = get_model()
    with _predict_lock:
        y = model.predict(x[..., None], batch_size=256, verbose=0)
    return np.asarray(y, dtype="float64").ravel() / SCALE


# ---------------------------------------------------------------- data
def _flatten(df):
    # newer yfinance returns (field, ticker) columns even for a single ticker
    if isinstance(df.columns, pd.MultiIndex):
        df = df.copy()
        df.columns = df.columns.get_level_values(0)
    return df


def _download(ticker, **kwargs):
    try:
        return yf.download(ticker, auto_adjust=False, progress=False, **kwargs)
    except Exception as e:
        log.warning("yfinance failed for %s: %s", ticker, e)
        raise UpstreamError(f"Couldn't reach Yahoo Finance: {e}") from e


def fetch_daily(ticker, years=10):
    key = f"stock:daily:{ticker}"
    cached = cache.get(key)
    if cached is not None:
        return cached
    df = _download(ticker, period=f"{years}y", interval="1d")
    if df is None or df.empty:
        raise TickerNotFound(f"No data found for '{ticker}'. NSE symbols need .NS, for example RELIANCE.NS.")
    df = _flatten(df).dropna(subset=["Open", "High", "Low", "Close"])
    df.index = pd.to_datetime(df.index).tz_localize(None)
    if len(df) < WINDOW + 60:
        raise NotEnoughData(f"Not enough history for '{ticker}' ({len(df)} trading days).")
    cache.set(key, df, DAILY_CACHE_SECONDS)
    return df


def fetch_intraday(ticker):
    """Latest session in 5-minute bars (the last session if the market is closed)."""
    key = f"stock:intraday:{ticker}"
    cached = cache.get(key)
    if cached is not None:
        return cached
    df = _download(ticker, period="5d", interval="5m")
    if df is None or df.empty:
        raise TickerNotFound(f"No intraday data for '{ticker}'.")
    df = _flatten(df).dropna(subset=["Open", "High", "Low", "Close"])
    last_day = df.index[-1].date()
    df = df[df.index.date == last_day]
    cache.set(key, df, INTRADAY_CACHE_SECONDS)
    return df


# ---------------------------------------------------------------- helpers
def _r(x, nd=4):
    """float for JSON: rounded, None for missing/NaN."""
    if x is None:
        return None
    x = float(x)
    return round(x, nd) if np.isfinite(x) else None


def _currency(ticker):
    return "INR" if ticker.upper().endswith((".NS", ".BO")) else "USD"


def _daily_predictions(closes, span):
    """Predicted moves for the last `span` target days plus tomorrow.

    Returns (start, moves, next_move):
      start     index of the first target day
      moves[k]  predicted move for day start+k, from closes[start+k-100 : start+k]
      next_move predicted move for the day after the last close
    """
    n = len(closes)
    start = max(WINDOW, n - span)
    windows = sliding_window_view(closes, WINDOW)          # windows[k] = closes[k : k+WINDOW]
    moves_all = _predict_moves(windows[start - WINDOW: n - WINDOW + 1])
    return start, moves_all[:-1], float(moves_all[-1])


def _accuracy_block(closes, moves):
    n = len(closes)
    k = min(ACCURACY_DAYS, len(moves))
    pm = moves[-k:]
    prev = closes[n - k - 1: n - 1]
    actual = closes[n - k: n]
    tm = actual / prev - 1.0
    model_rmse = float(np.sqrt(np.mean((pm - tm) ** 2))) * 100
    naive_rmse = float(np.sqrt(np.mean(tm ** 2))) * 100
    direction = float(np.mean(np.sign(pm) == np.sign(tm))) * 100
    gap = (naive_rmse - model_rmse) / naive_rmse * 100 if naive_rmse else 0.0
    verdict = "better" if gap > 1 else ("same" if gap > -1 else "worse")
    return {
        "days": int(k),
        "model_rmse_pct": _r(model_rmse, 3),
        "naive_rmse_pct": _r(naive_rmse, 3),
        "direction_correct_pct": _r(direction, 1),
        "verdict": verdict,
        "meaning": {
            "better": "The model's next-day miss is smaller than guessing 'tomorrow = today'.",
            "same": "The model is about as accurate as guessing 'tomorrow = today'.",
            "worse": "The model is less accurate than guessing 'tomorrow = today'.",
        }[verdict],
    }


def _accuracy_cached(ticker, closes):
    key = f"stock:accuracy:{ticker}"
    block = cache.get(key)
    if block is None:
        _, moves, _ = _daily_predictions(closes, ACCURACY_DAYS)
        block = _accuracy_block(closes, moves)
        cache.set(key, block, ACCURACY_CACHE_SECONDS)
    return block


# ---------------------------------------------------------------- payloads
def build_daily_payload(ticker, rng="3M"):
    daily = fetch_daily(ticker)
    closes = daily["Close"].to_numpy(dtype="float64")
    n = len(closes)

    want = n if RANGE_DAYS[rng] is None else min(RANGE_DAYS[rng], n)
    span = min(max(want, ACCURACY_DAYS), n - WINDOW)
    start, moves, next_move = _daily_predictions(closes, span)

    prev = closes[start - 1: n - 1]
    pred_prices = prev * (1.0 + moves)                      # pred_prices[k] is for day start+k
    accuracy = _accuracy_block(closes, moves)

    last, before = float(closes[-1]), float(closes[-2])
    predicted = last * (1.0 + next_move)

    opens, highs, lows = (daily[c].to_numpy(dtype="float64") for c in ("Open", "High", "Low"))
    volume = daily["Volume"].fillna(0).to_numpy(dtype="float64")
    candles = []
    for i in range(n - want, n):
        candles.append({
            "date": daily.index[i].strftime("%Y-%m-%d"),
            "open": _r(opens[i]), "high": _r(highs[i]), "low": _r(lows[i]), "close": _r(closes[i]),
            "volume": int(volume[i]),
            "predicted": _r(pred_prices[i - start]) if i >= start else None,
        })

    return {
        "status": "success",
        "ticker": ticker,
        "currency": _currency(ticker),
        "interval": "1d",
        "range": rng,
        "as_of": daily.index[-1].strftime("%Y-%m-%d"),
        "current_price": _r(last),
        "change": _r(last - before),
        "change_pct": _r((last - before) / before * 100, 2),
        "predicted_next_close": _r(predicted),
        "difference": _r(predicted - last),
        "difference_pct": _r((predicted - last) / last * 100, 2),
        "accuracy": accuracy,
        "candles": candles,
        "disclaimer": DISCLAIMER,
    }


def build_today_payload(ticker):
    daily = fetch_daily(ticker)
    intra = fetch_intraday(ticker)
    closes = daily["Close"].to_numpy(dtype="float64")

    session_day = intra.index[-1].date()
    before = closes[np.array([d < session_day for d in daily.index.date])]
    if len(before) < WINDOW - 1:
        raise NotEnoughData(f"Not enough daily history before today for '{ticker}'.")
    prev_close = float(before[-1])

    prices = intra["Close"].to_numpy(dtype="float64")
    base = before[-(WINDOW - 1):]
    # "if the day closed at this 5-minute price, what is the forecast for the next daily close?"
    windows = np.hstack([np.tile(base, (len(prices), 1)), prices[:, None]])
    forecasts = prices * (1.0 + _predict_moves(windows))

    last_bar = intra.index[-1]
    if last_bar.tzinfo is None:
        last_bar = last_bar.tz_localize("UTC")
    is_live = bool((pd.Timestamp.now(tz="UTC") - last_bar.tz_convert("UTC")) < LIVE_IF_BAR_NEWER_THAN)

    current = float(prices[-1])
    predicted = float(forecasts[-1])
    opens, highs, lows = (intra[c].to_numpy(dtype="float64") for c in ("Open", "High", "Low"))
    volume = intra["Volume"].fillna(0).to_numpy(dtype="float64")
    candles = [{
        "time": intra.index[i].isoformat(),
        "open": _r(opens[i]), "high": _r(highs[i]), "low": _r(lows[i]), "close": _r(prices[i]),
        "volume": int(volume[i]),
        "predicted": _r(forecasts[i]),
    } for i in range(len(prices))]

    return {
        "status": "success",
        "ticker": ticker,
        "currency": _currency(ticker),
        "interval": "5m",
        "session_date": str(session_day),
        "as_of": last_bar.isoformat(),
        "is_live": is_live,
        "previous_close": _r(prev_close),
        "current_price": _r(current),
        "change": _r(current - prev_close),
        "change_pct": _r((current - prev_close) / prev_close * 100, 2),
        "predicted_next_close": _r(predicted),
        "difference": _r(predicted - current),
        "difference_pct": _r((predicted - current) / current * 100, 2),
        "accuracy": _accuracy_cached(ticker, closes),
        "candles": candles,
        "note": "Each candle's 'predicted' is the model's forecast of the next daily close "
                "if the day ended at that candle's price. It is not a 5-minute forecast.",
        "disclaimer": DISCLAIMER,
    }


def model_info():
    path = model_path()
    return {
        "status": "success",
        "model_file": os.path.basename(path),
        "file_exists": os.path.exists(path),
        "loaded": model_loaded(),
        "window_days": WINDOW,
        "input": f"last {WINDOW} daily closes, each as (close / last_close - 1) * {SCALE:g}",
        "output": "next-day move as (next_close / last_close - 1) * %g" % SCALE,
    }