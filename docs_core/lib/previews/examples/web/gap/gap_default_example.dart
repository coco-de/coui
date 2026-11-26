import 'package:coui_web/coui_web.dart';

class GapDefaultExample extends StatelessComponent {
  const GapDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        Button(
          variant: CoreButtonVariant.primary,
          onPressed: () {},
          child: Text('A'),
        ),
        Gap.space16(),
        Button(
          variant: CoreButtonVariant.primary,
          onPressed: () {},
          child: Text('B'),
        ),
      ],
      classes: 'inline-flex flex-row items-center',
    );
  }
}
