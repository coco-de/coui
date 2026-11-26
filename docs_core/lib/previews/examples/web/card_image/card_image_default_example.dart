import 'package:coui_web/coui_web.dart';

/// Default preview for the unified Web `CardImage`. Uses a fixed
/// 240 × 160 image + a fixed 240 px card width so Flutter/Web render at
/// identical size regardless of the preview panel.
class CardImageDefaultExample extends StatelessComponent {
  const CardImageDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        CardImage(
          image: img(
            src: 'https://picsum.photos/seed/coui/240/160',
            classes: 'block object-cover',
            styles: Styles(
              raw: const {
                'width': '240px',
                'height': '160px',
                'margin': '0',
              },
            ),
          ),
          title: Text('산 풍경'),
          subtitle: Text('해 뜰 무렵 촬영'),
          onPressed: () {},
        ),
      ],
      styles: Styles(raw: const {'width': '240px'}),
    );
  }
}
