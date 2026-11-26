import 'package:coui_flutter/coui_flutter.dart';

class StatDefaultExample extends StatefulWidget {
  const StatDefaultExample({super.key});

  @override
  State<StatDefaultExample> createState() => _StatDefaultExampleState();
}

class _StatDefaultExampleState extends State<StatDefaultExample> {
  @override
  Widget build(BuildContext context) {
    return const Stat(
      label: '총매출',
      value: '4,523만',
      unit: '원',
      change: '+20.1%',
      changeType: CoreStatChangeType.positive,
      description: '환불 전 금액',
    );
  }
}
