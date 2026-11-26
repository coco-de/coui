import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

import 'support/brand_fixture.dart';

void main() {
  // The same decision holds for both mappings that ship: a brand palette
  // read through the standard mapping, and CoUI's own source.
  _disabledTokenSuite(
    'standard mapping on a brand palette',
    kBrandFixtureSource,
  );
  // CoUI light draws disabled content at neutral 400 (#5748) — lighter than
  // `placeholder` so an unusable field reads apart from a usable one. That
  // puts it under 3:1; disabled components are exempt from WCAG contrast
  // (1.4.3 / 1.4.11), and the floor here pins the decision so a further
  // drift still fails.
  _disabledTokenSuite('CoUI', CouiColorPresets.source, lightFloor: 1.85);

  group('components no longer dim on top of their disabled colours', () {
    test('chip / label / phone_input use a neutral multiplier', () {
      // Each of these already carried disabled colours; the multiplier on
      // top was what made their final contrast surface-dependent.
      expect(
        CoreChipStyle.defaultDisabledOpacity,
        equals(CoreOpacity.opacity100),
      );
      expect(
        CoreLabelStyle.defaultDisabledOpacity,
        equals(CoreOpacity.opacity100),
      );
      expect(
        CorePhoneInputStyle.defaultDisabledOpacity,
        equals(CoreOpacity.opacity100),
      );
    });

    test('chip disabled chrome comes from the tokens', () {
      final chrome = CoreChipStyle.defaultsByColor.values.first;
      // Two rows since the redesign, and the pair is the point: the chip
      // that was selected keeps a filled container so the selection is
      // still legible through the greying, the one that was not sits on the
      // page's own surface behind a hairline.
      expect(
        chrome.disabledSelectedBg.token,
        equals(CoreColors.disabledContainer),
      );
      expect(chrome.disabledBg.token, equals(CoreColors.surface));
      expect(
        chrome.disabledBorderColor.token,
        equals(CoreColors.disabledOutline),
      );
      // The label takes the graphics ink here rather than the one-step-down
      // text colour every other component uses — classified, with the
      // measurements, in `disabled_label_readability_test.dart`. A chip on
      // `surface` has no other chrome left to say "off" with.
      expect(chrome.disabledFg.token, equals(CoreColors.disabledContent));
    });
  });
}

void _disabledTokenSuite(
  String name,
  CoreSchemeSource source, {
  double lightFloor = 3,
}) {
  final light = source.light().resolved(CoreBrightness.light);
  final dark = source.dark().resolved(CoreBrightness.dark);

  group('$name: disabled tokens are wired', () {
    test('every mode resolves all three slots', () {
      for (final scheme in [light, dark]) {
        expect(scheme.disabledContent, isNotNull);
        expect(scheme.disabledContainer, isNotNull);
        expect(scheme.disabledOutline, isNotNull);
      }
    });

    test('the tokens read back off the scheme', () {
      expect(CoreColors.disabledContent.read(light), isNotNull);
      expect(CoreColors.disabledContainer.read(light), isNotNull);
      expect(CoreColors.disabledOutline.read(dark), isNotNull);
    });

    test('token names match the CSS variable spelling', () {
      expect(CoreColors.disabledContent.name, equals('disabled-content'));
      expect(CoreColors.disabledContainer.name, equals('disabled-container'));
      expect(CoreColors.disabledOutline.name, equals('disabled-outline'));
    });
  });

  group('$name: disabled foreground contrast', () {
    // The point of a fixed token over an opacity multiplier is that the
    // contrast is decided once here instead of depending on whichever
    // surface the element lands on. These numbers are that decision, so a
    // palette change that quietly erodes them should fail rather than ship.
    test('clears its floor against the surface in both modes', () {
      expect(
        CoreContrast.ratio(light.disabledContent, light.surface),
        greaterThanOrEqualTo(lightFloor),
      );
      expect(
        CoreContrast.ratio(dark.disabledContent, dark.surface),
        greaterThanOrEqualTo(3),
      );
    });

    test('clears its floor against its own container in both modes', () {
      expect(
        CoreContrast.ratio(light.disabledContent, light.disabledContainer),
        greaterThanOrEqualTo(lightFloor),
      );
      expect(
        CoreContrast.ratio(dark.disabledContent, dark.disabledContainer),
        greaterThanOrEqualTo(3),
      );
    });

    test('still reads as muted next to normal body text', () {
      // Disabled has to be *legible* and *obviously inactive*. If it matched
      // onSurface it would clear contrast while telling the user nothing.
      for (final s in [light, dark]) {
        expect(
          CoreContrast.ratio(s.disabledContent, s.surface),
          lessThan(CoreContrast.ratio(s.onSurface, s.surface)),
        );
      }
    });
  });

  group('$name: disabled chrome stays subdued', () {
    test('the container is a quiet fill, not a second surface', () {
      for (final s in [light, dark]) {
        expect(CoreContrast.ratio(s.disabledContainer, s.surface), lessThan(3));
      }
    });

    test('the outline is visible but under the normal outline', () {
      for (final s in [light, dark]) {
        expect(
          CoreContrast.ratio(s.disabledOutline, s.surface),
          lessThan(CoreContrast.ratio(s.outline, s.surface)),
        );
      }
    });
  });
}
