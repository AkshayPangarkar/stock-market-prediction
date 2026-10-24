const Duration kLiveRefresh = Duration(seconds: 30);

enum ChartRange {
  today('Today', 0),
  m1('1M', 22),
  m3('3M', 66),
  m6('6M', 132),
  y1('1Y', 252);

  const ChartRange(this.label, this.days);
  final String label;
  final int days;

  bool get isToday => this == ChartRange.today;
}
