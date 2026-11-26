// preview-only sample item count.

import 'package:coui_web/coui_web.dart';

class FadeScrollHorizontalExample extends StatelessComponent {
  const FadeScrollHorizontalExample({super.key});

  @override
  Component build(BuildContext context) {
    return FadeScroll(
      direction: .horizontal,
      showScrollbar: true,
      child: div(
        [
          for (var i = 0; i < 20; i += 1)
            div(
              [Text('항목 ${i + 1}').bodyMedium.onSurface],
              classes:
                  'flex items-center px-${CoreSpace.scale.space12} '
                  'whitespace-nowrap',
            ),
        ],
        classes: 'flex',
        styles: Styles(raw: {'width': 'max-content'}),
      ),
    );
  }
}
