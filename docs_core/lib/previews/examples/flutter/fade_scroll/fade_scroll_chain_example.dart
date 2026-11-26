// preview-only sample item count.

import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreFadeScrollStyle] slot without constructing the widget
/// from scratch.
class FadeScrollChainExample extends StatelessWidget {
  const FadeScrollChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: CoreSpace.space200,
      child:
          FadeScroll(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < 20; i += 1)
                  Padding(
                    padding: const CoreEdgeInsets.symmetric(
                      vertical: CoreSpace.space8,
                      horizontal: CoreSpace.space16,
                    ).toValue(geometry: Theme.of(context).geometry),
                    child: Text('항목 ${i + 1}').bodyMedium.onSurface,
                  ),
              ],
            ),
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
    );
  }
}
