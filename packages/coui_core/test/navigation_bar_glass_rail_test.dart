import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// The floating glass capsule — which modes take it, what the rail's is
/// made of, and the defaults a destination inside one answers. Both platform
/// resolvers ask here, so a mode cannot float on one platform and stay
/// docked on the other.
void main() {
  group('CoreNavigationBarStyle.glassStyleFor', () {
    test('the bar and the rail float; the sidebar stays docked', () {
      expect(
        CoreNavigationBarStyle.glassStyleFor(CoreNavigationBarMode.bar),
        same(CoreNavigationBarStyle.glassBarStyle),
      );
      expect(
        CoreNavigationBarStyle.glassStyleFor(CoreNavigationBarMode.rail),
        same(CoreNavigationBarStyle.glassRailStyle),
      );
      expect(
        CoreNavigationBarStyle.glassStyleFor(CoreNavigationBarMode.sidebar),
        isNull,
      );
    });

    test('every mode has an answer', () {
      // The selector is the one place the modes are named; a mode added
      // without a decision here would not compile, and this keeps the
      // decision visible as a list.
      expect(
        {
          for (final mode in CoreNavigationBarMode.values)
            mode: CoreNavigationBarStyle.glassStyleFor(mode) != null,
        },
        {
          CoreNavigationBarMode.bar: true,
          CoreNavigationBarMode.rail: true,
          CoreNavigationBarMode.sidebar: false,
        },
      );
    });
  });

  group('CoreNavigationBarStyle.glassRailStyle', () {
    const rail = CoreNavigationBarStyle.glassRailStyle;
    const bar = CoreNavigationBarStyle.glassBarStyle;

    /// Height of [count] icon-only destinations in the capsule.
    double capsuleHeight(int count) =>
        rail.padding!.top +
        rail.itemMinHeight! * count +
        rail.itemSpacing! * (count - 1) +
        rail.padding!.bottom;

    test('an icon-only destination lands on the 40-wide cell', () {
      // The glyph, the box it keeps around it, and the item's own padding
      // are what make the cell 40 across — the floor only restates it. If
      // one of the three moved alone the content would push past the floor
      // and the capsule would stop being one control wide.
      final glyph = CoreNavigationBarStyle.defaultIconStyle.size!;
      const itemPadding = CoreNavigationBarStyle.defaultItemPadding;
      final anchor = rail.iconAnchorPadding!;
      final content =
          itemPadding.left +
          anchor.left +
          glyph +
          anchor.right +
          itemPadding.right;

      expect(content, 40);
      expect(rail.iconOnlyItemMinWidth, content);
    });

    test('the capsule is 48 across', () {
      expect(
        rail.padding!.left + rail.iconOnlyItemMinWidth! + rail.padding!.right,
        48,
      );
    });

    test('four destinations stand 212 tall', () {
      expect(capsuleHeight(4), 212);
      // And every count is the same sum — one cell and one gap per
      // destination — so the capsule grows by a fixed stride.
      expect(capsuleHeight(5) - capsuleHeight(4), 52);
      expect(capsuleHeight(1), 56);
    });

    test('a destination is tall enough to tap', () {
      // The cell is 40 wide; what accepts a pointer is 48 on both axes.
      // The 4 either side comes out of the capsule's own padding, so two
      // destinations never reach for the same strip.
      expect(
        rail.itemMinHeight,
        greaterThanOrEqualTo(CoreNavigationBarStyle.defaultTouchTargetSize),
      );
      expect(
        rail.iconOnlyItemMinWidth! + rail.padding!.left + rail.padding!.right,
        greaterThanOrEqualTo(CoreNavigationBarStyle.defaultTouchTargetSize),
      );
    });

    test('it is detached and round, as the glass bar is', () {
      expect(rail.barRadius, bar.barRadius);
      expect(rail.barMargin, bar.barMargin);
      expect(rail.itemRadius, bar.itemRadius);
      // The focus ring starts from the item's corner.
      expect(rail.clickableStyle!.borderRadius, rail.itemRadius);
    });

    test('it marks the selection the way the glass bar does', () {
      // One lens, one colour: a rail that switched to the bar's row (or
      // back) keeps the selected face and its foreground.
      expect(rail.selectedBackgroundColor, bar.selectedBackgroundColor);
      expect(rail.selectedLabelTextStyle, bar.selectedLabelTextStyle);
      expect(rail.selectionMarkStyle, bar.selectionMarkStyle);
    });
  });

  group('a destination names itself in a tooltip', () {
    test('above it in a row, beside it in a column', () {
      // The decision as a list: a mode added without one would not be here.
      expect(
        {
          for (final mode in CoreNavigationBarMode.values)
            mode: mode.tooltipPosition,
        },
        {
          CoreNavigationBarMode.bar: CoreTooltipPosition.top,
          CoreNavigationBarMode.rail: CoreTooltipPosition.right,
          // The announced mode is a column too.
          CoreNavigationBarMode.sidebar: CoreTooltipPosition.right,
        },
      );
    });

    test('the side follows the axis the destinations run along', () {
      for (final mode in CoreNavigationBarMode.values) {
        expect(
          mode.tooltipPosition == CoreTooltipPosition.top,
          !mode.isVertical,
          reason: '$mode',
        );
      }
    });
  });

  group('a destination in the capsule answers the glass defaults', () {
    test('the glass rail hides its captions; the glass bar keeps them', () {
      expect(
        CoreNavigationBarMode.rail.defaultLabelModeFor(floatingGlass: true),
        CoreNavigationLabelMode.defaultGlassRailMode,
      );
      expect(
        CoreNavigationLabelMode.defaultGlassRailMode,
        CoreNavigationLabelMode.none,
      );
      expect(
        CoreNavigationBarMode.bar.defaultLabelModeFor(floatingGlass: true),
        CoreNavigationBarMode.bar.defaultLabelMode,
      );
    });

    test('outside the capsule every mode keeps its own label default', () {
      for (final mode in CoreNavigationBarMode.values) {
        expect(
          mode.defaultLabelModeFor(floatingGlass: false),
          mode.defaultLabelMode,
          reason: '$mode',
        );
      }
    });

    test('the capsule marks with colour alone in every mode', () {
      for (final mode in CoreNavigationBarMode.values) {
        expect(
          mode.defaultIndicatorFor(floatingGlass: true),
          CoreNavigationSelectionIndicator.defaultGlassIndicator,
          reason: '$mode',
        );
        expect(
          mode.defaultIndicatorFor(floatingGlass: false),
          mode.defaultIndicator,
          reason: '$mode',
        );
      }
      expect(
        CoreNavigationSelectionIndicator.defaultGlassIndicator,
        CoreNavigationSelectionIndicator.color,
      );
    });
  });
}
