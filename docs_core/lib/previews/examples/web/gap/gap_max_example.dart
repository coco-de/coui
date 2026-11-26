import 'package:coui_web/coui_web.dart';

class GapMaxExample extends StatelessComponent {
  const GapMaxExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        Button(
          variant: CoreButtonVariant.primary,
          onPressed: () {},
          child: Text('A'),
        ),
        MaxGap.space64(),
        Button(
          variant: CoreButtonVariant.primary,
          onPressed: () {},
          child: Text('B'),
        ),
      ],
      classes: 'flex flex-row items-center w-full',
    );
  }
}
