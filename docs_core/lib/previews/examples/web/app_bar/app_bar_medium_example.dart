import 'package:coui_web/coui_web.dart';

class AppBarMediumExample extends StatelessComponent {
  const AppBarMediumExample({super.key});

  @override
  Component build(BuildContext context) {
    return AppBar(
      variant: CoreAppBarVariant.medium,
      leading: [
        Button(
          variant: CoreButtonVariant.plain,
          onPressed: () {},
          child: const Icon(LucideIcons.arrowLeft),
        ),
      ],
      title: const Text('받은편지함'),
      trailing: [
        Button(
          variant: CoreButtonVariant.plain,
          onPressed: () {},
          child: const Icon(LucideIcons.ellipsisVertical),
        ),
      ],
    );
  }
}
