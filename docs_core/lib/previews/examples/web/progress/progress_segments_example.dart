import 'package:coui_web/coui_web.dart';

class ProgressSegmentsExample extends StatelessComponent {
  const ProgressSegmentsExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Progress(
      value: 1,
      max: 2,
      segments: 2,
      size: CoreProgressSize.xs,
      label: Text('1 / 2단계'),
      progressStyle: CoreProgressStyle(
        labelStyle: CoreTextStyle(
          color: CoreColor.token(CoreColors.primary),
        ),
      ),
    );
  }
}
