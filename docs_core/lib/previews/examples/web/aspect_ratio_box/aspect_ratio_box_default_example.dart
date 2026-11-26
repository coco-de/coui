import 'package:coui_web/coui_web.dart';

class AspectRatioBoxDefaultExample extends StatelessComponent {
  const AspectRatioBoxDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      styles: Styles(raw: {'width': '280px', 'max-width': '100%'}),
      [
        AspectRatioBox(
          ratio: 16 / 9,
          child: Card(
            child: div(
              classes: 'flex items-center justify-center w-full h-full',
              [Text('16 : 9').titleMedium],
            ),
          ),
        ),
      ],
    );
  }
}
