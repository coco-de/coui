/// Returns a Flutter code snippet string for the TrendChart component.
String trendChartCode(String? variant) {
  return switch (variant) {
    'bar' =>
      '''class TrendChartBarExample extends StatefulWidget {
  const TrendChartBarExample({super.key});

  @override
  State<TrendChartBarExample> createState() => _TrendChartBarExampleState();
}

class _TrendChartBarExampleState extends State<TrendChartBarExample> {
  @override
  Widget build(BuildContext context) {
    return TrendChart(
      variant: CoreTrendChartVariant.bar,
      semanticLabel: '요일별 문의 수',
      points: [
        CoreTrendPoint(date: DateTime(2026, 9, 1), value: 42, label: '월', valueLabel: '42건'),
        CoreTrendPoint(date: DateTime(2026, 9, 2), value: 58, label: '화', valueLabel: '58건'),
        CoreTrendPoint(date: DateTime(2026, 9, 3), value: 35, label: '수', valueLabel: '35건'),
        CoreTrendPoint(date: DateTime(2026, 9, 4), value: 61, label: '목', valueLabel: '61건'),
        CoreTrendPoint(date: DateTime(2026, 9, 5), value: 49, label: '금', valueLabel: '49건'),
        CoreTrendPoint(date: DateTime(2026, 9, 6), value: 12, label: '토', valueLabel: '12건'),
        CoreTrendPoint(date: DateTime(2026, 9, 7), value: 9, label: '일', valueLabel: '9건'),
      ],
    );
  }
}''',
    'chain' =>
      '''class TrendChartChainExample extends StatefulWidget {
  const TrendChartChainExample({super.key});

  @override
  State<TrendChartChainExample> createState() => _TrendChartChainExampleState();
}

class _TrendChartChainExampleState extends State<TrendChartChainExample> {
  @override
  Widget build(BuildContext context) {
    return TrendChart(
      semanticLabel: '월별 구독자 추이',
      points: [
        CoreTrendPoint(date: DateTime(2026, 4), value: 8200, label: '4월', valueLabel: '8,200명'),
        CoreTrendPoint(date: DateTime(2026, 5), value: 9100, label: '5월', valueLabel: '9,100명'),
        CoreTrendPoint(date: DateTime(2026, 6), value: 8800, label: '6월', valueLabel: '8,800명'),
        CoreTrendPoint(date: DateTime(2026, 7), value: 10400, label: '7월', valueLabel: '10,400명'),
        CoreTrendPoint(date: DateTime(2026, 8), value: 11200, label: '8월', valueLabel: '11,200명'),
        CoreTrendPoint(date: DateTime(2026, 9), value: 12480, label: '9월', valueLabel: '12,480명'),
      ],
    ).withStyle(
      const CoreTrendChartStyle(
        plotHeight: CoreSpace.space120,
        lineWidth: CoreStrokeWidth.stroke3,
        seriesColor: CoreColor.token(CoreColors.secondary),
      ),
    );
  }
}''',
    _ =>
      '''class TrendChartDefaultExample extends StatefulWidget {
  const TrendChartDefaultExample({super.key});

  @override
  State<TrendChartDefaultExample> createState() => _TrendChartDefaultExampleState();
}

class _TrendChartDefaultExampleState extends State<TrendChartDefaultExample> {
  int _period = 1;

  @override
  Widget build(BuildContext context) {
    return TrendChart(
      semanticLabel: '월별 구독자 추이',
      summary: const Stat(label: '구독자', value: '12,480명', change: '+11.4%', changeType: CoreStatChangeType.positive),
      periods: const ['7일', '30일', '12개월'],
      selectedPeriodIndex: _period,
      onPeriodChanged: (index) => setState(() => _period = index),
      referenceValue: 12000,
      referenceLabel: '목표 12,000명',
      points: [
        CoreTrendPoint(date: DateTime(2026, 4), value: 8200, label: '4월', valueLabel: '8,200명'),
        CoreTrendPoint(date: DateTime(2026, 5), value: 9100, label: '5월', valueLabel: '9,100명'),
        CoreTrendPoint(date: DateTime(2026, 6), value: 8800, label: '6월', valueLabel: '8,800명'),
        CoreTrendPoint(date: DateTime(2026, 7), value: 10400, label: '7월', valueLabel: '10,400명'),
        CoreTrendPoint(date: DateTime(2026, 8), value: 11200, label: '8월', valueLabel: '11,200명'),
        CoreTrendPoint(date: DateTime(2026, 9), value: 12480, label: '9월', valueLabel: '12,480명'),
      ],
    );
  }
}''',
  };
}
