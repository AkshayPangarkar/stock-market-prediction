import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;

typedef _Fn = double Function(double);

_Fn _activation(String name) {
  switch (name) {
    case 'relu':
      return (x) => x > 0 ? x : 0;
    case 'tanh':
      return (x) => (2 / (1 + math.exp(-2 * x))) - 1;
    case 'sigmoid':
      return (x) => 1 / (1 + math.exp(-x));
    case 'hard_sigmoid':
      return (x) => (0.2 * x + 0.5).clamp(0.0, 1.0).toDouble();
    default:
      return (x) => x; // linear
  }
}

Float64List _flatten(List rows) {
  final cols = (rows.first as List).length;
  final out = Float64List(rows.length * cols);
  for (var i = 0; i < rows.length; i++) {
    final row = rows[i] as List;
    for (var j = 0; j < cols; j++) {
      out[i * cols + j] = (row[j] as num).toDouble();
    }
  }
  return out;
}

Float64List _vec(List v) =>
    Float64List.fromList(v.map((e) => (e as num).toDouble()).toList());

abstract class _Layer {
  /// Takes a sequence (time x features) and returns a sequence.
  List<Float64List> forward(List<Float64List> x);
}

class _Lstm implements _Layer {
  _Lstm(Map<String, dynamic> j)
      : units = j['units'] as int,
        returnSeq = j['return_sequences'] as bool,
        act = _activation(j['activation'] as String),
        recAct = _activation(j['recurrent_activation'] as String),
        kernel = _flatten(j['kernel'] as List),
        rec = _flatten(j['recurrent_kernel'] as List),
        bias = _vec(j['bias'] as List) {
    inDim = kernel.length ~/ (4 * units);
  }

  final int units;
  final bool returnSeq;
  final _Fn act, recAct;
  final Float64List kernel, rec, bias;
  late final int inDim;

  @override
  List<Float64List> forward(List<Float64List> x) {
    final u = units, g = 4 * u;
    var h = Float64List(u);
    final c = Float64List(u);
    final z = Float64List(g);
    final out = <Float64List>[];

    for (final xt in x) {
      for (var k = 0; k < g; k++) {
        z[k] = bias[k];
      }
      for (var i = 0; i < inDim; i++) {
        final xv = xt[i];
        if (xv == 0) continue;
        final base = i * g;
        for (var k = 0; k < g; k++) {
          z[k] += xv * kernel[base + k];
        }
      }
      for (var i = 0; i < u; i++) {
        final hv = h[i];
        if (hv == 0) continue;
        final base = i * g;
        for (var k = 0; k < g; k++) {
          z[k] += hv * rec[base + k];
        }
      }
      final nh = Float64List(u);
      for (var j = 0; j < u; j++) {
        // Keras gate order: input, forget, cell candidate, output.
        final ig = recAct(z[j]);
        final fg = recAct(z[u + j]);
        final gg = act(z[2 * u + j]);
        final og = recAct(z[3 * u + j]);
        c[j] = fg * c[j] + ig * gg;
        nh[j] = og * act(c[j]);
      }
      h = nh;
      out.add(h);
    }
    return returnSeq ? out : [out.last];
  }
}

class _Dense implements _Layer {
  _Dense(Map<String, dynamic> j)
      : units = j['units'] as int,
        act = _activation(j['activation'] as String),
        kernel = _flatten(j['kernel'] as List),
        bias = _vec(j['bias'] as List) {
    inDim = kernel.length ~/ units;
  }

  final int units;
  final _Fn act;
  final Float64List kernel, bias;
  late final int inDim;

  @override
  List<Float64List> forward(List<Float64List> x) {
    return [
      for (final xt in x)
        () {
          final o = Float64List(units);
          for (var j = 0; j < units; j++) {
            var s = bias[j];
            for (var i = 0; i < inDim; i++) {
              s += xt[i] * kernel[i * units + j];
            }
            o[j] = act(s);
          }
          return o;
        }(),
    ];
  }
}

/// Runs your trained LSTM in pure Dart (works on web, Android, iOS, desktop).
///
/// Two weight formats are supported:
///  * old: last 100 closes MinMax-scaled to 0..1 (no "normalize" key in the JSON)
///  * new: each 100-day window divided by its own last close
///    ("normalize": {"mode": "window_last", "scale": S}), made by train_model.py
class LstmPredictor {
  static const int window = 100;

  /// How many recent days get a "predicted close" point on the chart.
  static const int predictDays = 132;

  List<_Layer>? _layers;
  bool _ratioMode = false;
  double _scale = 10;

  Future<void> load() async {
    if (_layers != null) return;
    final raw = await rootBundle.loadString('assets/model/lstm_weights.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;

    final norm = json['normalize'] as Map<String, dynamic>?;
    if (norm != null && norm['mode'] == 'window_last') {
      _ratioMode = true;
      _scale = (norm['scale'] as num).toDouble();
    }

    _layers = [
      for (final l in json['layers'] as List)
        switch ((l as Map<String, dynamic>)['type']) {
          'lstm' => _Lstm(l),
          'dense' => _Dense(l),
          _ => null, // dropout is a no-op at inference
        },
    ].whereType<_Layer>().toList();
  }

  /// Forecast for day [end], using closes[end-100 .. end-1].
  double _predictAt(List<double> closes, int end, double minV, double range) {
    final layers = _layers;
    if (layers == null) throw StateError('Call load() first.');

    var seq = <Float64List>[];
    if (_ratioMode) {
      final last = closes[end - 1];
      seq = [
        for (var j = 0; j < window; j++)
          Float64List.fromList([(closes[end - window + j] / last - 1) * _scale]),
      ];
    } else {
      seq = [
        for (var j = 0; j < window; j++)
          Float64List.fromList([(closes[end - window + j] - minV) / range]),
      ];
    }

    for (final layer in layers) {
      seq = layer.forward(seq);
    }
    final y = seq.last[0];
    return _ratioMode ? closes[end - 1] * (1 + y / _scale) : y * range + minV;
  }

  (double, double) _minRange(List<double> closes) {
    var minV = closes.first, maxV = closes.first;
    for (final c in closes) {
      if (c < minV) minV = c;
      if (c > maxV) maxV = c;
    }
    final range = (maxV - minV) == 0 ? 1.0 : (maxV - minV);
    return (minV, range);
  }

  /// One model pass: the forecast for the day after the last close in [closes].
  double predictNext(List<double> closes) {
    final (minV, range) = _minRange(closes);
    return _predictAt(closes, closes.length, minV, range);
  }

  /// predictions[i] = model's guess for closes[i] from closes[i-100 .. i-1],
  /// only for the last [predictDays] days; other slots are null.
  /// [next] is tomorrow's forecast.
  ({List<double?> predictions, double next}) run(List<double> closes) {
    final (minV, range) = _minRange(closes);

    final preds = List<double?>.filled(closes.length, null);
    final from = closes.length - predictDays < window
        ? window
        : closes.length - predictDays;
    for (var i = from; i < closes.length; i++) {
      preds[i] = _predictAt(closes, i, minV, range);
    }
    return (
      predictions: preds,
      next: _predictAt(closes, closes.length, minV, range),
    );
  }
}