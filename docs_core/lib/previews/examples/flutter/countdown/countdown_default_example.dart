import 'package:coui_flutter/coui_flutter.dart';

class CountdownDefaultExample extends StatefulWidget {
  const CountdownDefaultExample({super.key});

  @override
  State<CountdownDefaultExample> createState() => _CountdownDefaultExampleState();
}

class _CountdownDefaultExampleState extends State<CountdownDefaultExample> {
  @override
  Widget build(BuildContext context) {
    return const Countdown(value: 42);
  }
}
