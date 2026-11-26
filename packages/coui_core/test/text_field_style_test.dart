// Tests for CoreTextFieldStyle (Epic #1302 — Story #1307).
//
// CoreTextFieldStyle is shared between TextField and TextArea
// because chrome / dimensional / cursor / nested-slot fields are
// 99 % identical between the two — multi-line specifics live on the
// widget as behaviour flags rather than chrome.
//
// Mirrors the merge-chain pattern of #1316 / #1317 / #1306: a single
// nested style flows through `design system default → theme.style →
// theme.variantStyles[v] → widget.textFieldStyle`, with right-most
// non-null winning per field. Nested slot styles
// (label / placeholder / value / description / error / icons)
// merge recursively.
//
// variant / size are NOT in CoreTextFieldStyle — they live on the
// widget (Epic #1302 원칙 6/7).
// ignore_for_file: avoid_redundant_argument_values

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const double _kHeightSm = 32;
const double _kHeightMd = 40;

/// A multi-line `maxHeight` for TextArea-relevant merge tests
/// (four times the medium single-line height).
const double _kMaxHeight = _kHeightMd * 4;

/// A per-variant style override fixture for the `CoreTextFieldTheme`
/// tests — `style` is the base, `variantStyles[error]` layered when
/// `errorText != null`.
const CoreTextFieldStyle _kFieldThemeStyle = CoreTextFieldStyle(
  focusBorderColor: _kFocusPrimary,
);
const CoreTextFieldStyle _kFieldThemeErrorStyle = CoreTextFieldStyle(
  focusBorderColor: _kFocusPrimary,
);

/// `CoreTextAreaTheme` uses its own [CoreTextAreaStyle] (sibling, not
/// wrapper — Epic #1696).
const CoreTextAreaStyle _kAreaThemeStyle = CoreTextAreaStyle(
  maxHeight: _kMaxHeight,
);
const CoreTextAreaStyle _kAreaThemeErrorStyle = CoreTextAreaStyle(
  maxHeight: _kMaxHeight,
);
const _kPaddingHSm = CoreEdgeInsets.symmetric(horizontal: 12);
const _kPaddingHLg = CoreEdgeInsets.symmetric(horizontal: 24);
const _kRadiusSm = CoreBorderRadius.all(4);
const _kRadiusLg = CoreBorderRadius.all(12);
const double _kBorderThin = 1;
const double _kBorderThick = 2;
const double _kCursorWidth = 2;
const _kCursorRadius = CoreBorderRadius.all(1);
const double _kIconSm = 16;
const double _kIconMd = 20;

const _kBgSurface = CoreColor.token(CoreColors.surface);
const _kBgPrimary = CoreColor.token(CoreColors.primary);
const _kBorderOutline = CoreColor.token(CoreColors.outline);
const _kBorderError = CoreColor.token(CoreColors.error);
const _kFocusPrimary = CoreColor.token(CoreColors.primary);
const _kCursorPrimary = CoreColor.token(CoreColors.primary);
const _kCursorError = CoreColor.token(CoreColors.error);
// `CoreTextStyle.color` / `CoreIconStyle.color` are now `CoreColor?`
// (Epic #1415 Phase 2). These are used in nested text/icon style slots.
const _kBorderOutlineClr = CoreColor.token(CoreColors.outline);
const _kBorderErrorClr = CoreColor.token(CoreColors.error);

const double _kFontBody = 14;
const double _kFontTitle = 18;
const double _kLabelBottomPaddingDefault = 4;
const double _kLabelBottomPaddingOverride = 6;
const double _kRowSpacingDefault = 8;
const double _kRowSpacingOverride = 12;
const int _kWeightRegular = CoreFontWeight.regular;
const int _kWeightSemiBold = CoreFontWeight.semiBold;

void main() {
  group('CoreTextFieldStyle.merge', () {
    test('null other returns this', () {
      const a = CoreTextFieldStyle(
        backgroundColor: _kBgSurface,
        height: _kHeightMd,
      );
      expect(identical(a.merge(null), a), isTrue);
    });

    test('non-null fields in other override receiver', () {
      const base = CoreTextFieldStyle(
        backgroundColor: _kBgSurface,
        borderColor: _kBorderOutline,
        borderWidth: _kBorderThin,
        height: _kHeightMd,
        padding: _kPaddingHLg,
      );
      const override = CoreTextFieldStyle(
        backgroundColor: _kBgPrimary,
        borderWidth: _kBorderThick,
      );
      final merged = base.merge(override);
      expect(merged.backgroundColor, _kBgPrimary);
      expect(merged.borderColor, _kBorderOutline);
      expect(merged.borderWidth, _kBorderThick);
      expect(merged.height, _kHeightMd);
      expect(merged.padding, _kPaddingHLg);
    });

    test('chain — design system → theme.style → variantStyles → widget', () {
      const designSystem = CoreTextFieldStyle(
        backgroundColor: _kBgSurface,
        borderColor: _kBorderOutline,
        borderWidth: _kBorderThin,
        height: _kHeightMd,
        padding: _kPaddingHLg,
      );
      const themeStyle = CoreTextFieldStyle(
        height: _kHeightSm,
      );
      const variantStyle = CoreTextFieldStyle(
        focusBorderColor: _kFocusPrimary,
        cursorColor: _kCursorPrimary,
      );
      const widgetStyle = CoreTextFieldStyle(
        borderRadius: _kRadiusLg,
        padding: _kPaddingHSm,
      );

      final effective = designSystem
          .merge(themeStyle)
          .merge(variantStyle)
          .merge(widgetStyle);

      expect(effective.backgroundColor, _kBgSurface);
      expect(effective.borderColor, _kBorderOutline);
      expect(effective.borderWidth, _kBorderThin);
      expect(effective.height, _kHeightSm); // theme override
      expect(effective.focusBorderColor, _kFocusPrimary); // variant override
      expect(effective.cursorColor, _kCursorPrimary); // variant override
      expect(effective.padding, _kPaddingHSm); // widget override
      expect(effective.borderRadius, _kRadiusLg); // widget override
    });

    test('right-most non-null wins on each field', () {
      const a = CoreTextFieldStyle(
        height: _kHeightSm,
        padding: _kPaddingHSm,
      );
      const b = CoreTextFieldStyle(height: _kHeightMd);
      const c = CoreTextFieldStyle(padding: _kPaddingHLg);

      final result = a.merge(b).merge(c);

      expect(result.height, _kHeightMd); // from b (c is null)
      expect(result.padding, _kPaddingHLg); // from c overrides a
    });

    test('hoverBorderColor + stateLayer merge and copy like every field', () {
      const base = CoreTextFieldStyle(
        hoverBorderColor: _kBorderOutline,
        stateLayer: CoreStateLayer.subtle,
      );
      const over = CoreTextFieldStyle(
        hoverBorderColor: _kBgPrimary,
        stateLayer: CoreStateLayer.strong,
      );
      final merged = base.merge(over);
      expect(merged.hoverBorderColor, _kBgPrimary);
      expect(merged.stateLayer, CoreStateLayer.strong);
      expect(base.merge(const CoreTextFieldStyle()), base);
      expect(
        base.copyWith(stateLayer: CoreStateLayer.strong).stateLayer,
        CoreStateLayer.strong,
      );
      expect(base.copyWith(stateLayer: CoreStateLayer.strong), isNot(base));
      expect(base, isNot(base.copyWith(hoverBorderColor: _kBgPrimary)));
    });

    test('focus / error border + cursor merge', () {
      const base = CoreTextFieldStyle(
        focusBorderColor: _kFocusPrimary,
        errorBorderColor: _kBorderError,
        cursorColor: _kCursorPrimary,
        cursorWidth: _kCursorWidth,
        cursorHeight: 28,
        cursorRadius: _kCursorRadius,
      );
      const override = CoreTextFieldStyle(
        cursorColor: _kCursorError,
      );
      final merged = base.merge(override);
      expect(merged.focusBorderColor, _kFocusPrimary);
      expect(merged.errorBorderColor, _kBorderError);
      expect(merged.cursorColor, _kCursorError);
      expect(merged.cursorWidth, _kCursorWidth);
      expect(merged.cursorHeight, 28);
      expect(merged.copyWith(cursorHeight: 30).cursorHeight, 30);
      expect(merged.copyWith(cursorHeight: 30), isNot(merged));
      expect(
        merged.merge(const CoreTextFieldStyle(cursorHeight: 32)).cursorHeight,
        32,
      );
      expect(merged.cursorRadius, _kCursorRadius);
    });

    test('minHeight / maxHeight (TextArea-relevant) merge', () {
      const base = CoreTextFieldStyle(
        minHeight: _kHeightSm,
        maxHeight: _kMaxHeight,
      );
      const override = CoreTextFieldStyle(
        minHeight: _kHeightMd,
      );
      final merged = base.merge(override);
      expect(merged.minHeight, _kHeightMd);
      expect(merged.maxHeight, _kMaxHeight);
    });

    test('labelPadding / descriptionPadding / rowSpacing merge', () {
      const base = CoreTextFieldStyle(
        labelPadding: CoreEdgeInsets.only(
          bottom: _kLabelBottomPaddingDefault,
        ),
        descriptionPadding: CoreEdgeInsets.only(
          top: _kLabelBottomPaddingDefault,
        ),
        rowSpacing: _kRowSpacingDefault,
      );
      const override = CoreTextFieldStyle(
        labelPadding: CoreEdgeInsets.only(
          bottom: _kLabelBottomPaddingOverride,
        ),
        rowSpacing: _kRowSpacingOverride,
      );
      final merged = base.merge(override);
      expect(
        merged.labelPadding,
        const CoreEdgeInsets.only(bottom: _kLabelBottomPaddingOverride),
      );
      expect(
        merged.descriptionPadding,
        const CoreEdgeInsets.only(top: _kLabelBottomPaddingDefault),
      );
      expect(merged.rowSpacing, _kRowSpacingOverride);
    });
  });

  group('CoreTextFieldStyle.merge — nested slot styles', () {
    test('labelStyle merges recursively (subset override)', () {
      const base = CoreTextFieldStyle(
        labelStyle: CoreTextStyle(
          fontSize: _kFontBody,
          fontWeight: _kWeightRegular,
          color: _kBorderOutlineClr,
        ),
      );
      const override = CoreTextFieldStyle(
        labelStyle: CoreTextStyle(fontWeight: _kWeightSemiBold),
      );
      final merged = base.merge(override);
      expect(merged.labelStyle?.fontSize, _kFontBody);
      expect(merged.labelStyle?.fontWeight, _kWeightSemiBold);
      expect(merged.labelStyle?.color, _kBorderOutlineClr);
    });

    test('placeholderStyle / valueStyle / descriptionStyle / errorStyle '
        'merge recursively', () {
      const base = CoreTextFieldStyle(
        placeholderStyle: CoreTextStyle(fontSize: _kFontBody),
        valueStyle: CoreTextStyle(fontSize: _kFontBody),
        descriptionStyle: CoreTextStyle(color: _kBorderOutlineClr),
        errorStyle: CoreTextStyle(color: _kBorderErrorClr),
      );
      const override = CoreTextFieldStyle(
        valueStyle: CoreTextStyle(fontWeight: _kWeightSemiBold),
        errorStyle: CoreTextStyle(fontSize: _kFontTitle),
      );
      final merged = base.merge(override);
      expect(merged.placeholderStyle?.fontSize, _kFontBody);
      expect(merged.valueStyle?.fontSize, _kFontBody);
      expect(merged.valueStyle?.fontWeight, _kWeightSemiBold);
      expect(merged.descriptionStyle?.color, _kBorderOutlineClr);
      expect(merged.errorStyle?.color, _kBorderErrorClr);
      expect(merged.errorStyle?.fontSize, _kFontTitle);
    });

    test('leadingIconStyle / trailingIconStyle merge recursively', () {
      const base = CoreTextFieldStyle(
        leadingIconStyle: CoreIconStyle(
          size: _kIconMd,
          color: _kBorderOutlineClr,
        ),
        trailingIconStyle: CoreIconStyle(size: _kIconSm),
      );
      const override = CoreTextFieldStyle(
        leadingIconStyle: CoreIconStyle(color: _kBorderErrorClr),
        trailingIconStyle: CoreIconStyle(size: _kIconMd),
      );
      final merged = base.merge(override);
      expect(merged.leadingIconStyle?.size, _kIconMd);
      expect(merged.leadingIconStyle?.color, _kBorderErrorClr);
      expect(merged.trailingIconStyle?.size, _kIconMd);
    });

    test('null nested style on base inherits from override', () {
      const base = CoreTextFieldStyle();
      const override = CoreTextFieldStyle(
        labelStyle: CoreTextStyle(
          fontSize: _kFontTitle,
          color: _kBorderErrorClr,
        ),
      );
      final merged = base.merge(override);
      expect(merged.labelStyle?.fontSize, _kFontTitle);
      expect(merged.labelStyle?.color, _kBorderErrorClr);
    });
  });

  group('CoreTextFieldStyle equality', () {
    test('same fields → equal', () {
      const a = CoreTextFieldStyle(
        backgroundColor: _kBgSurface,
        borderRadius: _kRadiusSm,
        height: _kHeightMd,
      );
      const b = CoreTextFieldStyle(
        backgroundColor: _kBgSurface,
        borderRadius: _kRadiusSm,
        height: _kHeightMd,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different focusBorderColor → not equal', () {
      const a = CoreTextFieldStyle(focusBorderColor: _kFocusPrimary);
      const b = CoreTextFieldStyle(focusBorderColor: _kBorderError);
      expect(a, isNot(equals(b)));
    });

    test('different valueStyle → not equal', () {
      const a = CoreTextFieldStyle(
        valueStyle: CoreTextStyle(fontSize: _kFontBody),
      );
      const b = CoreTextFieldStyle(
        valueStyle: CoreTextStyle(fontSize: _kFontTitle),
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('CoreTextFieldStyle.copyWith', () {
    test('only-supplied fields override', () {
      const base = CoreTextFieldStyle(
        backgroundColor: _kBgSurface,
        height: _kHeightMd,
        padding: _kPaddingHLg,
      );
      final copy = base.copyWith(height: _kHeightSm);
      expect(copy.backgroundColor, _kBgSurface);
      expect(copy.height, _kHeightSm);
      expect(copy.padding, _kPaddingHLg);
    });

    test('preserves nested styles when not specified', () {
      const base = CoreTextFieldStyle(
        labelStyle: CoreTextStyle(fontSize: _kFontBody),
        leadingIconStyle: CoreIconStyle(size: _kIconMd),
      );
      final copy = base.copyWith(backgroundColor: _kBgPrimary);
      expect(copy.backgroundColor, _kBgPrimary);
      expect(copy.labelStyle?.fontSize, _kFontBody);
      expect(copy.leadingIconStyle?.size, _kIconMd);
    });
  });

  group('CoreTextFieldTheme', () {
    test('style + variantStyles[error] pass through', () {
      const style = CoreTextFieldStyle(padding: _kPaddingHLg);
      const theme = CoreTextFieldTheme(
        style: style,
        variantStyles: {
          .error: _kFieldThemeErrorStyle,
        },
      );
      expect(theme.style, style);
      expect(
        theme.variantStyles?[CoreTextFieldVariant.error],
        _kFieldThemeErrorStyle,
      );
    });

    test('null fields', () {
      const theme = CoreTextFieldTheme();
      expect(theme.style, isNull);
      expect(theme.variantStyles, isNull);
    });

    test('equality', () {
      const a = CoreTextFieldTheme(
        style: _kFieldThemeStyle,
        variantStyles: {.error: _kFieldThemeErrorStyle},
      );
      const b = CoreTextFieldTheme(
        style: _kFieldThemeStyle,
        variantStyles: {.error: _kFieldThemeErrorStyle},
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('CoreTextAreaTheme — owns CoreTextAreaStyle', () {
    test('style + variantStyles[error] use CoreTextAreaStyle directly', () {
      const theme = CoreTextAreaTheme(
        style: _kAreaThemeStyle,
        variantStyles: {true: _kAreaThemeErrorStyle},
      );
      expect(theme.style, _kAreaThemeStyle);
      expect(theme.variantStyles?[true]?.maxHeight, _kMaxHeight);
    });

    test('null fields', () {
      const theme = CoreTextAreaTheme();
      expect(theme.style, isNull);
      expect(theme.variantStyles, isNull);
    });
  });

  // #3773 — `defaultsBySize[size]!` is a Map lookup, not a `switch`, so
  // Dart's exhaustiveness checker never sees it. These groups are the
  // net — they fail the moment a member is added without a matching
  // entry, before any `!` ever gets a chance to throw at runtime.
  //
  // CoreTextFieldStyle and CoreTextAreaStyle are sibling classes (not
  // the same type — see the file header) with independent
  // `defaultsBySize` maps, so both need their own coverage.
  group('CoreTextFieldStyle.defaultsBySize (#3773)', () {
    test('covers every CoreComponentSize member', () {
      for (final size in CoreComponentSize.values) {
        expect(
          CoreTextFieldStyle.defaultsBySize[size],
          isNotNull,
          reason:
              'missing size chrome for CoreComponentSize.${size.name} — '
              'every `defaultsBySize[size]!` lookup in the resolvers '
              'assumes full coverage and would crash at runtime',
        );
      }
    });

    test('has exactly one entry per CoreComponentSize member', () {
      expect(
        CoreTextFieldStyle.defaultsBySize.length,
        CoreComponentSize.values.length,
      );
    });
  });

  group('CoreTextFieldStyle — the active boundary', () {
    test('the default is the resting 1 — focus and error speak in colour '
        '(#5747)', () {
      expect(
        CoreTextFieldStyle.defaultActiveBorderWidth,
        CoreStrokeWidth.stroke1,
      );
      expect(
        CoreTextFieldStyle.defaultActiveBorderWidth,
        CoreTextFieldStyle.defaultBorderWidth,
      );
      expect(
        CoreTextAreaStyle.defaultActiveBorderWidth,
        CoreTextFieldStyle.defaultActiveBorderWidth,
      );
    });

    test('merge — right-most non-null wins, null keeps the receiver', () {
      const base = CoreTextFieldStyle(activeBorderWidth: 1.5);
      const over = CoreTextFieldStyle(activeBorderWidth: 3);
      expect(base.merge(over).activeBorderWidth, 3);
      expect(base.merge(const CoreTextFieldStyle()).activeBorderWidth, 1.5);
      expect(over.merge(null).activeBorderWidth, 3);
    });

    test('copyWith replaces only the active width; == and hashCode see it', () {
      const a = CoreTextFieldStyle(borderWidth: 2, activeBorderWidth: 1.5);
      final b = a.copyWith(activeBorderWidth: 3);
      expect(b.activeBorderWidth, 3);
      expect(b.borderWidth, 2);
      expect(a, isNot(b));
      expect(a.hashCode, isNot(b.hashCode));
      expect(a.copyWith(), a);
      // The resting width is a different field, not an alias.
      expect(a.copyWith(borderWidth: 3), isNot(a));
    });
  });

  group('CoreTextFieldStyle — rows and spacing', () {
    test('the icon ladder is 12 · 14 · 16 · 18 · 20 · 24', () {
      const expected = {
        CoreComponentSize.xs: CoreIconSize.size12,
        CoreComponentSize.sm: CoreIconSize.size14,
        CoreComponentSize.md: CoreIconSize.size16,
        CoreComponentSize.lg: CoreIconSize.size18,
        CoreComponentSize.xl: CoreIconSize.size20,
        CoreComponentSize.xl2: CoreIconSize.size24,
      };
      for (final entry in expected.entries) {
        expect(
          CoreTextFieldStyle.defaultsBySize[entry.key]!.iconStyle!.size,
          entry.value,
          reason: '${entry.key}',
        );
      }
    });

    test('6 under the label and 6 over the helper', () {
      expect(
        CoreTextFieldStyle.defaultLabelPadding,
        const CoreEdgeInsets.only(bottom: CoreSpace.space6),
      );
      expect(
        CoreTextFieldStyle.defaultDescriptionPadding,
        const CoreEdgeInsets.only(top: CoreSpace.space6),
      );
    });
  });

  group('CoreTextAreaStyle defaults mirror the TextField rows', () {
    test("the active boundary has the field's name, default and reading", () {
      expect(
        CoreTextAreaStyle.defaultActiveBorderWidth,
        CoreTextFieldStyle.defaultActiveBorderWidth,
      );
      const base = CoreTextAreaStyle(activeBorderWidth: 1.5);
      expect(
        base.merge(const CoreTextAreaStyle(activeBorderWidth: 3)),
        const CoreTextAreaStyle(activeBorderWidth: 3),
      );
      expect(base.merge(const CoreTextAreaStyle()), base);
      expect(base.copyWith(activeBorderWidth: 3).activeBorderWidth, 3);
      expect(base.copyWith(activeBorderWidth: 3), isNot(base));
      expect(
        base.copyWith(activeBorderWidth: 3).hashCode,
        isNot(base.hashCode),
      );
    });

    test("every size row restates the field's icon size", () {
      for (final size in CoreComponentSize.values) {
        expect(
          CoreTextAreaStyle.defaultsBySize[size]!.iconStyle!.size,
          CoreTextFieldStyle.defaultsBySize[size]!.iconStyle!.size,
          reason: '$size',
        );
      }
    });

    test("the value role is the field's role at every size — body-medium "
        'through lg, body-large on xl / xl2', () {
      for (final size in CoreComponentSize.values) {
        expect(
          CoreTextAreaStyle.defaultsBySize[size]!.baseTextStyle!.token,
          CoreTextFieldStyle.defaultsBySize[size]!.baseTextStyle!.token,
          reason: '$size',
        );
      }
      expect(
        CoreTextAreaStyle
            .defaultsBySize[CoreComponentSize.xs]!
            .baseTextStyle!
            .token,
        CoreTextStyles.bodyMedium,
      );
      expect(
        CoreTextAreaStyle
            .defaultsBySize[CoreComponentSize.xl]!
            .baseTextStyle!
            .token,
        CoreTextStyles.bodyLarge,
      );
    });

    test("the area keeps the body role's own 150% line — 21 and 22.5 px", () {
      const scale = CoreTypography.coui;
      double lineOf(CoreComponentSize size) {
        final role = scale.resolve(
          CoreTextAreaStyle.defaultsBySize[size]!.baseTextStyle!,
        );
        return role.fontSize! * role.lineHeight!;
      }

      for (final size in [
        CoreComponentSize.xs,
        CoreComponentSize.sm,
        CoreComponentSize.md,
        CoreComponentSize.lg,
      ]) {
        expect(lineOf(size), 21, reason: '$size');
      }
      expect(lineOf(CoreComponentSize.xl), 22.5);
      expect(lineOf(CoreComponentSize.xl2), 22.5);
    });

    test('6 under the label and 6 over the helper', () {
      expect(
        CoreTextAreaStyle.defaultLabelGapStyle.size,
        CoreSpace.space6,
      );
      expect(
        CoreTextAreaStyle.defaultDescriptionGapStyle.size,
        CoreSpace.space6,
      );
    });
  });

  group('CoreTextAreaStyle.defaultsBySize (#3773)', () {
    // 2026-09-11 재검토 — the ladder was extended to the full six-tier
    // `CoreComponentSize` ("다른 컴포넌트와 통일"). `xl2`'s padding
    // restates `CoreTextFieldStyle.defaultsBySize[.xl2]` verbatim (the
    // two components already share the xs→xl cadence); the icon and the
    // value role restate the field's own row at every size.
    test('covers every CoreComponentSize member', () {
      for (final size in CoreComponentSize.values) {
        expect(
          CoreTextAreaStyle.defaultsBySize[size],
          isNotNull,
          reason:
              'missing size chrome for CoreComponentSize.${size.name} — '
              'every `defaultsBySize[size]!` lookup in the resolvers '
              'assumes full coverage and would crash at runtime',
        );
      }
    });

    test('has exactly one entry per CoreComponentSize member', () {
      expect(
        CoreTextAreaStyle.defaultsBySize.length,
        CoreComponentSize.values.length,
      );
    });
  });

  // `disabled > error` lives in one place both text inputs ask — TextField
  // through `CoreTextFieldVariant.of`, TextArea through
  // `CoreTextAreaVariant.of` — so neither platform's resolver can spell the
  // order differently from the other.
  group('disabled > error — the Core single source', () {
    test('showsErrorChrome is true only for an enabled field with an '
        'error', () {
      expect(
        CoreTextFieldVariant.showsErrorChrome(hasError: true, enabled: true),
        isTrue,
      );
      expect(
        CoreTextFieldVariant.showsErrorChrome(hasError: true, enabled: false),
        isFalse,
        reason: 'a disabled field is disabled first',
      );
      expect(
        CoreTextFieldVariant.showsErrorChrome(hasError: false, enabled: true),
        isFalse,
      );
    });

    test('CoreTextFieldVariant.of keeps the caller variant while '
        'disabled', () {
      expect(
        CoreTextFieldVariant.of(hasError: true),
        CoreTextFieldVariant.error,
      );
      expect(
        CoreTextFieldVariant.of(hasError: true, enabled: false),
        CoreTextFieldVariant.defaultVariant,
      );
      expect(
        CoreTextFieldVariant.of(
          hasError: true,
          enabled: false,
          variant: CoreTextFieldVariant.plain,
        ),
        CoreTextFieldVariant.plain,
      );
      expect(
        CoreTextFieldVariant.of(
          hasError: false,
          variant: CoreTextFieldVariant.plain,
        ),
        CoreTextFieldVariant.plain,
      );
    });

    test('CoreTextAreaVariant.of answers the same order', () {
      expect(
        CoreTextAreaVariant.of(hasError: true),
        CoreTextAreaVariant.error,
      );
      expect(
        CoreTextAreaVariant.of(hasError: true, enabled: false),
        CoreTextAreaVariant.defaultVariant,
      );
      expect(
        CoreTextAreaVariant.of(hasError: false),
        CoreTextAreaVariant.defaultVariant,
      );
    });
  });
}
