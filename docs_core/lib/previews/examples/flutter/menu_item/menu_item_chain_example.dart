import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreMenuItemStyle] slot without constructing the widget
/// from scratch.
class MenuItemChainExample extends StatelessWidget {
  const MenuItemChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CoreLayout.layout280,
      child:
          MenuItem(
            onPressed: () {},
            label: const Text('복사'),
            shortcut: const Text('⌘C'),
            leading: const Icon(LucideIcons.copy),
          ).withStyle(
            const CoreMenuItemStyle(
              padding: CoreEdgeInsets.symmetric(
                horizontal: CoreSpace.space16,
                vertical: CoreSpace.space8,
              ),
              contentGapStyle: CoreGapStyle(size: CoreSpace.space12),
              foregroundColor: CoreColor.token(CoreColors.primary),
            ),
          ),
    );
  }
}
