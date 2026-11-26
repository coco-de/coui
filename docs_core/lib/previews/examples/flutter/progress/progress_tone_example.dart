import 'package:coui_flutter/coui_flutter.dart';

class ProgressToneExample extends StatelessWidget {
  const ProgressToneExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Progress(value: 0.65),
        Gap.space8(),
        Progress(value: 0.65, tone: CoreProgressTone.success),
        Gap.space8(),
        Progress(value: 0.65, tone: CoreProgressTone.warning),
        Gap.space8(),
        Progress(value: 0.65, tone: CoreProgressTone.destructive),
      ],
    );
  }
}
