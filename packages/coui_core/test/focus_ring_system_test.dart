// The focus ring, held to one system.
//
// This exists because the ring drifted, twice, in the same direction and for
// the same reason: someone read a value off a Figma node and wrote it into
// one variant. Each edit looked local and correct. Together they left three
// different rings inside a single component — 2px primary from the shared
// default, 1.5px error on `destructive`, 1.5px grey on `plain` — and nothing
// in the suite had an opinion about that, because every one of them was a
// legal value in a legal slot.
//
// The decision (docs/decision-log-state-layer-opacity.md §2-3, and the ring
// discussion that followed it) is:
//
//   - colour follows the control's semantic tone, defaulting to `primary`;
//     the error family takes `error`
//   - geometry — width, offset, opacity — is shared and not per-variant
//
// So the assertions below are about the SHAPE of an override, not about a
// list of blessed values. A variant may say what colour it is. It may not
// quietly restate the geometry, because the point of sharing the geometry is
// that changing it once reaches everything.
//
// The schemes are CoUI's own source — `CouiColorPresets.source` through
// `resolveThemeSchemeFrom`, which is what `CoreThemePresets` puts on screen.
// A generated palette read through a mapping is the brand path; a guard
// that measured one would check a palette this product does not ship.
// Reading the source is the difference between checking the screen and
// checking a palette nobody sees.
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// WCAG 1.4.11 — a focus indicator is non-text content.
const _kNonTextMinimum = 3.0;

double _contrast(int a, int b) =>
    CoreContrast.ratio(CoreColor(a), CoreColor(b));

/// [fg] over [bg] at [alpha] — what a translucent ring actually shows.
int _over(int fg, double alpha, int bg) {
  int channel(int shift) {
    final f = (fg >> shift) & 0xFF;
    final b = (bg >> shift) & 0xFF;
    return (f * alpha + b * (1 - alpha)).round().clamp(0, 255);
  }

  return 0xFF000000 | (channel(16) << 16) | (channel(8) << 8) | channel(0);
}

Map<String, CoreColorScheme> _schemes() {
  const source = CouiColorPresets.source;
  return {
    'light': resolveThemeSchemeFrom(
      source,
      brightness: CoreBrightness.light,
    ),
    'dark': resolveThemeSchemeFrom(
      source,
      brightness: CoreBrightness.dark,
    ),
    'high-contrast light': resolveThemeSchemeFrom(
      source,
      brightness: CoreBrightness.light,
      highContrast: true,
    ),
    'high-contrast dark': resolveThemeSchemeFrom(
      source,
      brightness: CoreBrightness.dark,
      highContrast: true,
    ),
  };
}

void main() {
  group('geometry is shared, not restated per variant', () {
    CoreButtonStyle.defaultsByVariant.forEach((variant, style) {
      final ring = style.focusOutlineStyle;
      if (ring == null) return;

      test('${variant.name} overrides colour only', () {
        // Width is the one that has actually gone wrong, and it goes wrong
        // invisibly: a thinner ring is not a broken ring, it is a slightly
        // less visible one, which nobody files.
        expect(
          ring.borderWidth,
          isNull,
          reason:
              '${variant.name} restates the ring width. Geometry is shared '
              'so that changing it once reaches every control — a variant '
              'that pins its own is exactly the drift this guards',
        );
        expect(
          ring.ringOpacity,
          isNull,
          reason:
              '${variant.name} restates the ring opacity, which dilutes the '
              'ring against the offset band and is not a per-variant call',
        );
      });
    });

    test('the shared width is the thickness WCAG 2.2 names', () {
      // SC 2.4.13 (Focus Appearance) benchmarks the indicator against a
      // 2 CSS px thick perimeter. It is AAA, so falling below is not a
      // conformance failure at AA — but it is the only criterion that
      // speaks to ring THICKNESS, and dropping under it should be a
      // decision someone makes rather than a number someone copies.
      //
      // The practical half: 2 is on the Tailwind ring scale (0/1/2/4/8) and
      // 1.5 is not, so an off-scale width moves every ring in the catalogue
      // off a cached utility class and onto a per-instance scoped rule.
      expect(CoreFocusOutlineStyle.defaultBorderWidth, greaterThanOrEqualTo(2));
    });

    test('the shared ring is opaque', () {
      // NOT a contrast argument, and it is worth saying so because it was
      // first written as one. On the scheme CoUI ships the ring measures
      // 14.14 against the offset band at full opacity in light mode and
      // 6.32 at the 0.75 this briefly used — both clear 3:1 with room, so
      // alpha was never the risk. (The figures that once suggested
      // otherwise, 4.63 and 3.01, came from measuring a chromatic blue
      // ramp this product does not ship. See the note at the top.)
      //
      // The real reason is the same as the width's: opacity is geometry, it
      // is shared, and Figma authors all 309 ring nodes at 1.0. A variant
      // that dilutes its own ring is restating a shared decision, which is
      // what the two tests above forbid — this one just pins the value the
      // sharing starts from.
      const opacity = CoreFocusOutlineStyle.defaultRingOpacity;
      expect(opacity >= 1.0, isTrue);
    });
  });

  group('every ring colour is legible against what it sits beside', () {
    // The ring's neighbour is whatever fills the 2px gap next to it. By
    // default that gap is transparent, so the neighbour is the background
    // the control sits on — the page `surface`. A component whose
    // background is unknown turns the band on, and then the neighbour is
    // the band itself. Both partners are measured: the first is the common
    // case, the second is the promise the opaque band exists to keep.
    final schemes = _schemes();

    final colours = <String, CoreColor>{
      'shared default': CoreFocusOutlineStyle.defaultBorderColor,
      for (final e in CoreButtonStyle.defaultsByVariant.entries)
        if (e.value.focusOutlineStyle?.borderColor != null)
          'button/${e.key.name}': e.value.focusOutlineStyle!.borderColor!,
    };

    final partners = <String, CoreColor>{
      'page background (transparent gap)': const CoreColor.token(
        CoreColors.surface,
      ),
      'opaque band': CoreFocusRing.opaqueOffsetColor,
    };

    test('the default gap is transparent, so the page is the partner', () {
      expect(CoreFocusOutlineStyle.defaultOffsetColor, CoreColor.transparent);
      expect(CoreFocusRing.ringOffsetColor.argb >>> 24, 0);
      expect(CoreFocusRing.ringOffsetColor.token, isNull);
    });

    for (final MapEntry(key: name, value: colour) in colours.entries) {
      for (final MapEntry(key: partnerName, value: partner)
          in partners.entries) {
        schemes.forEach((mode, scheme) {
          test('$name against the $partnerName, $mode', () {
            final background = scheme.resolve(partner).argb;
            expect(
              background >>> 24,
              0xFF,
              reason:
                  'the $partnerName must be opaque to be a contrast '
                  'partner at all',
            );
            final ring = _over(
              scheme.resolve(colour).argb,
              colour.opacity,
              background,
            );

            final ratio = _contrast(ring, background);
            expect(
              ratio,
              greaterThanOrEqualTo(_kNonTextMinimum),
              reason:
                  '$name measures ${ratio.toStringAsFixed(2)} against the '
                  '$partnerName in $mode — under the 3:1 a focus indicator '
                  'owes',
            );
          });
        });
      }
    }
  });
}
