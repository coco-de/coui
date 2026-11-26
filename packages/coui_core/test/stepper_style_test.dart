// Tests for CoreStepperStyle / CoreStepperTheme.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const double _kFontLabel = 14;
const _kColorPrimary = CoreColor.token(CoreColors.primary);
const _kColorOnSurface = CoreColor.token(CoreColors.onSurface);
const _kColorOnSurfaceVariant = CoreColor.token(CoreColors.onSurfaceVariant);

void main() {
  group('CoreStepperStyle', () {
    test('chain — design system → theme.style → widget', () {
      const designSystem = CoreStepperStyle(
        indicatorActiveColor: _kColorPrimary,
        indicatorSize: 24,
        connectorActiveColor: _kColorPrimary,
        connectorThickness: 2,
        labelStyle: CoreTextStyle(
          fontSize: _kFontLabel,
          color: _kColorOnSurface,
        ),
      );
      const widgetStyle = CoreStepperStyle(connectorThickness: 4);
      final effective = designSystem.merge(widgetStyle);
      expect(effective.indicatorActiveColor, _kColorPrimary);
      expect(effective.indicatorSize, 24);
      expect(effective.connectorThickness, 4);
      expect(effective.labelStyle?.fontSize, _kFontLabel);
    });

    test('descriptionStyle / indicatorIconStyle merge', () {
      const a = CoreStepperStyle(
        descriptionStyle: CoreTextStyle(color: _kColorOnSurface),
        indicatorIconStyle: CoreIconStyle(size: 16),
      );
      const b = CoreStepperStyle(
        descriptionStyle: CoreTextStyle(fontSize: _kFontLabel),
      );
      final merged = a.merge(b);
      expect(merged.descriptionStyle?.color, _kColorOnSurface);
      expect(merged.descriptionStyle?.fontSize, _kFontLabel);
      expect(merged.indicatorIconStyle?.size, 16);
    });

    test('indicatorContentGapStyle / labelGapStyle merge', () {
      const a = CoreStepperStyle(
        indicatorContentGapStyle: CoreGapStyle(size: 8),
        labelGapStyle: CoreGapStyle(size: 4),
      );
      const b = CoreStepperStyle(
        indicatorContentGapStyle: CoreGapStyle(color: _kColorPrimary),
        labelGapStyle: CoreGapStyle(size: 6),
      );
      final merged = a.merge(b);
      expect(merged.indicatorContentGapStyle?.size, 8);
      expect(merged.indicatorContentGapStyle?.color, _kColorPrimary);
      expect(merged.labelGapStyle?.size, 6);
    });

    test('equality + copyWith preserves nested', () {
      const a = CoreStepperStyle(
        indicatorActiveColor: _kColorPrimary,
        labelStyle: CoreTextStyle(fontSize: _kFontLabel),
      );
      final copy = a.copyWith(connectorThickness: 2);
      expect(copy.connectorThickness, 2);
      expect(copy.labelStyle?.fontSize, _kFontLabel);
      expect(copy.indicatorActiveColor, _kColorPrimary);
    });
  });

  // The vertical label role is bold, so the other steps carry their own
  // semi-bold; the current step's semi-bold overlay applies in either
  // orientation, and the horizontal role (500) states no weight.
  group('CoreStepperStyle label weights', () {
    test('vertical: every other step is semi-bold on titleSmall', () {
      final label = CoreStepperStyle.defaultLabelVerticalStyle;
      expect(label.token, CoreTextStyles.titleSmall);
      expect(label.fontWeight, CoreFontWeight.semiBold);
    });

    test('horizontal: every other step takes the labelLarge role', () {
      const label = CoreStepperStyle.defaultLabelHorizontalStyle;
      expect(label.token, CoreTextStyles.labelLarge);
      expect(label.fontWeight, isNull);
    });

    test('labelActiveStyle merges, copies and compares', () {
      const a = CoreStepperStyle(
        labelActiveStyle: CoreTextStyle(fontWeight: CoreFontWeight.bold),
      );
      const b = CoreStepperStyle(
        labelActiveStyle: CoreTextStyle(fontWeight: CoreFontWeight.black),
      );
      expect(a.merge(b).labelActiveStyle?.fontWeight, CoreFontWeight.black);
      expect(
        const CoreStepperStyle().copyWith(labelActiveStyle: b.labelActiveStyle),
        equals(b),
      );
      expect(a, isNot(equals(b)));
      expect(a.hashCode, isNot(b.hashCode));
    });

    test('the current step is semi-bold in both orientations', () {
      for (final label in [
        CoreStepperStyle.defaultLabelVerticalStyle,
        CoreStepperStyle.defaultLabelHorizontalStyle,
      ]) {
        final current = label.merge(CoreStepperStyle.defaultLabelActiveStyle);
        expect(current.token, label.token);
        expect(current.fontWeight, CoreFontWeight.semiBold);
      }
    });

    test(
      'an upcoming step reads in onSurfaceVariant, in both orientations',
      () {
        for (final label in [
          CoreStepperStyle.defaultLabelVerticalStyle,
          CoreStepperStyle.defaultLabelHorizontalStyle,
        ]) {
          final upcoming = label.merge(
            CoreStepperStyle.defaultLabelUpcomingStyle,
          );
          expect(upcoming.token, label.token);
          expect(upcoming.color, _kColorOnSurfaceVariant);
          expect(label.color, _kColorOnSurface);
        }
      },
    );
  });

  group('CoreStepperStyle redesign defaults', () {
    test('a completed step is primary, the current one a surface in a primary '
        'ring, an upcoming one a surface in a quieter ring', () {
      const surface = CoreColor.token(CoreColors.surface);
      expect(CoreStepperStyle.defaultIndicatorActiveColor, _kColorPrimary);
      expect(
        CoreStepperStyle.defaultIndicatorIconColor,
        const CoreColor.token(CoreColors.onPrimary),
      );
      expect(CoreStepperStyle.defaultIndicatorCurrentColor, surface);
      expect(
        CoreStepperStyle.defaultIndicatorCurrentBorderColor,
        _kColorPrimary,
      );
      expect(CoreStepperStyle.defaultIndicatorInactiveColor, surface);
      expect(
        CoreStepperStyle.defaultIndicatorInactiveBorderColor,
        const CoreColor.token(CoreColors.outlineVariant),
      );
      expect(
        CoreStepperStyle.defaultIndicatorBorderWidth,
        CoreStrokeWidth.stroke1,
      );
    });

    test('the completed line is primary, the upcoming one outlineVariant', () {
      expect(CoreStepperStyle.defaultConnectorActiveColor, _kColorPrimary);
      expect(
        CoreStepperStyle.defaultConnectorInactiveColor,
        const CoreColor.token(CoreColors.outlineVariant),
      );
    });

    test('the step numbers are labelMedium semi-bold', () {
      final active = CoreStepperStyle.defaultIndicatorNumberActiveStyle;
      final inactive = CoreStepperStyle.defaultIndicatorNumberInactiveStyle;
      for (final number in [active, inactive]) {
        expect(number.token, CoreTextStyles.labelMedium);
        expect(number.fontWeight, CoreFontWeight.semiBold);
      }
      // The current number sits on the surface, inside the ring.
      expect(active.color, _kColorOnSurface);
      expect(inactive.color, _kColorOnSurfaceVariant);
    });

    test('a connector meets its circle and the next one — no margin in '
        'either layout', () {
      expect(CoreStepperStyle.defaultConnectorMargin, CoreSpace.space0);
      expect(CoreStepperStyle.defaultConnectorMarginVertical, CoreSpace.space0);
      expect(
        CoreStepperStyle.defaultDescriptionGapStyle.size,
        CoreSpace.space2,
      );
    });

    test('a disabled stepper reads from the disabled tokens', () {
      expect(
        CoreStepperStyle.defaultIndicatorDisabledColor,
        const CoreColor.token(CoreColors.disabledContainer),
      );
      expect(
        CoreStepperStyle.defaultIndicatorDisabledBorderColor,
        const CoreColor.token(CoreColors.disabledOutline),
      );
      expect(
        CoreStepperStyle.defaultConnectorDisabledColor,
        const CoreColor.token(CoreColors.disabledOutline),
      );
      expect(
        CoreStepperStyle.defaultDisabledForegroundColor,
        const CoreColor.token(CoreColors.disabledContent),
      );
    });

    test('the new fields merge, copy and compare', () {
      const a = CoreStepperStyle(
        indicatorCurrentColor: _kColorPrimary,
        indicatorCurrentBorderColor: _kColorPrimary,
        indicatorInactiveBorderColor: _kColorPrimary,
        indicatorDisabledColor: _kColorPrimary,
        indicatorDisabledBorderColor: _kColorPrimary,
        connectorDisabledColor: _kColorPrimary,
        disabledForegroundColor: _kColorPrimary,
        connectorMarginVertical: 6,
        descriptionGapStyle: CoreGapStyle(size: 3),
        labelUpcomingStyle: CoreTextStyle(color: _kColorPrimary),
      );
      const b = CoreStepperStyle(
        disabledForegroundColor: _kColorOnSurface,
        connectorMarginVertical: 10,
        descriptionGapStyle: CoreGapStyle(color: _kColorPrimary),
      );
      final merged = a.merge(b);
      expect(merged.disabledForegroundColor, _kColorOnSurface);
      expect(merged.connectorMarginVertical, 10);
      expect(merged.descriptionGapStyle?.size, 3);
      expect(merged.descriptionGapStyle?.color, _kColorPrimary);
      expect(merged.indicatorCurrentColor, _kColorPrimary);
      expect(merged.indicatorCurrentBorderColor, _kColorPrimary);
      expect(merged.indicatorInactiveBorderColor, _kColorPrimary);
      expect(merged.indicatorDisabledColor, _kColorPrimary);
      expect(merged.indicatorDisabledBorderColor, _kColorPrimary);
      expect(merged.connectorDisabledColor, _kColorPrimary);
      expect(merged.labelUpcomingStyle?.color, _kColorPrimary);
      expect(
        a.copyWith(connectorMarginVertical: 10).connectorMarginVertical,
        10,
      );
      expect(a, isNot(equals(a.copyWith(connectorMarginVertical: 10))));
      expect(
        a,
        isNot(equals(a.copyWith(disabledForegroundColor: _kColorOnSurface))),
      );
      expect(
        a.hashCode,
        isNot(a.copyWith(labelUpcomingStyle: const CoreTextStyle()).hashCode),
      );
      // The current step's own fields are part of what makes two styles equal —
      // a style that restates only them must still rebuild its children.
      for (final changed in [
        a.copyWith(indicatorCurrentColor: _kColorOnSurface),
        a.copyWith(indicatorCurrentBorderColor: _kColorOnSurface),
      ]) {
        expect(a, isNot(equals(changed)));
        expect(a.hashCode, isNot(changed.hashCode));
      }
      expect(
        a
            .copyWith(indicatorCurrentBorderColor: _kColorOnSurface)
            .indicatorCurrentBorderColor,
        _kColorOnSurface,
      );
    });
  });

  group('CoreStepperTheme', () {
    test('passes through style', () {
      const style = CoreStepperStyle(
        indicatorActiveColor: _kColorPrimary,
      );
      const theme = CoreStepperTheme(style: style);
      expect(theme.style, style);
    });
  });
}
