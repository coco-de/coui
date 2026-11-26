import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

/// What a panel's text actually sits on: its own fill composited over the
/// backdrop the material has already saturated and dimmed.
///
/// Mirrors the two platforms rather than approximating them. Flutter builds
/// `diag(b,b,b,1)` onto the Rec.709 saturation matrix and Web emits
/// `saturate(s) brightness(b)` into one filter list — same weights, same
/// order, slope only, alpha untouched. The blur is not modelled because a
/// Gaussian of a uniform patch is that patch: every backdrop here stands for
/// what a blur averaged to locally, which is exactly the quantity a contrast
/// figure is about.
Color _composite(Color fill, double alpha, Color backdrop, double brightness) {
  const lumR = 0.213;
  const lumG = 0.715;
  const lumB = 0.072;
  final saturation = CoreSurfaceRecipe.of(
    CoreSurfaceStyleId.liquidGlass,
  ).surfaceFor(CoreSurfaceRole.functional)!.saturation;

  final invR = lumR * (1 - saturation);
  final invG = lumG * (1 - saturation);
  final invB = lumB * (1 - saturation);

  double channel(double r, double g, double b) =>
      (r + g + b).clamp(0.0, 1.0) * brightness;

  final r = channel(
    (invR + saturation) * backdrop.r,
    invG * backdrop.g,
    invB * backdrop.b,
  ).clamp(0.0, 1.0);
  final g = channel(
    invR * backdrop.r,
    (invG + saturation) * backdrop.g,
    invB * backdrop.b,
  ).clamp(0.0, 1.0);
  final b = channel(
    invR * backdrop.r,
    invG * backdrop.g,
    (invB + saturation) * backdrop.b,
  ).clamp(0.0, 1.0);

  return Color.from(
    alpha: 1,
    red: fill.r * alpha + r * (1 - alpha),
    green: fill.g * alpha + g * (1 - alpha),
    blue: fill.b * alpha + b * (1 - alpha),
  );
}

double _contrast(Color a, Color b) {
  final first = a.computeLuminance();
  final second = b.computeLuminance();
  final lighter = first > second ? first : second;
  final darker = first > second ? second : first;

  return (lighter + 0.05) / (darker + 0.05);
}

Color _token(ThemeData theme, CoreColorToken token) =>
    theme.colorScheme.resolve(CoreColor.token(token)).toValue();

void main() {
  // The floating material's fill. Held here so the arithmetic below cannot
  // drift from the recipe if the fill is ever retuned.
  final floating = CoreSurfaceRecipe.of(
    CoreSurfaceStyleId.liquidGlass,
  ).surfaceFor(CoreSurfaceRole.functional)!;

  const aa = 4.5;

  group('the dimming does not cost the text more than it is worth', () {
    // Every combination in this group was swept before the values were
    // picked; these are the cells at the edges of that sweep. They are
    // pinned as *numbers a palette change could move*, not as a
    // restatement of the recipe — the recipe can be retuned, and then
    // these have to be re-derived deliberately rather than re-recorded.

    test('the inverted-polarity floor holds in dark', () {
      // The one cell the dimming makes worse on a backdrop its mode
      // actually sees. A tooltip inverts the polarity — it fills with
      // `onSurface` and writes in `surface` — so dimming the backdrop
      // moves its text the wrong way.
      //
      // Measured over a near-black page under the current palette: 4.37
      // with the fill at 0.5, which is under AA, and 5.99 with the dark
      // fill at 0.6. That is why the fill is a per-mode pair and not one
      // number: the floor below does not move, the fill does. A palette
      // tweak of a couple of levels moves this cell, and nothing else in
      // the suite would notice — which is why this is a test and not a
      // comment.
      final theme = applySurfaceStyle(
        ThemeData.fromCore(CoreThemePresets.dark),
        surfaceStyle: CoreSurfaceStyleId.liquidGlass,
        highContrast: false,
      );
      const nearBlack = Color(0xFF0A0A0A);

      final panel = _composite(
        _token(theme, CoreColors.onSurface),
        floating.opacity.resolve(CoreBrightness.dark),
        nearBlack,
        floating.backdropBrightness.resolve(CoreBrightness.dark),
      );

      expect(
        _contrast(_token(theme, CoreColors.surface), panel),
        greaterThanOrEqualTo(aa),
        reason:
            'a tooltip in dark over a near-black page is the cell this '
            'value costs; it may be worse than it was, but it may not drop '
            'below AA',
      );
    });

    test('and dark normal polarity is repaired rather than dented', () {
      // The other side of the same trade, and the reason it is worth
      // paying: a dark floating panel over a bright backdrop was giving
      // its body text 3.28, below AA, before this value existed.
      final theme = applySurfaceStyle(
        ThemeData.fromCore(CoreThemePresets.dark),
        surfaceStyle: CoreSurfaceStyleId.liquidGlass,
        highContrast: false,
      );
      const white = Color(0xFFFFFFFF);

      final fill = _token(theme, CoreColors.surface);
      final text = _token(theme, CoreColors.onSurface);
      final before = _contrast(
        text,
        _composite(
          fill,
          floating.opacity.resolve(CoreBrightness.dark),
          white,
          CoreBackdropBrightness.identityValue,
        ),
      );
      final after = _contrast(
        text,
        _composite(
          fill,
          floating.opacity.resolve(CoreBrightness.dark),
          white,
          floating.backdropBrightness.resolve(CoreBrightness.dark),
        ),
      );

      expect(before, lessThan(aa));
      expect(after, greaterThanOrEqualTo(aa));
      expect(after, greaterThan(before));
    });

    test('light pays nothing on any backdrop that mode sits over', () {
      // Dimming in light mode moves dark text the wrong way, so the value
      // there is small. What that costs is bounded by checking it over the
      // backdrops a light-mode panel plausibly covers — a light page, a
      // mid grey, a brand fill, a warm photo — rather than over a
      // near-black one, which is where the cost concentrates and which a
      // light-mode panel does not sit on.
      final theme = applySurfaceStyle(
        ThemeData.fromCore(CoreThemePresets.light),
        surfaceStyle: CoreSurfaceStyleId.liquidGlass,
        highContrast: false,
      );
      const plausible = [
        Color(0xFFFFFFFF),
        Color(0xFFFCFCFD),
        Color(0xFF97989B),
        Color(0xFF3B6FD5),
        Color(0xFFEE7C2B),
      ];

      final fill = _token(theme, CoreColors.surface);
      final text = _token(theme, CoreColors.onSurface);
      final dim = floating.backdropBrightness.resolve(CoreBrightness.light);
      final share = floating.opacity.resolve(CoreBrightness.light);

      for (final backdrop in plausible) {
        expect(
          _contrast(text, _composite(fill, share, backdrop, dim)),
          greaterThanOrEqualTo(aa),
          reason: '$backdrop is a backdrop a light floating panel covers',
        );
      }
    });

    test('the content material dims by the same pair', () {
      // The content role is what cards, commands, description-cards and
      // item-pickers draw, and it is the majority of the wired set. It is
      // the same glass as the floating role by decision, so it dims by
      // the same measured pair — a card that stayed at identity beside a
      // dimmed popover would be the two-material look this reversed.
      for (final preset in [CoreThemePresets.light, CoreThemePresets.dark]) {
        final theme = applySurfaceStyle(
          ThemeData.fromCore(preset),
          surfaceStyle: CoreSurfaceStyleId.liquidGlass,
          highContrast: false,
        );
        final content = theme
            .surfaceFor(CoreSurfaceRole.content)!
            .backdropBrightnessIn(theme);

        expect(content, isNot(CoreBackdropBrightness.identityValue));
        expect(
          content,
          theme
              .surfaceFor(CoreSurfaceRole.functional)!
              .backdropBrightnessIn(theme),
        );
      }
    });
  });

  test('the model reproduces a number someone measured on a screen', () {
    // The arithmetic above is only worth as much as its agreement with a
    // rendered pixel. The recipe records one: the control pair the term was
    // first measured with — 0.65 fill, 0.25 brightness — puts a white panel
    // over a white page "near a 74% grey". If this model cannot land that,
    // none of the figures above mean anything either.
    const white = Color(0xFFFFFFFF);
    final grey = _composite(white, 0.65, white, 0.25);

    expect(grey.r, closeTo(0.73, 0.02));
    expect(ui.clampDouble(grey.g, 0, 1), closeTo(0.73, 0.02));
  });
}
