import 'package:coui_web/coui_web.dart';

class ProgressDefaultExample extends StatefulComponent {
  const ProgressDefaultExample({super.key});

  @override
  State<ProgressDefaultExample> createState() => _ProgressDefaultExampleState();
}

class _ProgressDefaultExampleState extends State<ProgressDefaultExample> {
  @override
  Component build(BuildContext context) {
    return Progress(value: 0.65);
  }
}
