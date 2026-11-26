import 'package:coui_web/coui_web.dart';

class NumberTickerDefaultExample extends StatefulComponent {
  const NumberTickerDefaultExample({super.key});

  @override
  State<NumberTickerDefaultExample> createState() => _NumberTickerDefaultExampleState();
}

class _NumberTickerDefaultExampleState extends State<NumberTickerDefaultExample> {
  @override
  Component build(BuildContext context) {
    return NumberTicker(value: 1234, initialValue: 0);
  }
}
