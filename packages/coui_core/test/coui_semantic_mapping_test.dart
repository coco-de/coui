// CouiSemanticMapping — CoUI's fixed palette read into the semantic slots,
// four modes.
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

import 'support/brand_fixture.dart';

const CouiSchemeSource _kSource = CouiColorPresets.source;
const CouiPalette _kPalette = CouiColorPresets.palette;

CoreColorScheme _scheme(CoreBrightness brightness, {required bool hc}) =>
    switch ((brightness, hc)) {
      (.light, false) => _kSource.light(),
      (.dark, false) => _kSource.dark(),
      (.light, true) => _kSource.highContrastLight(),
      (.dark, true) => _kSource.highContrastDark(),
    };

const List<(CoreBrightness, bool)> _kModes = [
  (CoreBrightness.light, false),
  (CoreBrightness.dark, false),
  (CoreBrightness.light, true),
  (CoreBrightness.dark, true),
];

String _label((CoreBrightness, bool) mode) =>
    '${mode.$1.name}${mode.$2 ? ' high contrast' : ''}';

void main() {
  group('every slot is a CoUI primitive or the shared tone it links', () {
    // The unit-level form of the Figma export's "unresolved" gate: a slot
    // whose colour is not one of the 67 primitives has no variable to alias.
    // The category and syntax slots the table links are the exception —
    // they alias the brand-less shared groups by name, so each must hold
    // the very tone its link names.
    final primitiveTriplets = PrimitiveCssGenerator.primitiveVars(
      _kSource,
    ).values.toSet();
    final sharedTriplets = {
      ...PrimitiveCssGenerator.categoryPrimitiveTriplets(),
      ...PrimitiveCssGenerator.syntaxPrimitiveTriplets(),
    };

    for (final mode in _kModes) {
      test(_label(mode), () {
        final vars = PrimitiveCssGenerator.semanticVars(
          _scheme(mode.$1, hc: mode.$2).resolved(mode.$1),
        );
        final links = {
          ...CoreCategoryPalette.primitiveLinks(
            mode.$1,
            highContrast: mode.$2,
          ),
          ...CoreSyntaxPalette.primitiveLinks(mode.$1),
        };

        expect(vars, hasLength(131));
        for (final entry in vars.entries) {
          final link = links[entry.key.substring('--coui-'.length)];
          if (link != null) {
            expect(
              entry.value,
              sharedTriplets[link],
              reason: '${entry.key} is not the $link it links',
            );
            continue;
          }
          expect(
            primitiveTriplets,
            contains(entry.value),
            reason: '${entry.key} is not a CoUI primitive',
          );
        }
      });
    }
  });

  group('status indicators (#5725)', () {
    // Icons, status dots, progress bars, chart marks — non-text, so 3:1 on
    // the page in the normal modes and 4.5:1 in high contrast. Dark reads
    // `500`, except warning, which stays at `400` (designer decision
    // 2026-11-04).
    const steps = {
      (CoreBrightness.light, false): 500,
      (CoreBrightness.dark, false): 500,
      (CoreBrightness.light, true): 700,
      (CoreBrightness.dark, true): 300,
    };
    final ramps = {
      'error': _kPalette.error,
      'success': _kPalette.success,
      'warning': _kPalette.warning,
      'info': _kPalette.info,
    };
    CoreColor? icon(CoreColorScheme s, String family) => switch (family) {
      'error' => s.errorIcon,
      'success' => s.successIcon,
      'warning' => s.warningIcon,
      _ => s.infoIcon,
    };

    for (final mode in _kModes) {
      test('${_label(mode)} reads step ${steps[mode]} of each status ramp', () {
        final s = _scheme(mode.$1, hc: mode.$2);
        for (final MapEntry(key: family, value: ramp) in ramps.entries) {
          final step =
              mode == (CoreBrightness.dark, false) && family == 'warning'
              ? 400
              : steps[mode]!;
          expect(
            icon(s, family)!.argb,
            ramp.steps[step]!.argb,
            reason: family,
          );
        }
      });

      test('${_label(mode)} clears its bar on the page', () {
        final s = _scheme(mode.$1, hc: mode.$2).resolved(mode.$1);
        final bar = mode.$2 ? 4.5 : 3.0;
        for (final family in ramps.keys) {
          expect(
            CoreContrast.ratio(icon(s, family)!, s.surface),
            greaterThanOrEqualTo(bar),
            reason: family,
          );
        }
      });
    }

    test('the standard mapping keeps every mark on the page bar', () {
      final source = CoreSemanticMappingSet.standard.bind(
        CouiColorPresets.defaultPalette,
      );
      for (final (s, bar) in [
        (source.light().resolved(.light), 3.0),
        (source.dark().resolved(.dark), 3.0),
        (source.highContrastLight().resolved(.light), 4.5),
        (source.highContrastDark().resolved(.dark), 4.5),
      ]) {
        for (final family in ramps.keys) {
          expect(
            CoreContrast.ratio(icon(s, family)!, s.surface),
            greaterThanOrEqualTo(bar),
            reason: family,
          );
        }
      }
    });
  });

  group('designer decisions (2026-10-07)', () {
    test('dark outline is neutral 500, clearing 3:1 on every dark tone', () {
      expect(_kSource.dark().outline!.argb, _kPalette.neutral.s500.argb);
    });

    test('the shadow is black in every mode — dark strengthens the alpha', () {
      expect(_kSource.dark().shadow!.argb, _kPalette.black.argb);
      expect(_kSource.highContrastDark().shadow!.argb, _kPalette.black.argb);
      expect(_kSource.light().shadow!.argb, _kPalette.black.argb);
      expect(_kSource.highContrastLight().shadow!.argb, _kPalette.black.argb);
    });

    test('placeholder is neutral 600 in light and 500 in dark', () {
      expect(_kSource.light().placeholder!.argb, _kPalette.neutral.s600.argb);
      expect(_kSource.dark().placeholder!.argb, _kPalette.neutral.s500.argb);
    });

    test('the light page is base white, not neutral 50', () {
      expect(_kSource.light().surface!.argb, _kPalette.white.argb);
    });
  });

  group('designer decisions (2026-10-08)', () {
    double ratio(CoreColor? a, CoreColor? b) => CoreContrast.ratio(a!, b!);

    test('light CTA is neutral 900, hover 800, pressed 700 (#6135)', () {
      final s = _kSource.light();
      final p = _kPalette.neutral;

      expect(s.primary.argb, p.s900.argb);
      expect(s.primaryHover!.argb, p.s800.argb);
      expect(s.primaryPressed!.argb, p.s700.argb);
      // Tertiary restates the fill.
      expect(s.tertiary!.argb, p.s900.argb);
      // The slots that keep their step.
      expect(s.focusRing!.argb, p.s800.argb);
      expect(s.surfaceTint!.argb, p.s800.argb);
      expect(s.onPrimaryContainer!.argb, p.s900.argb);
      expect(s.onPrimary!.argb, _kPalette.white.argb);
    });

    test('light CTA is unchanged by the dark CTA decision (2026-10-14)', () {
      // The white dark CTA is a dark-modes-only change: light and
      // high-contrast light keep their near-black fill.
      final p = _kPalette.neutral;

      for (final s in [_kSource.light(), _kSource.highContrastLight()]) {
        expect(s.primary.argb, isNot(_kPalette.neutral.s100.argb));
      }
      // High contrast keeps the ring on the fill. Light keeps its ring at
      // `800` when the fill moved to `900` (#6135 moves only the fill and
      // its hover / pressed steps).
      expect(
        _kSource.highContrastLight().focusRing!.argb,
        _kSource.highContrastLight().primary.argb,
      );
      expect(_kSource.light().focusRing!.argb, p.s800.argb);
      expect(_kSource.light().primary.argb, p.s900.argb);
      expect(_kSource.highContrastLight().primary.argb, p.s1000.argb);
    });

    test('the CTA walk clears the figures the designer stated', () {
      // The designer's contrast table, read off the real schemes rather
      // than off the palette: a mapping that moved a step would move these.
      final light = _kSource.light();
      final dark = _kSource.dark();
      final hcLight = _kSource.highContrastLight();
      final hcDark = _kSource.highContrastDark();

      final measured = <String, (double, double)>{
        'light fill': (
          ratio(light.onPrimary, light.primary),
          14.19,
        ),
        'light hover': (ratio(light.onPrimary, light.primaryHover), 10.22),
        'light pressed': (ratio(light.onPrimary, light.primaryPressed), 7.02),
        'light on-primary-container on primary-container': (
          ratio(light.onPrimaryContainer, light.primaryContainer),
          11.33,
        ),
        'light primary-text-large on white': (
          ratio(light.primaryTextLarge, light.surface),
          7.02,
        ),
        'dark fill': (ratio(dark.onPrimary, dark.primary), 16.45),
        'dark hover': (ratio(dark.onPrimary, dark.primaryHover), 14.34),
        'dark pressed': (ratio(dark.onPrimary, dark.primaryPressed), 11.74),
        'dark primary-text on surface': (
          ratio(dark.primaryText, dark.surface),
          11.74,
        ),
        'dark primary-text-large on surface': (
          ratio(dark.primaryTextLarge, dark.surface),
          8.74,
        ),
        'hc light fill': (ratio(hcLight.onPrimary, hcLight.primary), 17.95),
        'hc light hover': (
          ratio(hcLight.onPrimary, hcLight.primaryHover),
          14.19,
        ),
        'hc light pressed': (
          ratio(hcLight.onPrimary, hcLight.primaryPressed),
          10.22,
        ),
        'hc dark fill': (ratio(hcDark.onPrimary, hcDark.primary), 20.10),
        'hc dark hover': (
          ratio(hcDark.onPrimary, hcDark.primaryHover),
          19.24,
        ),
        'hc dark pressed': (
          ratio(hcDark.onPrimary, hcDark.primaryPressed),
          16.77,
        ),
      };
      for (final entry in measured.entries) {
        expect(
          entry.value.$1,
          closeTo(entry.value.$2, 0.006),
          reason: entry.key,
        );
      }
    });
  });

  group('designer decisions (2026-10-14) — the dark CTA is near-white', () {
    final n = _kPalette.neutral;
    final p = _kPalette.neutral;
    double ratio(CoreColor? a, CoreColor? b) => CoreContrast.ratio(a!, b!);

    test('dark CTA is neutral 100, hover 200, pressed 300, label 1000', () {
      final s = _kSource.dark();

      expect(s.primary.argb, n.s100.argb);
      expect(s.primaryHover!.argb, n.s200.argb);
      expect(s.primaryPressed!.argb, n.s300.argb);
      expect(s.onPrimary!.argb, n.s1000.argb);
    });

    test('high-contrast dark CTA is neutral 50, hover 100, pressed 200', () {
      final s = _kSource.highContrastDark();

      expect(s.primary.argb, n.s50.argb);
      expect(s.primaryHover!.argb, n.s100.argb);
      expect(s.primaryPressed!.argb, n.s200.argb);
      // The label was already black there and stays.
      expect(s.onPrimary!.argb, _kPalette.black.argb);
    });

    test('the slots that follow the fill move with it, in both dark modes', () {
      final dark = _kSource.dark();
      expect(dark.focusRing!.argb, n.s100.argb);
      expect(dark.tertiary!.argb, n.s100.argb);
      expect(dark.surfaceTint!.argb, n.s100.argb);
      expect(dark.onTertiary!.argb, n.s1000.argb);

      final hc = _kSource.highContrastDark();
      expect(hc.focusRing!.argb, n.s50.argb);
      expect(hc.tertiary!.argb, n.s50.argb);
      expect(hc.surfaceTint!.argb, n.s50.argb);
      expect(hc.onTertiary!.argb, _kPalette.black.argb);

      // CoUI has no second hue, so the accent slots still read as primary.
      for (final s in [dark, hc]) {
        expect(s.tertiary!.argb, s.primary.argb);
        expect(s.onTertiary!.argb, s.onPrimary!.argb);
      }
    });

    test(
      'the container, fixed, inverse and text slots keep their steps',
      () {
        final dark = _kSource.dark();
        expect(dark.primaryContainer!.argb, p.s800.argb);
        expect(dark.onPrimaryContainer!.argb, p.s100.argb);
        expect(dark.primaryFixed!.argb, p.s200.argb);
        expect(dark.primaryFixedDim!.argb, p.s300.argb);
        expect(dark.onPrimaryFixed!.argb, p.s1000.argb);
        expect(dark.onPrimaryFixedVariant!.argb, p.s800.argb);
        expect(dark.inversePrimary!.argb, p.s900.argb);
        expect(dark.primaryText!.argb, p.s300.argb);
        expect(dark.primaryTextLarge!.argb, p.s400.argb);

        final hc = _kSource.highContrastDark();
        expect(hc.primaryContainer!.argb, p.s800.argb);
        expect(hc.onPrimaryContainer!.argb, _kPalette.white.argb);
        expect(hc.primaryFixed!.argb, p.s200.argb);
        expect(hc.primaryFixedDim!.argb, p.s300.argb);
        expect(hc.inversePrimary!.argb, p.s1000.argb);
        expect(hc.primaryText!.argb, p.s100.argb);
        expect(hc.primaryTextLarge!.argb, p.s200.argb);
      },
    );

    test('high contrast still governs every slot it governed before', () {
      // `raiseByDelta` lays over only the slots where the two tables differ;
      // a slot that came to agree would silently drop out of high contrast.
      final base = _kSource.dark();
      final raised = _kSource.raiseContrast(base, CoreBrightness.dark);
      final hc = _kSource.highContrastDark();

      for (final slot in <(String, CoreColor? Function(CoreColorScheme))>[
        ('primary', (s) => s.primary),
        ('primaryHover', (s) => s.primaryHover),
        ('primaryPressed', (s) => s.primaryPressed),
        ('onPrimary', (s) => s.onPrimary),
        ('focusRing', (s) => s.focusRing),
        ('tertiary', (s) => s.tertiary),
        ('surfaceTint', (s) => s.surfaceTint),
      ]) {
        expect(
          slot.$2(raised)!.argb,
          slot.$2(hc)!.argb,
          reason: slot.$1,
        );
        expect(
          slot.$2(raised)!.argb,
          isNot(slot.$2(base)!.argb),
          reason: '${slot.$1} no longer differs from the normal table',
        );
      }
    });

    test(
      'the contrast figures in the issue hold, read off the real schemes',
      () {
        final dark = _kSource.dark();
        final hc = _kSource.highContrastDark();

        final measured = <String, (double, double)>{
          'dark label / fill': (ratio(dark.onPrimary, dark.primary), 16.45),
          'dark label / hover': (
            ratio(dark.onPrimary, dark.primaryHover),
            14.34,
          ),
          'dark label / pressed': (
            ratio(dark.onPrimary, dark.primaryPressed),
            11.74,
          ),
          'dark fill / surface': (ratio(dark.primary, dark.surface), 16.45),
          'dark ring / surface': (ratio(dark.focusRing, dark.surface), 16.45),
          'dark ring / surface-container-highest': (
            ratio(dark.focusRing, dark.surfaceContainerHighest),
            9.36,
          ),
          'dark fill → hover step': (
            ratio(dark.primary, dark.primaryHover),
            1.15,
          ),
          'hc label / fill': (ratio(hc.onPrimary, hc.primary), 20.10),
          'hc label / hover': (ratio(hc.onPrimary, hc.primaryHover), 19.24),
          'hc label / pressed': (ratio(hc.onPrimary, hc.primaryPressed), 16.77),
          'hc fill / surface': (ratio(hc.primary, hc.surface), 17.18),
          'hc ring / surface': (ratio(hc.focusRing, hc.surface), 17.18),
          'hc ring / surface-container-highest': (
            ratio(hc.focusRing, hc.surfaceContainerHighest),
            9.78,
          ),
        };
        for (final entry in measured.entries) {
          expect(
            entry.value.$1,
            closeTo(entry.value.$2, 0.006),
            reason: entry.key,
          );
        }
      },
    );
  });

  group('designer decisions (2026-10-08) — surfaces and placeholder', () {
    final n = _kPalette.neutral;

    test('the dark panel is neutral 900 in both dark modes', () {
      expect(_kSource.dark().surfaceBright!.argb, n.s900.argb);
      expect(_kSource.highContrastDark().surfaceBright!.argb, n.s900.argb);
      // Light keeps white — the panel and the page are one tone there.
      expect(_kSource.light().surfaceBright!.argb, _kPalette.white.argb);
      expect(
        _kSource.highContrastLight().surfaceBright!.argb,
        _kPalette.white.argb,
      );
    });

    test('the dark tonal fill is neutral 800 in both dark modes', () {
      expect(_kSource.dark().secondaryContainer!.argb, n.s800.argb);
      expect(_kSource.highContrastDark().secondaryContainer!.argb, n.s800.argb);
      // Light modes are not part of the decision.
      expect(_kSource.light().secondaryContainer!.argb, n.s100.argb);
      expect(
        _kSource.highContrastLight().secondaryContainer!.argb,
        n.s150.argb,
      );
    });

    test('the dark tonal fill is not the panel it lies on', () {
      // 800 on a 900 panel: the tonal button still reads as a surface.
      for (final s in [_kSource.dark(), _kSource.highContrastDark()]) {
        expect(
          s.secondaryContainer!.argb,
          isNot(s.surfaceBright!.argb),
          reason: 'a tonal fill equal to the panel is invisible on it',
        );
      }
    });

    test('high-contrast placeholder is neutral 700 in light, 400 in dark', () {
      expect(_kSource.highContrastLight().placeholder!.argb, n.s700.argb);
      expect(_kSource.highContrastDark().placeholder!.argb, n.s400.argb);
      // The normal modes keep their own step.
      expect(_kSource.light().placeholder!.argb, n.s600.argb);
      expect(_kSource.dark().placeholder!.argb, n.s500.argb);
    });

    test('high-contrast placeholder stays weaker than the value text', () {
      // A placeholder reads as "nothing entered yet" only while the text
      // that replaces it is stronger — in dark it used to be the lighter.
      for (final s in [
        _kSource.highContrastLight(),
        _kSource.highContrastDark(),
      ]) {
        final page = s.surface;
        expect(
          CoreContrast.ratio(s.placeholder!, page!),
          lessThan(CoreContrast.ratio(s.onSurfaceVariant!, page)),
        );
        expect(
          CoreContrast.ratio(s.onSurfaceVariant!, page),
          lessThan(CoreContrast.ratio(s.onSurface!, page)),
        );
      }
    });

    test('the dark panel and tonal figures match the designer table', () {
      final dark = _kSource.dark();
      final hcDark = _kSource.highContrastDark();
      double ratio(CoreColor? a, CoreColor? b) => CoreContrast.ratio(a!, b!);

      // Re-measured after the achromatic neutral (#6135); the
      // floors the 2026-10-08 table was checked against still clear.
      final measured = <String, (double, double)>{
        'dark panel: on-surface': (
          ratio(dark.onSurface, dark.surfaceBright),
          13.00,
        ),
        'dark panel: on-surface-variant': (
          ratio(dark.onSurfaceVariant, dark.surfaceBright),
          6.91,
        ),
        'dark panel: placeholder': (
          ratio(dark.placeholder, dark.surfaceBright),
          4.72,
        ),
        'dark tonal / on-secondary-container': (
          ratio(dark.onSecondaryContainer, dark.secondaryContainer),
          9.36,
        ),
        'hc dark tonal / on-secondary-container': (
          ratio(hcDark.onSecondaryContainer, hcDark.secondaryContainer),
          10.22,
        ),
        'hc light placeholder on white': (
          ratio(
            _kSource.highContrastLight().placeholder,
            _kSource.highContrastLight().surface,
          ),
          7.02,
        ),
        'hc dark placeholder on page': (
          ratio(hcDark.placeholder, hcDark.surface),
          8.74,
        ),
      };
      for (final entry in measured.entries) {
        expect(
          entry.value.$1,
          closeTo(entry.value.$2, 0.006),
          reason: entry.key,
        );
      }
    });

    test('the dark control boundary clears 3:1 on the panel', () {
      // The designer's table lists 3.02 for this pair, which is
      // `neutral/600` on the panel. The mapping states `neutral/500`
      // (decision 2026-10-07) and measures 4.72 since the achromatic
      // neutral (#6135) — still over the 3:1 a control boundary needs.
      final dark = _kSource.dark();
      expect(
        CoreContrast.ratio(dark.outline!, dark.surfaceBright!),
        closeTo(4.72, 0.006),
      );
    });
  });

  group('designer decisions (2026-10-08) — outline-subtle', () {
    final n = _kPalette.neutral;
    double ratio(CoreColor? a, CoreColor? b) => CoreContrast.ratio(a!, b!);

    test('the floating-panel line is 150 · 800 · 600 · 400 by mode', () {
      expect(_kSource.light().outlineSubtle!.argb, n.s150.argb);
      expect(_kSource.dark().outlineSubtle!.argb, n.s800.argb);
      // High contrast raises it past the token export's 500 in both modes.
      expect(_kSource.highContrastLight().outlineSubtle!.argb, n.s600.argb);
      expect(_kSource.highContrastDark().outlineSubtle!.argb, n.s400.argb);
    });

    test('it is a slot of its own, not outline-variant under another name', () {
      for (final mode in _kModes) {
        final s = _scheme(mode.$1, hc: mode.$2);
        final vars = PrimitiveCssGenerator.semanticVars(s.resolved(mode.$1));

        expect(vars, contains('--coui-outline-subtle'), reason: _label(mode));
      }
      // High-contrast light disagrees with outline-variant, so a slot that
      // aliased it would fail. (Dark used to disagree too; since #5748 moved
      // dark outline-variant up to 800 the two share that step.)
      expect(
        _kSource.highContrastLight().outlineSubtle!.argb,
        isNot(_kSource.highContrastLight().outlineVariant!.argb),
      );
    });

    test('the high-contrast line clears the UI bar on the page and the '
        'panel', () {
      final hcLight = _kSource.highContrastLight();
      final hcDark = _kSource.highContrastDark();

      // The designer's figures (F2) — 4.67 on white, 8.65 on the dark page;
      // 4.68 and 8.74 since the achromatic neutral (#6135).
      expect(
        ratio(hcLight.outlineSubtle, hcLight.surface),
        closeTo(4.68, 0.006),
      );
      expect(ratio(hcDark.outlineSubtle, hcDark.surface), closeTo(8.74, 0.006));
      for (final s in [hcLight, hcDark]) {
        for (final ground in [s.surface, s.surfaceBright]) {
          expect(
            ratio(s.outlineSubtle, ground),
            greaterThanOrEqualTo(4.5),
            reason: 'a floating panel leans on this line instead of its shadow',
          );
        }
      }
    });

    test('the token export value would have missed that bar', () {
      // neutral/500 is what the designer's token JSON carries for both
      // high-contrast modes; the light one measures 3.01 on white. This is
      // why the mapping states 600 and 400 instead.
      expect(
        ratio(n.s500, _kSource.highContrastLight().surface),
        closeTo(3.01, 0.006),
      );
    });

    test('in light it is quieter than outline-variant', () {
      final light = _kSource.light();
      expect(
        ratio(light.outlineSubtle, light.surface),
        lessThan(ratio(light.outlineVariant, light.surface)),
      );
    });

    test('the dark line is drawn on the panel it borders', () {
      // A floating panel's fill is `surfaceBright` (900); a line in that same
      // tone draws nothing. One step lighter is 1.39:1 on the panel. Since
      // #5748 moved dark outline-variant from 850 to 800 the two lines share
      // that step — the panel line is no longer weaker than it, and no
      // longer stronger either.
      final dark = _kSource.dark();
      expect(dark.outlineSubtle!.argb, isNot(dark.surfaceBright!.argb));
      expect(
        ratio(dark.outlineSubtle, dark.surfaceBright),
        closeTo(1.39, 0.006),
      );
      expect(
        ratio(dark.outlineSubtle, dark.surface),
        greaterThanOrEqualTo(ratio(dark.outlineVariant, dark.surface)),
      );
    });
  });

  group('onSurfaceSubtle — the third text tier', () {
    final n = _kPalette.neutral;
    double ratio(CoreColor? a, CoreColor? b) => CoreContrast.ratio(a!, b!);

    test('it is neutral 600 · 500 · 700 · 400 by mode', () {
      expect(_kSource.light().onSurfaceSubtle!.argb, n.s600.argb);
      expect(_kSource.dark().onSurfaceSubtle!.argb, n.s500.argb);
      expect(_kSource.highContrastLight().onSurfaceSubtle!.argb, n.s700.argb);
      expect(_kSource.highContrastDark().onSurfaceSubtle!.argb, n.s400.argb);
    });

    test('it clears 4.5:1 on the page tones, in every mode', () {
      // The placeholder's step and the placeholder's promise: the page and
      // the tone that equals it. The grey containers are left to the second
      // tier (light measures 4.26 on `surfaceContainer`).
      for (final mode in _kModes) {
        final s = _scheme(mode.$1, hc: mode.$2);
        for (final tone in [s.surface, s.surfaceContainerLowest]) {
          expect(
            ratio(s.onSurfaceSubtle, tone),
            greaterThanOrEqualTo(4.5),
            reason: '${_label(mode)} on ${tone!.argb.toRadixString(16)}',
          );
        }
      }
    });

    test('it reads weaker than the second tier on the page', () {
      for (final mode in _kModes) {
        final s = _scheme(mode.$1, hc: mode.$2);
        expect(
          ratio(s.onSurfaceSubtle, s.surface),
          lessThan(ratio(s.onSurfaceVariant, s.surface)),
          reason: _label(mode),
        );
      }
    });

    test('it is a slot of its own, not placeholder under another name', () {
      for (final mode in _kModes) {
        final s = _scheme(mode.$1, hc: mode.$2);
        final vars = PrimitiveCssGenerator.semanticVars(s.resolved(mode.$1));

        expect(
          vars,
          contains('--coui-on-surface-subtle'),
          reason: _label(mode),
        );
      }
      // The two share a step on CoUI's palette and nothing else: moving one
      // leaves the other where it was.
      final moved = _kSource.light().copyWith(placeholder: n.s700);
      expect(moved.onSurfaceSubtle!.argb, n.s600.argb);
    });
  });

  group('surfaceRaised — the face that rises out of a track', () {
    final n = _kPalette.neutral;

    test('it is white in light and the top rung in dark', () {
      expect(_kSource.light().surfaceRaised!.argb, _kPalette.white.argb);
      expect(
        _kSource.highContrastLight().surfaceRaised!.argb,
        _kPalette.white.argb,
      );
      expect(_kSource.dark().surfaceRaised!.argb, n.s800.argb);
      expect(_kSource.highContrastDark().surfaceRaised!.argb, n.s800.argb);
    });

    test('it is lighter than the track it rises out of, in every mode', () {
      for (final mode in _kModes) {
        final s = _scheme(mode.$1, hc: mode.$2).resolved(mode.$1);
        expect(
          CoreContrast.relativeLuminance(s.surfaceRaised),
          greaterThan(CoreContrast.relativeLuminance(s.surfaceContainer)),
          reason: _label(mode),
        );
      }
    });
  });

  group('link — a colour of its own on the info ramp', () {
    final info = _kPalette.info;
    double ratio(CoreColor? a, CoreColor? b) => CoreContrast.ratio(a!, b!);

    List<CoreColor?> tones(CoreColorScheme s) => [
      s.surface,
      s.surfaceDim,
      s.surfaceBright,
      s.surfaceContainerLowest,
      s.surfaceContainerLow,
      s.surfaceContainer,
      s.surfaceContainerHigh,
      s.surfaceContainerHighest,
    ];

    test('the link is info 700 · 400 · 800 · 200 by mode', () {
      expect(_kSource.light().link!.argb, info.s700.argb);
      expect(_kSource.dark().link!.argb, info.s400.argb);
      expect(_kSource.highContrastLight().link!.argb, info.s800.argb);
      expect(_kSource.highContrastDark().link!.argb, info.s200.argb);
    });

    test('it is a slot of its own, not info under another name', () {
      for (final mode in _kModes) {
        final s = _scheme(mode.$1, hc: mode.$2);
        final vars = PrimitiveCssGenerator.semanticVars(s.resolved(mode.$1));

        expect(vars, contains('--coui-link'), reason: _label(mode));
      }
      // Only light disagrees with the status `info` (600 against 700), so a
      // slot that aliased `info` would fail exactly there.
      expect(
        _kSource.light().link!.argb,
        isNot(_kSource.light().info.argb),
      );
    });

    test('it is not the brand ink — primary is what it replaced', () {
      for (final mode in _kModes) {
        final s = _scheme(mode.$1, hc: mode.$2);
        expect(s.link!.argb, isNot(s.primary.argb), reason: _label(mode));
      }
    });

    test('it clears 4.5:1 on every surface tone in every mode', () {
      for (final mode in _kModes) {
        final s = _scheme(mode.$1, hc: mode.$2);
        for (final tone in tones(s)) {
          expect(
            ratio(s.link, tone),
            greaterThanOrEqualTo(4.5),
            reason: '${_label(mode)} on ${tone!.argb.toRadixString(16)}',
          );
        }
      }
    });

    test('the tightest tone is the darkest container', () {
      // Light 700 on the lightest grey container; dark 400 on the darkest.
      // Recorded so a palette change that eats the margin shows up here, not
      // only in the gate's pass/fail.
      final light = _kSource.light();
      final dark = _kSource.dark();
      expect(
        ratio(light.link, light.surfaceContainerHighest),
        closeTo(5.17, 0.006),
      );
      expect(
        ratio(dark.link, dark.surfaceContainerHighest),
        closeTo(4.91, 0.006),
      );
    });

    test(
      'the status step would have missed the bar on the grey containers',
      () {
        // info/600 is the status fill; as link text it falls under 4.5:1 on
        // the two higher light grey containers (4.37 and 4.04), and clears it
        // on the lower one (4.63). This is why light states 700.
        final light = _kSource.light();
        for (final tone in [
          light.surfaceContainerHigh,
          light.surfaceContainerHighest,
        ]) {
          expect(ratio(info.s600, tone), lessThan(4.5));
        }
      },
    );
  });

  group('the standard mapping states a link colour of its own', () {
    for (final (name, brightness, scheme) in [
      ('light', CoreBrightness.light, kBrandFixtureSource.light()),
      ('dark', CoreBrightness.dark, kBrandFixtureSource.dark()),
      (
        'high-contrast light',
        CoreBrightness.light,
        kBrandFixtureSource.highContrastLight(),
      ),
      (
        'high-contrast dark',
        CoreBrightness.dark,
        kBrandFixtureSource.highContrastDark(),
      ),
    ]) {
      test('$name clears 4.5:1 on every surface tone', () {
        final s = scheme.resolved(brightness);
        for (final tone in [
          s.surface,
          s.surfaceDim,
          s.surfaceBright,
          s.surfaceContainerLowest,
          s.surfaceContainerLow,
          s.surfaceContainer,
          s.surfaceContainerHigh,
          s.surfaceContainerHighest,
        ]) {
          expect(
            CoreContrast.ratio(s.link, tone),
            greaterThanOrEqualTo(4.5),
            reason: name,
          );
        }
      });
    }

    test('it is not the status info of the same mode', () {
      // The status step is tuned for a filled chip; the link steps one tone
      // away from it in the two normal modes.
      for (final scheme in [
        kBrandFixtureSource.light(),
        kBrandFixtureSource.dark(),
      ]) {
        expect(scheme.link!.argb, isNot(scheme.info.argb));
      }
    });
  });

  group('the standard mapping reads outline-subtle as outline-variant', () {
    // No brand states a floating-panel border, so the slot must not invent
    // one: every mode of the standard mapping — and so of a brand that
    // states no mapping of its own — answers with its own outline-variant.
    for (final (name, scheme) in [
      ('light', kBrandFixtureSource.light()),
      ('dark', kBrandFixtureSource.dark()),
      ('high-contrast light', kBrandFixtureSource.highContrastLight()),
      ('high-contrast dark', kBrandFixtureSource.highContrastDark()),
    ]) {
      test(name, () {
        expect(scheme.outlineSubtle, isNotNull);
        expect(scheme.outlineSubtle!.argb, scheme.outlineVariant!.argb);
      });
    }
  });

  group('the tertiary family restates primary', () {
    for (final mode in _kModes) {
      test(_label(mode), () {
        final s = _scheme(mode.$1, hc: mode.$2);
        final pairs = {
          'tertiary': (s.tertiary, s.primary),
          'onTertiary': (s.onTertiary, s.onPrimary),
          'tertiaryContainer': (s.tertiaryContainer, s.primaryContainer),
          'onTertiaryContainer': (s.onTertiaryContainer, s.onPrimaryContainer),
          'tertiaryFixed': (s.tertiaryFixed, s.primaryFixed),
          'tertiaryFixedDim': (s.tertiaryFixedDim, s.primaryFixedDim),
          'onTertiaryFixed': (s.onTertiaryFixed, s.onPrimaryFixed),
          'onTertiaryFixedVariant': (
            s.onTertiaryFixedVariant,
            s.onPrimaryFixedVariant,
          ),
        };
        for (final entry in pairs.entries) {
          expect(
            entry.value.$1!.argb,
            entry.value.$2!.argb,
            reason: entry.key,
          );
        }

        // The accent alias reads the tertiary slots, so it restates primary
        // too.
        final vars = PrimitiveCssGenerator.semanticVars(s.resolved(mode.$1));
        expect(vars['--coui-accent'], vars['--coui-primary']);
        expect(vars['--coui-on-accent'], vars['--coui-on-primary']);
      });
    }
  });

  // High contrast lays only the slots its table changes over its base, so a
  // surface style that bent the base survives on every other slot. Seeded
  // with one sentinel colour in every slot: whatever comes back as the
  // sentinel was kept from the base, whatever does not was raised. The
  // expected raised set is the difference between the two tables, computed
  // here — not a count copied from the tables.
  group('raiseContrast keeps the base where the tables agree', () {
    const sentinel = '#123456';
    const sentinelTriplet = '18 52 86';

    final vocabulary = PrimitiveCssGenerator.semanticVarsFor(
      _kSource,
      .light,
    ).keys.map((k) => k.substring('--coui-'.length));
    final sentinelBase = CoreColorScheme.fromMap({
      for (final slot in vocabulary)
        if (slot != 'accent' && slot != 'on-accent') slot: sentinel,
    });

    for (final brightness in CoreBrightness.values) {
      test(brightness.name, () {
        final normal = PrimitiveCssGenerator.semanticVarsFor(
          _kSource,
          brightness,
        );
        final raisedTable = PrimitiveCssGenerator.semanticVarsFor(
          _kSource,
          brightness,
          highContrast: true,
        );
        final result = PrimitiveCssGenerator.semanticVars(
          _kSource.raiseContrast(sentinelBase, brightness).resolved(brightness),
        );

        var raised = 0;
        for (final key in normal.keys) {
          if (normal[key] == raisedTable[key]) {
            expect(result[key], sentinelTriplet, reason: '$key was not kept');
          } else {
            raised++;
            expect(result[key], raisedTable[key], reason: '$key not raised');
          }
        }
        expect(raised, greaterThan(0));
        expect(raised, lessThan(normal.length));
      });
    }
  });

  group('resolveThemeSchemeFrom with a surface style under high contrast', () {
    test('the style keeps its bent tones; high contrast wins the outline', () {
      for (final brightness in CoreBrightness.values) {
        final styled = resolveThemeSchemeFrom(
          _kSource,
          brightness: brightness,
          surfaceStyle: .neumorphism,
        );
        final raised = resolveThemeSchemeFrom(
          _kSource,
          brightness: brightness,
          highContrast: true,
          surfaceStyle: .neumorphism,
        );
        final table = _scheme(brightness, hc: true);
        final reason = brightness.name;

        // Neumorphism flattens the container tones onto the page — the
        // high-contrast table states the same tones as the normal one, so
        // the flattening survives.
        expect(raised.surfaceContainerLow, styled.surfaceContainerLow);
        expect(raised.surfaceContainer, styled.surfaceContainer);
        expect(raised.surfaceContainerHigh, styled.surfaceContainerHigh);
        expect(raised.surfaceContainerLow!.argb, raised.surface!.argb);
        // The outline is a slot high contrast governs: the style's emphasis
        // gives way to the table's value.
        expect(
          raised.outline!.argb,
          table.outline!.argb,
          reason: reason,
        );
        expect(
          styled.outline!.argb,
          isNot(table.outline!.argb),
          reason: '$reason: precondition — the style moved the outline',
        );
      }
    });
  });

  group('dark status containers (designer decision 2026-11-05, #6012)', () {
    final dark = _kSource.dark();
    const p = CouiColorPresets.palette;

    test('containers read the dark-only 950 step', () {
      expect(dark.successContainer!.argb, p.success.s950.argb);
      expect(dark.infoContainer!.argb, p.info.s950.argb);
      expect(dark.errorContainer!.argb, p.error.s950.argb);
      expect(dark.warningContainer!.argb, p.warning.s950.argb);
    });

    test('on-container text reads 400 / 500 / 400 / 400', () {
      expect(dark.onSuccessContainer!.argb, p.success.s400.argb);
      expect(dark.onInfoContainer!.argb, p.info.s500.argb);
      expect(dark.onErrorContainer!.argb, p.error.s400.argb);
      expect(dark.onWarningContainer!.argb, p.warning.s400.argb);
    });

    test('every pair clears 4.5:1', () {
      final pairs = {
        'success': (dark.onSuccessContainer, dark.successContainer),
        'info': (dark.onInfoContainer, dark.infoContainer),
        'error': (dark.onErrorContainer, dark.errorContainer),
        'warning': (dark.onWarningContainer, dark.warningContainer),
      };
      for (final MapEntry(key: family, value: (ink, fill)) in pairs.entries) {
        expect(
          CoreContrast.ratio(ink!, fill!),
          greaterThanOrEqualTo(4.5),
          reason: family,
        );
      }
    });

    test('error ink also clears 4.5:1 on the dark surfaces', () {
      // `onErrorContainer` is read off its container too (Badge destructive
      // outlined, a failed StepItem's note, the `invalid` syntax role), so
      // it stays at `400`: `500` measures 3.98 on surface container high.
      for (final tone in [
        dark.surface,
        dark.surfaceContainer,
        dark.surfaceContainerHigh,
        dark.surfaceBright,
      ]) {
        expect(
          CoreContrast.ratio(dark.onErrorContainer!, tone!),
          greaterThanOrEqualTo(4.5),
        );
      }
    });

    test('the light and high-contrast modes keep their steps', () {
      final light = _kSource.light();
      final hcDark = _kSource.highContrastDark();
      expect(light.infoContainer!.argb, p.info.s100.argb);
      expect(light.onInfoContainer!.argb, p.info.s700.argb);
      expect(hcDark.infoContainer!.argb, p.info.s900.argb);
      expect(hcDark.errorContainer!.argb, p.error.s900.argb);
    });
  });
}
