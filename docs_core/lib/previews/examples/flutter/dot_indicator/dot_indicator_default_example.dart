import 'package:coui_flutter/coui_flutter.dart';

class DotIndicatorDefaultExample extends StatefulWidget {
  const DotIndicatorDefaultExample({super.key});

  @override
  State<DotIndicatorDefaultExample> createState() => _DotIndicatorDefaultExampleState();
}

class _DotIndicatorDefaultExampleState extends State<DotIndicatorDefaultExample> {
  int _index = 2;

  @override
  Widget build(BuildContext context) {
    return DotIndicator(
      index: _index,
      length: 5,
      onChanged: (v) => setState(() => _index = v),
    );
  }
}
