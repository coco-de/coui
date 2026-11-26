import 'package:coui_web/coui_web.dart';

class ProgressToneExample extends StatelessComponent {
  const ProgressToneExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        const Progress(value: 0.65),
        const Gap.space8(),
        const Progress(value: 0.65, tone: CoreProgressTone.success),
        const Gap.space8(),
        const Progress(value: 0.65, tone: CoreProgressTone.warning),
        const Gap.space8(),
        const Progress(value: 0.65, tone: CoreProgressTone.destructive),
      ],
      classes: 'flex flex-col w-full',
    );
  }
}
