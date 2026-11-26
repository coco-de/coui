// The toast is a dark bubble — `inverse-surface` with `inverse-on-surface`
// text — and two of its tiers are that text colour at an opacity: the
// description at 75 %, the resting close glyph at 70 %. There is no
// `inverse-on-surface-variant` in the scheme, so the quieter tiers cannot be
// a second token, and a contrast check that read the token alone would
// measure the full-strength colour and pass a tier the screen draws fainter.
//
// So every pair here is measured the way it is painted: the fill composited
// over the page, then the foreground composited over the fill at its own
// alpha. `CoreContrast.auditScheme` already pins `inverseOnSurface` on
// `inverseSurface` at full strength; this file is what holds the faded tiers
// and the variant glyphs, which nothing else measures on this fill.
//
// Four modes, for the reason `banner_alert_contrast_test.dart` gives: high
// contrast pushes the foregrounds to their extremes, and the pairing that
// produces is not one the two ordinary modes cover.
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// WCAG 1.4.3 for body text.
const _kTextMinimum = 4.5;

/// WCAG 1.4.11 for a glyph — the close ✕ and the variant mark have to be
/// made out, not read.
const _kNonTextMinimum = 3.0;

/// Pairs that do not clear their floor today, with what they measure.
///
/// A listed pair that starts passing fails, so an exemption cannot outlive
/// the defect it was written for.
const _knownGaps = <String, double>{};

double _contrast(int a, int b) =>
    CoreContrast.ratio(CoreColor(a), CoreColor(b));

/// [fg] laid over [bg] at [alpha] — the composite the screen shows.
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
    'light': resolveThemeSchemeFrom(source, brightness: CoreBrightness.light),
    'dark': resolveThemeSchemeFrom(source, brightness: CoreBrightness.dark),
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

class _Pair {
  const _Pair(this.name, this.background, this.foreground, this.floor);

  final String name;
  final CoreColor background;
  final CoreColor foreground;
  final double floor;
}

List<_Pair> _toastPairs() {
  final out = <_Pair>[];
  CoreToastStyle.defaultsByVariant.forEach((variant, vs) {
    final id = 'toast/${variant.name}';
    out
      ..add(
        _Pair(
          '$id message',
          vs.backgroundColor,
          vs.foregroundColor,
          _kTextMinimum,
        ),
      )
      ..add(
        _Pair(
          '$id description',
          vs.backgroundColor,
          vs.descriptionForeground ?? vs.foregroundColor,
          _kTextMinimum,
        ),
      )
      // Both resolvers inject `foregroundColor` under the action, so the
      // action label is the message colour on the same fill.
      ..add(
        _Pair(
          '$id action',
          vs.backgroundColor,
          vs.foregroundColor,
          _kTextMinimum,
        ),
      )
      ..add(
        _Pair(
          '$id close (resting)',
          vs.backgroundColor,
          vs.closeForeground,
          _kNonTextMinimum,
        ),
      )
      ..add(
        _Pair(
          '$id close (hover)',
          vs.backgroundColor,
          vs.closeHoverForeground,
          _kNonTextMinimum,
        ),
      );
    final icon = vs.iconColor;
    if (icon != null) {
      out.add(
        _Pair('$id glyph', vs.backgroundColor, icon, _kNonTextMinimum),
      );
    }
  });
  return out;
}

void main() {
  group('the toast bubble stays readable', () {
    final schemes = _schemes();

    for (final pair in _toastPairs()) {
      schemes.forEach((mode, scheme) {
        test('${pair.name}, $mode', () {
          final bg = _over(
            scheme.resolve(pair.background).argb,
            pair.background.opacity,
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

    test('the fill is opaque — otherwise the page shows through', () {
      for (final MapEntry(key: variant, value: vs)
          in CoreToastStyle.defaultsByVariant.entries) {
        expect(vs.backgroundColor.opacity, 1.0, reason: variant.name);
      }
    });

    test('the faded tiers really are faded — otherwise this file measures '
        'the full-strength pair twice', () {
      for (final MapEntry(key: variant, value: vs)
          in CoreToastStyle.defaultsByVariant.entries) {
        expect(
          vs.descriptionForeground?.opacity,
          CoreOpacity.opacity75,
          reason: variant.name,
        );
        expect(
          vs.closeForeground.opacity,
          CoreOpacity.opacity70,
          reason: variant.name,
        );
      }
    });
  });
}
