import 'package:coui_web/coui_web.dart';

class DotIndicatorDefaultExample extends StatefulComponent {
  const DotIndicatorDefaultExample({super.key});

  @override
  State<DotIndicatorDefaultExample> createState() => _DotIndicatorDefaultExampleState();
}

class _DotIndicatorDefaultExampleState extends State<DotIndicatorDefaultExample> {
  int _index = 2;

  @override
  Component build(BuildContext context) {
    return DotIndicator(
      index: _index,
      length: 5,
      onChanged: (v) => setState(() => _index = v),
    );
  }
}
