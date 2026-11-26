import 'package:coui_flutter/coui_flutter.dart';

class StatOutlinedExample extends StatefulWidget {
  const StatOutlinedExample({super.key});

  @override
  State<StatOutlinedExample> createState() => _StatOutlinedExampleState();
}

class _StatOutlinedExampleState extends State<StatOutlinedExample> {
  @override
  Widget build(BuildContext context) {
    return const Stat(
      label: '총매출',
      value: '4,523만',
      unit: '원',
      variant: CoreStatVariant.outlined,
      change: '+20.1%',
      changeType: CoreStatChangeType.positive,
      description: '환불 전 금액',
    );
  }
}
