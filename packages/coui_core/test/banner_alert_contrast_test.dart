// Banner and Alert after they stopped tinting.
//
// Both surfaces used to paint a pale wash of their own severity colour and
// put that same colour on top of it — `warning` on `warning` at 10 %, which
// in light mode measures 1.71:1. `tinted_surface_label_test.dart` is the
// net that caught that, and it caught it for Alert.
//
// It cannot catch it here any more, and that is the whole reason this file
// exists. That test only looks at pairs where the fill is actually a tint;
// now that both components fill with opaque `{tone}Container` tokens, they
// fall out of its scope entirely and it audits neither. A component leaving
// a guard's scope looks exactly like a component passing it.
//
// Banner was never in that test's scope at all, despite having been the
// worse of the two: it used the saturated accent itself as a label colour
// over a 10 % wash of the same hue. The redesign is what fixed it; this is
// what keeps it fixed.
//
// Four modes, not two. High contrast matters here specifically because
// `_raiseLight` / `_raiseDark` push the foregrounds to their extremes while
// leaving `*Container` fills untouched — the pairing that produces is not
// one anything else in the repo measures.
//
// The schemes are CoUI's own source — `CouiColorPresets.source` through
// `resolveThemeSchemeFrom`, which is what `CoreThemePresets` puts on screen.
// A generated palette read through a mapping is the brand path; a guard
// that measured one would check a palette this product does not ship.
// Reading the source is the difference between checking the screen and
// checking a palette nobody sees.
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// WCAG 1.4.3 for body text.
const _kTextMinimum = 4.5;

/// WCAG 1.4.11 for a glyph or a rule — things you must be able to make out
/// but do not have to read.
const _kNonTextMinimum = 3.0;

/// Pairs that do not clear their floor today, with what they measure.
///
/// Empty, and worth saying how it emptied rather than just deleting the
/// row. The one entry was the `warning` glyph on the icon chip's opaque
/// `surface` fill — 1.82 in light mode, because `color/warning` against
/// white is 1.82 no matter which component asks. It was not fixed by
/// retuning anything: the chip was removed, so the glyph now sits on the
/// panel in the tone's own dark step, which is the pair the description
/// text already uses there and already clears.
///
/// Kept as a live map rather than deleted so the mechanism below still
/// has something to enforce — a listed pair that starts passing fails,
/// so an exemption cannot outlive the defect it was written for.
const _knownGaps = <String, double>{};

double _contrast(int a, int b) =>
    CoreContrast.ratio(CoreColor(a), CoreColor(b));

/// [fg] laid over [bg] at its own alpha — the composite the screen shows.
///
/// Every colour in both tables is opaque today, so this is the identity in
/// practice. It stays because the moment one of them is not, the number
/// this file reports has to be the composited one or it is measuring a
/// colour nobody's screen displays.
int _over(int fg, double alpha, int bg) {
  int channel(int shift) {
    final f = (fg >> shift) & 0xFF;
    final b = (bg >> shift) & 0xFF;
    return (f * alpha + b * (1 - alpha)).round().clamp(0, 255);
  }

  return 0xFF000000 | (channel(16) << 16) | (channel(8) << 8) | channel(0);
}

/// The four modes a colour has to answer for.
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

/// One foreground-on-background pair and the floor it has to clear.
class _Pair {
  const _Pair(this.name, this.background, this.foreground, this.floor);

  final String name;
  final CoreColor background;
  final CoreColor foreground;
  final double floor;
}

List<_Pair> _bannerPairs() {
  final out = <_Pair>[];
  CoreBannerStyle.defaultsByVariant.forEach((variant, byEmphasis) {
    byEmphasis.forEach((emphasis, vs) {
      final id = 'banner/${variant.name}/${emphasis.name}';
      out
        ..add(
          _Pair('$id title', vs.backgroundColor, vs.textColor, _kTextMinimum),
        )
        ..add(
          _Pair(
            '$id description',
            vs.backgroundColor,
            vs.descriptionColor,
            _kTextMinimum,
          ),
        )
        ..add(
          _Pair('$id icon', vs.backgroundColor, vs.iconColor, _kNonTextMinimum),
        )
        // The action label. It reads the same token as the title because
        // both resolvers inject `textColor` into `actionButtonStyle` —
        // before that it kept `Button plain`'s own label colour, chosen
        // for a light neutral surface, and on a solid banner that was a
        // dark grey word on a saturated fill. This pair is the thing that
        // keeps the injection: drop it and the label silently reverts to
        // a colour nothing here measures.
        ..add(
          _Pair('$id action', vs.backgroundColor, vs.textColor, _kTextMinimum),
        );
      // The bottom rule only exists on the emphasis that states one.
      final border = vs.borderColor;
      if (border != null) {
        out.add(
          _Pair('$id rule', vs.backgroundColor, border, _kNonTextMinimum),
        );
      }
    });
  });
  return out;
}

List<_Pair> _alertPairs() {
  final out = <_Pair>[];
  CoreAlertStyle.defaultsByVariant.forEach((variant, vs) {
    final id = 'alert/${variant.name}';
    // A tone's title is the glyph's `on-{tone}-container`, in either
    // layout; `neutral` states none and draws each layout's own title colour
    // (the inline strip's is `onSurfaceVariant`, one tier down). Each layout
    // is its own pair, so the colour each one actually draws is measured.
    CoreAlertStyle.defaultsByLayout.forEach((layout, row) {
      out.add(
        _Pair(
          '$id title (${layout.name})',
          vs.backgroundColor,
          vs.titleColor ?? row.titleColor!,
          _kTextMinimum,
        ),
      );
    });
    out
      ..add(
        _Pair(
          '$id description',
          vs.backgroundColor,
          vs.descriptionColor,
          _kTextMinimum,
        ),
      )
      // The glyph sits on the panel now, not on a chip of its own — so
      // the panel is what it has to be legible against.
      ..add(
        _Pair('$id icon', vs.backgroundColor, vs.iconColor, _kNonTextMinimum),
      );
  });
  return out;
}

void main() {
  group('an opaque banner / alert stays readable', () {
    final schemes = _schemes();
    final pairs = [..._bannerPairs(), ..._alertPairs()];

    for (final pair in pairs) {
      schemes.forEach((mode, scheme) {
        test('${pair.name}, $mode', () {
          final bg = _over(
            scheme.resolve(pair.background).argb,
            pair.background.opacity,
            // Both components fill opaquely, so nothing shows through. The
            // page is passed anyway so a future translucent fill composites
            // against something real rather than black.
            scheme.resolve(const CoreColor.token(CoreColors.surface)).argb,
          );
          final fg = _over(
            scheme.resolve(pair.foreground).argb,
            pair.foreground.opacity,
            bg,
          );

          final ratio = _contrast(fg, bg);
          final id = '${pair.name}, $mode';
          final known = _knownGaps[id];

          if (known == null) {
            expect(
              ratio,
              greaterThanOrEqualTo(pair.floor),
              reason:
                  '$id measures ${ratio.toStringAsFixed(2)}, under its '
                  '${pair.floor} floor',
            );
            return;
          }

          // A listed gap that starts passing has to leave the list —
          // otherwise the list outlives the defect and the next reader
          // trusts an exemption that guards nothing.
          expect(
            ratio,
            lessThan(pair.floor),
            reason:
                '$id now measures ${ratio.toStringAsFixed(2)} — remove it '
                'from _knownGaps',
          );
        });
      });
    }

    test('the fills really are opaque — otherwise this measures nothing', () {
      // The whole redesign is "stop compositing the label against the page".
      // If a fill regained an alpha, every number above would quietly become
      // a measurement of a different colour than the one on screen.
      final fills = <String, CoreColor>{
        for (final e in CoreBannerStyle.defaultsByVariant.entries)
          for (final f in e.value.entries)
            'banner/${e.key.name}/${f.key.name}': f.value.backgroundColor,
        for (final e in CoreAlertStyle.defaultsByVariant.entries)
          'alert/${e.key.name}': e.value.backgroundColor,
      };

      for (final MapEntry(key: name, value: fill) in fills.entries) {
        expect(
          fill.opacity,
          1.0,
          reason:
              '$name regained an alpha — the contrast numbers in this file '
              'stop describing what renders the moment that happens',
        );
      }
    });
  });
}
