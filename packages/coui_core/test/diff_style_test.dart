// Tests for CoreDiffStyle.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kColorTokenOutline = CoreColor.token(CoreColors.outline);

void main() {
  group('CoreDiffStyle', () {
    test('chain — design system → theme.style → widget', () {
      const designSystem = CoreDiffStyle(
        borderRadius: CoreBorderRadius.all(16),
        resizerColor: _kColorTokenOutline,
        resizerWidth: 2,
      );
      const themeStyle = CoreDiffStyle(resizerWidth: 3);
      const widgetStyle = CoreDiffStyle(borderRadius: CoreBorderRadius.all(8));

      final effective = designSystem.merge(themeStyle).merge(widgetStyle);

      expect(effective.borderRadius, const CoreBorderRadius.all(8));
      expect(effective.resizerColor, _kColorTokenOutline);
      expect(effective.resizerWidth, 3);
    });

    test('right-most non-null wins', () {
      const a = CoreDiffStyle(
        borderRadius: CoreBorderRadius.all(16),
        resizerWidth: 2,
      );
      const b = CoreDiffStyle(borderRadius: CoreBorderRadius.all(24));
      final merged = a.merge(b);
      expect(merged.borderRadius, const CoreBorderRadius.all(24));
      expect(merged.resizerWidth, 2);
    });

    test('equality + copyWith', () {
      const a = CoreDiffStyle(
        borderRadius: CoreBorderRadius.all(16),
        resizerColor: _kColorTokenOutline,
      );
      const b = CoreDiffStyle(
        borderRadius: CoreBorderRadius.all(16),
        resizerColor: _kColorTokenOutline,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);

      final copy = a.copyWith(resizerWidth: 4);
      expect(copy.resizerWidth, 4);
      expect(copy.borderRadius, const CoreBorderRadius.all(16));
      expect(copy.resizerColor, _kColorTokenOutline);
    });

    test('keyboardStep — merge / copyWith / equality', () {
      const a = CoreDiffStyle(keyboardStep: 0.05);
      const b = CoreDiffStyle(keyboardStep: 0.1);
      expect(a.merge(b).keyboardStep, 0.1);
      expect(b.merge(const CoreDiffStyle()).keyboardStep, 0.1);
      expect(a.copyWith(keyboardStep: 0.2).keyboardStep, 0.2);
      expect(a, equals(const CoreDiffStyle(keyboardStep: 0.05)));
      expect(a == b, isFalse);
    });

    test('keyboardPageStep — merge / copyWith / equality', () {
      const a = CoreDiffStyle(keyboardPageStep: 0.1);
      const b = CoreDiffStyle(keyboardPageStep: 0.2);
      expect(a.merge(b).keyboardPageStep, 0.2);
      expect(b.merge(const CoreDiffStyle()).keyboardPageStep, 0.2);
      expect(a.copyWith(keyboardPageStep: 0.3).keyboardPageStep, 0.3);
      expect(a, equals(const CoreDiffStyle(keyboardPageStep: 0.1)));
      expect(a == b, isFalse);
    });

    test('a page step is twice an arrow step by default', () {
      expect(
        CoreDiffStyle.defaultKeyboardPageStep,
        CoreDiffStyle.defaultKeyboardStep * 2,
      );
    });
  });

  group('CoreDiffStyle — handle / line / frame / label fields', () {
    test('every new field survives merge, copyWith and equality', () {
      const full = CoreDiffStyle(
        borderColor: CoreColor.token(CoreColors.outline),
        borderWidth: 2,
        resizerShadow: CoreShadow.md,
        handleSize: 48,
        handleHitSize: 56,
        handleColor: CoreColor.token(CoreColors.surface),
        handleBorderColor: CoreColor.token(CoreColors.outline),
        handleBorderWidth: 2,
        handleShadow: CoreShadow.md,
        handleHoverShadow: CoreShadow.lg,
        handlePressedShadow: CoreShadow.sm,
        handlePressedScale: 0.9,
        handleTransitionDuration: Duration(milliseconds: 300),
        handleIconStyle: CoreIconStyle(size: 20),
        labelInset: CoreEdgeInsets.all(8),
        labelBadgeStyle: CoreBadgeStyle(borderWidth: 2),
        focusOutlineStyle: CoreFocusOutlineStyle(borderWidth: 3),
      );

      // merge: the right side wins field by field.
      expect(const CoreDiffStyle().merge(full), full);
      expect(full.merge(const CoreDiffStyle()), full);

      // copyWith: each field is carried and replaceable.
      expect(full.copyWith(), full);
      expect(full.copyWith(handleSize: 40).handleSize, 40);
      expect(full.copyWith(handleHitSize: 44).handleHitSize, 44);
      expect(full.copyWith(handlePressedScale: 1).handlePressedScale, 1);
      expect(
        full
            .copyWith(handleTransitionDuration: Duration.zero)
            .handleTransitionDuration,
        Duration.zero,
      );
      expect(
        full.copyWith(resizerShadow: CoreShadow.none).resizerShadow,
        isEmpty,
      );

      // equality + hashCode over every field, including the shadow lists.
      expect(full.hashCode, full.copyWith().hashCode);
      expect(full == full.copyWith(handleSize: 40), isFalse);
      expect(
        full == full.copyWith(handleTransitionDuration: Duration.zero),
        isFalse,
      );
      expect(full == full.copyWith(handleShadow: CoreShadow.xs), isFalse);
      expect(full == full.copyWith(handleHoverShadow: CoreShadow.xs), isFalse);
      expect(
        full == full.copyWith(handlePressedShadow: CoreShadow.lg),
        isFalse,
      );
      expect(full == full.copyWith(resizerShadow: CoreShadow.xs), isFalse);
      expect(full == full.copyWith(borderWidth: 1), isFalse);
      expect(full == full.copyWith(labelInset: CoreEdgeInsets.zero), isFalse);
    });

    test('nested slots merge recursively, not by replacement', () {
      const base = CoreDiffStyle(
        handleIconStyle: CoreIconStyle(
          size: 16,
          color: CoreColor.token(CoreColors.onSurface),
        ),
        labelBadgeStyle: CoreBadgeStyle(
          backgroundColor: CoreColor.token(CoreColors.surfaceRaised),
        ),
        focusOutlineStyle: CoreFocusOutlineStyle(borderWidth: 2),
      );
      const patch = CoreDiffStyle(
        handleIconStyle: CoreIconStyle(size: 20),
        labelBadgeStyle: CoreBadgeStyle(borderWidth: 2),
        focusOutlineStyle: CoreFocusOutlineStyle(
          borderColor: CoreColor.token(CoreColors.primary),
        ),
      );
      final merged = base.merge(patch);

      // The patch changes the size only; the colour the base stated stays.
      expect(merged.handleIconStyle!.size, 20);
      expect(
        merged.handleIconStyle!.color,
        const CoreColor.token(CoreColors.onSurface),
      );
      expect(
        merged.labelBadgeStyle!.backgroundColor,
        const CoreColor.token(CoreColors.surfaceRaised),
      );
      expect(merged.labelBadgeStyle!.borderWidth, 2);
      expect(merged.focusOutlineStyle!.borderWidth, 2);
      expect(
        merged.focusOutlineStyle!.borderColor,
        const CoreColor.token(CoreColors.primary),
      );
    });

    test('defaults state the redesigned look', () {
      // The line and the handle share the carousel's raised face.
      expect(
        CoreDiffStyle.defaultResizerColor,
        const CoreColor.token(CoreColors.surfaceRaised),
      );
      expect(
        CoreDiffStyle.defaultHandleColor,
        const CoreColor.token(CoreColors.surfaceRaised),
      );
      expect(
        CoreDiffStyle.defaultHandleBorderColor,
        const CoreColor.token(CoreColors.outlineVariant),
      );
      expect(CoreDiffStyle.defaultHandleBorderWidth, CoreStrokeWidth.stroke1);

      // The cast steps: rest sm, hover one up (md), pressed one down (xs).
      expect(CoreDiffStyle.defaultResizerShadow, CoreShadow.sm);
      expect(CoreDiffStyle.defaultHandleShadow, CoreShadow.sm);
      expect(CoreDiffStyle.defaultHandleHoverShadow, CoreShadow.md);
      expect(CoreDiffStyle.defaultHandlePressedShadow, CoreShadow.xs);
      expect(CoreDiffStyle.defaultHandlePressedScale, 0.94);
      expect(
        CoreDiffStyle.defaultHandleTransitionDuration,
        const Duration(milliseconds: CoreDuration.fast),
      );

      // Forty disc, forty-four grab area, sixteen glyph.
      expect(CoreDiffStyle.defaultHandleSize, 40);
      expect(CoreDiffStyle.defaultHandleHitSize, 44);
      expect(CoreDiffStyle.defaultHandleIconStyle.size, 16);
      expect(
        CoreDiffStyle.defaultHandleIconStyle.color,
        const CoreColor.token(CoreColors.onSurface),
      );

      // The frame edge and the label chips.
      expect(
        CoreDiffStyle.defaultBorderColor,
        const CoreColor.token(CoreColors.outlineSubtle),
      );
      expect(CoreDiffStyle.defaultBorderWidth, CoreStrokeWidth.stroke1);
      expect(CoreDiffStyle.defaultLabelInset, const CoreEdgeInsets.all(12));
    });

    test('the grab area is never smaller than the disc it surrounds', () {
      expect(
        CoreDiffStyle.defaultHandleHitSize,
        greaterThanOrEqualTo(CoreDiffStyle.defaultHandleSize),
      );
      // WCAG 2.2 target size (2.5.8) floor.
      expect(CoreDiffStyle.defaultHandleHitSize, greaterThanOrEqualTo(24));
    });

    test('the handle focus ring turns the gap band on', () {
      expect(
        CoreDiffStyle.defaultFocusOutlineStyle.offsetColor,
        CoreFocusRing.opaqueOffsetColor,
      );
      expect(
        CoreDiffStyle.defaultFocusOutlineStyle.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius9999),
      );
    });
  });

  group('CoreDiffTheme passes through style', () {
    test('CoreDiffTheme', () {
      const style = CoreDiffStyle(borderRadius: CoreBorderRadius.all(12));
      const theme = CoreDiffTheme(style: style);
      expect(theme.style, style);
    });
  });
}
