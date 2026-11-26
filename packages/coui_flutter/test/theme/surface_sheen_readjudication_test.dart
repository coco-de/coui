import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG relative-luminance contrast between two opaque colours.
///
/// Both arguments must already be composited — the formula has no notion
/// of alpha, so handing it a translucent colour silently measures the
/// colour it would be at full strength.
double _contrastRatio(Color a, Color b) {
  final first = a.computeLuminance();
  final second = b.computeLuminance();
  final lighter = first > second ? first : second;
  final darker = first > second ? second : first;

  return (lighter + 0.05) / (darker + 0.05);
}

/// WCAG 1.4.11 non-text minimum — the floor component boundaries are
/// held to elsewhere in this kit.
const double _nonTextMinimum = 3;

/// A run that cannot be told from the surface it lies on is half the
/// treatment.
const double _runVisibilityMinimum = 1.05;

/// The fills a surface in this kit actually chooses.
///
/// Not a component list: components are free to move between these, and
/// a new one that picks any of them is covered without editing anything.
/// What is enumerated is the palette's surface family — which is closed
/// in a way the component set is not.
const Map<String, CoreColorToken> _surfaceFamily = {
  'surface': CoreColors.surface,
  'surfaceContainerLowest': CoreColors.surfaceContainerLowest,
  'surfaceContainerLow': CoreColors.surfaceContainerLow,
  'surfaceContainer': CoreColors.surfaceContainer,
  'surfaceContainerHigh': CoreColors.surfaceContainerHigh,
};

({Color horizontal, Color vertical, Color ring, Color fill}) _seenOn(
  CoreColorToken fillToken,
  String mode,
) {
  final core = mode == 'dark' ? CoreThemePresets.dark : CoreThemePresets.light;
  final scheme = ThemeData.fromCore(core).colorScheme;
  // The band lives on the functional role. The content layer is a
  // standard material under this style and states no band at all, so
  // reading `.surface` here would be reading a role that has nothing to
  // measure.
  final sheen = CoreSurfaceRecipe.of(
    CoreSurfaceStyleId.liquidGlass,
  ).functionalSurface!.sheen!;
  final fill = scheme.resolve(CoreColor.token(fillToken)).toValue();

  return (
    // The runs are translucent, so what matters is each composited over
    // the fill it lies on — the raw token flatters both.
    horizontal: Color.alphaBlend(
      scheme.resolve(sheen.lightColor).toValue(),
      fill,
    ),
    vertical: Color.alphaBlend(scheme.resolve(sheen.darkColor).toValue(), fill),
    ring: scheme.resolve(CoreFocusOutlineStyle.defaultBorderColor).toValue(),
    fill: fill,
  );
}

void main() {
  // The band's colours were chosen against one fill — `surface` — back
  // when two components wore the material. This epic multiplied the
  // surface count, and a pair that reads on a white page does not
  // automatically read on a tinted container. Two requirements meet
  // here: each run has to separate from the fill it lies on, and neither
  // may come within 3:1 of the focus ring.
  //
  // Measured here rather than asserted from the earlier judgement.
  // Values with CoUI's fixed palette (`CouiColorPresets.source`):
  //
  //                            light                    dark
  //                     runH  runV  ringH ringV   runH  runV  ringH ringV
  //   surface           1.22  1.37  8.54  7.59    1.27  1.49 13.01 11.05
  //   surfaceContLowest 1.22  1.37  8.54  7.59    1.24  1.46 14.07 11.95
  //   surfaceContLow    1.21  1.36  8.20  7.32    1.28  1.50 11.67  9.96
  //   surfaceContainer  1.21  1.35  7.89  7.06    1.28  1.49 10.17  8.77
  //   surfaceContHigh   1.20  1.34  7.51  6.74    1.27  1.45  8.92  7.79
  //
  // The ring is `primary/800` in light and `neutral/100` in dark, so it
  // clears every run by a wide margin in both modes. The tight
  // side is the light horizontal run: it is `outline` at 16%, and it
  // stays between 1.20 and 1.22 on every light fill — above the
  // visibility floor below (1.05) on all of them. The run before it,
  // `surfaceContainerHighest` at 40%, sat at 1.03 on
  // `surfaceContainerHigh`, under that floor.

  group('every run stays visible on every surface fill', () {
    for (final mode in const ['light', 'dark']) {
      for (final entry in _surfaceFamily.entries) {
        test('in $mode, on ${entry.key}', () {
          final seen = _seenOn(entry.value, mode);

          for (final run in [seen.horizontal, seen.vertical]) {
            expect(
              _contrastRatio(run, seen.fill),
              greaterThanOrEqualTo(_runVisibilityMinimum),
              reason: 'a run that cannot be seen is half the treatment',
            );
          }
        });
      }
    }
  });

  group('the vertical run stays the heavier of the two on every fill', () {
    // What makes this a band rather than an outline, and the property
    // that must not flip as surfaces spread across fills: the same run
    // has to lead everywhere, or the band's character changes with
    // whichever component you are looking at.
    for (final mode in const ['light', 'dark']) {
      for (final entry in _surfaceFamily.entries) {
        test('in $mode, on ${entry.key}', () {
          final seen = _seenOn(entry.value, mode);

          expect(
            _contrastRatio(seen.vertical, seen.fill),
            greaterThan(_contrastRatio(seen.horizontal, seen.fill)),
          );
        });
      }
    }
  });

  group('the focus ring stays clear of the band where it can touch it', () {
    // The fills the surfaces this epic wired actually use. Every one of
    // drawer / toast / command / item_picker / draggable_panel /
    // description_card resolves to one of these, which is why the
    // window still holds for them.
    const clearsTheWindow = {
      'surface': CoreColors.surface,
      'surfaceContainerLowest': CoreColors.surfaceContainerLowest,
      'surfaceContainerLow': CoreColors.surfaceContainerLow,
      // With `primary` as the ring these two clear the window as widely as
      // the others (6.74 is the narrowest in light), so they belong here.
      'surfaceContainer': CoreColors.surfaceContainer,
      'surfaceContainerHigh': CoreColors.surfaceContainerHigh,
    };

    for (final mode in const ['light', 'dark']) {
      for (final entry in clearsTheWindow.entries) {
        test('in $mode, on ${entry.key}', () {
          final seen = _seenOn(entry.value, mode);

          for (final run in [seen.horizontal, seen.vertical]) {
            expect(
              _contrastRatio(seen.ring, run),
              greaterThanOrEqualTo(_nonTextMinimum),
              reason: 'the ring must not read as part of the band',
            );
          }
        });
      }
    }
  });

  group('and the surfaces this epic wired really do use those fills', () {
    // The group above says "the fills the wired surfaces use" and then
    // lists fills. That sentence is a claim about components, and a
    // claim about components goes stale the moment one changes its
    // default. So it is checked rather than asserted in a comment.
    // Role-tagged, and every role is judged: under the shipped glass both
    // roles wear the band, so a content-layer surface is held to the same
    // ring clearance as a floating one. The role is read off the recipe
    // rather than assumed, so a preset that took the band off one role
    // would fail here as "no band to judge" instead of passing vacuously.
    const wiredFills = <String, ({CoreSurfaceRole role, CoreColor fill})>{
      'drawer': (
        role: CoreSurfaceRole.functional,
        fill: CoreDrawerStyle.defaultPanelBackgroundColor,
      ),
      'draggable_panel': (
        role: CoreSurfaceRole.functional,
        fill: CoreDraggablePanelStyle.defaultPanelBackgroundColor,
      ),
      'command': (
        role: CoreSurfaceRole.content,
        fill: CoreCommandStyle.defaultBackgroundColor,
      ),
      'item_picker': (
        role: CoreSurfaceRole.content,
        fill: CoreItemPickerStyle.defaultBackgroundColor,
      ),
    };

    for (final mode in const ['light', 'dark']) {
      for (final entry in wiredFills.entries) {
        test('in $mode, ${entry.key} keeps the ring clear of the band', () {
          final core = mode == 'dark'
              ? CoreThemePresets.dark
              : CoreThemePresets.light;
          final scheme = ThemeData.fromCore(core).colorScheme;
          final sheen = CoreSurfaceRecipe.of(
            CoreSurfaceStyleId.liquidGlass,
          ).surfaceFor(entry.value.role)!.sheen;

          expect(
            sheen,
            isNotNull,
            reason:
                '${entry.key} sits in the ${entry.value.role.name} layer, '
                'which states no band — nothing to judge the ring against',
          );

          final fill = scheme.resolve(entry.value.fill).toValue();
          final ring = scheme
              .resolve(CoreFocusOutlineStyle.defaultBorderColor)
              .toValue();

          for (final run in [sheen!.lightColor, sheen.darkColor]) {
            final seen = Color.alphaBlend(
              scheme.resolve(run).toValue(),
              fill,
            );

            expect(
              _contrastRatio(ring, seen),
              greaterThanOrEqualTo(_nonTextMinimum),
              reason:
                  '${entry.key} moved to a fill the band was not judged '
                  'against — re-run the measurement rather than lowering '
                  'this floor',
            );
          }
        });
      }
    }
  });
}
