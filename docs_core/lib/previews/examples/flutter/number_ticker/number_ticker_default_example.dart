import 'package:coui_flutter/coui_flutter.dart';

class NumberTickerDefaultExample extends StatefulWidget {
  const NumberTickerDefaultExample({super.key});

  @override
  State<NumberTickerDefaultExample> createState() => _NumberTickerDefaultExampleState();
}

class _NumberTickerDefaultExampleState extends State<NumberTickerDefaultExample> {
  @override
  Widget build(BuildContext context) {
    return NumberTicker(
      value: 1234,
      initialValue: 0,
    );
  }
}
