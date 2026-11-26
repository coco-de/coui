// The height floor both surfaces gained, on the side that shipped without it.
//
// The Flutter twin of this file existed first and passed, and the floor was
// still missing from every Web banner on the site — the resolver never read
// `minHeight` at all. Nothing failed: the Core field had a default, the
// Flutter resolver consumed it, and the orphan-field guard only asks whether
// a field has a baseline somewhere, not whether both platforms emit it. The
// only thing that would have caught it is this file, and it did not exist.
//
// So this is not a mirror of the Flutter test for symmetry's sake. It is the
// specific net for the specific way this pair of fields fails: one platform
// at a time, silently, with the other platform's test still green.
//
// The promise is a pairing — a floor and a centre cross-axis alignment.
// Either alone looks right in the case you have open and wrong in the other,
// and neither throws when it goes. On this platform the two halves are
// emitted from *different places* (the floor inline, the centring in the
// root className), which is exactly why both are asserted here: deleting
// either one leaves the other in place and looks deliberate.
import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/display/banner/banner.dart';
import 'package:coui_web/src/components/overlay/alert/alert.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../helpers/pump_with_theme.dart';

/// The root element of the component under test.
///
/// Both components render their own chrome onto the first `<div>`, so this
/// reads what actually reached the DOM rather than what the resolver
/// returned — a value can be resolved correctly and still never be emitted,
/// which is the failure this file exists for.
DomComponent _root(ComponentTester tester) =>
    find.tag('div').evaluate().first.component as DomComponent;

/// The floor as CSS, from the token — never a literal.
///
/// Writing `'4.5rem'` here would pass while asserting the token's current
/// value rather than the wiring, and would then have to be edited by anyone
/// retuning the token, which is the moment a stale expectation gets
/// "corrected" to match a regression.
String _rem(double logicalPx) => '${logicalPx / kRemDivisor}rem';

void main() {
  group('the floor reaches the DOM', () {
    testComponents('banner emits its minHeight', (tester) async {
      pumpWithTheme(tester, Banner(message: const Component.text('Message')));

      expect(
        _root(tester).styles?.properties['min-height'],
        equals(_rem(CoreBannerStyle.defaultMinHeight)),
      );
    });

    testComponents('alert emits its minHeight', (tester) async {
      pumpWithTheme(tester, const Alert(title: 'Title'));

      expect(
        _root(tester).styles?.properties['min-height'],
        equals(_rem(CoreAlertStyle.defaultMinHeight)),
      );
    });

    testComponents('the inline alert states none', (tester) async {
      // The inline strip is as tall as its content. A floor here would
      // hold every status strip open to a panel's height — and on this
      // platform it would be the one thing the Flutter twin does not do.
      pumpWithTheme(
        tester,
        const Alert(layout: CoreAlertLayout.inline, title: 'Title'),
      );

      expect(_root(tester).styles?.properties['min-height'], isNull);
    });

    testComponents('both emphases state the same floor', (tester) async {
      // `weak` draws a bottom rule and `solid` does not. The rule is kept
      // out of the outer height by `box-sizing: border-box` — drop that and
      // `weak` becomes exactly one stroke taller, a difference nobody sees
      // until two banners sit adjacent.
      final heights = <CoreBannerEmphasis, String?>{};
      final boxSizing = <CoreBannerEmphasis, String?>{};

      for (final emphasis in CoreBannerEmphasis.values) {
        pumpWithTheme(
          tester,
          Banner(message: const Component.text('Message'), emphasis: emphasis),
        );
        final styles = _root(tester).styles?.properties;
        heights[emphasis] = styles?['min-height'];
        boxSizing[emphasis] = styles?['box-sizing'];
      }

      expect(
        heights[CoreBannerEmphasis.weak],
        equals(heights[CoreBannerEmphasis.solid]),
      );
      expect(
        boxSizing[CoreBannerEmphasis.weak],
        equals('border-box'),
        reason: 'without this the bottom rule adds to the outer height',
      );
    });
  });

  group('the centring half is there too', () {
    // Half the pairing lives in the className rather than inline, so it can
    // go missing on its own while the floor above still passes — and a band
    // with a floor and no centring pins its content to the top, which reads
    // as a padding bug rather than a missing property.
    testComponents('banner centres its row', (tester) async {
      pumpWithTheme(tester, Banner(message: const Component.text('Message')));

      // `flex` too — `items-center` on a block box is inert, which is the
      // shape Alert below shipped in.
      final classes = _root(tester).classes ?? '';
      expect(classes, contains('flex'));
      expect(classes, contains('items-center'));
    });

    testComponents('alert centres its row', (tester) async {
      pumpWithTheme(tester, const Alert(title: 'Title'));

      // Both halves, on the same box, and `flex` is asserted alongside
      // `items-center` rather than assumed.
      //
      // This test used to read the inline `align-items: center` instead —
      // which was emitted, and did nothing, because that root was
      // `display: block`. A string-presence assertion on an inline bundle
      // cannot tell "the property is set" from "the property applies", and
      // this harness has no layout engine to tell them apart either. So it
      // passed for as long as the alert was top-pinned on every page.
      //
      // Asserting the class closes that specifically: `items-center` only
      // means anything next to a display utility, so demanding both in one
      // place makes the inert combination unrepresentable.
      final classes = _root(tester).classes ?? '';
      expect(classes, contains('flex'));
      expect(classes, contains('items-center'));
    });
  });
}
