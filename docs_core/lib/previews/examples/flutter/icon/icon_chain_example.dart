import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreIconStyle] slot without constructing the widget
/// from scratch.
class IconChainExample extends StatelessWidget {
  const IconChainExample({super.key});

  @override
  Widget build(BuildContext context) {
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
