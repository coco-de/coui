import 'package:coui_web/coui_web.dart';

class TrendChartDefaultExample extends StatefulComponent {
  const TrendChartDefaultExample({super.key});

  @override
  State<TrendChartDefaultExample> createState() => _TrendChartDefaultExampleState();
}

class _TrendChartDefaultExampleState extends State<TrendChartDefaultExample> {
  int _period = 1;

  @override
  Component build(BuildContext context) {
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
}
