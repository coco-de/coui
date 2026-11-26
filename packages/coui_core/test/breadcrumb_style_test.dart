// Tests for CoreBreadcrumbStyle / CoreBreadcrumbTheme.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const double _kFontLabel = 14;
const _kCoreOnSurface = CoreColor.token(CoreColors.onSurface);

void main() {
  group('CoreBreadcrumbStyle', () {
    test('chain — design system → theme.style → widget', () {
      const designSystem = CoreBreadcrumbStyle(
        itemSeparatorGapStyle: CoreGapStyle(size: 4),
        currentItemColor: _kCoreOnSurface,
        itemTextStyle: CoreTextStyle(fontSize: _kFontLabel),
        separatorIconStyle: CoreIconStyle(size: 16),
      );
      const widgetStyle = CoreBreadcrumbStyle(
        itemSeparatorGapStyle: CoreGapStyle(size: 8),
      );
      final effective = designSystem.merge(widgetStyle);
      expect(effective.itemSeparatorGapStyle?.size, 8);
      expect(effective.currentItemColor, _kCoreOnSurface);
      expect(effective.itemTextStyle?.fontSize, _kFontLabel);
      expect(effective.separatorIconStyle?.size, 16);
    });

    test('equality', () {
      const a = CoreBreadcrumbStyle(
        itemSeparatorGapStyle: CoreGapStyle(size: 8),
      );
      const b = CoreBreadcrumbStyle(
        itemSeparatorGapStyle: CoreGapStyle(size: 8),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('copyWith — itemHoverColor override', () {
      const base = CoreBreadcrumbStyle();
      final updated = base.copyWith(itemHoverColor: _kCoreOnSurface);
      expect(updated.itemHoverColor, _kCoreOnSurface);
      // Other fields untouched.
      expect(updated.itemSeparatorGapStyle, isNull);
      expect(updated.itemColor, isNull);
      expect(updated.currentItemColor, isNull);
    });

    test('equality — itemHoverColor differs', () {
      const a = CoreBreadcrumbStyle(itemHoverColor: _kCoreOnSurface);
      const b = CoreBreadcrumbStyle(itemHoverColor: _kCoreOnSurface);
      const c = CoreBreadcrumbStyle();
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });

    test('merge — itemHoverColor override wins', () {
      const base = CoreBreadcrumbStyle();
      const override = CoreBreadcrumbStyle(itemHoverColor: _kCoreOnSurface);
      final effective = base.merge(override);
      expect(effective.itemHoverColor, _kCoreOnSurface);
    });
  });

  group('CoreBreadcrumbStyle redesign (#5965)', () {
    test('defaults state the redesigned values', () {
      expect(CoreBreadcrumbStyle.defaultItemSeparatorGapStyle.size, 4);
      expect(
        CoreBreadcrumbStyle.defaultItemPadding,
        const CoreEdgeInsets.symmetric(vertical: 2, horizontal: 4),
      );
      expect(
        CoreBreadcrumbStyle.defaultSeparatorColor,
        const CoreColor.token(CoreColors.onSurfaceSubtle),
      );
      expect(
        CoreBreadcrumbStyle.defaultDisabledColor,
        const CoreColor.token(CoreColors.disabledContent),
      );
      // Links are the Regular body role, the current item the Medium label.
      expect(
        CoreBreadcrumbStyle.defaultItemTextStyle.token,
        CoreTextStyles.bodyMedium,
      );
      expect(
        CoreBreadcrumbStyle.defaultCurrentItemTextStyle.token,
        CoreTextStyles.labelLarge,
      );
      // The ring wraps a radius-6 item (ring corner 10), press-shrink off.
      expect(
        CoreBreadcrumbStyle.defaultClickableStyle.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius6),
      );
      expect(CoreBreadcrumbStyle.defaultClickableStyle.pressedScale, 1);
    });

    test('the new fields take part in merge, copyWith and equality', () {
      const a = CoreBreadcrumbStyle(
        disabledColor: _kCoreOnSurface,
        currentItemTextStyle: CoreTextStyle(fontSize: _kFontLabel),
        itemPadding: CoreEdgeInsets.all(8),
      );
      const same = CoreBreadcrumbStyle(
        disabledColor: _kCoreOnSurface,
        currentItemTextStyle: CoreTextStyle(fontSize: _kFontLabel),
        itemPadding: CoreEdgeInsets.all(8),
      );
      expect(a, same);
      expect(a.hashCode, same.hashCode);
      expect(a.copyWith(itemPadding: const CoreEdgeInsets.all(2)), isNot(a));
      expect(
        a.copyWith(disabledColor: const CoreColor.token(CoreColors.primary)),
        isNot(a),
      );
      expect(
        a.copyWith(currentItemTextStyle: const CoreTextStyle(fontSize: 16)),
        isNot(a),
      );

      final merged = a.merge(
        const CoreBreadcrumbStyle(itemPadding: CoreEdgeInsets.all(2)),
      );
      expect(merged.itemPadding, const CoreEdgeInsets.all(2));
      expect(merged.disabledColor, _kCoreOnSurface);
      expect(merged.currentItemTextStyle?.fontSize, _kFontLabel);
    });
  });

  group('CoreBreadcrumbTheme', () {
    test('passes through style', () {
      const style = CoreBreadcrumbStyle(
        itemSeparatorGapStyle: CoreGapStyle(size: 8),
      );
      const theme = CoreBreadcrumbTheme(style: style);
      expect(theme.style, style);
    });
  });
}
