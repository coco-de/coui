import 'package:coui_web/coui_web.dart';

class StatDefaultExample extends StatefulComponent {
  const StatDefaultExample({super.key});

  @override
  State<StatDefaultExample> createState() => _StatDefaultExampleState();
}

class _StatDefaultExampleState extends State<StatDefaultExample> {
  @override
  Component build(BuildContext context) {
    return Stat(
      label: '총매출',
      value: '4,523만',
      unit: '원',
      change: '+20.1%',
      changeType: CoreStatChangeType.positive,
      description: '환불 전 금액',
    );
  }
}
