import 'package:coui_web/coui_web.dart';

class JoinDefaultExample extends StatelessComponent {
  const JoinDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return Join(
      children: [
        Button(
          variant: CoreButtonVariant.outline,
          onPressed: () {},
          child: Text('1'),
        ),
        Button(
          variant: CoreButtonVariant.outline,
          onPressed: () {},
          child: Text('2'),
        ),
        Button(
          variant: CoreButtonVariant.outline,
          onPressed: () {},
          child: Text('3'),
        ),
      ],
    );
  }
}
