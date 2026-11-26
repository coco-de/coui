import 'package:coui_flutter/coui_flutter.dart';

class AppBarTextExample extends StatelessWidget {
  const AppBarTextExample({super.key});

  @override
  Widget build(BuildContext context) {
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
