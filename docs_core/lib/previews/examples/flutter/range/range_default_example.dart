import 'package:coui_flutter/coui_flutter.dart';

class RangeDefaultExample extends StatefulWidget {
  const RangeDefaultExample({super.key});

  @override
  State<RangeDefaultExample> createState() => _RangeDefaultExampleState();
}

class _RangeDefaultExampleState extends State<RangeDefaultExample> {
  double _min = 20;
  double _max = 80;

  @override
  Widget build(BuildContext context) {
    return Range(
      minValue: _min,
      maxValue: _max,
      onChanged: (min, max) => setState(() {
        _min = min;
        _max = max;
      }),
    );
  }
}
