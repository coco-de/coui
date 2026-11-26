import 'package:coui_flutter/coui_flutter.dart';

class ProgressDefaultExample extends StatefulWidget {
  const ProgressDefaultExample({super.key});

  @override
  State<ProgressDefaultExample> createState() => _ProgressDefaultExampleState();
}

class _ProgressDefaultExampleState extends State<ProgressDefaultExample> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: double.infinity,
      child: Progress(value: 0.65),
    );
  }
}
