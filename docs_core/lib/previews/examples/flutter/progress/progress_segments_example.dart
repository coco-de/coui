import 'package:coui_flutter/coui_flutter.dart';

class ProgressSegmentsExample extends StatelessWidget {
  const ProgressSegmentsExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: double.infinity,
      child: Progress(
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
      ),
    );
  }
}
