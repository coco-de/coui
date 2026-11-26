import 'package:coui_flutter/coui_flutter.dart';

class AppBarDenseExample extends StatelessWidget {
  const AppBarDenseExample({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      variant: CoreAppBarVariant.dense,
      leading: [
        Button(
          variant: CoreButtonVariant.plain,
          size: CoreComponentSize.sm,
          onPressed: () {},
          child: const Icon(LucideIcons.panelLeft),
        ),
      ],
      title: const Text('워크스페이스'),
      trailing: [
        Button(
          variant: CoreButtonVariant.plain,
          size: CoreComponentSize.sm,
          onPressed: () {},
          child: const Icon(LucideIcons.search),
        ),
        Button(
          variant: CoreButtonVariant.plain,
          size: CoreComponentSize.sm,
          onPressed: () {},
          child: const Icon(LucideIcons.settings),
        ),
      ],
    );
  }
}
