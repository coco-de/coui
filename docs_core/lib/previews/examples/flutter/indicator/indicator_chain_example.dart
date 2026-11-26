import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreIndicatorStyle] slot without constructing the widget
/// from scratch.
class IndicatorChainExample extends StatelessWidget {
  const IndicatorChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Indicator(
      item: const Status(
        color: CoreStatusColor.success,
        size: CoreStatusSize.lg,
      ),
      child: const Avatar(initials: 'C'),
    ).withStyle(
      const CoreIndicatorStyle(offset: CoreSpace.space8),
    );
  }
}
