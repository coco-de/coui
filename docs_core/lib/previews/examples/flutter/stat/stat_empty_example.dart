import 'package:coui_flutter/coui_flutter.dart';

class StatEmptyExample extends StatefulWidget {
  const StatEmptyExample({super.key});

  @override
  State<StatEmptyExample> createState() => _StatEmptyExampleState();
}

class _StatEmptyExampleState extends State<StatEmptyExample> {
  @override
  Widget build(BuildContext context) {
    return const Stat(
      label: '총매출',
      unit: '원',
      description: '아직 집계 전이에요',
    );
  }
}
