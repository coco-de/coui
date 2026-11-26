import 'package:coui_flutter/coui_flutter.dart';

class DotIndicatorVerticalExample extends StatefulWidget {
  const DotIndicatorVerticalExample({super.key});

  @override
  State<DotIndicatorVerticalExample> createState() => _DotIndicatorVerticalExampleState();
}

class _DotIndicatorVerticalExampleState extends State<DotIndicatorVerticalExample> {
  int _index = 2;

  @override
  Widget build(BuildContext context) {
    return DotIndicator(
      index: _index,
      length: 3,
      direction: CoreAxis.vertical,
      onChanged: (v) => setState(() => _index = v),
    );
  }
}
