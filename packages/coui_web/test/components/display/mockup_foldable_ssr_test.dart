// The markup a browser receives for a Web `MockupFoldable`.
//
// The resolver's rules are covered by `mockup_foldable_style_test.dart`,
// which calls `resolveMockupFoldable` directly, and the mounted component by
// `mockup_foldable_test.dart`. That leaves the seam between them and the
// page: a component that resolved the right chrome and then put it on the
// wrong element, in the wrong order, or without the attributes that keep a
// second copy of the content out of a reader's hands would pass both. This
// file renders the component, so the document has to say it.
//
// `testServer` (not `testComponents`) because only the real SSR binding hands
// back markup — and a server has no frames, so the device is drawn at the
// angle it was given.
import 'package:coui_web/coui_web.dart';
import 'package:html/dom.dart' as html;
import 'package:jaspr_test/server_test.dart';

/// What marks the content, so the document can be asked where it is and how
/// many times.
const String _kContentClass = 'fold-content';

const Component _kContent = div([
  Text('screen'),
], classes: _kContentClass);

Future<html.Element> _render(
  ServerTester tester,
  double angle, {
  double? width,
  bool showCamera = CoreMockupFoldableContract.defaultShowCamera,
  bool showStatus = CoreMockupFoldableContract.defaultShowStatus,
  bool showGestureBar = CoreMockupFoldableContract.defaultShowGestureBar,
  CoreBrightness? screenBrightness,
  CoreMockupFoldableStyle? style,
  String? classes,
  Styles? css,
  Map<String, String>? attributes,
}) async {
  tester.pumpComponent(
    CoUIWeb(
      theme: .coui,
      child: MockupFoldable(
        id: 'fold',
        foldAngle: angle,
        width: width,
        showCamera: showCamera,
        showStatus: showStatus,
        showGestureBar: showGestureBar,
        screenBrightness: screenBrightness,
        mockupFoldableStyle: style,
        classes: classes,
        css: css,
        attributes: attributes,
        child: _kContent,
      ),
    ),
  );
  final response = await tester.request('/');

  return response.document!.querySelector('#fold')!;
}

List<String> _classes(html.Element element) =>
    element.className.split(' ').where((c) => c.isNotEmpty).toList();

/// One declaration of [element]'s inline style.
String? _style(html.Element element, String property) {
  for (final declaration in (element.attributes['style'] ?? '').split(';')) {
    final colon = declaration.indexOf(':');
    if (colon < 0) continue;
    if (declaration.substring(0, colon).trim() == property) {
      return declaration.substring(colon + 1).trim();
    }
  }

  return null;
}

double _rem(String value) => double.parse(value.replaceFirst('rem', '')) * 16;

/// The alpha of a CSS colour the adapter writes: `rgb(…)` is opaque,
/// `rgba(r, g, b, a)` states it as a share and `rgb(var(--x) / N%)` as a
/// percentage.
double _alphaOf(String css) {
  final percent = RegExp(r'/ ([0-9.]+)%\)$').firstMatch(css);
  if (percent != null) return double.parse(percent.group(1)!) / 100;
  final share = RegExp(r'^rgba\(.*, ([0-9.]+)\)$').firstMatch(css);

  return share == null ? 1 : double.parse(share.group(1)!);
}

/// The six parts, back to front, as the document orders them.
({
  html.Element live,
  html.Element rightHalf,
  html.Element rightEdge,
  html.Element leftHalf,
  html.Element leftEdge,
  html.Element cover,
})
_parts(html.Element root) {
  final children = root.children;
  expect(children, hasLength(6));

  return (
    live: children.first,
    rightHalf: children[1],
    rightEdge: children[2],
    leftHalf: children[3],
    leftEdge: children[4],
    cover: children[5],
  );
}

int _contentIn(html.Element element) =>
    element.querySelectorAll('.$_kContentClass').length;

/// What [half] shows: the one box inside it, which cuts it at the hinge.
html.Element _cutOf(html.Element half) => half.children.single;

/// The status islands under [element], in document order: the layer over a
/// screen that takes no pointer and is kept from assistive technology.
List<html.Element> _islands(html.Element element) => element.querySelectorAll(
  'div.pointer-events-none.inset-0[aria-hidden="true"]',
);

/// The screen [island] lies on: the box around the device's content box,
/// which is the box around the room the island is drawn in.
html.Element _screenOf(html.Element island) => island.parent!.parent!.parent!;

void main() {
  group('MockupFoldable SSR — the parts and their order', () {
    for (final angle in [180.0, 144.0, 60.0, 0.0]) {
      testServer('at $angle° the root holds the open body, the right half, '
          'its edge, the left half, its edge and the cover, in that order', (
        tester,
      ) async {
        final root = await _render(tester, angle);
        final parts = _parts(root);

        expect(_classes(root), containsAll(['relative', 'inline-flex']));
        for (final part in root.children) {
          expect(part.localName, 'div');
          expect(_classes(part), containsAll(['absolute', 'left-0', 'top-0']));
        }
        // The open body has no transform of its own: it is the stage.
        expect(_style(parts.live, 'transform'), isNull);
        // The halves are cut at the hinge; nothing else is. The cut is the
        // box inside the turned half, which is that half's own box: a clip
        // of the turned element's own is drawn soft on a dense screen.
        expect(
          _style(_cutOf(parts.rightHalf), 'clip-path'),
          startsWith('inset('),
        );
        expect(
          _style(_cutOf(parts.leftHalf), 'clip-path'),
          startsWith('polygon('),
        );
        for (final half in [parts.rightHalf, parts.leftHalf]) {
          final cut = _cutOf(half);
          expect(cut.localName, 'div');
          expect(_classes(cut), ['absolute', 'inset-0']);
          expect(_style(cut, 'transform'), isNull);
        }
        for (final part in root.children) {
          expect(_style(part, 'clip-path'), isNull);
        }
        // The left slab's parts carry the fold; the right slab's do not.
        final placed = _style(parts.rightHalf, 'transform')!;
        final folded = _style(parts.leftHalf, 'transform')!;
        expect(folded, startsWith(placed));
        expect(_style(parts.rightEdge, 'transform'), startsWith(placed));
        expect(_style(parts.leftEdge, 'transform'), startsWith(folded));
        expect(_style(parts.cover, 'transform'), startsWith(folded));
        expect(_style(parts.cover, 'transform'), endsWith('rotateY(180deg)'));
        // Every transformed part turns about its own corner.
        for (final part in root.children.skip(1)) {
          expect(_style(part, 'transform-origin'), '0 0');
        }
        // An edge is a strip as wide as the slab is deep. It paints nothing
        // itself: it holds one fill, and shows what of that lies inside it.
        for (final edge in [parts.rightEdge, parts.leftEdge]) {
          expect(
            _rem(_style(edge, 'width')!),
            CoreMockupFoldableStyle.defaultThickness,
          );
          expect(_classes(edge), contains('overflow-hidden'));
          expect(_style(edge, 'background-color'), isNull);
          expect(_classes(edge).where((c) => c.startsWith('bg-')), isEmpty);

          final fill = edge.children.single;
          expect(fill.localName, 'div');
          expect(fill.children, isEmpty);
          expect(_classes(fill), containsAll(['absolute', 'top-0', 'h-full']));
          expect(
            _style(fill, 'background-color'),
            CoreMockupFoldableStyle.defaultEdgeColor.toValue(),
          );
        }
      });
    }

    testServer('an edge\u2019s fill is pinned to the side the device\u2019s '
        'outline is on and rounded there, in the variable the body\u2019s '
        'corner is drawn with', (tester) async {
      // What a fill says of itself: the side it is pinned to, and the
      // corners it rounds.
      ({String pinned, List<String> rounded}) cutOf(html.Element edge) {
        final fill = edge.children.single;
        final classes = _classes(fill);

        return (
          pinned: [
            for (final side in ['left', 'right'])
              if (classes.contains('$side-0')) side,
          ].single,
          rounded: [
            for (final corner in [
              'top-left',
              'top-right',
              'bottom-left',
              'bottom-right',
            ])
              if (_style(fill, 'border-$corner-radius') != null) corner,
          ],
        );
      }

      void expectCut(
        html.Element edge, {
        required String pinned,
        required List<String> rounded,
      }) {
        final cut = cutOf(edge);
        expect(cut.pinned, pinned);
        expect(cut.rounded, rounded);
      }

      // A book: the right slab shows its inner face, so its edge ends at
      // its back; the left one shows its inner face too, and its outline is
      // the cover, where its edge starts.
      final book = _parts(await _render(tester, 144));
      expectCut(
        book.rightEdge,
        pinned: 'right',
        rounded: ['top-right', 'bottom-right'],
      );
      expectCut(
        book.leftEdge,
        pinned: 'left',
        rounded: ['top-left', 'bottom-left'],
      );
      // Past upright the left slab shows its cover, and its outline is the
      // inner face.
      final upright = _parts(await _render(tester, 60));
      expectCut(
        upright.leftEdge,
        pinned: 'right',
        rounded: ['top-right', 'bottom-right'],
      );

      for (final edge in [book.rightEdge, book.leftEdge, upright.leftEdge]) {
        final fill = edge.children.single;
        final radii = [
          for (final corner in cutOf(edge).rounded)
            _style(fill, 'border-$corner-radius')!,
        ];
        // Across and down, both through the radius scale's variable: what
        // re-points the scale in the stylesheet reaches the cut with no
        // rebuild.
        for (final radius in [...radii, _style(fill, 'width')!]) {
          expect(radius, contains('var(--coui-radius-'));
          expect(radius, isNot(contains('px')));
        }
        expect(_style(fill, 'width'), startsWith('max('));
      }

      // Flat, no edge is drawn and none states a cut.
      final flat = _parts(await _render(tester, 180));
      for (final edge in [flat.rightEdge, flat.leftEdge]) {
        expect(_classes(edge), contains('hidden'));
        expect(cutOf(edge).rounded, isEmpty);
        expect(
          _style(edge.children.single, 'width'),
          _style(edge, 'width'),
        );
      }
    });

    testServer('which parts are displayed follows the angle', (tester) async {
      Future<Map<String, bool>> shown(double angle) async {
        final parts = _parts(await _render(tester, angle));
        bool displayed(html.Element part) => !_classes(part).contains('hidden');

        return {
          'rightHalf': displayed(parts.rightHalf),
          'rightEdge': displayed(parts.rightEdge),
          'leftHalf': displayed(parts.leftHalf),
          'leftEdge': displayed(parts.leftEdge),
          'cover': displayed(parts.cover),
        };
      }

      // Flat: the open body as it is — no half, no edge, no cover.
      expect(await shown(180), {
        'rightHalf': false,
        'rightEdge': false,
        'leftHalf': false,
        'leftEdge': false,
        'cover': false,
      });
      // A book: both halves and both edges; the cover faces away.
      expect(await shown(144), {
        'rightHalf': true,
        'rightEdge': true,
        'leftHalf': true,
        'leftEdge': true,
        'cover': false,
      });
      // Past upright: the left half has turned its back, which is the cover.
      expect(await shown(60), {
        'rightHalf': true,
        'rightEdge': true,
        'leftHalf': false,
        'leftEdge': true,
        'cover': true,
      });
      // Shut: the cover lies on the right half.
      expect(await shown(0), {
        'rightHalf': true,
        'rightEdge': false,
        'leftHalf': false,
        'leftEdge': false,
        'cover': true,
      });
    });
  });

  group('MockupFoldable SSR — the stage', () {
    testServer('the root is the open body’s box at every angle', (
      tester,
    ) async {
      const width = 400.0;
      final flat = await _render(tester, 180, width: width);
      final box = (_style(flat, 'width'), _style(flat, 'height'));

      expect(_rem(box.$1!), width);
      // A tablet on its side: wider than tall.
      expect(_rem(box.$2!), lessThan(width));
      expect(_rem(box.$2!), greaterThan(width / 2));
      for (final angle in [179.0, 144.0, 90.0, 60.0, 30.0, 0.0]) {
        final root = await _render(tester, angle, width: width);
        expect(
          (_style(root, 'width'), _style(root, 'height')),
          box,
          reason: '$angle°',
        );
      }
    });

    testServer('the open body is a MockupDevice the size of the stage, and '
        'the cover one half as wide and as tall', (tester) async {
      final root = await _render(tester, 0, width: 400);
      final parts = _parts(root);
      final body = parts.live.children.single;
      final cover = parts.cover.children.first;

      expect(_style(body, 'width'), _style(root, 'width'));
      expect(_style(body, 'height'), _style(root, 'height'));
      expect(_rem(_style(cover, 'width')!), 200);
      expect(_style(cover, 'height'), _style(root, 'height'));
      // The cover's own box is the one its transform is applied to.
      expect(_style(parts.cover, 'width'), _style(cover, 'width'));
      expect(_style(parts.cover, 'height'), _style(cover, 'height'));
    });

    testServer('what the caller puts on the component lands on the root', (
      tester,
    ) async {
      final root = await _render(
        tester,
        144,
        classes: 'mx-auto',
        css: const Styles(raw: {'margin-top': '2rem'}),
        attributes: {'data-testid': 'device', 'aria-label': 'Folding phone'},
      );

      expect(root.id, 'fold');
      expect(
        _classes(root),
        containsAll(['relative', 'inline-flex', 'mx-auto']),
      );
      expect(_style(root, 'margin-top'), '2rem');
      // …beside the box the component states, not instead of it.
      expect(_style(root, 'width'), isNotNull);
      expect(root.attributes['data-testid'], 'device');
      expect(root.attributes['aria-label'], 'Folding phone');
      // And on nothing below it.
      expect(root.querySelectorAll('[data-testid]'), isEmpty);
      expect(root.querySelectorAll('.mx-auto'), isEmpty);
    });
  });

  group('MockupFoldable SSR — where the content is', () {
    testServer('open flat: once, in the open body, shown and within reach', (
      tester,
    ) async {
      final root = await _render(tester, 180);
      final parts = _parts(root);

      expect(_contentIn(root), 1);
      expect(_contentIn(parts.live), 1);
      expect(_classes(parts.live), isNot(contains('invisible')));
      expect(_classes(parts.live), isNot(contains('opacity-0')));
      expect(parts.live.attributes.containsKey('inert'), isFalse);
      // No half is drawn: each one's cut holds nothing.
      expect(_cutOf(parts.rightHalf).children, isEmpty);
      expect(_cutOf(parts.leftHalf).children, isEmpty);
    });

    for (final angle in [179.0, 144.0, 60.0]) {
      testServer('at $angle°, bent: the original is hidden and inert, and '
          'each half holds a copy that is inert and hidden from assistive '
          'technology', (tester) async {
        final root = await _render(tester, angle);
        final parts = _parts(root);

        expect(_contentIn(root), 3);
        // The original — mounted, hidden, out of reach.
        expect(_contentIn(parts.live), 1);
        // Out of sight whatever a descendant says of its own visibility.
        expect(_classes(parts.live), containsAll(['invisible', 'opacity-0']));
        expect(_classes(parts.live), isNot(contains('hidden')));
        expect(parts.live.attributes['inert'], '');
        // The copies.
        for (final half in [parts.rightHalf, parts.leftHalf]) {
          expect(_contentIn(half), 1);
          expect(half.attributes['inert'], '');
          expect(half.attributes['aria-hidden'], 'true');
          // The body, the dark of a screen going off, the shade — all
          // inside the cut.
          expect(_cutOf(half).children, hasLength(3));
        }
        expect(_contentIn(parts.cover), 0);
      });
    }

    for (final angle in [30.0, 0.0]) {
      testServer('at $angle°, nearly shut: once, on the cover, within reach', (
        tester,
      ) async {
        final root = await _render(tester, angle);
        final parts = _parts(root);

        expect(_contentIn(root), 1);
        expect(_contentIn(parts.cover), 1);
        expect(_classes(parts.cover), isNot(contains('hidden')));
        expect(parts.cover.attributes.containsKey('inert'), isFalse);
        expect(parts.cover.attributes.containsKey('aria-hidden'), isFalse);
        // The open body is still out of reach, with nothing on its screen.
        expect(parts.live.attributes['inert'], '');
        expect(_contentIn(parts.live), 0);
      });
    }

    testServer('the halves are out of reach at every angle', (tester) async {
      for (final angle in [180.0, 144.0, 0.0]) {
        final parts = _parts(await _render(tester, angle));
        for (final half in [parts.rightHalf, parts.leftHalf]) {
          expect(half.attributes['inert'], '', reason: '$angle°');
          expect(half.attributes['aria-hidden'], 'true', reason: '$angle°');
        }
      }
    });
  });

  group('MockupFoldable SSR — what lies on the bodies', () {
    testServer('the dark of the inner screen and of the cover screen follow '
        'the angle', (tester) async {
      // (angle, inner dark, cover dark), as the shared table has them.
      const table = [
        (0.0, 1.0, 0.0),
        (20.0, 1.0, 0.5),
        (45.0, 0.5, 1.0),
        (144.0, 0.0, 1.0),
      ];

      for (final (angle, innerDark, coverDark) in table) {
        final parts = _parts(await _render(tester, angle));
        final innerScrim = _cutOf(parts.rightHalf).children[1];
        final coverScrim = parts.cover.children[1];

        expect(
          _alphaOf(_style(innerScrim, 'background-color')!),
          closeTo(innerDark, 0.01),
          reason: '$angle° inner',
        );
        expect(
          _alphaOf(_style(coverScrim, 'background-color')!),
          closeTo(coverDark, 0.01),
          reason: '$angle° cover',
        );
        // The same dark on both halves of the one screen.
        expect(
          _cutOf(parts.leftHalf).children[1].attributes['style'],
          innerScrim.attributes['style'],
        );
        for (final layer in [
          innerScrim,
          coverScrim,
          _cutOf(parts.rightHalf).children[2],
          parts.cover.children[2],
        ]) {
          expect(
            _classes(layer),
            containsAll(['absolute', 'pointer-events-none']),
          );
          expect(layer.children, isEmpty);
        }
      }
    });

    testServer('the style reaches the document: the slab’s depth, the '
        'edge colour and the cover’s own device style', (tester) async {
      const edge = CoreColor(0xFF224466);
      // The bezel, not the rail: this device's own default states the rail
      // as a gradient, and on a `MockupDevice` a stated gradient is drawn in
      // place of a stated rail colour.
      const rail = CoreColor(0xFFAA5500);
      final plain = _parts(await _render(tester, 60));
      final styled = _parts(
        await _render(
          tester,
          60,
          style: const CoreMockupFoldableStyle(
            thickness: 24,
            edgeColor: edge,
            coverDeviceStyle: CoreMockupDeviceStyle(bezelColor: rail),
          ),
        ),
      );

      expect(_rem(_style(styled.leftEdge, 'width')!), 24);
      for (final strip in [styled.leftEdge, styled.rightEdge]) {
        expect(
          _style(strip.children.single, 'background-color'),
          edge.toValue(),
        );
        expect(_style(strip, 'background-color'), isNull);
      }
      // The cover's body is drawn with the colour its nested slot was given…
      expect(styled.cover.outerHtml, contains(rail.toValue()));
      expect(plain.cover.outerHtml, isNot(contains(rail.toValue())));
      // …and the open body, which was given none, is not.
      expect(styled.live.outerHtml, isNot(contains(rail.toValue())));
    });

    testServer('the camera is the cover’s: leaving it out changes the '
        'cover and nothing on the open body', (tester) async {
      final drawn = _parts(await _render(tester, 0));
      final left = _parts(await _render(tester, 0, showCamera: false));

      expect(
        left.cover.querySelectorAll('div').length,
        lessThan(drawn.cover.querySelectorAll('div').length),
      );
      expect(left.live.outerHtml, drawn.live.outerHtml);
    });

    testServer('the status flag reaches both screens', (tester) async {
      final drawn = _parts(await _render(tester, 144));
      final left = _parts(await _render(tester, 144, showStatus: false));

      // The clock is the only words an island carries. Asked of the islands
      // rather than of everything kept from assistive technology: a bent
      // copy of the content is kept from it too, and the content's own text
      // is a span.
      Iterable<html.Element> words(html.Element part) => _islands(
        part,
      ).expand((island) => island.querySelectorAll('span'));

      for (final (without, withStatus) in [
        (left.live, drawn.live),
        (left.rightHalf, drawn.rightHalf),
        (left.cover, drawn.cover),
      ]) {
        expect(words(without), isEmpty);
        expect(words(withStatus), isNotEmpty);
      }
    });
  });

  group('MockupFoldable SSR — the status island', () {
    for (final (angle, renderings) in [
      // Flat: the open body and the cover. Bent: the two copies as well.
      (180.0, 2),
      (144.0, 4),
      (60.0, 4),
      (0.0, 4),
    ]) {
      testServer('at $angle° every rendering of a body carries its '
          'screen’s island — $renderings of them — out of a pointer’s way '
          'and kept from assistive technology', (tester) async {
        final root = await _render(tester, angle);
        final parts = _parts(root);
        final bent = angle < 180;

        expect(_islands(root), hasLength(renderings));
        expect(_islands(parts.live), hasLength(1));
        expect(_islands(parts.rightHalf), hasLength(bent ? 1 : 0));
        expect(_islands(parts.leftHalf), hasLength(bent ? 1 : 0));
        expect(_islands(parts.cover), hasLength(1));
        for (final island in _islands(root)) {
          expect(island.localName, 'div');
          expect(island.attributes['aria-hidden'], 'true');
          expect(
            _classes(island),
            containsAll(['absolute', 'inset-0', 'pointer-events-none']),
          );
          // The clock's words, and the indicator's two drawings.
          final clock = island.querySelectorAll('span > span').single;
          expect(clock.text, '9:41');
          final drawings = island.querySelectorAll('svg');
          expect(drawings, hasLength(2));
          for (final drawing in drawings) {
            expect(drawing.attributes['aria-hidden'], 'true');
            expect(drawing.attributes['viewBox'], '0 0 42.0 42.0');
            final path = drawing.children.single;
            expect(path.localName, 'path');
            expect(path.attributes['fill'], 'currentColor');
            expect(path.attributes['d'], startsWith('M '));
          }
          expect(
            drawings.first.children.single.attributes['fill-rule'],
            'evenodd',
          );
          expect(
            drawings.last.children.single.attributes['fill-rule'],
            'nonzero',
          );
        }
        // Only the cover's has a camera: a filled circle before the clock.
        for (final island in _islands(root)) {
          final first = island.children.first;
          final onCover = _islands(parts.cover).single == island;
          expect(first.localName, onCover ? 'div' : 'span');
          if (onCover) {
            expect(_style(first, 'border-radius'), isNotNull);
            expect(_style(first, 'background-color'), isNotNull);
            expect(first.children, isEmpty);
          }
        }
      });
    }

    testServer('the cover’s camera stands at the top-right of its screen, '
        'the clock and the indicator under it, down the middle of the '
        'island’s column', (tester) async {
      final parts = _parts(await _render(tester, 0));
      final island = _islands(parts.cover).single;
      final screen = _screenOf(island);
      final screenWidth = _rem(_style(screen, 'width')!);
      final screenHeight = _rem(_style(screen, 'height')!);
      const scale = CoreMockupFoldableStyle.defaultSystemScale;
      const column = CoreMockupFoldableStyle.defaultIslandWidth * scale;
      final [camera, clock, indicator] = island.children;
      double centre(html.Element box) =>
          _rem(_style(box, 'left')!) + _rem(_style(box, 'width')!) / 2;

      for (final box in [camera, clock, indicator]) {
        expect(centre(box), closeTo(screenWidth - column / 2, 1e-6));
      }
      expect(
        _rem(_style(camera, 'top')!),
        closeTo(CoreMockupFoldableStyle.defaultIslandOffset * scale, 1e-6),
      );
      // The top-right corner, in so many words.
      expect(_rem(_style(camera, 'left')!), greaterThan(screenWidth * 3 / 4));
      expect(
        _rem(_style(camera, 'top')!) + _rem(_style(camera, 'height')!),
        lessThan(screenHeight / 4),
      );
      expect(
        _rem(_style(clock, 'top')!),
        greaterThan(
          _rem(_style(camera, 'top')!) + _rem(_style(camera, 'height')!),
        ),
      );
      expect(
        _rem(_style(indicator, 'top')!),
        greaterThanOrEqualTo(
          _rem(_style(clock, 'top')!) + _rem(_style(clock, 'height')!),
        ),
      );
    });

    testServer('the content’s room stops short of the island’s column, and '
        'the island lies over the screen beside the content’s holder', (
      tester,
    ) async {
      final root = await _render(tester, 144);
      const column =
          CoreMockupFoldableStyle.defaultIslandWidth *
          CoreMockupFoldableStyle.defaultSystemScale;

      for (final island in _islands(root)) {
        final room = island.parent!;
        final holder = room.children.first;

        expect(room.children, [holder, island]);
        expect(_classes(room), contains('h-full'));
        expect(_style(room, 'box-sizing'), 'border-box');
        expect(_rem(_style(room, 'padding-right')!), closeTo(column, 1e-6));
        expect(_classes(holder), ['contents']);
        // The room is the device's own content box, the whole screen: the
        // island's parts are placed in the screen's frame.
        expect(_classes(room.parent!), containsAll(['absolute', 'inset-0']));
      }
      // The content is in a holder, never beside the island.
      for (final content in root.querySelectorAll('.$_kContentClass')) {
        expect(_classes(content.parent!), ['contents']);
      }
    });

    testServer('no body draws a status bar or a camera of its own, and '
        'left unstated there is no home bar', (tester) async {
      final root = await _render(tester, 144);
      final html = root.outerHtml;

      // What a tablet's status bar would have written beside its clock.
      expect(html, isNot(contains(CoreMockupDeviceStyle.sampleDate)));
      expect(html, isNot(contains(CoreMockupDeviceStyle.sampleMeridiem)));
      // Every hidden-from-readers `span` is an island's clock.
      expect(
        root.querySelectorAll('span > span').map((words) => words.text).toSet(),
        {'9:41'},
      );
      // The device's safe area keeps nothing: no status bar above, no home
      // bar below.
      for (final island in _islands(root)) {
        final content = island.parent!.parent!;
        for (final side in ['top', 'right', 'bottom', 'left']) {
          expect(_rem(_style(content, 'padding-$side')!), 0, reason: side);
        }
      }
      expect(root.querySelectorAll('.bg-on-surface'), isEmpty);
    });

    testServer('the home bar is drawn on every body when asked for, and '
        'takes its room from the bottom of the content’s', (tester) async {
      final root = await _render(tester, 144, showGestureBar: true);

      expect(root.querySelectorAll('.bg-on-surface'), hasLength(4));
      for (final island in _islands(root)) {
        final content = island.parent!.parent!;
        expect(_rem(_style(content, 'padding-bottom')!), greaterThan(0));
        expect(_rem(_style(content, 'padding-top')!), 0);
      }
    });

    testServer('without the camera the cover’s island starts with the '
        'clock, at the island’s offset', (tester) async {
      final parts = _parts(await _render(tester, 0, showCamera: false));
      final island = _islands(parts.cover).single;

      expect(island.children.map((child) => child.localName), ['span', 'div']);
      expect(
        _rem(_style(island.children.first, 'top')!),
        closeTo(
          CoreMockupFoldableStyle.defaultIslandOffset *
              CoreMockupFoldableStyle.defaultSystemScale,
          1e-6,
        ),
      );
    });

    testServer('without the status the inner screen has no island and its '
        'content the whole width; the cover keeps its camera alone', (
      tester,
    ) async {
      final root = await _render(tester, 144, showStatus: false);
      final parts = _parts(root);

      for (final part in [parts.live, parts.rightHalf, parts.leftHalf]) {
        expect(_islands(part), isEmpty);
        final room = part.querySelector('.$_kContentClass')!.parent!.parent!;
        expect(_classes(room), ['h-full']);
        expect(room.attributes['style'], isNull);
      }
      final island = _islands(parts.cover).single;
      expect(island.children.map((child) => child.localName), ['div']);
      expect(root.querySelectorAll('svg'), isEmpty);

      final bare = await _render(
        tester,
        144,
        showCamera: false,
        showStatus: false,
      );
      expect(_islands(bare), isEmpty);
    });

    testServer('the island reads the screen’s brightness: it is drawn '
        'inside the screen’s own scope', (tester) async {
      final root = await _render(
        tester,
        144,
        screenBrightness: CoreBrightness.dark,
      );

      for (final island in _islands(root)) {
        html.Element? scope = island;
        while (scope != null && scope.attributes['data-theme'] == null) {
          scope = scope == root ? null : scope.parent;
        }
        expect(scope, isNotNull);
        expect(scope!.attributes['data-theme'], 'dark');
      }
    });

    testServer('the island’s style reaches the document: a raw colour '
        'inline, a token as a class, the column’s width on the room', (
      tester,
    ) async {
      const literal = CoreColor(0xFF123456);
      final plain = _islands(_parts(await _render(tester, 0)).cover).single;
      final styled = _islands(
        _parts(
          await _render(
            tester,
            0,
            style: const CoreMockupFoldableStyle(
              islandWidth: 120,
              islandIconColor: literal,
              islandTextStyle: CoreTextStyle.token(
                CoreTextStyles.labelSmall,
                color: CoreColor.token(CoreColors.primary),
              ),
            ),
          ),
        ).cover,
      ).single;

      expect(
        _rem(_style(styled.parent!, 'padding-right')!),
        closeTo(120 * CoreMockupFoldableStyle.defaultSystemScale, 1e-6),
      );
      final ring = styled.querySelectorAll('svg').first;
      expect(_style(ring, 'color'), literal.toValue());
      expect(_classes(ring).where((c) => c.startsWith('text-')), isEmpty);
      final plainRing = plain.querySelectorAll('svg').first;
      expect(_classes(plainRing), contains('text-on-surface'));
      expect(plainRing.attributes['style'], isNull);
      // The dots were left their token.
      expect(
        _classes(styled.querySelectorAll('svg').last),
        contains('text-on-surface/30'),
      );
      final clock = styled.children[1];
      expect(
        _classes(clock),
        containsAll(['text-label-small', 'text-primary']),
      );
      expect(_classes(clock), isNot(contains('text-title-small')));
      expect(
        _style(clock, 'font-size'),
        contains('--coui-text-label-small-size'),
      );
    });
  });
}
