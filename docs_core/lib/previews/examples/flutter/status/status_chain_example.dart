import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreStatusStyle] slot without constructing the widget
/// from scratch — chained with the primitive-token `.radius16` getter
/// (a direct 1:1 alias for `CoreRadius.radius16`), which is shorter
/// than a second `.withStyle(const CoreStatusStyle(borderRadius:
/// CoreBorderRadius.all(CoreRadius.radius16)))` call.
class StatusChainExample extends StatefulWidget {
  const StatusChainExample({super.key});

  @override
  State<StatusChainExample> createState() => _StatusChainExampleState();
}

class _StatusChainExampleState extends State<StatusChainExample> {
  @override
  Widget build(BuildContext context) {
    return const Status(
          color: CoreStatusColor.primary,
          size: CoreStatusSize.lg,
        )
        .withStyle(
          const CoreStatusStyle(
            size: CoreSize.size24,
            color: CoreColor.token(CoreColors.tertiary),
          ),
        )
        .radius16;
  }
}
