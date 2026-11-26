import 'package:coui_web/coui_web.dart';

class ProgressRadialExample extends StatefulComponent {
  const ProgressRadialExample({super.key});

  @override
  State<ProgressRadialExample> createState() => _ProgressRadialExampleState();
}

class _ProgressRadialExampleState extends State<ProgressRadialExample> {
  @override
  Component build(BuildContext context) {
    return const RadialProgress(
      value: 75,
      showValueText: true,
      radialProgressStyle: CoreRadialProgressStyle(size: 64),
    );
  }
}
