import 'package:coui_web/coui_web.dart';

class JoinVerticalExample extends StatelessComponent {
  const JoinVerticalExample({super.key});

  @override
  Component build(BuildContext context) {
    return Join(
      vertical: true,
      children: [
        Button(
          variant: CoreButtonVariant.outline,
          onPressed: () {},
          child: Text('A'),
        ),
        Button(
          variant: CoreButtonVariant.outline,
          onPressed: () {},
          child: Text('B'),
        ),
        Button(
          variant: CoreButtonVariant.outline,
          onPressed: () {},
          child: Text('C'),
        ),
      ],
    );
  }
}
