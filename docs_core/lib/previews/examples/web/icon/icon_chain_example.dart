import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreIconStyle] slot without constructing the widget
/// from scratch.
class IconChainExample extends StatelessComponent {
  const IconChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Icon(
      LucideIcons.house,
      iconStyle: CoreIconStyle(size: 28),
    ).withStyle(
      const CoreIconStyle(
        size: CoreIconSize.size32,
        color: CoreColor.token(CoreColors.primary),
      ),
    );
  }
}
