import 'package:coui_web/coui_web.dart';

class SliderDisabledExample extends StatefulComponent {
  const SliderDisabledExample({super.key});

  @override
  State<SliderDisabledExample> createState() => _SliderDisabledExampleState();
}

class _SliderDisabledExampleState extends State<SliderDisabledExample> {
  double _value = 50;

  @override
  Component build(BuildContext context) {
    return Slider(
      value: _value,
      min: 0,
      max: 100,
      enabled: false,
      onChanged: (value) {
        setState(() {
          _value = value;
        });
      },
    );
  }
}
