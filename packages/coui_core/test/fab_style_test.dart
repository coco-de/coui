// Tests for CoreFabStyle — #3773.
//
// Scope: the `defaultsBySize` regression net only (issue #3773's
// completion definition). Before this file, CoreFabStyle had zero
// tests pinning `defaultsBySize` coverage — a `CoreFabSize` member
// could be added without a matching entry and the only signal would be
// a runtime crash the first time some resolver hit
// `defaultsBySize[size]!` (a Map lookup, not a `switch`, so Dart's
// exhaustiveness checker never sees it).

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreFabStyle.defaultsBySize (#3773)', () {
    test('covers every CoreFabSize member', () {
      for (final size in CoreFabSize.values) {
        expect(
          CoreFabStyle.defaultsBySize[size],
          isNotNull,
          reason:
              'missing size chrome for CoreFabSize.${size.name} — every '
              '`defaultsBySize[size]!` lookup in the resolvers assumes '
              'full coverage and would crash at runtime',
        );
      }
    });

    test('has exactly one entry per CoreFabSize member', () {
      // Guards the other direction: a stale entry left behind after a
      // member is removed from CoreFabSize.
      expect(CoreFabStyle.defaultsBySize.length, CoreFabSize.values.length);
    });
  });

  group('CoreFabStyle menu panel', () {
    const panel = CoreFabStyle.defaultPopupStyle;

    // The Fab states only the width band and the gap; the rest of the card
    // is the `Popup`'s own default, so read each field the way the popup
    // resolver does (`panel.X ?? CorePopupStyle.defaultX`).
    test(
      'draws the floating card: surface-bright, outline-variant, panel, lg',
      () {
        expect(
          panel.backgroundColor ?? CorePopupStyle.defaultBackgroundColor,
          const CoreColor.token(CoreColors.surfaceBright),
        );
        expect(
          panel.borderColor ?? CorePopupStyle.defaultBorderColor,
          const CoreColor.token(CoreColors.outlineVariant),
        );
        expect(
          panel.borderWidth ?? CorePopupStyle.defaultBorderWidth,
          CoreStrokeWidth.stroke1,
        );
        expect(
          panel.borderRadius ?? CorePopupStyle.defaultBorderRadius,
          const CoreBorderRadius.all(CoreRadiusRole.panel),
        );
        expect(
          panel.boxShadow ?? CorePopupStyle.defaultBoxShadow,
          CoreShadow.lg,
        );
        expect(panel.spacing, CoreSpace.space2);
      },
    );

    test('restates none of the Popup card defaults (partial forward)', () {
      expect(panel.backgroundColor, isNull);
      expect(panel.borderColor, isNull);
      expect(panel.borderWidth, isNull);
      expect(panel.borderRadius, isNull);
      expect(panel.boxShadow, isNull);
    });

    test('states the Popup list inset 6, not the content 16', () {
      expect(panel.padding, CorePopupStyle.defaultListPadding);
      expect(panel.padding, const CoreEdgeInsets.all(CoreSpace.space6));
      expect(panel.padding, isNot(CorePopupStyle.defaultPadding));
    });

    test('is content-driven between layout/160 and layout/280', () {
      expect(panel.minWidth, CoreLayout.layout160);
      expect(panel.minWidth, 160);
      expect(panel.maxWidth, CoreLayout.layout280);
      expect(panel.maxWidth, 280);
    });

    test('is its own panel, not an alias of the Menu panel', () {
      expect(panel, isNot(CoreMenuStyle.defaultPopupStyle));
      expect(
        panel.minWidth,
        lessThan(CoreMenuStyle.defaultPopupStyle.minWidth!),
      );
    });
  });

  group('CoreFabStyle action rows', () {
    test('are MenuItem rows on the touch-target rung', () {
      expect(CoreFabContract.actionItemSize, CoreMenuItemSize.lg);
      final row =
          CoreMenuItemStyle.defaultsBySize[CoreFabContract.actionItemSize]!;
      expect(row.minHeight, CoreControlSize.heightLg);
      expect(row.minHeight, 48);
    });

    test('pin only the hosted corner — 8, the corner of every list row', () {
      expect(
        CoreFabStyle.defaultActionItemStyle,
        const CoreMenuItemStyle(
          borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
        ),
      );
      final panelCorner =
          (CoreFabStyle.defaultPopupStyle.borderRadius ??
                  CorePopupStyle.defaultBorderRadius)
              .topLeft;
      final panelPadding =
          (CoreFabStyle.defaultPopupStyle.padding ??
                  CorePopupStyle.defaultPadding)
              .left;
      expect(panelCorner, 12);
      expect(panelPadding, 6);
      expect(CoreFabStyle.defaultActionItemStyle.borderRadius!.topLeft, 8);
      // The row never rounds past the panel that holds it.
      expect(
        CoreFabStyle.defaultActionItemStyle.borderRadius!.topLeft,
        lessThan(panelCorner),
      );
    });

    test('actionItemStyle merges recursively and survives copyWith', () {
      const base = CoreFabStyle(
        actionItemStyle: CoreMenuItemStyle(minHeight: 56),
      );
      const patch = CoreFabStyle(
        actionItemStyle: CoreMenuItemStyle(
          borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
        ),
      );
      final merged = base.merge(patch);
      expect(merged.actionItemStyle!.minHeight, 56);
      expect(
        merged.actionItemStyle!.borderRadius,
        patch.actionItemStyle!.borderRadius,
      );
      expect(base.copyWith(diameter: 40).actionItemStyle, base.actionItemStyle);
      expect(base == base.copyWith(), isTrue);
      expect(base == patch, isFalse);
      expect(base.hashCode == base.copyWith().hashCode, isTrue);
    });
  });

  // The Button-row fields are deprecated, not removed: they still reach the
  // row, folded into a MenuItem style under the new slot.
  group('CoreFabStyle deprecated Button-row fields', () {
    test('fold into effectiveActionItemStyle', () {
      const style = CoreFabStyle(
        actionButtonStyle: CoreButtonStyle(
          padding: CoreEdgeInsets.all(CoreSpace.space8),
          borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
          iconLabelGapStyle: CoreGapStyle(size: CoreSpace.space4),
          height: 56,
          backgroundColor: CoreColor.token(CoreColors.primary),
        ),
        actionIconStyle: CoreIconStyle(size: CoreIconSize.size20),
        actionLabelTextStyle: CoreTextStyle.token(CoreTextStyles.labelSmall),
      );
      final row = style.effectiveActionItemStyle!;
      expect(row.padding, const CoreEdgeInsets.all(CoreSpace.space8));
      expect(row.borderRadius, const CoreBorderRadius.all(CoreRadius.radius4));
      expect(row.contentGapStyle, const CoreGapStyle(size: CoreSpace.space4));
      expect(row.minHeight, 56);
      expect(row.backgroundColor, const CoreColor.token(CoreColors.primary));
      expect(row.leadingIconStyle!.size, CoreIconSize.size20);
      expect(
        row.labelStyle,
        const CoreTextStyle.token(CoreTextStyles.labelSmall),
      );
    });

    test('lose to actionItemStyle field by field', () {
      const style = CoreFabStyle(
        actionButtonStyle: CoreButtonStyle(
          padding: CoreEdgeInsets.all(CoreSpace.space8),
          borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
        ),
        actionItemStyle: CoreMenuItemStyle(
          borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
        ),
      );
      final row = style.effectiveActionItemStyle!;
      expect(row.borderRadius, const CoreBorderRadius.all(CoreRadius.radius8));
      expect(row.padding, const CoreEdgeInsets.all(CoreSpace.space8));
    });

    test('let actionIconStyle own the glyph size, as the Button rows did', () {
      const style = CoreFabStyle(
        actionButtonStyle: CoreButtonStyle(
          leadingIconStyle: CoreIconStyle(
            size: CoreIconSize.size16,
            color: CoreColor.token(CoreColors.error),
          ),
        ),
        actionIconStyle: CoreIconStyle(size: CoreIconSize.size28),
      );
      final icon = style.effectiveActionItemStyle!.leadingIconStyle!;
      expect(icon.size, CoreIconSize.size28);
      expect(icon.color, const CoreColor.token(CoreColors.error));
    });

    test('pass actionItemStyle through untouched when unset', () {
      const item = CoreMenuItemStyle(minHeight: 60);
      expect(
        const CoreFabStyle(actionItemStyle: item).effectiveActionItemStyle,
        item,
      );
      expect(const CoreFabStyle().effectiveActionItemStyle, isNull);
    });

    test('take part in merge, copyWith and equality', () {
      const a = CoreFabStyle(actionIconStyle: CoreIconStyle(size: 20));
      const b = CoreFabStyle(actionIconStyle: CoreIconStyle(size: 28));
      expect(a == b, isFalse);
      expect(a.merge(b).actionIconStyle!.size, 28);
      expect(a.copyWith(diameter: 40).actionIconStyle, a.actionIconStyle);
    });
  });

  group('CoreFabStyle menu ladder — the menu grows with the circle', () {
    // size: (gap, panel inset, panel min width, row min height, row inset,
    // icon, icon-label gap, label role)
    const ladder = {
      CoreFabSize.mini: (12, 8, 160, 48, 8, 20, 8, CoreTextStyles.labelLarge),
      CoreFabSize.regular: (12, 8, 176, 48, 8, 20, 10, CoreTextStyles.labelXl),
      CoreFabSize.large: (16, 10, 224, 56, 10, 24, 12, CoreTextStyles.labelXl2),
    };
    final base =
        CoreMenuItemStyle.defaultsBySize[CoreFabContract.actionItemSize]!;

    for (final MapEntry(key: size, value: expected) in ladder.entries) {
      test('${size.name} states its menu values', () {
        final (gap, inset, width, height, rowInset, icon, content, role) =
            expected;
        final row = CoreFabStyle.defaultsBySize[size]!;
        final panel = CoreFabStyle.defaultPopupStyle.merge(row.popupStyle);
        final item = base.merge(
          CoreFabStyle.defaultActionItemStyle.merge(row.actionItemStyle),
        );

        expect(row.spacing, gap);
        expect(panel.padding, CoreEdgeInsets.all(inset.toDouble()));
        expect(panel.minWidth, width);
        expect(panel.maxWidth, CoreLayout.layout280);
        expect(panel.spacing, CoreSpace.space2);
        expect(item.minHeight, height);
        expect(item.minHeight, greaterThanOrEqualTo(48));
        expect(item.padding!.left, rowInset);
        expect(item.padding!.right, rowInset);
        expect(item.padding!.top, CoreSpace.space12);
        expect(item.leadingIconStyle!.size, icon);
        expect(item.contentGapStyle!.size, content);
        expect(item.labelStyle, CoreTextStyle.token(role));
        expect(item.borderRadius!.topLeft, CoreRadius.radius8);
      });
    }
  });
}
