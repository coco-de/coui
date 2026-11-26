import 'package:coui_web/coui_web.dart';

class StatEmptyExample extends StatefulComponent {
  const StatEmptyExample({super.key});

  @override
  State<StatEmptyExample> createState() => _StatEmptyExampleState();
}

class _StatEmptyExampleState extends State<StatEmptyExample> {
  @override
  Component build(BuildContext context) {
    return Stat(
      label: '총매출',
      unit: '원',
      description: '아직 집계 전이에요',
    );
  }
}
