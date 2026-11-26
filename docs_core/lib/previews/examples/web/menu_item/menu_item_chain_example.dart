import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreMenuItemStyle] slot without constructing the component
/// from scratch.
class MenuItemChainExample extends StatelessComponent {
  const MenuItemChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
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
      ],
      classes: 'w-${CoreLayout.scale.layout280}',
    );
  }
}
