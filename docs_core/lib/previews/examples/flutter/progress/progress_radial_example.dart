import 'package:coui_flutter/coui_flutter.dart';

class ProgressRadialExample extends StatefulWidget {
  const ProgressRadialExample({super.key});

  @override
  State<ProgressRadialExample> createState() => _ProgressRadialExampleState();
}

class _ProgressRadialExampleState extends State<ProgressRadialExample> {
  @override
  Widget build(BuildContext context) {
    return const RadialProgress(
      value: 75,
      showValueText: true,
      radialProgressStyle: CoreRadialProgressStyle(size: 64),
    );
  }
}
