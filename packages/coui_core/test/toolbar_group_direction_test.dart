import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// The axis a toolbar group runs along and the seat a glass control takes
/// on it. Both platforms ask here for the seat and for the button that
/// fills it, so the two cannot disagree.
void main() {
  test('a group is a row unless told otherwise', () {
    expect(CoreToolbarGroupContract.defaultDirection, CoreAxis.horizontal);
  });

  group('the glass seat', () {
    test('is 44 in a row and 48 in a column', () {
      expect(
        CoreToolbarGroupContract.glassActionMinSizeFor(CoreAxis.horizontal),
        CoreToolbarGroupContract.glassActionMinSize,
      );
      expect(
        CoreToolbarGroupContract.glassActionMinSizeFor(CoreAxis.vertical),
        CoreToolbarGroupContract.glassVerticalActionMinSize,
      );
      // Spelled as values too, so the constants and the mapping drifting
      // together still fails.
      expect(CoreToolbarGroupContract.glassActionMinSize, 44);
      expect(CoreToolbarGroupContract.glassVerticalActionMinSize, 48);
    });

    test('a column is as wide as the glass navigation rail', () {
      // The two capsules stand in the same side strip.
      const rail = CoreNavigationBarStyle.glassRailStyle;
      const group = CoreToolbarGroupContract.glassPopupStyle;

      expect(
        group.padding!.left +
            CoreToolbarGroupContract.glassVerticalActionMinSize +
            group.padding!.right,
        rail.padding!.left + rail.iconOnlyItemMinWidth! + rail.padding!.right,
      );
    });
  });

  group('the glass button defaults', () {
    test('fill the seat of the group direction', () {
      for (final direction in CoreAxis.values) {
        final seat = CoreToolbarGroupContract.glassActionMinSizeFor(direction);
        final style = CoreToolbarGroupContract.glassButtonTheme(
          null,
          direction: direction,
        ).style!;

        expect(style.height, seat, reason: '$direction');
        expect(style.minWidth, seat, reason: '$direction');
        expect(style.pressedScale, 1, reason: '$direction');
      }
    });

    test('a row is what the theme answers with no direction stated', () {
      final style = CoreToolbarGroupContract.glassButtonTheme(null).style!;

      expect(style.height, CoreToolbarGroupContract.glassActionMinSize);
      expect(style.minWidth, CoreToolbarGroupContract.glassActionMinSize);
    });

    test('a column draws the glyph the glass rail draws', () {
      // Two capsules in one strip carry one weight of icon.
      expect(
        CoreToolbarGroupContract.glassVerticalIconSize,
        CoreNavigationBarStyle.defaultIconStyle.size,
      );
      expect(CoreToolbarGroupContract.glassVerticalIconSize, 24);

      final style = CoreToolbarGroupContract.glassButtonTheme(
        null,
        direction: CoreAxis.vertical,
      ).style!;
      // Wherever the button carries a glyph: beside a label or alone.
      for (final slot in [
        style.leadingIconStyle,
        style.trailingIconStyle,
        style.iconShapeIconStyle,
      ]) {
        expect(slot?.size, 24);
      }
      // And the size the two resolvers read off it, for both button shapes.
      for (final iconShaped in [true, false]) {
        expect(
          CoreButtonStyle.iconSizeFor(
            size: CoreComponentSize.md,
            iconShaped: iconShaped,
            iconShapeOverride: style.iconShapeIconStyle,
            leadingOverride: style.leadingIconStyle,
            trailingOverride: style.trailingIconStyle,
          ),
          24,
          reason: 'iconShaped: $iconShaped',
        );
      }
    });

    test('a row leaves the button its own glyph', () {
      final style = CoreToolbarGroupContract.glassButtonTheme(null).style!;

      expect(style.leadingIconStyle, isNull);
      expect(style.trailingIconStyle, isNull);
      expect(style.iconShapeIconStyle, isNull);
      expect(
        CoreToolbarGroupContract.glassIconStyleFor(CoreAxis.horizontal),
        isNull,
      );
    });

    test('an authored glyph still wins in a column', () {
      final style = CoreToolbarGroupContract.glassButtonTheme(
        const CoreButtonTheme(
          style: CoreButtonStyle(
            iconShapeIconStyle: CoreIconStyle(size: CoreIconSize.size20),
          ),
        ),
        direction: CoreAxis.vertical,
      ).style!;

      expect(style.iconShapeIconStyle!.size, 20);
      // The slots it did not state keep the column's.
      expect(style.leadingIconStyle!.size, 24);
    });

    test('an authored button size still wins in a column', () {
      final style = CoreToolbarGroupContract.glassButtonTheme(
        const CoreButtonTheme(style: CoreButtonStyle(height: 56)),
        direction: CoreAxis.vertical,
      ).style!;

      expect(style.height, 56);
      expect(
        style.minWidth,
        CoreToolbarGroupContract.glassVerticalActionMinSize,
      );
    });
  });
}
