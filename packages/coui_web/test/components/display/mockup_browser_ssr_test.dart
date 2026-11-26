// Where the address-bar alignment lands in the markup.
//
// `text-align` only moves text inside a box wider than the text. A pill
// that `justify-content`-centres its child shrink-wraps that child to the
// URL, so the alignment has nothing to act on and every value renders
// centred. What makes the field real is structural: the URL sits in a label
// that spans the pill, and the alignment is written on that label.
//
// `testServer` (not `testComponents`) because only the real SSR binding
// hands back markup, and this is a claim about the element the URL's text
// actually lives in.
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/server_test.dart';

const _kUrl = 'a.io';

void main() {
  group('MockupBrowser SSR — the URL label spans the pill', () {
    for (final (align, css) in const [
      (CoreTextAlign.start, 'start'),
      (CoreTextAlign.center, 'center'),
      (CoreTextAlign.end, 'end'),
    ]) {
      testServer('$css: the alignment sits on a full-width label, and the '
          'pill does not shrink-wrap it', (tester) async {
        tester.pumpComponent(
          CoUIWeb(
            theme: .coui,
            child: MockupBrowser(
              showControls: false,
              addressBar: _kUrl,
              mockupBrowserStyle: CoreMockupBrowserStyle(
                addressBarTextAlign: align,
              ),
            ),
          ),
        );
        final response = await tester.request('/');
        // `Text` renders its own inheriting `<span>`; the element the
        // alignment has to be on is the one that holds that span.
        final urlText = response.document
            ?.querySelectorAll('span')
            .where((el) => el.text.trim() == _kUrl)
            .single;
        final label = urlText?.parent;

        expect(label, isNotNull);
        expect(label!.localName, 'div');
        expect(label.classes, containsAll(['flex-1', 'min-w-0', 'truncate']));
        expect(label.attributes['style'], contains('text-align: $css'));

        final pill = label.parent!.parent!;
        expect(pill.classes, containsAll(['flex', 'items-center', 'flex-1']));
        expect(pill.classes, isNot(contains('justify-center')));
        expect(pill.attributes['style'] ?? '', isNot(contains('text-align')));
      });
    }
  });

  group('MockupBrowser SSR — no child collapses the card', () {
    // The contract says a `null` child leaves no empty card: the card has
    // no height of its own, so the window keeps its toolbar and the bottom
    // thickness only — the same collapse Flutter's height-less `Container`
    // makes. What would break that here is the card carrying a height or
    // placeholder content of its own.
    testServer('the card renders with no content and no height', (
      tester,
    ) async {
      tester.pumpComponent(
        CoUIWeb(theme: .coui, child: const MockupBrowser(addressBar: null)),
      );
      final response = await tester.request('/');
      final card = response.document
          ?.querySelectorAll('div')
          .where(
            (el) =>
                el.classes.contains('overflow-hidden') &&
                el.classes.contains('bg-surface'),
          )
          .single;

      expect(card, isNotNull);
      expect(card!.children, hasLength(1));
      expect(card.text.trim(), isEmpty);
      final style = card.attributes['style'] ?? '';
      expect(style, contains('height: 100%'));
      expect(style, isNot(contains('padding')));
    });
  });
}
