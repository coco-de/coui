import 'package:coui_web/coui_web.dart';

class AppBarTextExample extends StatelessComponent {
  const AppBarTextExample({super.key});

  @override
  Component build(BuildContext context) {
    return AppBar(
      leading: [
        Button(
          variant: CoreButtonVariant.ghost,
          onPressed: () {},
          child: const Text('뒤로'),
        ),
      ],
      trailing: [
        Button(
          variant: CoreButtonVariant.ghost,
          buttonStyle: const CoreButtonStyle(
            foregroundColor: CoreColor.token(CoreColors.onSurfaceVariant),
          ),
          onPressed: () {},
          child: const Text('목록으로'),
        ),
      ],
    );
  }
}
