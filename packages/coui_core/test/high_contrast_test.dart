import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

import 'support/brand_fixture.dart';

void main() {
  // The same promises hold for both mappings that ship: a brand palette
  // read through the standard mapping, and CoUI's own source.
  _highContrastSuite(
    'standard mapping on a brand palette',
    kBrandFixtureSource,
  );
  _highContrastSuite('CoUI', CouiColorPresets.source);
}

void _highContrastSuite(String name, CoreSchemeSource source) {
  final light = source.light().resolved(.light);
  final dark = source.dark().resolved(.dark);
  final hcLight = source.highContrastLight().resolved(.light);
  final hcDark = source.highContrastDark().resolved(.dark);

  group('$name: high contrast actually raises contrast', () {
    test('body text against the surface', () {
      expect(
        CoreContrast.ratio(hcLight.onSurface, hcLight.surface),
        greaterThan(CoreContrast.ratio(light.onSurface, light.surface)),
      );
      expect(
        CoreContrast.ratio(hcDark.onSurface, hcDark.surface),
        greaterThan(CoreContrast.ratio(dark.onSurface, dark.surface)),
      );
    });

    test('secondary text against the surface', () {
      expect(
        CoreContrast.ratio(hcLight.onSurfaceVariant, hcLight.surface),
        greaterThan(CoreContrast.ratio(light.onSurfaceVariant, light.surface)),
      );
    });

    test('component boundaries clear 3:1 in every mode', () {
      // This once asserted that the *normal* outline sat below 3:1 — the bug
      // written down as an expectation. A boundary that identifies a control
      // owes 1.4.11 its 3:1 in the mode the user is already in, not only in
      // the mode they had to go find. Both sets clear it now, and high
      // contrast may not regress below normal.
      expect(
        CoreContrast.ratio(light.outline, light.surface),
        greaterThanOrEqualTo(3),
      );
      expect(
        CoreContrast.ratio(dark.outline, dark.surface),
        greaterThanOrEqualTo(3),
      );
      expect(
        CoreContrast.ratio(hcLight.outline, hcLight.surface),
        greaterThanOrEqualTo(CoreContrast.ratio(light.outline, light.surface)),
      );
      expect(
        CoreContrast.ratio(hcDark.outline, hcDark.surface),
        greaterThanOrEqualTo(CoreContrast.ratio(dark.outline, dark.surface)),
      );
    });

    test('filled surfaces carry legible foregrounds', () {
      // On the standard mapping tertiary / success / info fail 4.5:1 in the
      // normal set; the high-contrast set darkens the fill so the white
      // foreground clears.
      for (final pair in [
        (hcLight.onPrimary, hcLight.primary),
        (hcLight.onTertiary, hcLight.tertiary),
        (hcLight.onSuccess, hcLight.success),
        (hcLight.onInfo, hcLight.info),
      ]) {
        expect(CoreContrast.ratio(pair.$1, pair.$2), greaterThanOrEqualTo(4.5));
      }
    });

    test('disabled stays muted but becomes legible', () {
      expect(
        CoreContrast.ratio(hcLight.disabledContent, hcLight.surface),
        greaterThan(CoreContrast.ratio(light.disabledContent, light.surface)),
      );
      expect(
        CoreContrast.ratio(hcLight.disabledContent, hcLight.surface),
        lessThan(CoreContrast.ratio(hcLight.onSurface, hcLight.surface)),
        reason: 'disabled must still read as inactive, not as body text.',
      );
    });
  });

  group('$name: what high contrast deliberately leaves alone', () {
    test('surface tones stay distinguishable', () {
      // Flattening them to white would maximise text contrast and erase the
      // boundary of every component that differentiates by background tone
      // without drawing a border — a worse outcome than low contrast.
      expect(hcLight.surface, isNot(equals(hcLight.surfaceContainerHighest)));
      expect(hcDark.surface, isNot(equals(hcDark.surfaceContainerHighest)));
    });

    test('foreground polarity is consistent within a mode', () {
      // Choosing black or white per role by whichever contrasts more would
      // make the same component read light-on-dark in one place and
      // dark-on-light in another.
      for (final fg in [
        hcLight.onPrimary,
        hcLight.onSecondary,
        hcLight.onTertiary,
        hcLight.onError,
        hcLight.onSuccess,
        hcLight.onWarning,
        hcLight.onInfo,
      ]) {
        expect(
          CoreContrast.relativeLuminance(fg),
          greaterThan(0.9),
          reason: 'all light in light',
        );
      }
      for (final fg in [
        hcDark.onPrimary,
        hcDark.onSecondary,
        hcDark.onTertiary,
        hcDark.onError,
        hcDark.onSuccess,
        hcDark.onWarning,
        hcDark.onInfo,
      ]) {
        expect(
          CoreContrast.relativeLuminance(fg),
          lessThan(0.1),
          reason: 'all dark in dark',
        );
      }
    });
  });

  group('$name: the axis can actually trigger a rebuild', () {
    test('the high-contrast scheme is unequal to the base one', () {
      // Every slot the axis writes has to be inside value equality, or the
      // framework compares the new scheme equal to the old and never
      // rebuilds — the axis would compute correctly and change nothing.
      expect(source.highContrastLight(), isNot(equals(source.light())));
      expect(source.highContrastDark(), isNot(equals(source.dark())));
    });

    test('and hashes differently', () {
      expect(
        source.highContrastLight().hashCode,
        isNot(equals(source.light().hashCode)),
      );
      expect(
        source.highContrastDark().hashCode,
        isNot(equals(source.dark().hashCode)),
      );
    });
  });
}
