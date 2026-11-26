import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreGapStyle] slot without constructing the widget
/// from scratch.
class GapChainExample extends StatelessWidget {
  const GapChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Button(
          variant: CoreButtonVariant.primary,
          onPressed: () {},
          child: const Text('A'),
        ),
        const Gap.space16().withStyle(
          const CoreGapStyle(
            size: CoreSpace.space64,
            crossAxisExtent: CoreSpace.space24,
            color: CoreColor.token(CoreColors.primary),
          ),
        ),
        Button(
          variant: CoreButtonVariant.primary,
          onPressed: () {},
          child: const Text('B'),
        ),
      ],
    );
  }
}
