// A filled button's label must be readable ON ITS OWN FILL.
//
// `check_contrast.sh` cannot see this. That guard audits the semantic
// scheme — it measures slot COUPLES (`onError` against `error`) and
// those pass. But a variant is free to pair a fill with a foreground
// that is not that fill's couple, and free to put alpha on the fill so
// what the label actually sits on is neither slot but a composite.
// `destructive` did both: white-literal foreground over `error` at 50%,
// which is 2.36:1 in light — and the guard measured a pair that was
// never rendered.
//
// So this test constructs the pair the SCREEN constructs: the variant's
// own foreground token against its own fill token, composited over the
// page when the fill carries alpha.
//
// Hover is measured but not asserted. At the shared `0.8` alpha the
// light-mode numbers are under 4.5 across the filled variants (primary
// 3.27, destructive 3.74) — that is one convention to decide, not a
// per-variant defect, and pinning it here would freeze whichever value
// happened to be current.

// The schemes are CoUI's own source — `CouiColorPresets.source` through
// `resolveThemeSchemeFrom`, which is what `CoreThemePresets` puts on screen.
// A generated palette read through a mapping is the brand path; a guard
// that measured one would check a palette this product does not ship.
// Reading the source is the difference between checking the screen and
// checking a palette nobody sees.
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

double _contrast(int a, int b) =>
    CoreContrast.ratio(CoreColor(a), CoreColor(b));

/// `src` at [alpha] composited over `dst` — what the eye receives when a
/// fill is translucent. Without this the measurement would be of a
/// colour no one sees.
int _composite(int src, double alpha, int dst) {
  int channel(int shift) {
    final s = (src >> shift) & 0xFF;
    final d = (dst >> shift) & 0xFF;
    return (s * alpha + d * (1 - alpha)).round().clamp(0, 255);
  }

  return 0xFF000000 | (channel(16) << 16) | (channel(8) << 8) | channel(0);
}

/// The colour a `CoreColor` becomes on [scheme], flattened onto the page
/// when it carries alpha.
int _rendered(CoreColorScheme scheme, CoreColor color, int page) {
  final resolved = scheme.resolve(color);
  final opacity = color.opacity;
  if (opacity >= 1) return resolved.argb | 0xFF000000;
  return _composite(resolved.argb, opacity, page);
}

/// The filled variants — the ones whose label sits on a colour the
/// button itself paints. Ghost / link / text draw no fill, so their
/// label sits on the page and the scheme guard already covers it.
const _filled = <CoreButtonVariant>[
  CoreButtonVariant.primary,
  CoreButtonVariant.secondary,
  CoreButtonVariant.tonal,
  CoreButtonVariant.destructive,
];

/// The states a button paints its own fill for, beyond rest.
///
/// Named rather than inlined so adding one is a single entry — the defect
/// this guards came from a state nobody had listed.
class _EngagedState {
  const _EngagedState(this.name, this.fill, this.label);

  final String name;
  final CoreColor? Function(CoreButtonVariantStyle) fill;
  final CoreColor? Function(CoreButtonVariantStyle) label;
}

/// Translucent engaged fills that do not clear 4.5:1 today, with what
/// they measure.
///
/// Empty today. `destructive` (3.74) and `primary` (3.27) both had the
/// same shape — a variant's own colour diluted toward whatever page sits
/// behind the button, which over a light page moves it TOWARD the label
/// rather than away. Both moved off dilution entirely: `destructive` to
/// the `errorContainer`/`onErrorContainer` pair, `primary`/`secondary`/
/// `outline` to an opaque state-layer overlay composited over the
/// unchanged resting fill instead of diluting it (see
/// `CoreButtonVariantStyle.stateLayer?.hover`'s doc).
///
/// Listed rather than skipped so the numbers are in the source and the
/// list can only shrink — the assertion below fails if an entry starts
/// passing, so a fix cannot leave a stale exemption behind.
const _knownTranslucentHoverGaps = <String, double>{};

const _engagedStates = [
  _EngagedState('hover', _hoverFill, _hoverLabel),
  _EngagedState('selected', _selectedFill, _selectedLabel),
];

CoreColor? _hoverFill(CoreButtonVariantStyle s) => s.hoverBackgroundColor;
CoreColor? _hoverLabel(CoreButtonVariantStyle s) => s.hoverForegroundColor;
CoreColor? _selectedFill(CoreButtonVariantStyle s) => s.selectedBackgroundColor;
CoreColor? _selectedLabel(CoreButtonVariantStyle s) =>
    s.selectedForegroundColor;

void main() {
  group('a filled button label is readable on its own fill', () {
    for (final brightness in CoreBrightness.values) {
      for (final variant in _filled) {
        test('${variant.name} at rest, ${brightness.name}', () {
          final scheme = resolveThemeSchemeFrom(
            CouiColorPresets.source,
            brightness: brightness,
          );
          final style = CoreButtonStyle.defaultsByVariant[variant]!;
          final page = scheme
              .resolve(const CoreColor.token(CoreColors.surface))
              .argb;

          final fill = _rendered(scheme, style.backgroundColor, page);
          final label = _rendered(scheme, style.foregroundColor, fill);

          expect(
            _contrast(label, fill),
            greaterThanOrEqualTo(4.5),
            reason:
                '${variant.name} label on its own fill in '
                '${brightness.name}',
          );
        });
      }
    }

    // Rest was the only state audited, and that is how `card` shipped
    // hover and selected fills of `outline` under an `onSurfaceVariant`
    // label — 1.43 light, 1.26 dark, invisible in both. A button spends
    // real time in these states; they are not decoration on top of a
    // checked one.
    //
    // Every variant is checked, not only the filled ones: an engaged fill
    // is a fill even when the resting variant paints none, which is
    // exactly the case that hid this.
    for (final brightness in CoreBrightness.values) {
      for (final variant in CoreButtonVariant.values) {
        for (final state in _engagedStates) {
          test('${variant.name} ${state.name}, ${brightness.name}', () {
            final scheme = resolveThemeSchemeFrom(
              CouiColorPresets.source,
              brightness: brightness,
            );
            final style = CoreButtonStyle.defaultsByVariant[variant]!;
            final stateFill = state.fill(style);
            // A variant that does not restate its fill for this state
            // keeps the resting one, which the test above already holds.
            if (stateFill == null) return;
            // A fully transparent fill is not a fill — the label sits on
            // whatever is behind the button, which is the page, and the
            // scheme guard already holds that pair. Compositing it would
            // read the sentinel's own zero-alpha black as a background
            // and report every borderless variant as unreadable.
            if (scheme.resolve(stateFill).argb >> 24 == 0) return;

            final page = scheme
                .resolve(const CoreColor.token(CoreColors.surface))
                .argb;
            final fill = _rendered(scheme, stateFill, page);
            final label = _rendered(
              scheme,
              state.label(style) ?? style.foregroundColor,
              fill,
            );

            final ratio = _contrast(label, fill);
            final id = '${variant.name} ${state.name} ${brightness.name}';
            final known = _knownTranslucentHoverGaps[id];

            if (known == null) {
              expect(
                ratio,
                greaterThanOrEqualTo(4.5),
                reason:
                    '${variant.name} label on its ${state.name} fill in '
                    '${brightness.name}',
              );
              return;
            }

            // A listed gap that starts passing has to leave the list —
            // otherwise the list outlives the defect and the next reader
            // trusts an exemption that guards nothing.
            expect(
              ratio,
              lessThan(4.5),
              reason:
                  '$id now measures ${ratio.toStringAsFixed(2)} — remove '
                  'it from _knownTranslucentHoverGaps',
            );
            expect(ratio, closeTo(known, 0.01), reason: id);
          });
        }
      }
    }

    // A pale tonal fill answers hover and pressed with a wash of its own
    // label colour, not a second fill — so neither the resting check nor
    // the engaged-fill loop above ever sees the colour the label sits on
    // while it is pressed. This composites the variant's `stateLayer` at
    // each weight over the resting fill and measures the label on that.
    for (final brightness in CoreBrightness.values) {
      for (final variant in const [
        CoreButtonVariant.secondary,
        CoreButtonVariant.tonal,
      ]) {
        final style = CoreButtonStyle.defaultsByVariant[variant]!;
        final layer = style.stateLayer!;
        for (final (state, weight) in [
          ('rest', 0.0),
          ('hover', layer.hover),
          ('pressed', layer.pressed),
        ]) {
          test('${variant.name} $state under its state layer, '
              '${brightness.name}', () {
            final scheme = resolveThemeSchemeFrom(
              CouiColorPresets.source,
              brightness: brightness,
            );
            final page = scheme
                .resolve(const CoreColor.token(CoreColors.surface))
                .argb;
            final fill = _rendered(scheme, style.backgroundColor, page);
            final ink = _rendered(scheme, style.foregroundColor, fill);
            final washed = _composite(ink, weight, fill);
            expect(
              _contrast(ink, washed),
              greaterThanOrEqualTo(4.5),
              reason:
                  '${variant.name} label on its $state face in '
                  '${brightness.name}',
            );
          });
        }
      }
    }

    test('no filled variant states a colour literal', () {
      // The white literal was invisible to every colour audit in the
      // repo precisely because it is not a token — nothing that reasons
      // about slots can see it. Its absence is the cheap half of the
      // check above.
      for (final variant in _filled) {
        final style = CoreButtonStyle.defaultsByVariant[variant]!;
        for (final entry in <String, CoreColor?>{
          'backgroundColor': style.backgroundColor,
          'foregroundColor': style.foregroundColor,
          'iconColor': style.iconColor,
        }.entries) {
          final color = entry.value;
          if (color == null) continue;
          expect(
            color.token,
            isNotNull,
            reason: '${variant.name}.${entry.key} is a literal, not a token',
          );
        }
      }
    });
  });
}
