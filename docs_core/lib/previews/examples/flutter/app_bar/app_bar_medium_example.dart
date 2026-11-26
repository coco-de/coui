import 'package:coui_flutter/coui_flutter.dart';

class AppBarMediumExample extends StatelessWidget {
  const AppBarMediumExample({super.key});

  @override
  Widget build(BuildContext context) {
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
