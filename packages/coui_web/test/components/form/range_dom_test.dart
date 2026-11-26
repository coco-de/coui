import 'package:coui_web/coui_web.dart';
import 'package:html/dom.dart' as html;
import 'package:jaspr_test/server_test.dart';

// `testServer` (not `testComponents`) because only the real SSR binding
// hands back markup, and what these pin is DOM shape: each thumb's
// travel and the ring that wraps it.

const _kMinValue = 20.0;
const _kMaxValue = 80.0;
const _kRangeMin = 0.0;
const _kRangeMax = 100.0;

Component _range({
  double minValue = _kMinValue,
  double maxValue = _kMaxValue,
}) => Range(onChanged: (_, __) {}, minValue: minValue, maxValue: maxValue);

/// The thumbs' positioners — the `FocusOutline` wrappers that carry the
/// travel. `role="slider"` sits on the thumb inside each one.
List<html.Element> _positioners(html.Document? document) =>
    document
        ?.querySelectorAll('[role="slider"]')
        .map((t) => t.parent!)
        .toList() ??
    <html.Element>[];

void main() {
  group('Range thumb anchoring', () {
    // A thumb's edges — not its centre — stop at the track ends, so its
    // travel carries its own width. 50% is the one value where that
    // model and a centre-anchored one agree, so these pin the ends.
    testServer('at the range ends the thumbs travel track minus thumb', (
      tester,
    ) async {
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          child: _range(minValue: _kRangeMin, maxValue: _kRangeMax),
        ),
      );
      final response = await tester.request('/');
      final positioners = _positioners(response.document);
      expect(positioners, hasLength(2));

      expect(
        positioners.first.attributes['style'],
        contains('left: calc(0.0000 * (100% - 1.0rem))'),
      );
      expect(
        positioners.last.attributes['style'],
        contains('left: calc(1.0000 * (100% - 1.0rem))'),
      );
    });

    testServer('a thumb no longer centres itself on its position', (
      tester,
    ) async {
      tester.pumpComponent(CoUIWeb(theme: .coui, child: _range()));
      final response = await tester.request('/');

      for (final positioner in _positioners(response.document)) {
        expect(positioner.className, isNot(contains('-translate-x-1/2')));
      }
    });

    testServer('the fill spans thumb centre to thumb centre', (tester) async {
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          child: _range(minValue: _kRangeMin, maxValue: _kRangeMax),
        ),
      );
      final response = await tester.request('/');
      final fill = _positioners(response.document).first.parent?.children.first;

      // Both ends are a thumb's travel, offset by half a thumb — not
      // plain percentages, which would disagree with the thumbs
      // everywhere but the midpoint.
      expect(
        fill?.attributes['style'],
        contains('left: calc(0.0000 * (100% - 1.0rem) + 0.5rem)'),
      );
    });
  });

  group('Range focus ring', () {
    testServer('the thumbs no longer draw a ring of their own', (
      tester,
    ) async {
      tester.pumpComponent(CoUIWeb(theme: .coui, child: _range()));
      final response = await tester.request('/');

      for (final thumb
          in response.document?.querySelectorAll(
                '[role="slider"]',
              ) ??
              <html.Element>[]) {
        // The ring is drawn by the `FocusOutline` that positions the
        // thumb — a second ring here is the divergence this replaced.
        expect(thumb.className, isNot(contains('focus-visible:outline')));
        expect(thumb.className, contains('outline-none'));
        expect(
          thumb.attributes['style'],
          isNot(contains('--coui-range-focus')),
        );
      }
    });
  });
}
