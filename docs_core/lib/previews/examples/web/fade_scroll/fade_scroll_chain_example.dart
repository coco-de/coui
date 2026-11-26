// preview-only sample item count.

import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreFadeScrollStyle] slot without constructing the
/// component from scratch.
class FadeScrollChainExample extends StatelessComponent {
  const FadeScrollChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        FadeScroll(
          child: div([
            for (var i = 0; i < 20; i += 1)
              div(
                [Text('항목 ${i + 1}').bodyMedium.onSurface],
                classes: 'py-${CoreSpace.scale.space8} px-${CoreSpace.scale.space16}',
              ),
          ]),
        ).withStyle(
          const CoreFadeScrollStyle(
            startOffset: CoreSpace.space80,
            endOffset: CoreSpace.space80,
            gradient: [
              CoreColor.token(CoreColors.primary),
              CoreColor.transparent,
            ],
          ),
        ),
      ],
      classes: 'inline-flex',
      styles: Styles(raw: {'height': '${CoreSpace.space200}px'}),
    );
  }
}
