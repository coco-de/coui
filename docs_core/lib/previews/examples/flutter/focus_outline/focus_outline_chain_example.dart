import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreFocusOutlineStyle] slot without constructing the
/// widget from scratch — chained with the primitive-token `.radius16`
/// getter (a direct 1:1 alias for `CoreRadius.radius16`), which is
/// shorter than a second `.withStyle(const CoreFocusOutlineStyle(
/// borderRadius: CoreBorderRadius.all(CoreRadius.radius16)))` call.
class FocusOutlineChainExample extends StatelessWidget {
  const FocusOutlineChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return FocusOutline(
          focused: true,
          child: Card(child: Text('포커스된 요소').bodyMedium),
        )
        .withStyle(
          const CoreFocusOutlineStyle(
            borderColor: CoreColor.token(CoreColors.tertiary),
            borderWidth: CoreStrokeWidth.stroke3,
            duration: Duration(milliseconds: CoreDuration.fast),
          ),
        )
        .radius16;
  }
}
