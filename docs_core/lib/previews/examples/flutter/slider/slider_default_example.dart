import 'package:coui_flutter/coui_flutter.dart';

class SliderDefaultExample extends StatefulWidget {
  const SliderDefaultExample({super.key});

  @override
  State<SliderDefaultExample> createState() => _SliderDefaultExampleState();
}

class _SliderDefaultExampleState extends State<SliderDefaultExample> {
  double _value = 50;

  @override
  Widget build(BuildContext context) {
    return Slider(
      value: _value,
      min: 0,
      max: 100,
      onChanged: (v) => setState(() => _value = v),
    );
  }
}
