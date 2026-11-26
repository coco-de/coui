import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

/// The NavigationBar's own state-layer ramp, read back where it lands.
///
/// `CoreNavigationBarStyle.defaultStateLayer` is 3 / 8 / 8 — the subtle
/// tier's hover and focus, and a pressed wash that stops at 8 % so the
/// unselected label keeps 4.5 : 1 over it in dark. These read the
/// resolver's PAINT-READY output (the colours the widget selects among),
/// not the Core constant, so a resolver that stopped reading the field —
/// or kept reading `CoreStateLayer.subtle` — fails here.
///
/// The second group is the other half of the claim: the shared subtle ramp
/// is still 12 % pressed for the component that reads it.
void main() {
  Future<({ResolvedNavigationBar resolved, Color ink})> resolveBar(
    WidgetTester tester, {
    CoreNavigationBarStyle? style,
    ThemeData? theme,
    CoreNavigationSelectionIndicator indicator =
        CoreNavigationSelectionIndicator.fill,
  }) async {
    late ResolvedNavigationBar resolved;
    late Color ink;
    // Tear the previous tree down first: the harness' Overlay keeps its
    // initial entries, so a second pump into the same tree would not run
    // the new builder at all.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      buildTestApp(
        theme: theme,
        Builder(
          builder: (context) {
            resolved = resolveNavigationBar(
              context,
              mode: CoreNavigationBarMode.bar,
              variant: CoreNavigationBarVariant.defaultVariant,
              // The ramp is the `fill` indicator's; the bar's own default
              // (`color`) lays none — read back in its own group below.
              indicator: indicator,
              navigationBarStyle: style,
            );
            // The ink is stated in Core (`defaultStateLayerColor`) and
            // resolved the way the resolver resolves it, through the
            // active scheme.
            ink = Theme.of(context).colorScheme
                .resolve(CoreNavigationBarStyle.defaultStateLayerColor)
                .toValue();
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return (resolved: resolved, ink: ink);
  }

  // The same arithmetic the resolver performs, restated from the colours
  // it hands back so the expectation is not read off the code under test.
  Color wash(Color ink, Color bar, double weight) =>
      Color.alphaBlend(ink.withValues(alpha: weight), bar);

  group('the color indicator lays no hover wash', () {
    // Focus keeps the 8 % wash every indicator lays (#5740): the keyboard
    // pose reads the same under `fill` and `color`.
    testWidgets('hover paints nothing, focus washes 8 %, the foreground '
        'darkens', (
      tester,
    ) async {
      final (:resolved, :ink) = await resolveBar(
        tester,
        theme: ThemeData.fromCore(CoreThemePresets.light),
        indicator: CoreNavigationSelectionIndicator.color,
      );
      final bar = resolved.backgroundColor;
      expect(resolved.hoverBackgroundColor, wash(ink, bar, 0));
      expect(resolved.focusBackgroundColor, wash(ink, bar, 0.08));
      expect(resolved.pressedBackgroundColor, wash(ink, bar, 0.08));
      expect(resolved.hoverForegroundColor, ink);
      expect(resolved.hoverLabelTextStyle.color, ink);
    });
  });

  group('NavigationBar paints its own 3 / 8 / 8 ramp', () {
    for (final (name, theme) in [
      ('light', ThemeData.fromCore(CoreThemePresets.light)),
      ('dark', ThemeData.fromCore(CoreThemePresets.dark)),
    ]) {
      testWidgets('$name — hover 3 %, focus 8 %, pressed 8 %', (tester) async {
        final (:resolved, :ink) = await resolveBar(tester, theme: theme);
        final bar = resolved.backgroundColor;

        expect(resolved.hoverBackgroundColor, wash(ink, bar, 0.03));
        expect(resolved.focusBackgroundColor, wash(ink, bar, 0.08));
        expect(resolved.pressedBackgroundColor, wash(ink, bar, 0.08));
      });

      testWidgets("$name — pressed is NOT the subtle tier's 12 %", (
        tester,
      ) async {
        final (:resolved, :ink) = await resolveBar(tester, theme: theme);

        expect(
          resolved.pressedBackgroundColor,
          isNot(wash(ink, resolved.backgroundColor, 0.12)),
          reason: 'pressed fell back to the shared subtle ramp',
        );
      });

      testWidgets('$name — focus and pressed wash alike, hover is lighter', (
        tester,
      ) async {
        final (:resolved, :ink) = await resolveBar(tester, theme: theme);

        expect(resolved.focusBackgroundColor, resolved.pressedBackgroundColor);
        expect(
          resolved.hoverBackgroundColor,
          isNot(resolved.focusBackgroundColor),
        );
      });
    }

    testWidgets('the instance slot still wins over the default', (
      tester,
    ) async {
      final theme = ThemeData.fromCore(CoreThemePresets.light);
      final (:resolved, :ink) = await resolveBar(
        tester,
        theme: theme,
        style: const CoreNavigationBarStyle(stateLayer: CoreStateLayer.subtle),
      );

      // The field is the live source: handing the subtle ramp back through
      // it restores the 12 % pressed wash, which only holds if the resolver
      // reads `merged.stateLayer` and not a number of its own.
      expect(
        resolved.pressedBackgroundColor,
        wash(ink, resolved.backgroundColor, 0.12),
      );
    });
  });

  group('the shared subtle ramp is still 12 % pressed', () {
    Future<ResolvedChip> resolveChipWith(
      WidgetTester tester, {
      CoreChipStyle? style,
    }) async {
      late ResolvedChip resolved;
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        buildTestApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          Builder(
            builder: (context) {
              resolved = resolveChip(
                context,
                variant: CoreChipVariant.outlined,
                chipColor: CoreChipColor.defaultColor,
                size: CoreChipSize.defaultSize,
                selected: false,
                emphasis: CoreChipEmphasis.defaultEmphasis,
                enabled: true,
                chipStyle: style,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      return resolved;
    }

    testWidgets("Chip's default pressed fill equals an explicit subtle", (
      tester,
    ) async {
      final byDefault = await resolveChipWith(tester);
      final explicitSubtle = await resolveChipWith(
        tester,
        style: const CoreChipStyle(stateLayer: CoreStateLayer.subtle),
      );
      final explicitEight = await resolveChipWith(
        tester,
        style: const CoreChipStyle(
          stateLayer: CoreStateLayer(hover: 0.03, focus: 0.08, pressed: 0.08),
        ),
      );

      expect(
        byDefault.pressedContainerStyle,
        explicitSubtle.pressedContainerStyle,
      );
      // And it is genuinely the 12 % one: an 8 % pressed wash resolves to a
      // different fill, so the equality above is not vacuous.
      expect(
        byDefault.pressedContainerStyle,
        isNot(explicitEight.pressedContainerStyle),
      );
    });
  });
}
