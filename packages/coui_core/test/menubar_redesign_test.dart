import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// The Menubar redesign's Core defaults — the bar's face, its hairline and
/// corner, the trigger label weights, and the value-type contract
/// (merge · copyWith · == · hashCode) the open-trigger slot keeps.
void main() {
  group('CoreMenubarStyle bar chrome', () {
    test('the bar is the raised face with the quiet hairline', () {
      expect(
        CoreMenubarStyle.defaultBarBackgroundColor,
        const CoreColor.token(CoreColors.surfaceBright),
      );
      expect(
        CoreMenubarStyle.defaultBarBorderColor,
        const CoreColor.token(CoreColors.outlineSubtle),
      );
      final standard =
          CoreMenubarStyle.defaultsByVariant[CoreMenubarVariant.standard]!;
      expect(
        standard.barBackgroundColor,
        CoreMenubarStyle.defaultBarBackgroundColor,
      );
      expect(standard.barBorderColor, CoreMenubarStyle.defaultBarBorderColor);
    });

    test('the bar corner is the control role (8)', () {
      expect(
        CoreMenubarStyle.defaultBarBorderRadius,
        const CoreBorderRadius.all(CoreRadiusRole.control),
      );
      expect(CoreRadiusRole.control, 8);
    });

    test('the bar padding, border width and the trigger corner stay', () {
      expect(
        CoreMenubarStyle.defaultBarPadding,
        const CoreEdgeInsets.all(CoreSpace.space4),
      );
      expect(CoreMenubarStyle.defaultBarBorderWidth, CoreStrokeWidth.stroke1);
      expect(
        CoreMenubarStyle.defaultItemBorderRadius,
        const CoreBorderRadius.all(CoreRadius.radius8),
      );
    });
  });

  group('CoreMenubarStyle trigger label', () {
    test('a resting trigger reads regular, the open one reads medium', () {
      expect(
        CoreMenubarStyle.defaultLabelTextStyle.fontWeight,
        CoreFontWeight.regular,
      );
      expect(
        CoreMenubarStyle.defaultOpenTriggerButtonStyle.labelStyle?.fontWeight,
        CoreFontWeight.medium,
      );
    });

    test('the resting label keeps the label role and the ink', () {
      expect(
        CoreMenubarStyle.defaultLabelTextStyle.token,
        CoreTextStyles.labelLarge,
      );
      expect(
        CoreMenubarStyle.defaultLabelTextStyle.color,
        const CoreColor.token(CoreColors.onSurface),
      );
    });
  });

  group('CoreMenubarStyle.openTriggerButtonStyle', () {
    const open = CoreButtonStyle(
      labelStyle: CoreTextStyle(fontWeight: CoreFontWeight.bold),
    );

    test('is null by default and is not part of an empty style', () {
      expect(const CoreMenubarStyle().openTriggerButtonStyle, isNull);
    });

    test('merge lets the later slot win and keeps the earlier one', () {
      const base = CoreMenubarStyle(openTriggerButtonStyle: open);
      expect(base.merge(const CoreMenubarStyle()).openTriggerButtonStyle, open);
      expect(
        const CoreMenubarStyle().merge(base).openTriggerButtonStyle,
        open,
      );
    });

    test('copyWith, == and hashCode carry the slot', () {
      final copy = const CoreMenubarStyle().copyWith(
        openTriggerButtonStyle: open,
      );
      expect(copy.openTriggerButtonStyle, open);
      expect(copy, const CoreMenubarStyle(openTriggerButtonStyle: open));
      expect(
        copy.hashCode,
        const CoreMenubarStyle(openTriggerButtonStyle: open).hashCode,
      );
      expect(copy, isNot(const CoreMenubarStyle()));
    });
  });

  group('CoreButtonStyle menubar variant', () {
    final row = CoreButtonStyle.defaultsByVariant[CoreButtonVariant.menubar]!;

    test('an open trigger is one step softer than a hovered one', () {
      expect(
        row.selectedBackgroundColor,
        const CoreColor.token(CoreColors.surfaceContainerHigh),
      );
      expect(
        row.hoverBackgroundColor,
        const CoreColor.token(
          CoreColors.surfaceContainerHighest,
          fallbacks: [CoreColors.surfaceContainerHigh],
        ),
      );
    });
  });
}
