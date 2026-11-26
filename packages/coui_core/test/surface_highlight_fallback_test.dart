import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// Lightness, on the 0–1 scale the conversion helper uses.
double _lightness(CoreColor c) => CoreColorConversion.colorToHSL(c).l;

/// The roots every palette has to state, so the cases below can vary
/// only the one thing under test.
const _root = CoreColor.fromARGB(255, 90, 100, 200);

/// A palette that states a surface and says nothing about a highlight —
/// the shape any consumer-authored palette starts out as.
CoreColorScheme _silentPalette(CoreColor surface) => CoreColorScheme(
  primary: _root,
  secondary: _root,
  error: _root,
  success: _root,
  warning: _root,
  info: _root,
  surface: surface,
);

void main() {
  group('a palette that states no highlight still gets one', () {
    test('it resolves to a value in both modes', () {
      // The whole point. An unresolved highlight fails asymmetrically:
      // Flutter paints it at alpha 0 (the rim is merely absent), while
      // Web emits an undefined custom property that invalidates the
      // entire `box-shadow` declaration — so the surface loses every
      // layer, including the ones that had nothing to do with the rim.
      for (final brightness in CoreBrightness.values) {
        final resolved = _silentPalette(
          const CoreColor.fromARGB(255, 250, 249, 252),
        ).resolved(brightness);

        expect(
          resolved.surfaceHighlight,
          isNotNull,
          reason: 'no highlight resolved in ${brightness.name}',
        );
      }
    });

    test('the derived highlight is lighter than the surface it sits on', () {
      // Non-null is not the requirement — being *visible* is. A rim the
      // same lightness as its surface is a value that passes every type
      // check and shows nothing.
      const surface = CoreColor.fromARGB(255, 32, 33, 36);
      final resolved = _silentPalette(surface).resolved(CoreBrightness.dark);

      expect(
        _lightness(resolved.surfaceHighlight),
        greaterThan(_lightness(surface)),
      );
    });

    test('two palettes with different surfaces get different rims', () {
      // The A → B switch, and the one shape that actually discriminates.
      // Comparing across modes does not: the shipped palettes already
      // differ by mode, so a rim *copied* from them still varies and the
      // check passes on the broken code. Same mode, two surfaces — a
      // copied rim is then identical for both, and a derived one is not.
      const dim = CoreColor.fromARGB(255, 18, 18, 20);
      const lifted = CoreColor.fromARGB(255, 64, 64, 70);

      final fromDim = _silentPalette(dim).resolved(CoreBrightness.dark);
      final fromLifted = _silentPalette(lifted).resolved(CoreBrightness.dark);

      expect(
        _lightness(fromDim.surfaceHighlight),
        lessThan(_lightness(fromLifted.surfaceHighlight)),
        reason:
            'both palettes landed on the same rim, so it came from '
            'the default palette rather than from their own surfaces',
      );
    });

    test('it keeps the surface hue rather than introducing a neutral', () {
      // A fixed white — or a grey borrowed from the default palette —
      // reads as foreign on a tinted surface. Comparing the hues, not
      // merely "is it saturated": the borrowed grey is itself faintly
      // tinted, so a saturation check passes on the broken code too.
      const tinted = CoreColor.fromARGB(255, 40, 28, 48);
      final resolved = _silentPalette(tinted).resolved(CoreBrightness.dark);
      final surfaceHue = CoreColorConversion.colorToHSL(tinted).h;
      final rimHue = CoreColorConversion.colorToHSL(
        resolved.surfaceHighlight,
      ).h;

      expect(
        // Not exact: the lift round-trips through 8-bit channels, which
        // moves the hue by about a degree. The borrowed-grey failure
        // this rules out lands ~50 degrees away.
        (rimHue - surfaceHue).abs(),
        lessThanOrEqualTo(2),
        reason:
            'the rim sits at hue $rimHue on a surface at $surfaceHue, '
            'so it was not derived from that surface',
      );
    });
  });

  group('the derivation reaches the path a painted colour takes', () {
    test('resolving the token on a silent palette yields a real colour', () {
      // `resolved()` is not the path a widget uses — `resolve(token)` is.
      // A derivation that lived only in the former would pass every unit
      // test above and still paint nothing.
      const surface = CoreColor.fromARGB(255, 28, 29, 32);
      final resolved = _silentPalette(
        surface,
      ).resolve(const CoreColor.token(CoreColors.surfaceHighlight));

      expect(resolved.isResolved, isTrue);
      expect(_lightness(resolved), greaterThan(_lightness(surface)));
    });
  });

  group('a palette that does state one keeps it', () {
    test('the stated value wins over the derivation', () {
      const stated = CoreColor.fromARGB(255, 255, 240, 200);
      final resolved = CoreColorScheme(
        primary: _root,
        secondary: _root,
        error: _root,
        success: _root,
        warning: _root,
        info: _root,
        surface: const CoreColor.fromARGB(255, 28, 29, 32),
        surfaceHighlight: stated,
      ).resolved(CoreBrightness.dark);

      expect(resolved.surfaceHighlight.argb, stated.argb);
    });

    group('the shipped palettes state their own', () {
      // Shipped values are designed, not incidental — the derivation is
      // the safety net for palettes this package did not author. What a
      // designed rim has to do is read on the tones it actually sits on.

      /// The tinted container tones a raised surface is filled with in
      /// light mode. `surfaceContainerLowest` and `surfaceBright` are not
      /// here: in light they are white, like `surface`, and so like
      /// `surface` they are covered by the accepted case below.
      Map<String, CoreColor> lightContainers(ResolvedColorScheme s) => {
        'surfaceDim': s.surfaceDim,
        'surfaceContainerLow': s.surfaceContainerLow,
        'surfaceContainer': s.surfaceContainer,
        'surfaceContainerHigh': s.surfaceContainerHigh,
        'surfaceContainerHighest': s.surfaceContainerHighest,
      };

      final light = {
        'light': CoreThemePresets.lightColorScheme.resolved(
          CoreBrightness.light,
        ),
        'high-contrast light': CoreThemePresets.highContrastLightColorScheme
            .resolved(CoreBrightness.light),
      };
      final dark = {
        'dark': CoreThemePresets.darkColorScheme.resolved(CoreBrightness.dark),
        'high-contrast dark': CoreThemePresets.highContrastDarkColorScheme
            .resolved(CoreBrightness.dark),
      };

      test('light: brighter than every tinted container tone', () {
        for (final MapEntry(key: mode, value: s) in light.entries) {
          for (final MapEntry(key: name, value: tone) in lightContainers(
            s,
          ).entries) {
            expect(
              _lightness(s.surfaceHighlight),
              greaterThan(_lightness(tone)),
              reason: 'in $mode the rim does not read on $name',
            );
          }
        }
      });

      test('light: on white it is white — accepted, not a regression', () {
        // Designer decision 19 of #5319 (2026-10-08): in light and
        // high-contrast light the highlight and `surface` are both white,
        // so the rim cannot show on a white page, and that is accepted —
        // the rim only has to read on the container tones above. What
        // must still hold is that it is never *darker* than the white
        // tones: a rim below its surface would read as a groove.
        for (final MapEntry(key: mode, value: s) in light.entries) {
          for (final MapEntry(key: name, value: tone) in {
            'surface': s.surface,
            'surfaceBright': s.surfaceBright,
            'surfaceContainerLowest': s.surfaceContainerLowest,
          }.entries) {
            expect(
              _lightness(s.surfaceHighlight),
              greaterThanOrEqualTo(_lightness(tone)),
              reason: 'in $mode the rim is darker than $name',
            );
          }
        }
      });

      test('dark: brighter than surface and every container tone', () {
        for (final MapEntry(key: mode, value: s) in dark.entries) {
          for (final MapEntry(key: name, value: tone) in {
            'surface': s.surface,
            'surfaceBright': s.surfaceBright,
            'surfaceContainerLowest': s.surfaceContainerLowest,
            'surfaceContainerLow': s.surfaceContainerLow,
            'surfaceContainer': s.surfaceContainer,
            'surfaceContainerHigh': s.surfaceContainerHigh,
            'surfaceContainerHighest': s.surfaceContainerHighest,
          }.entries) {
            expect(
              _lightness(s.surfaceHighlight),
              greaterThan(_lightness(tone)),
              reason: 'in $mode the rim does not read on $name',
            );
          }
        }
      });
    });
  });
}
