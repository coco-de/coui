// preview-only sample item count.

import 'package:coui_web/coui_web.dart';

class FadeScrollWithScrollbarExample extends StatelessComponent {
  const FadeScrollWithScrollbarExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        FadeScroll(
          showScrollbar: true,
          child: div([
            for (var i = 0; i < 20; i += 1)
              div(
                [Text('항목 ${i + 1}').bodyMedium.onSurface],
                classes: 'py-${CoreSpace.scale.space8} px-${CoreSpace.scale.space16}',
              ),
          ]),
        ),
      ],
      classes: 'inline-flex',
      styles: Styles(raw: {'height': '${CoreSpace.space200}px'}),
    );
  }
}
