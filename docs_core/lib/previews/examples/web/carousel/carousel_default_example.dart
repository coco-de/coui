import 'package:coui_web/coui_web.dart';

class CarouselDefaultExample extends StatefulComponent {
  const CarouselDefaultExample({super.key});

  @override
  State<CarouselDefaultExample> createState() => _CarouselDefaultExampleState();
}

class _CarouselDefaultExampleState extends State<CarouselDefaultExample> {
  int _index = 0;

  @override
  Component build(BuildContext context) {
    return Carousel(
      currentIndex: _index,
      onIndexChanged: (idx) => setState(() => _index = idx),
      items: [
        div(
          [Text('슬라이드 1')],
          styles: Styles(
            raw: {
              'background': '#3B82F6',
              'color': 'white',
              'font-size': '18px',
              'display': 'flex',
              'align-items': 'center',
              'justify-content': 'center',
              'padding': 'var(--coui-space-64)',
            },
          ),
        ),
        div(
          [Text('슬라이드 2')],
          styles: Styles(
            raw: {
              'background': '#22C55E',
              'color': 'white',
              'font-size': '18px',
              'display': 'flex',
              'align-items': 'center',
              'justify-content': 'center',
              'padding': 'var(--coui-space-64)',
            },
          ),
        ),
        div(
          [Text('슬라이드 3')],
          styles: Styles(
            raw: {
              'background': '#F97316',
              'color': 'white',
              'font-size': '18px',
              'display': 'flex',
              'align-items': 'center',
              'justify-content': 'center',
              'padding': 'var(--coui-space-64)',
            },
          ),
        ),
      ],
    );
  }
}
