import 'package:coui_web/coui_web.dart';

class ToggleDisabledExample extends StatefulComponent {
  const ToggleDisabledExample({super.key});

  @override
  State<ToggleDisabledExample> createState() => _ToggleDisabledExampleState();
}

class _ToggleDisabledExampleState extends State<ToggleDisabledExample> {
  bool _value = false;

  @override
  Component build(BuildContext context) {
    return Toggle(
      value: _value,
      label: '다크 모드',
      enabled: false,
      onChanged: (value) {
        setState(() {
          _value = value;
        });
      },
    );
  }
}
