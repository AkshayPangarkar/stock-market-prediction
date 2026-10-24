import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/core/constants/app_constants.dart';
import 'package:frontend/data/models/stock_model.dart';
import 'package:frontend/domain/constants/app_routes.dart';
import 'package:frontend/ui/dashboard/bloc/stock_bloc.dart';
import 'package:frontend/ui/dashboard/bloc/stock_event.dart';
import 'package:frontend/ui/dashboard/bloc/stock_state.dart';
import 'package:frontend/ui/dashboard/widgets/price_chart.dart';
import 'package:frontend/ui/dashboard/widgets/summary_cards.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _controller = TextEditingController(text: 'RELIANCE.NS');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _submit());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() =>
      context.read<StockBloc>().add(StockRequested(_controller.text));

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access');
    await prefs.remove('refresh');
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),
      appBar: AppBar(
        title: const Text('Stock Predictor'),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _submit(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _SearchRow(controller: _controller, onSubmit: _submit),
              const SizedBox(height: 16),
              BlocBuilder<StockBloc, StockState>(
                builder: (context, state) => switch (state) {
                  StockInitial() => const SizedBox.shrink(),
                  StockLoading() => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 80),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  StockFailure(:final message) => _ErrorBox(message),
                  StockLoaded() => _Loaded(state: state),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchRow extends StatelessWidget {
  const _SearchRow({required this.controller, required this.onSubmit});
  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onSubmit(),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'e.g. RELIANCE.NS, TCS.NS, AAPL',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        FilledButton(
          onPressed: onSubmit,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Get Data'),
        ),
      ],
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.state});
  final StockLoaded state;

  @override
  Widget build(BuildContext context) {
    final d = state.data;
    final today = state.showingToday;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SummaryCards(data: d),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(TextSpan(children: [
                const TextSpan(
                    text: 'Actual vs Predicted Price ',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                TextSpan(
                    text: today
                        ? '(Today, 5-minute candles)'
                        : '(Candlestick with LSTM Prediction)',
                    style: const TextStyle(fontSize: 13)),
              ])),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final r in ChartRange.values)
                    ChoiceChip(
                      label: Text(r.label),
                      selected: state.range == r,
                      onSelected: (_) =>
                          context.read<StockBloc>().add(StockRangeChanged(r)),
                    ),
                  if (today) _LiveBadge(open: d.marketOpen, updatedAt: d.updatedAt),
                ],
              ),
              if (state.range.isToday && state.intraday == null)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    "Live intraday data isn't available for this ticker. Showing the last 3 months.",
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
              if (!today && state.daily.modelErrorPct != null)
                _AccuracyNote(data: state.daily),
              SizedBox(
                height: 420,
                child: PriceChart(
                  key: ValueKey('${d.ticker}-${state.range}'),
                  candles: state.visibleCandles,
                  intraday: today,
                  previousClose: today ? d.previousClose : null,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          today
              ? "Each point on the dashed pink line is the model's forecast for the next daily close if the day ended at that candle's price. It is adjusted by the model's average miss over the last 60 trading days and is not a forecast of the next 5 minutes. Not financial advice."
              : 'Predictions come from a model trained on past prices, adjusted by its average miss over the last 60 trading days. They are not financial advice.',
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
      ],
    );
  }
}

class _AccuracyNote extends StatelessWidget {
  const _AccuracyNote({required this.data});
  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final m = data.modelErrorPct!;
    final b = data.naiveErrorPct!;
    final better = m < b;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        'Accuracy check, last 60 days: the model is off by ${m.toStringAsFixed(2)}% a day on average. '
        'Guessing "tomorrow = today" is off by ${b.toStringAsFixed(2)}%. '
        '${better ? 'The model is closer than that simple guess.' : 'The model is not closer than that simple guess.'}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: better ? const Color(0xFF1FA04F) : const Color(0xFFE5484D),
        ),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.open, required this.updatedAt});
  final bool open;
  final DateTime updatedAt;

  @override
  Widget build(BuildContext context) {
    final color = open ? const Color(0xFF1FA04F) : Colors.grey;
    final time = DateFormat.Hms().format(updatedAt);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 10, color: color),
        const SizedBox(width: 6),
        Text(
          open ? 'Live · updated $time' : 'Market closed · last session · $time',
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE9E9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFE5484D)),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}