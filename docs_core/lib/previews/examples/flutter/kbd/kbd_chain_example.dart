import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreKbdStyle] slot without constructing the widget
/// from scratch. Keeps the default example's content and layers a
/// full-control style patch on top.
class KbdChainExample extends StatelessWidget {
  const KbdChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Kbd(keys: ['Ctrl', 'C']).withStyle(
      const CoreKbdStyle(
        keyRadius: CoreBorderRadius.all(CoreRadius.radius9999),
        keyBackgroundColor: CoreColor.token(CoreColors.primaryContainer),
        keyBorderColor: CoreColor.token(CoreColors.primary),
        keyBorderWidth: CoreStrokeWidth.stroke2,
        keyPadding: CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space12,
          vertical: CoreSpace.space6,
        ),
        keyTextStyle: CoreTextStyle.token(
          CoreTextStyles.labelMedium,
          color: CoreColor.token(CoreColors.onPrimaryContainer),
        ),
      ),
    );
  }
}
