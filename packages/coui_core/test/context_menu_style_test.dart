// Tests for CoreContextMenuStyle (Epic #2676 — independent from dropdown).

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kRadius8 = CoreBorderRadius.all(8);
const _kRadius16 = CoreBorderRadius.all(16);
const _kPadH8 = CoreEdgeInsets.symmetric(horizontal: 8);
const _kPadH16 = CoreEdgeInsets.symmetric(horizontal: 16);

void main() {
  group('CoreContextMenuStyle.merge', () {
    test('null other returns this', () {
      const a = CoreContextMenuStyle(
        menuStyle: CoreMenuStyle(
          itemStyle: CoreMenuItemStyle(padding: _kPadH8),
        ),
      );
      expect(identical(a.merge(null), a), isTrue);
    });

    test('nested menuStyle merges recursively', () {
      const base = CoreContextMenuStyle(
        menuStyle: CoreMenuStyle(
          popupStyle: CorePopupStyle(borderRadius: _kRadius8),
          itemStyle: CoreMenuItemStyle(padding: _kPadH8),
        ),
      );
      const override = CoreContextMenuStyle(
        menuStyle: CoreMenuStyle(
          popupStyle: CorePopupStyle(borderRadius: _kRadius16),
        ),
      );
      final merged = base.merge(override);
      // radius from override, item padding from base.
      expect(merged.menuStyle?.popupStyle?.borderRadius, _kRadius16);
      expect(merged.menuStyle?.itemStyle?.padding, _kPadH8);
    });

    test('null menuStyle on base inherits from override', () {
      const base = CoreContextMenuStyle();
      const override = CoreContextMenuStyle(
        menuStyle: CoreMenuStyle(
          itemStyle: CoreMenuItemStyle(padding: _kPadH16),
        ),
      );
      expect(
        base.merge(override).menuStyle?.itemStyle?.padding,
        _kPadH16,
      );
    });
  });

  group('CoreContextMenuStyle.copyWith / equality', () {
    test('copyWith replaces the whole slot', () {
      const base = CoreContextMenuStyle(
        menuStyle: CoreMenuStyle(
          popupStyle: CorePopupStyle(borderRadius: _kRadius8),
        ),
      );
      final copy = base.copyWith(
        menuStyle: const CoreMenuStyle(
          itemStyle: CoreMenuItemStyle(padding: _kPadH16),
        ),
      );
      expect(copy.menuStyle?.itemStyle?.padding, _kPadH16);
      expect(copy.menuStyle?.popupStyle, isNull);
    });

    test('same menuStyle → equal; different → not equal', () {
      const a = CoreContextMenuStyle(
        menuStyle: CoreMenuStyle(
          itemStyle: CoreMenuItemStyle(padding: _kPadH8),
        ),
      );
      const b = CoreContextMenuStyle(
        menuStyle: CoreMenuStyle(
          itemStyle: CoreMenuItemStyle(padding: _kPadH8),
        ),
      );
      const c = CoreContextMenuStyle(
        menuStyle: CoreMenuStyle(
          itemStyle: CoreMenuItemStyle(padding: _kPadH16),
        ),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });
  });

  group('CoreContextMenuStyle lift fields', () {
    const cast = <CoreShadowLayer>[
      (
        offsetX: 0,
        offsetY: 8,
        blurRadius: 24,
        spreadRadius: 2,
        opacity: 0.2,
        inset: false,
      ),
    ];
    const full = CoreContextMenuStyle(
      liftScale: 1.1,
      liftDuration: Duration(milliseconds: 200),
      liftDimOpacity: 0.35,
      liftCast: cast,
      liftRadius: _kRadius8,
      retractScale: 0.5,
    );

    test('a style states nothing by default', () {
      const none = CoreContextMenuStyle();
      expect(none.liftScale, isNull);
      expect(none.liftDuration, isNull);
      expect(none.liftDimOpacity, isNull);
      expect(none.liftCast, isNull);
      expect(none.liftRadius, isNull);
      expect(none.retractScale, isNull);
    });

    test('the defaults are the numbers the lift shipped with', () {
      expect(CoreContextMenuStyle.defaultLiftScale, 1.04);
      expect(
        CoreContextMenuStyle.defaultLiftDuration,
        const Duration(milliseconds: CoreDuration.moderate),
      );
      expect(CoreContextMenuStyle.defaultLiftDimOpacity, CoreOpacity.opacity20);
      expect(CoreContextMenuStyle.defaultLiftCast, CoreShadow.lg);
      expect(
        CoreContextMenuStyle.defaultLiftRadius,
        const CoreBorderRadius.all(CoreRadiusRole.surface),
      );
      expect(CoreContextMenuStyle.defaultRetractScale, 0.3);
    });

    test('merge: the other style wins field by field', () {
      const base = CoreContextMenuStyle(
        liftScale: 1.2,
        liftDuration: Duration(milliseconds: 100),
        liftDimOpacity: 0.1,
        liftCast: CoreShadow.md,
        liftRadius: _kRadius16,
        retractScale: 0.9,
      );
      final merged = base.merge(full);
      expect(merged, full);

      // A field the other style leaves out keeps the base's.
      final partial = base.merge(const CoreContextMenuStyle(liftScale: 1.5));
      expect(partial.liftScale, 1.5);
      expect(partial.liftDuration, const Duration(milliseconds: 100));
      expect(partial.liftDimOpacity, 0.1);
      expect(partial.liftCast, CoreShadow.md);
      expect(partial.liftRadius, _kRadius16);
      expect(partial.retractScale, 0.9);
    });

    test('merge: each field is independent of the others', () {
      const empty = CoreContextMenuStyle();
      expect(
        empty.merge(const CoreContextMenuStyle(liftScale: 1.3)).liftScale,
        1.3,
      );
      expect(
        empty
            .merge(
              const CoreContextMenuStyle(
                liftDuration: Duration(milliseconds: 90),
              ),
            )
            .liftDuration,
        const Duration(milliseconds: 90),
      );
      expect(
        empty
            .merge(const CoreContextMenuStyle(liftDimOpacity: 0.4))
            .liftDimOpacity,
        0.4,
      );
      expect(
        empty.merge(const CoreContextMenuStyle(liftCast: cast)).liftCast,
        cast,
      );
      expect(
        empty
            .merge(const CoreContextMenuStyle(liftRadius: _kRadius8))
            .liftRadius,
        _kRadius8,
      );
      expect(
        empty.merge(const CoreContextMenuStyle(retractScale: 0.2)).retractScale,
        0.2,
      );
    });

    test('copyWith replaces only the field it is given', () {
      final copy = full.copyWith(liftScale: 1.3);
      expect(copy.liftScale, 1.3);
      expect(copy.liftDuration, full.liftDuration);
      expect(copy.liftDimOpacity, full.liftDimOpacity);
      expect(copy.liftCast, full.liftCast);
      expect(copy.liftRadius, full.liftRadius);
      expect(copy.retractScale, full.retractScale);
      expect(
        full
            .copyWith(liftDuration: const Duration(milliseconds: 1))
            .liftDuration,
        const Duration(milliseconds: 1),
      );
      expect(full.copyWith(liftDimOpacity: 0.9).liftDimOpacity, 0.9);
      expect(full.copyWith(liftCast: CoreShadow.xl).liftCast, CoreShadow.xl);
      expect(full.copyWith(liftRadius: _kRadius16).liftRadius, _kRadius16);
      expect(full.copyWith(retractScale: 0.8).retractScale, 0.8);
    });

    test(
      'equal styles are equal and hash alike, a cast compared layer by layer',
      () {
        // Built separately, so the lists are different objects.
        final other = CoreContextMenuStyle(
          liftScale: 1.1,
          liftDuration: const Duration(milliseconds: 200),
          liftDimOpacity: 0.35,
          liftCast: List<CoreShadowLayer>.of(cast),
          liftRadius: _kRadius8,
          retractScale: 0.5,
        );
        expect(other, full);
        expect(other.hashCode, full.hashCode);
      },
    );

    test('a difference in any one field makes the styles unequal', () {
      final variants = <String, CoreContextMenuStyle>{
        'liftScale': full.copyWith(liftScale: 1.2),
        'liftDuration': full.copyWith(
          liftDuration: const Duration(milliseconds: 201),
        ),
        'liftDimOpacity': full.copyWith(liftDimOpacity: 0.36),
        'liftCast': full.copyWith(liftCast: CoreShadow.md),
        'liftRadius': full.copyWith(liftRadius: _kRadius16),
        'retractScale': full.copyWith(retractScale: 0.51),
      };
      for (final entry in variants.entries) {
        expect(entry.value, isNot(full), reason: entry.key);
      }
      // A stated-but-empty cast is not the same as no cast stated.
      expect(
        const CoreContextMenuStyle(liftCast: []),
        isNot(const CoreContextMenuStyle()),
      );
    });
  });

  group('CoreContextMenuTheme', () {
    test('style passes through; null style', () {
      const style = CoreContextMenuStyle(
        menuStyle: CoreMenuStyle(
          itemStyle: CoreMenuItemStyle(padding: _kPadH8),
        ),
      );
      expect(const CoreContextMenuTheme(style: style).style, style);
      expect(const CoreContextMenuTheme().style, isNull);
    });

    test('equality', () {
      const a = CoreContextMenuTheme(
        style: CoreContextMenuStyle(menuStyle: CoreMenuStyle()),
      );
      const b = CoreContextMenuTheme(
        style: CoreContextMenuStyle(menuStyle: CoreMenuStyle()),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });
}
