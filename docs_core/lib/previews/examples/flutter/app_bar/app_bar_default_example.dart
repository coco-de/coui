import 'package:coui_flutter/coui_flutter.dart';

class AppBarDefaultExample extends StatelessWidget {
  const AppBarDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: [
        Button(
          variant: CoreButtonVariant.plain,
          onPressed: () {},
          child: const Icon(LucideIcons.arrowLeft),
        ),
      ],
      title: const Text('대시보드'),
      trailing: [
        Button(
          variant: CoreButtonVariant.plain,
          onPressed: () {},
          child: const Icon(LucideIcons.settings),
        ),
      ],
    );
  }
}
