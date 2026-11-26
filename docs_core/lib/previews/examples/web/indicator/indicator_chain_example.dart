import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreIndicatorStyle] slot without constructing the widget
/// from scratch.
class IndicatorChainExample extends StatelessComponent {
  const IndicatorChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return Indicator(
      item: Status(
        color: CoreStatusColor.success,
        size: CoreStatusSize.lg,
      ),
      child: Avatar(initials: 'C'),
    ).withStyle(
      const CoreIndicatorStyle(offset: CoreSpace.space8),
    );
  }
}
