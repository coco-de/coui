// Tests for CoreCarouselStyle / CoreTreeStyle / CoreTableStyle
// (Epic #1302 — Story #1321). CoreTimelineStyle moved to
// timeline_style_test.dart (batch 2.5).

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kColorPrimary = CoreColor.token(CoreColors.primary);
const _kColorOnSurface = CoreColor.token(CoreColors.onSurface);
// CoreTimelineStyle / CoreTableStyle / CoreTreeStyle now use CoreColor
// (Epic #1415 Phase 6f).
const _kColorPrimaryCore = CoreColor.token(CoreColors.primary);
const _kColorOutlineCore = CoreColor.token(CoreColors.outline);
const _kColorSurfaceCore = CoreColor.token(CoreColors.surface);

void main() {
  group('CoreCarouselStyle', () {
    test('chain — design system → theme.style → widget', () {
      const designSystem = CoreCarouselStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
        indicatorActiveColor: _kColorPrimary,
        indicatorSize: 8,
        navInset: CoreEdgeInsets.symmetric(horizontal: 16),
        prevNextButtonStyle: CoreButtonStyle(
          padding: CoreEdgeInsets.symmetric(horizontal: 8),
        ),
      );
      const themeStyle = CoreCarouselStyle(
        indicatorInset: CoreEdgeInsets.only(bottom: 24),
        prevNextButtonStyle: CoreButtonStyle(
          padding: CoreEdgeInsets.symmetric(horizontal: 12),
        ),
      );
      const widgetStyle = CoreCarouselStyle(
        indicatorSize: 12,
        controlOverlayColor: _kColorPrimary,
      );
      final effective = designSystem.merge(themeStyle).merge(widgetStyle);
      expect(
        effective.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius16),
      );
      expect(effective.indicatorActiveColor, _kColorPrimary);
      expect(effective.indicatorSize, 12);
      expect(
        effective.indicatorInset,
        const CoreEdgeInsets.only(bottom: 24),
      );
      expect(
        effective.navInset,
        const CoreEdgeInsets.symmetric(horizontal: 16),
      );
      expect(effective.controlOverlayColor, _kColorPrimary);
      expect(
        effective.prevNextButtonStyle?.padding,
        const CoreEdgeInsets.symmetric(horizontal: 12),
      );
    });

    test('equality + copyWith', () {
      const a = CoreCarouselStyle(indicatorSpacing: 4);
      const b = CoreCarouselStyle(indicatorSpacing: 4);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      final copy = a.copyWith(
        borderRadius: const CoreBorderRadius.all(CoreRadius.radius8),
        indicatorActiveColor: _kColorPrimary,
        navGapStyle: const CoreGapStyle(size: 8),
        navInset: const CoreEdgeInsets.symmetric(horizontal: 12),
      );
      expect(copy.navGapStyle, const CoreGapStyle(size: 8));
      expect(
        const CoreCarouselStyle(navGapStyle: CoreGapStyle(size: 8)),
        isNot(equals(const CoreCarouselStyle())),
      );
      expect(copy.indicatorSpacing, 4);
      expect(
        copy.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius8),
      );
      expect(copy.indicatorActiveColor, _kColorPrimary);
      expect(
        copy.navInset,
        const CoreEdgeInsets.symmetric(horizontal: 12),
      );
    });
  });

  group("CoreCarouselStyle defaults — the designer's decisions", () {
    test('the nav disc is 32, the size every other small control is', () {
      expect(CoreCarouselStyle.defaultNavButtonSize, 32);
    });

    test('the dots space themselves — no second gap above them', () {
      // `DotIndicator` carries its own padding; a gap here as well
      // stacked two of them.
      expect(CoreCarouselStyle.defaultIndicatorBelowGapStyle.size, 0);
    });

    test('the dots take the accent when active and `outline` when not', () {
      // The carousel states its own tone: its position is worth the accent,
      // and over a slide the inactive step has to still read as a dot.
      expect(
        CoreCarouselStyle.defaultIndicatorActiveColor,
        const CoreColor.token(CoreColors.primary),
      );
      expect(
        CoreCarouselStyle.defaultIndicatorInactiveColor,
        const CoreColor.token(CoreColors.outline),
      );
    });

    test('the nav buttons are raised faces: opaque, edged and cast', () {
      const style = CoreCarouselStyle.defaultPrevNextButtonStyle;

      // Opaque `surfaceRaised` — no alpha for the slide to show through.
      expect(
        CoreCarouselStyle.defaultControlOverlayColor,
        const CoreColor.token(CoreColors.surfaceRaised),
      );
      expect(
        style.backgroundColor,
        CoreCarouselStyle.defaultControlOverlayColor,
      );
      // A one-px edge in `outlineVariant`, so the disc reads on a surface of
      // its own tone.
      expect(
        style.borderColor,
        const CoreColor.token(CoreColors.outlineVariant),
      );
      expect(style.borderWidth, CoreStrokeWidth.stroke1);
      // The `sm` cast — the nearest step to the designer's 0 1 3 · 12%.
      expect(style.boxShadow, CoreShadow.sm);
      // The disc stays 32.
      expect(style.width, CoreCarouselStyle.defaultNavButtonSize);
      expect(style.height, CoreCarouselStyle.defaultNavButtonSize);
    });

    test('the banner pair sits four apart, and the gap is a Style slot', () {
      expect(CoreCarouselStyle.defaultNavGapStyle.size, 4);
      const patch = CoreCarouselStyle(navGapStyle: CoreGapStyle(size: 8));
      expect(
        CoreCarouselStyle.defaultNavGapStyle.merge(patch.navGapStyle).size,
        8,
      );
    });

    test('the viewport corner is 16, the step the docs chain binds', () {
      expect(
        CoreCarouselStyle.defaultBorderRadius,
        const CoreBorderRadius.all(CoreRadius.radius16),
      );
    });
  });

  group('CoreTreeStyle', () {
    test('chain — design system → theme.style → widget', () {
      const designSystem = CoreTreeStyle(
        nodeBackgroundColor: _kColorSurfaceCore,
        nodeSelectedColor: _kColorPrimaryCore,
        indent: 16,
        indentLineColor: _kColorOutlineCore,
        nodeTextStyle: CoreTextStyle(color: _kColorOnSurface),
        chevronIconStyle: CoreIconStyle(size: 16),
      );
      const widgetStyle = CoreTreeStyle(indent: 24);
      final effective = designSystem.merge(widgetStyle);
      expect(effective.nodeBackgroundColor, _kColorSurfaceCore);
      expect(effective.nodeSelectedColor, _kColorPrimaryCore);
      expect(effective.indent, 24);
      expect(effective.indentLineColor, _kColorOutlineCore);
      expect(effective.nodeTextStyle?.color, _kColorOnSurface);
      expect(effective.chevronIconStyle?.size, 16);
    });

    test('nodeMinHeight — merge, copyWith, equality', () {
      const a = CoreTreeStyle(nodeMinHeight: 32);
      expect(a.merge(const CoreTreeStyle()).nodeMinHeight, 32);
      expect(a.merge(const CoreTreeStyle(nodeMinHeight: 40)).nodeMinHeight, 40);
      expect(a.copyWith().nodeMinHeight, 32);
      expect(a.copyWith(nodeMinHeight: 20).nodeMinHeight, 20);
      expect(a, equals(const CoreTreeStyle(nodeMinHeight: 32)));
      expect(a, isNot(equals(const CoreTreeStyle(nodeMinHeight: 33))));
      expect(
        a.hashCode,
        const CoreTreeStyle(nodeMinHeight: 32).hashCode,
      );
    });

    test('leafIconStyle — merge recurses, copyWith, equality, hashCode', () {
      const a = CoreTreeStyle(
        leafIconStyle: CoreIconStyle(size: 18, color: _kColorOnSurface),
      );
      // A colour-only override keeps the size (nested merge, not replace).
      final merged = a.merge(
        const CoreTreeStyle(
          leafIconStyle: CoreIconStyle(color: _kColorOutlineCore),
        ),
      );
      expect(merged.leafIconStyle?.size, 18);
      expect(merged.leafIconStyle?.color, _kColorOutlineCore);
      expect(a.merge(const CoreTreeStyle()).leafIconStyle, a.leafIconStyle);
      expect(
        const CoreTreeStyle().merge(a).leafIconStyle,
        a.leafIconStyle,
      );
      expect(a.copyWith().leafIconStyle, a.leafIconStyle);
      expect(
        a
            .copyWith(leafIconStyle: const CoreIconStyle(size: 20))
            .leafIconStyle
            ?.size,
        20,
      );
      expect(
        a,
        equals(
          const CoreTreeStyle(
            leafIconStyle: CoreIconStyle(size: 18, color: _kColorOnSurface),
          ),
        ),
      );
      expect(
        a,
        isNot(
          equals(
            const CoreTreeStyle(leafIconStyle: CoreIconStyle(size: 19)),
          ),
        ),
      );
      expect(
        a.hashCode,
        const CoreTreeStyle(
          leafIconStyle: CoreIconStyle(size: 18, color: _kColorOnSurface),
        ).hashCode,
      );
      expect(a.hashCode, isNot(const CoreTreeStyle().hashCode));
    });

    test('equality + null nested style on base inherits', () {
      const a = CoreTreeStyle(indent: 16);
      const b = CoreTreeStyle(indent: 16);
      expect(a, equals(b));
      const base = CoreTreeStyle();
      const override = CoreTreeStyle(
        chevronIconStyle: CoreIconStyle(size: 16),
      );
      final merged = base.merge(override);
      expect(merged.chevronIconStyle?.size, 16);
    });

    test('row geometry defaults — 6 inset, 18 indent, radius 6', () {
      // Read back as numbers, not as the tokens the declarations name: a
      // token re-pointed at a different step would still equal itself.
      expect(CoreTreeStyle.defaultIndent, 18);
      expect(CoreTreeStyle.defaultNodePadding.left, 6);
      expect(CoreTreeStyle.defaultNodePadding.right, 6);
      // No block inset: the row's height is `nodeMinHeight`, which centres
      // the 21px label line.
      expect(CoreTreeStyle.defaultNodePadding.top, 0);
      expect(CoreTreeStyle.defaultNodePadding.bottom, 0);
      expect(CoreTreeStyle.defaultNodeMinHeight, 28);
      expect(
        CoreTreeStyle.defaultBorderRadius,
        const CoreBorderRadius.all(CoreRadius.radius6),
      );
      expect(CoreTreeStyle.defaultBorderRadius.topLeft, 6);
    });

    test('glyph defaults — leading 14, chevron 12 / file glyph in '
        'onSurfaceSubtle, folder onSurfaceVariant', () {
      expect(CoreTreeStyle.defaultIconStyle.size, 14);
      expect(CoreTreeStyle.defaultChevronIconStyle.size, 12);
      // One chevron colour for every row state, not the label's.
      expect(
        CoreTreeStyle.defaultChevronIconStyle.color,
        const CoreColor.token(CoreColors.onSurfaceSubtle),
      );
      expect(
        CoreTreeStyle.defaultIconColor,
        const CoreColor.token(CoreColors.onSurfaceVariant),
      );
      // The file glyph states a colour only, so its size follows the
      // leading icon size.
      expect(
        CoreTreeStyle.defaultLeafIconStyle.color,
        const CoreColor.token(CoreColors.onSurfaceSubtle),
      );
      expect(CoreTreeStyle.defaultLeafIconStyle.size, isNull);
      // The leaf-row slot holds the chevron's place.
      expect(
        CoreTreeStyle.defaultChevronPlaceholderGapStyle.size,
        CoreTreeStyle.defaultChevronIconStyle.size,
      );
      expect(CoreTreeStyle.defaultChevronPlaceholderGapStyle.size, 12);
    });

    test('gaps — chevron ↔ icon 6, icon ↔ label 6', () {
      expect(CoreTreeStyle.defaultIconGapStyle.size, 6);
      expect(CoreTreeStyle.defaultLabelGapStyle.size, 6);
    });

    test('the name is codeSm in both states', () {
      expect(
        CoreTreeStyle.defaultNodeTextStyle.token,
        CoreTextStyles.codeSm,
      );
      expect(
        CoreTreeStyle.defaultNodeSelectedTextStyle.token,
        CoreTextStyles.codeSm,
      );
    });

    test('colours — the label rests on onSurfaceVariant and steps up to '
        'onSurface on the opaque surfaceContainerHigh selected face', () {
      expect(
        CoreTreeStyle.defaultNodeTextStyle.color,
        const CoreColor.token(CoreColors.onSurfaceVariant),
      );
      expect(
        CoreTreeStyle.defaultNodeSelectedTextStyle.color,
        _kColorOnSurface,
      );
      expect(
        CoreTreeStyle.defaultNodeSelectedColor,
        const CoreColor.token(CoreColors.surfaceContainerHigh),
      );
      // Opaque: the face is a container step, not a tint of the accent.
      expect(CoreTreeStyle.defaultNodeSelectedColor.opacity, 1);
    });

    test('drop affordances keep their primary colours, off the selected '
        'face', () {
      // The tint behind a valid folder target is primary at 10 %, the
      // insertion line solid primary — their own defaults, so a selected
      // face that is no longer primary does not move them.
      expect(
        CoreTreeStyle.defaultDropTargetColor,
        const CoreColor.token(
          CoreColors.primary,
          opacity: CoreOpacity.opacity10,
        ),
      );
      expect(CoreTreeStyle.defaultDropIndicatorColor, _kColorPrimary);
      expect(
        CoreTreeStyle.defaultDropTargetColor,
        isNot(CoreTreeStyle.defaultNodeSelectedColor),
      );
      expect(
        CoreTreeStyle.defaultDropIndicatorColor,
        isNot(CoreTreeStyle.defaultNodeSelectedColor),
      );
    });

    test('drop colours are their own fields — merged, copied and compared '
        'apart from the selected face', () {
      const base = CoreTreeStyle(nodeSelectedColor: _kColorPrimaryCore);
      const patch = CoreTreeStyle(
        dropTargetColor: _kColorOutlineCore,
        dropIndicatorColor: _kColorSurfaceCore,
      );
      final merged = base.merge(patch);
      expect(merged.nodeSelectedColor, _kColorPrimaryCore);
      expect(merged.dropTargetColor, _kColorOutlineCore);
      expect(merged.dropIndicatorColor, _kColorSurfaceCore);
      // Unstated fields defer to the named defaults, not to each other.
      expect(base.dropTargetColor, isNull);
      expect(base.dropIndicatorColor, isNull);

      expect(
        base.copyWith(dropTargetColor: _kColorOutlineCore).dropTargetColor,
        _kColorOutlineCore,
      );
      expect(
        base
            .copyWith(dropIndicatorColor: _kColorSurfaceCore)
            .dropIndicatorColor,
        _kColorSurfaceCore,
      );
      // Equality and hash see both fields — a drop colour that changed alone
      // must still read as a different style (it decides a rebuild).
      expect(
        const CoreTreeStyle(dropTargetColor: _kColorOutlineCore),
        isNot(const CoreTreeStyle(dropTargetColor: _kColorSurfaceCore)),
      );
      expect(
        const CoreTreeStyle(dropIndicatorColor: _kColorOutlineCore),
        isNot(const CoreTreeStyle(dropIndicatorColor: _kColorSurfaceCore)),
      );
      expect(
        const CoreTreeStyle(dropTargetColor: _kColorOutlineCore).hashCode,
        isNot(
          const CoreTreeStyle(dropTargetColor: _kColorSurfaceCore).hashCode,
        ),
      );
      expect(
        const CoreTreeStyle(dropIndicatorColor: _kColorOutlineCore).hashCode,
        isNot(
          const CoreTreeStyle(dropIndicatorColor: _kColorSurfaceCore).hashCode,
        ),
      );
    });

    test('chevron size is its own — a leading-icon size does not move it', () {
      const style = CoreTreeStyle(iconStyle: CoreIconStyle(size: 20));
      final chevron = CoreTreeStyle.defaultChevronIconStyle.merge(
        style.chevronIconStyle,
      );
      expect(chevron.size, 12);
      // …and a chevron override still does.
      final resized = CoreTreeStyle.defaultChevronIconStyle.merge(
        const CoreIconStyle(size: 16),
      );
      expect(resized.size, 16);
    });

    test('the rename field takes the row corner and the label role', () {
      final field = CoreTreeRenameRules.fieldStyle(
        CoreTreeStyle.defaultNodeTextStyle,
      );
      expect(field.borderRadius, CoreTreeStyle.defaultBorderRadius);
      expect(field.borderRadius?.topLeft, 6);
      expect(field.baseTextStyle?.token, CoreTextStyles.codeSm);
    });

    test('the text typed into the rename field is onSurface, not the dimmer '
        'unselected label colour', () {
      final field = CoreTreeRenameRules.fieldStyle(
        CoreTreeStyle.defaultNodeTextStyle,
      );
      // The label the row rests on is onSurfaceVariant…
      expect(
        CoreTreeStyle.defaultNodeTextStyle.color,
        const CoreColor.token(CoreColors.onSurfaceVariant),
      );
      // …and the field does not inherit it.
      expect(field.baseTextStyle?.color, _kColorOnSurface);
      expect(CoreTreeRenameRules.fieldTextColor, _kColorOnSurface);
      // Even a caller-restyled label colour leaves the typed text alone.
      final restyled = CoreTreeRenameRules.fieldStyle(
        CoreTreeStyle.defaultNodeTextStyle.merge(
          const CoreTextStyle(color: _kColorPrimary),
        ),
      );
      expect(restyled.baseTextStyle?.color, _kColorOnSurface);
      expect(restyled.baseTextStyle?.token, CoreTextStyles.codeSm);
    });
  });

  group('CoreTableStyle', () {
    test('chain — design system → theme.style → widget', () {
      const designSystem = CoreTableStyle(
        headerBackgroundColor: _kColorSurfaceCore,
        headerHeight: 40,
        rowHeight: 36,
        cellPadding: CoreEdgeInsets.all(12),
        borderColor: _kColorOutlineCore,
        borderWidth: 1,
        headerTextStyle: CoreTextStyle(color: _kColorOnSurface),
      );
      const widgetStyle = CoreTableStyle(rowHeight: 44);
      final effective = designSystem.merge(widgetStyle);
      expect(effective.headerBackgroundColor, _kColorSurfaceCore);
      expect(effective.headerHeight, 40);
      expect(effective.rowHeight, 44);
      expect(effective.cellPadding, const CoreEdgeInsets.all(12));
      expect(effective.borderColor, _kColorOutlineCore);
      expect(effective.headerTextStyle?.color, _kColorOnSurface);
    });

    test('zebra-stripe / hover / selected colors override', () {
      const a = CoreTableStyle(
        rowAlternateBackgroundColor: _kColorSurfaceCore,
        rowHoverColor: _kColorOutlineCore,
      );
      const b = CoreTableStyle(rowSelectedColor: _kColorPrimaryCore);
      final merged = a.merge(b);
      expect(merged.rowAlternateBackgroundColor, _kColorSurfaceCore);
      expect(merged.rowHoverColor, _kColorOutlineCore);
      expect(merged.rowSelectedColor, _kColorPrimaryCore);
    });

    test('cellTextStyle merges recursively', () {
      const a = CoreTableStyle(
        cellTextStyle: CoreTextStyle(fontSize: 14),
      );
      const b = CoreTableStyle(
        cellTextStyle: CoreTextStyle(color: _kColorOnSurface),
      );
      final merged = a.merge(b);
      expect(merged.cellTextStyle?.fontSize, 14);
      expect(merged.cellTextStyle?.color, _kColorOnSurface);
    });
  });

  group('CoreTableStyle outer box and cell defaults', () {
    test('the outer box is off by default and the separators stay on', () {
      expect(CoreTableStyle.defaultOuterBorderWidth, 0);
      expect(CoreTableStyle.defaultBorderWidth, CoreStrokeWidth.stroke1);
    });

    test('outerBorderWidth merges, copies and compares', () {
      const base = CoreTableStyle(borderWidth: 1);
      const override = CoreTableStyle(outerBorderWidth: 2);
      final merged = base.merge(override);
      expect(merged.outerBorderWidth, 2);
      expect(merged.borderWidth, 1);
      expect(base.merge(const CoreTableStyle()).outerBorderWidth, isNull);
      expect(base.copyWith(outerBorderWidth: 3).outerBorderWidth, 3);
      expect(base.copyWith(outerBorderWidth: 3).borderWidth, 1);
      expect(
        const CoreTableStyle(outerBorderWidth: 1),
        isNot(const CoreTableStyle(outerBorderWidth: 2)),
      );
      expect(
        const CoreTableStyle(outerBorderWidth: 1).hashCode,
        const CoreTableStyle(outerBorderWidth: 1).hashCode,
      );
      expect(
        const CoreTableStyle(outerBorderWidth: 1),
        const CoreTableStyle(outerBorderWidth: 1),
      );
    });

    test('header cells pad 10 by 4, body and footer cells 12 by 4', () {
      expect(
        CoreTableStyle.defaultHeaderPadding,
        const CoreEdgeInsets.symmetric(
          vertical: CoreSpace.space10,
          horizontal: CoreSpace.space4,
        ),
      );
      expect(
        CoreTableStyle.defaultCellPadding,
        const CoreEdgeInsets.symmetric(
          vertical: CoreSpace.space12,
          horizontal: CoreSpace.space4,
        ),
      );
    });

    test('the header text roles and foreground are named defaults', () {
      expect(
        CoreTableStyle.defaultHeaderTextStyle.token,
        CoreTextStyles.labelMedium,
      );
      expect(
        CoreTableStyle.defaultCellTextStyle.token,
        CoreTextStyles.labelLarge,
      );
      // The header's enabled ink rides its default text style.
      expect(
        CoreTableStyle.defaultHeaderTextStyle.color!.token,
        CoreColors.onSurfaceSubtle,
      );
      expect(
        CoreTableStyle.defaultCellTextStyle.color,
        isNull,
        reason: 'body cells inherit; only the header states a colour',
      );
    });
  });

  group('CoreTableStyle colour slots', () {
    final modes = <(String, CoreColorScheme)>[
      ('light', CouiColorPresets.source.light()),
      ('dark', CouiColorPresets.source.dark()),
      ('high-contrast light', CouiColorPresets.source.highContrastLight()),
      ('high-contrast dark', CouiColorPresets.source.highContrastDark()),
    ];

    /// [actual] as each mode paints it, against the slot it should name.
    void expectSlotInEveryMode(
      CoreColor actual,
      CoreColorToken expected, {
      double opacity = 1,
    }) {
      for (final (mode, scheme) in modes) {
        final want = scheme.resolve(
          CoreColor.token(expected, opacity: opacity),
        );
        final got = scheme.resolve(actual);
        expect(got.argb, want.argb, reason: mode);
        expect(got.effectiveOpacity, closeTo(want.effectiveOpacity, 1e-9));
      }
    }

    test('row and header separators are the outlineVariant hairline', () {
      expectSlotInEveryMode(
        CoreTableStyle.defaultBorderColor,
        CoreColors.outlineVariant,
      );
    });

    test('the header has no fill of its own', () {
      expect(
        CoreTableStyle.defaultHeaderBackgroundColor,
        CoreColor.transparent,
      );
      expect(CoreTableStyle.defaultHeaderBackgroundColor.alpha, 0);
    });

    test('the footer keeps surfaceContainer', () {
      expectSlotInEveryMode(
        CoreTableStyle.defaultFooterBackgroundColor,
        CoreColors.surfaceContainer,
      );
    });

    test('header ink is onSurfaceSubtle in every mode', () {
      expectSlotInEveryMode(
        CoreTableStyle.defaultHeaderTextStyle.color!,
        CoreColors.onSurfaceSubtle,
      );
    });

    test('hover is an onSurface wash at opacity/hover', () {
      expectSlotInEveryMode(
        CoreTableStyle.defaultRowHoverColor,
        CoreColors.onSurface,
        opacity: CoreOpacity.hover,
      );
    });

    test('selection is an opaque surfaceContainerHigh fill', () {
      expectSlotInEveryMode(
        CoreTableStyle.defaultRowSelectedColor,
        CoreColors.surfaceContainerHigh,
      );
      for (final (mode, scheme) in modes) {
        expect(
          scheme.resolve(CoreTableStyle.defaultRowSelectedColor).alpha,
          0xFF,
          reason: mode,
        );
      }
    });

    test('a frozen cell still covers the rows under it with surface', () {
      expectSlotInEveryMode(
        CoreTableStyle.defaultFrozenCellBackgroundColor,
        CoreColors.surface,
      );
    });
  });

  group('Themes pass through style', () {
    test('CoreCarouselTheme', () {
      const style = CoreCarouselStyle(
        indicatorActiveColor: _kColorPrimary,
      );
      const theme = CoreCarouselTheme(style: style);
      expect(theme.style, style);
    });

    test('CoreTreeTheme', () {
      const style = CoreTreeStyle(indent: 16);
      const theme = CoreTreeTheme(style: style);
      expect(theme.style, style);
    });

    test('CoreTableTheme', () {
      const style = CoreTableStyle(rowHeight: 36);
      const theme = CoreTableTheme(style: style);
      expect(theme.style, style);
    });
  });
}
