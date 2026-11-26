import 'package:coui_web/coui_web.dart';

class AppBarDefaultExample extends StatelessComponent {
  const AppBarDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
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
