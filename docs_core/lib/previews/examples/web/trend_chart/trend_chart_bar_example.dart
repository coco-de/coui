import 'package:coui_web/coui_web.dart';

class TrendChartBarExample extends StatefulComponent {
  const TrendChartBarExample({super.key});

  @override
  State<TrendChartBarExample> createState() => _TrendChartBarExampleState();
}

class _TrendChartBarExampleState extends State<TrendChartBarExample> {
  @override
  Component build(BuildContext context) {
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
}
