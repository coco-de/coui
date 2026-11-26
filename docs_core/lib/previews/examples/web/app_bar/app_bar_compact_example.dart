import 'package:coui_web/coui_web.dart';

class AppBarCompactExample extends StatelessComponent {
  const AppBarCompactExample({super.key});

  @override
  Component build(BuildContext context) {
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
