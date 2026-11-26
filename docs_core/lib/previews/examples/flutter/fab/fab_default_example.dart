import 'package:coui_flutter/coui_flutter.dart';

class FabDefaultExample extends StatelessWidget {
  const FabDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Fab(
      trigger: const Icon(LucideIcons.plus),
      onPressed: () {},
      expandDirection: CoreFabExpandDirection.down,
      actions: [
        FabAction(
          icon: const Icon(LucideIcons.pencil),
          label: const Text('편집'),
        ),
        FabAction(
          icon: const Icon(LucideIcons.share2),
          label: const Text('공유'),
        ),
      ],
    );
  }
}
