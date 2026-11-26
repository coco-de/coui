import 'package:coui_web/coui_web.dart';

class FabDefaultExample extends StatelessComponent {
  const FabDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return Fab(
      trigger: const Icon(LucideIcons.plus),
      onPressed: () {},
      expandDirection: CoreFabExpandDirection.down,
      actions: [
        FabAction(
          icon: const Icon(LucideIcons.pencil),
          label: Text('편집'),
        ),
        FabAction(
          icon: const Icon(LucideIcons.share2),
          label: Text('공유'),
        ),
      ],
    );
  }
}
