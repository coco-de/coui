// `ScrollArea` draws no scrollbar of its own — it composes `Scrollbar` and
// hands it a partial `CoreScrollbarStyle`. These pin what the composed bar
// ends up with, because the only thing `ScrollArea` states is its ink: the
// thickness it used to state is now the `Scrollbar` default, and dropping
// the override must not have moved a pixel.

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/server_test.dart';

Future<String> _css(ServerTester tester) async {
  tester.pumpComponent(
    CoUIWeb(
      theme: .coui,
      child: const ScrollArea(
        id: 'sa',
        child: Component.element(
          tag: 'div',
          children: [Component.text('content')],
        ),
      ),
    ),
  );
  final response = await tester.request('/');
  return response.document!.querySelector('#sa style')!.text;
}

void main() {
  group('ScrollArea composed Scrollbar', () {
    testServer('keeps a 6px thumb: it is now the Scrollbar default, not an '
        'override', (tester) async {
      final css = await _css(tester);

      // 6px thumb + 2px inset on both sides = a 10px footprint, and the
      // capsule is 6px of it, kept 2px clear of the edge.
      expect(css, contains('width: 0.625rem'));
      expect(css, contains('width: 0.375rem'));
      expect(css, contains('inset-inline-end: 0.125rem'));
    });

    testServer('keeps its own 25% ink instead of the Scrollbar 50%', (
      tester,
    ) async {
      final css = await _css(tester);

      // The capsule at rest is the ink at full strength.
      expect(
        css,
        contains('background-color: rgb(var(--coui-on-surface) / 25%)'),
      );
      expect(css, isNot(contains('/ 50%)')));
    });

    testServer('draws the thumb over the content instead of beside it', (
      tester,
    ) async {
      final css = await _css(tester);

      // The browser's own scrollbar is the thing that took 10px of the
      // content's width; it is hidden, and the thumb floats in a layer
      // that has no height of its own.
      expect(css, contains('scrollbar-width: none'));
      expect(css, contains('::-webkit-scrollbar { display: none; }'));
      expect(css, contains('position: sticky'));
      expect(css, contains('height: 0;'));
    });
  });
}
