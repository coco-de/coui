import 'package:coui_web/coui_web.dart';
import 'package:html/dom.dart' as html;
import 'package:jaspr_test/server_test.dart';

// `testServer` (not `testComponents`) because only the real SSR binding
// hands back markup, and what these pin is DOM shape: the keyboard ring
// is drawn by a composed `FocusOutline` wrapper, not by the slider
// itself, so the interior it wraps has to keep the width and height the
// track and thumb are laid out against.

const _kInitialValue = 50.0;
const _kMinValue = 0.0;
const _kMaxValue = 100.0;

Component _slider({double value = _kInitialValue}) =>
    Slider(onChanged: (_) {}, value: value);

/// The interior is the box the track and the thumb live in — the root's
/// only child when the slider has no slots.
html.Element? _interiorOf(html.Document? document) =>
    _rootOf(document)?.children.single;

/// The thumb's `FocusOutline` host: it carries the position, the thumb
/// itself is its only child.
html.Element? _thumbHostOf(html.Document? document) =>
    _interiorOf(document)?.children.last;

html.Element? _thumbOf(html.Document? document) =>
    _thumbHostOf(document)?.children.single;

html.Element? _rootOf(html.Document? document) =>
    document?.querySelector('[role="slider"]');

void main() {
  group('Slider DOM', () {
    testServer('the interior spans the root and holds track + ring host', (
      tester,
    ) async {
      tester.pumpComponent(CoUIWeb(theme: .coui, child: _slider()));
      final response = await tester.request('/');
      final interior = _interiorOf(response.document);

      // The box is thumb-sized, so the container padding stays outside it.
      expect(interior?.attributes['style'], contains('height'));
      expect(interior?.className, contains('w-full'));
      // `min-w-0` lets it shrink beside the slots instead of overflowing.
      expect(interior?.className, contains('min-w-0'));

      // Track, then the thumb's ring host.
      expect(interior?.children, hasLength(2));
      expect(interior?.children.first.attributes['style'], contains('height'));
    });

    testServer('the root and interior fill the parent, no fixed width', (
      tester,
    ) async {
      tester.pumpComponent(CoUIWeb(theme: .coui, child: _slider()));
      final response = await tester.request('/');
      final root = _rootOf(response.document);
      final interior = _interiorOf(response.document);

      // 디자이너 확인: 캔버스의 240 은 보여 주기 위한 폭이고, 코드는 부모 폭을 채운다.
      expect(root?.className, contains('w-full'));
      expect(root?.attributes['style'] ?? '', isNot(contains('width')));
      expect(interior?.className, contains('w-full'));
      expect(interior?.attributes['style'] ?? '', isNot(contains('width')));
    });

    testServer('the ring wraps the thumb only, not the track', (tester) async {
      tester.pumpComponent(CoUIWeb(theme: .coui, child: _slider()));
      final response = await tester.request('/');
      final host = _thumbHostOf(response.document);

      // The host is the positioned wrapper (the ring is drawn on it) and
      // the thumb is its single child — the track is a sibling.
      expect(host?.className, contains('absolute'));
      expect(host?.children, hasLength(1));
      expect(host?.children.single.attributes['style'], contains('width'));
    });

    testServer('the thumb casts the smallest shadow step', (tester) async {
      tester.pumpComponent(CoUIWeb(theme: .coui, child: _slider()));
      final response = await tester.request('/');
      final style = _thumbOf(response.document)?.attributes['style'];

      expect(style, contains('box-shadow: var(--shadow-xs)'));
    });

    testServer('without slots the root holds the interior alone', (
      tester,
    ) async {
      tester.pumpComponent(CoUIWeb(theme: .coui, child: _slider()));
      final response = await tester.request('/');

      expect(_rootOf(response.document)?.children, hasLength(1));
    });

    testServer('leading and trailing sit either side of the track, with a '
        'gap each', (tester) async {
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          child: Slider(
            onChanged: (_) {},
            value: _kInitialValue,
            leading: const Component.text('low'),
            trailing: const Component.text('high'),
          ),
        ),
      );
      final response = await tester.request('/');
      final root = _rootOf(response.document);

      // leading text · gap · interior · gap · trailing text
      expect(root?.nodes.first.text?.trim(), 'low');
      expect(root?.nodes.last.text?.trim(), 'high');
      expect(root?.children, hasLength(3));
      expect(
        root?.children[1].attributes.containsKey('data-coui-slider-track'),
        isTrue,
      );
    });
    testServer('the root no longer draws a ring of its own', (tester) async {
      tester.pumpComponent(CoUIWeb(theme: .coui, child: _slider()));
      final response = await tester.request('/');
      final root = _rootOf(response.document);

      // The root takes focus but hands the ring to `FocusOutline` — a
      // second ring here is the divergence this replaced.
      expect(root?.className, isNot(contains('focus-visible:outline')));
      expect(root?.className, contains('outline-none'));
      expect(root?.attributes['style'], isNot(contains('--coui-slider-focus')));
    });
  });

  group('Slider thumb anchoring', () {
    // The thumb's edges — not its centre — stop at the track ends, so its
    // `left` carries the thumb's own width. 50% is the one value where
    // that model and a centre-anchored one agree, so these pin the ends.
    testServer('at min the thumb sits at the track start, not half outside', (
      tester,
    ) async {
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          child: _slider(value: _kMinValue),
        ),
      );
      final response = await tester.request('/');
      final style = _thumbHostOf(response.document)?.attributes['style'];

      expect(style, contains('left: calc(0.0000 *'));
      // A centre-anchored thumb would carry this and hang half a thumb
      // past the track on both ends.
      expect(
        _thumbHostOf(response.document)?.className,
        isNot(contains('-translate-x-1/2')),
      );
    });

    testServer('at max the thumb travels the track minus its own width', (
      tester,
    ) async {
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          child: _slider(value: _kMaxValue),
        ),
      );
      final response = await tester.request('/');
      final style = _thumbHostOf(response.document)?.attributes['style'];

      expect(style, contains('left: calc(1.0000 * (100% - 1.0rem))'));
    });

    testServer('the fill runs to the thumb centre at every value', (
      tester,
    ) async {
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          child: _slider(value: _kMinValue),
        ),
      );
      final response = await tester.request('/');
      final fill = _rootOf(
        response.document,
      )?.children.single.children.first.children.single;

      // Same travel as the thumb, plus half a thumb — not a plain
      // `ratio%`, which would disagree with the thumb everywhere but the
      // midpoint.
      expect(
        fill?.attributes['style'],
        contains('width: calc(0.0000 * (100% - 1.0rem) + 0.5rem)'),
      );
    });
  });
}
