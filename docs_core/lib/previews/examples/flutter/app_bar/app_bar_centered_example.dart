import 'package:coui_flutter/coui_flutter.dart';

class AppBarCenteredExample extends StatelessWidget {
  const AppBarCenteredExample({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      leading: [
        Button(
          variant: CoreButtonVariant.plain,
          onPressed: () {},
          child: const Icon(LucideIcons.arrowLeft),
        ),
      ],
      title: const Text('주문 상세'),
      trailing: [
        Button(
          variant: CoreButtonVariant.ghost,
          size: CoreComponentSize.sm,
          onPressed: () {},
          child: const Text('공유'),
        ),
        Button(
          variant: CoreButtonVariant.ghost,
          size: CoreComponentSize.sm,
          onPressed: () {},
          child: const Text('편집'),
        ),
      ],
    );
  }
}
