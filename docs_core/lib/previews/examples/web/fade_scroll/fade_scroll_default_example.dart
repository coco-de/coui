// preview-only sample item count.

import 'package:coui_web/coui_web.dart';

class FadeScrollDefaultExample extends StatelessComponent {
  const FadeScrollDefaultExample({super.key});

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
        ),
      ],
      classes: 'inline-flex',
      styles: Styles(raw: {'height': '${CoreSpace.space200}px'}),
    );
  }
}
