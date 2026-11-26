import 'package:coui_web/coui_web.dart';

class DotIndicatorVerticalExample extends StatefulComponent {
  const DotIndicatorVerticalExample({super.key});

  @override
  State<DotIndicatorVerticalExample> createState() => _DotIndicatorVerticalExampleState();
}

class _DotIndicatorVerticalExampleState extends State<DotIndicatorVerticalExample> {
  int _index = 2;

  @override
  Component build(BuildContext context) {
    return DotIndicator(
      index: _index,
      length: 3,
      direction: CoreAxis.vertical,
      onChanged: (v) => setState(() => _index = v),
    );
  }
}
