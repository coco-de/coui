// A press on a field's box beside the `<input>`.
//
// Flutter wraps the whole row in one tap region, so a press on the inset or
// on a glyph beside the input focuses the field and fires `onTap`. The
// native `<input>` only owns the pixels it covers; the box takes the rest. Which targets inside it keep their own click (the input, a button, a
// link) is the DOM's to say, so that judgment is read in a real browser
// (`tool/parity/test/web/field_box_press_probe_test.dart`); here the box's
// wiring is read as data.
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// The box: the one `<div>` that listens for a press.
Iterable<DomComponent> _boxes() => find
    .tag('div')
    .evaluate()
    .map((e) => e.component)
    .whereType<DomComponent>()
    .where((e) => e.events?.containsKey('mousedown') ?? false);

void _press(DomComponent box, String event) =>
    (box.events![event]! as void Function(Object))(Object());

void main() {
  group('TextField — a press on the framed box', () {
    testComponents('a bare field has a box to press too', (tester) async {
      var taps = 0;
      pumpWithTheme(tester, TextField(onTap: () => taps++));

      final box = _boxes().single;
      _press(box, 'mousedown');
      _press(box, 'click');
      expect(taps, 1);
    });

    testComponents('a framed field fires onTap once per press on its box', (
      tester,
    ) async {
      var taps = 0;
      pumpWithTheme(
        tester,
        TextField(prefix: const Component.text('@'), onTap: () => taps++),
      );

      final box = _boxes().single;
      _press(box, 'mousedown');
      expect(taps, 0, reason: 'the press itself is not the tap');
      _press(box, 'click');
      expect(taps, 1);
    });

    testComponents('a framed field without onTap still takes the press', (
      tester,
    ) async {
      pumpWithTheme(tester, TextField(prefix: const Component.text('@')));

      expect(() => _press(_boxes().single, 'click'), returnsNormally);
    });

    testComponents('the input keeps its own click', (tester) async {
      pumpWithTheme(
        tester,
        TextField(prefix: const Component.text('@'), onTap: () {}),
      );

      final input =
          find.tag('input').evaluate().single.component as DomComponent;
      expect(input.events, contains('click'));
    });

    testComponents('a disabled framed field takes no press', (tester) async {
      var taps = 0;
      pumpWithTheme(
        tester,
        TextField(
          prefix: const Component.text('@'),
          enabled: false,
          onTap: () => taps++,
        ),
      );

      expect(_boxes(), isEmpty);
      expect(taps, 0);
    });

    testComponents('a framed field with a feature button still has its box', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        TextField(features: [CoreInputFeature.clear()], onTap: () {}),
      );

      expect(_boxes(), hasLength(1));
    });
  });
}
