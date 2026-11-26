import 'package:coui_web/coui_web.dart';

class CountdownDefaultExample extends StatefulComponent {
  const CountdownDefaultExample({super.key});

  @override
  State<CountdownDefaultExample> createState() => _CountdownDefaultExampleState();
}

class _CountdownDefaultExampleState extends State<CountdownDefaultExample> {
  @override
  Component build(BuildContext context) {
    return Countdown(value: 42);
  }
}
