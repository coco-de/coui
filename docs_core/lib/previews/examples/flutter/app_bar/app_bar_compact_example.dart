import 'package:coui_flutter/coui_flutter.dart';

class AppBarCompactExample extends StatelessWidget {
  const AppBarCompactExample({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      variant: CoreAppBarVariant.compact,
      leading: [
        Button(
          variant: CoreButtonVariant.plain,
          onPressed: () {},
          child: const Icon(LucideIcons.arrowLeft),
        ),
      ],
      title: const Text('알림'),
      trailing: [
        Button(
          variant: CoreButtonVariant.plain,
          onPressed: () {},
          child: const Icon(LucideIcons.check),
        ),
      ],
    );
  }
}
