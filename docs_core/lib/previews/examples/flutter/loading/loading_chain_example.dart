import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreLoadingStyle] slot without constructing the widget
/// from scratch.
class LoadingChainExample extends StatelessWidget {
  const LoadingChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Loading().withStyle(
      const CoreLoadingStyle(
        color: CoreColor.token(CoreColors.tertiary),
        trackColor: CoreColor.token(CoreColors.surfaceContainerHighest),
        size: CoreSize.size48,
        strokeWidth: CoreStrokeWidth.stroke4,
      ),
    );
  }
}
