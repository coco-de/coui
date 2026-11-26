import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// The selected destination's face and the icon-only destination's size are
/// design decisions both platforms and the canvas read from one table
/// (#5740). These pin the table itself; the platform tests read what each
/// widget paints from it.
void main() {
  final fill = CoreNavigationBarStyle
      .defaultsByIndicator[CoreNavigationSelectionIndicator.fill]!;
  final color = CoreNavigationBarStyle
      .defaultsByIndicator[CoreNavigationSelectionIndicator.color]!;

  group('both indicators mark the selection with primary at bold', () {
    test('fill paints the tile, dimmed to disabledContainer (#6358)', () {
      expect(
        fill.selectedBackgroundColor,
        CoreNavigationBarStyle.defaultSelectedFaceColor,
      );
      expect(
        fill.disabledSelectedBackgroundColor,
        CoreNavigationBarStyle.defaultDisabledSelectedFaceColor,
      );
      expect(
        CoreNavigationBarStyle.defaultSelectedFaceColor,
        const CoreColor.token(CoreColors.surfaceContainerHigh),
      );
      expect(
        CoreNavigationBarStyle.defaultDisabledSelectedFaceColor,
        const CoreColor.token(CoreColors.disabledContainer),
      );
    });

    test('color paints no face, selected or selected and disabled (#6393)', () {
      expect(color.selectedBackgroundColor, CoreColor.transparent);
      expect(color.disabledSelectedBackgroundColor, CoreColor.transparent);
    });

    test('the label and glyph are primary, stacked or a row', () {
      for (final cell in [fill, color]) {
        expect(
          cell.selectedLabelTextStyle?.color,
          const CoreColor.token(CoreColors.primary),
        );
        expect(
          cell.selectedIconStyle?.color,
          const CoreColor.token(CoreColors.primary),
        );
        expect(cell.selectedRowLabelTextStyle, isNull);
      }
    });

    test('the selected label is bold, the resting one medium', () {
      expect(
        CoreNavigationBarStyle.defaultSelectedLabelTextStyle.fontWeight,
        CoreFontWeight.bold,
      );
      expect(
        CoreNavigationBarStyle.defaultDisabledSelectedLabelTextStyle.fontWeight,
        CoreFontWeight.bold,
      );
      for (final cell in [fill, color]) {
        expect(cell.selectedLabelTextStyle?.fontWeight, isNull);
      }
    });

    test('no mode states a selected face of its own', () {
      for (final cell in CoreNavigationBarStyle.defaultsByMode.values) {
        expect(cell.selectedBackgroundColor, isNull);
      }
    });

    test('the lines are outlineSubtle', () {
      expect(
        CoreNavigationBarStyle.defaultBarBorderColor,
        const CoreColor.token(CoreColors.outlineSubtle),
      );
      expect(
        CoreNavigationBarStyle.defaultDividerColor,
        const CoreColor.token(CoreColors.outlineSubtle),
      );
    });

    test("hover stays the indicator's own", () {
      expect(fill.hoverForegroundColor, isNull);
      expect(
        color.hoverForegroundColor,
        const CoreColor.token(CoreColors.onSurface),
      );
      expect(color.stateLayer?.hover, CoreOpacity.opacity0);
      expect(fill.stateLayer, isNull);
    });
  });

  test('the bottom bar names every destination by default', () {
    expect(
      CoreNavigationBarMode.bar.defaultLabelMode,
      CoreNavigationLabelMode.all,
    );
  });

  group('focus lays the same wash under every indicator', () {
    for (final indicator in CoreNavigationSelectionIndicator.values) {
      test(indicator.name, () {
        final layer =
            CoreNavigationBarStyle.defaultsByIndicator[indicator]!.stateLayer ??
            CoreNavigationBarStyle.defaultStateLayer;
        expect(layer.focus, CoreOpacity.focus);
        expect(layer.focus, 0.08);
      });
    }
  });

  group('an icon-only destination paints 64 × 40 and accepts 48', () {
    test('defaults', () {
      expect(CoreNavigationBarStyle.defaultIconOnlyItemMinHeight, 40);
      expect(CoreNavigationBarStyle.defaultIconOnlyItemMinWidth, 64);
      expect(
        CoreNavigationBarStyle.defaultTouchTargetSize,
        CoreA11ySize.touchTarget,
      );
      expect(CoreNavigationBarStyle.defaultTouchTargetSize, 48);
    });

    test('the fields merge, copy and compare', () {
      const a = CoreNavigationBarStyle(
        iconOnlyItemMinHeight: 44,
        iconOnlyItemMinWidth: 72,
        touchTargetSize: 56,
      );
      final merged = const CoreNavigationBarStyle().merge(a);
      expect(merged, a);
      expect(merged.hashCode, a.hashCode);
      expect(
        a.copyWith(touchTargetSize: 60),
        isNot(a),
      );
      expect(a.copyWith().touchTargetSize, 56);
    });
  });
}
