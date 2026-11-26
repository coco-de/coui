import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreGapStyle] slot without constructing the widget
/// from scratch.
class GapChainExample extends StatelessComponent {
  const GapChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        Button(
          variant: CoreButtonVariant.primary,
          onPressed: () {},
          child: Text('A'),
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
          child: Text('B'),
        ),
      ],
      classes: 'inline-flex flex-row items-center',
    );
  }
}
