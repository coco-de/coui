// A label on a surface tinted with its own accent.
//
// Alert and ValidationBadge both paint a pale wash of their severity colour
// and put text on it. The text used to be that same colour at full
// strength — `warning` on `warning` at 10%, which in light mode is
// **1.71:1**. Yellow is the worst of them but none of the four cleared 4.5.
//
// Nothing saw it. The design system defines `onWarningContainer` as the
// thing that goes on a warning-tinted surface, so a guard that checks
// `on-X` against `X` never constructs `warning` × `warning`. The pair that
// renders was not the pair that was declared.
//
// This test builds the pair that renders: the accent composited onto the
// page at its stated alpha, then the label composited onto that.
//
// The schemes are CoUI's own source — `CouiColorPresets.source` through
// `resolveThemeSchemeFrom`, which is what `CoreThemePresets` puts on screen.
// A generated palette read through a mapping is the brand path; a guard
// that measured one would check a palette this product does not ship.
// Reading the source is the difference between checking the screen and
// checking a palette nobody sees.
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kBodyTextMinimum = 4.5;

double _contrast(int a, int b) =>
    CoreContrast.ratio(CoreColor(a), CoreColor(b));

/// [fg] laid over [bg] at [alpha] — the composite the screen actually shows.
int _over(int fg, double alpha, int bg) {
  int channel(int shift) {
    final f = (fg >> shift) & 0xFF;
    final b = (bg >> shift) & 0xFF;
    return (f * alpha + b * (1 - alpha)).round().clamp(0, 255);
  }

  return 0xFF000000 | (channel(16) << 16) | (channel(8) << 8) | channel(0);
}

/// One label-on-tint pair, named the way a reader would describe it.
class _Tinted {
  const _Tinted(this.name, this.fill, this.label);

  final String name;
  final CoreColor fill;
  final CoreColor label;
}

List<_Tinted> _pairs() {
  const alert = CoreAlertStyle.defaultsByVariant;
  const badge = CoreValidationBadgeStyle.defaultsByState;

  return [
    // Alert's redesign split the old single `foregroundColor` into a
    // neutral title and a tone-carrying `descriptionColor` — the
    // description is what actually sits on the tint now.
    for (final entry in alert.entries)
      _Tinted(
        'alert/${entry.key.name}',
        entry.value.backgroundColor,
        entry.value.descriptionColor,
      ),
    for (final entry in badge.entries)
      _Tinted(
        'validation-badge/${entry.key.name}',
        entry.value.backgroundColor,
        entry.value.foregroundColor,
      ),
  ];
}

void main() {
  group('a label on its own accent tint', () {
    for (final brightness in CoreBrightness.values) {
      for (final pair in _pairs()) {
        test('${pair.name} is readable, ${brightness.name}', () {
          final scheme = resolveThemeSchemeFrom(
            CouiColorPresets.source,
            brightness: brightness,
          );
          final page = scheme
              .resolve(const CoreColor.token(CoreColors.surface))
              .argb;

          final fill = _over(
            scheme.resolve(pair.fill).argb,
            pair.fill.opacity,
            page,
          );
          final label = _over(
            scheme.resolve(pair.label).argb,
            pair.label.opacity,
            fill,
          );

          expect(
            _contrast(label, fill),
            greaterThanOrEqualTo(_kBodyTextMinimum),
            reason: '${pair.name} label on its own tint in ${brightness.name}',
          );
        });
      }
    }

    test('the pairs under test are not empty', () {
      // The fills are containers now (opaque), so the label is measured on
      // the fill itself; a translucent fill still composites over the page
      // in `_over`, which keeps this check honest if one comes back.
      expect(_pairs(), isNotEmpty);
    });
  });
}
