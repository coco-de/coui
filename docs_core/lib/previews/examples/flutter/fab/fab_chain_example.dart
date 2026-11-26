import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreFabStyle] slot without constructing the widget from
/// scratch.
class FabChainExample extends StatelessWidget {
  const FabChainExample({super.key});

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
    ).withStyle(
      const CoreFabStyle(
        diameter: CoreSize.size72,
        iconStyle: CoreIconStyle(
          size: CoreIconSize.size32,
          color: CoreColor.token(CoreColors.onPrimary),
        ),
        popupStyle: CorePopupStyle(
          backgroundColor: CoreColor.token(CoreColors.primaryContainer),
          borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
        ),
        spacing: CoreSpace.space24,
      ),
    );
  }
}
