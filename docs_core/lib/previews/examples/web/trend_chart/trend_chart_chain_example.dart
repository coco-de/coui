import 'package:coui_web/coui_web.dart';

class TrendChartChainExample extends StatefulComponent {
  const TrendChartChainExample({super.key});

  @override
  State<TrendChartChainExample> createState() => _TrendChartChainExampleState();
}

class _TrendChartChainExampleState extends State<TrendChartChainExample> {
  @override
  Component build(BuildContext context) {
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
}
