import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreClickableStyle] slot without constructing the widget
/// from scratch — chained with the primitive-token `.radius16` getter
/// (a direct 1:1 alias for `CoreRadius.radius16`), which is shorter than
/// a second `.withStyle(const CoreClickableStyle(borderRadius:
/// CoreBorderRadius.all(CoreRadius.radius16)))` call.
class ClickableChainExample extends StatelessWidget {
  const ClickableChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Clickable(
          onPressed: () {},
          child: Card(child: Text('클릭 가능한 영역').bodyMedium),
        )
        .withStyle(
          const CoreClickableStyle(
            disabledOpacity: CoreOpacity.opacity30,
            duration: Duration(milliseconds: CoreDuration.fast),
            pressDuration: Duration(milliseconds: CoreDuration.instant),
          ),
        )
        .radius16;
  }
}
