// Tests for CoreStepItemStyle — the row's defaults, the status rows, and
// the nested merge / copyWith / equality contract the resolvers rely on.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kSuccess = CoreColor.token(CoreColors.success);
const _kPrimary = CoreColor.token(CoreColors.primary);
const _kOutline = CoreColor.token(CoreColors.outline);
const _kError = CoreColor.token(CoreColors.error);
const _kOnSurface = CoreColor.token(CoreColors.onSurface);
const _kOnSurfaceVariant = CoreColor.token(CoreColors.onSurfaceVariant);
const _kOnSurfaceSubtle = CoreColor.token(CoreColors.onSurfaceSubtle);
const _kOnErrorContainer = CoreColor.token(CoreColors.onErrorContainer);

void main() {
  group('CoreStepItemStyle defaults', () {
    test('a 32 row, 6 above and below, 10 between glyph and title', () {
      expect(CoreStepItemStyle.defaultMinHeight, 32);
      expect(
        CoreStepItemStyle.defaultPadding,
        const CoreEdgeInsets.symmetric(vertical: CoreSpace.space6),
      );
      expect(CoreStepItemStyle.defaultIconTitleGapStyle.size, 10);
      expect(CoreStepItemStyle.defaultTitleTrailingGapStyle.size, 10);
    });

    test('a 16 glyph, a labelLarge title and a labelSmall note', () {
      expect(CoreStepItemStyle.defaultIconStyle.size, 16);
      expect(
        CoreStepItemStyle.defaultTitleStyle.token,
        CoreTextStyles.labelLarge,
      );
      expect(
        CoreStepItemStyle.defaultTrailingStyle.token,
        CoreTextStyles.labelSmall,
      );
    });

    test('one line of the title role and its padding fit the row', () {
      final role = CoreTypography.coui.labelLarge;
      final line = role.fontSize! * role.lineHeight!;
      const padding = CoreStepItemStyle.defaultPadding;
      expect(
        padding.top + line + padding.bottom,
        lessThanOrEqualTo(CoreStepItemStyle.defaultMinHeight),
      );
    });

    test('the default status is todo', () {
      expect(CoreStepStatus.defaultStatus, CoreStepStatus.todo);
    });
  });

  group('CoreStepItemStyle.defaultsByStatus', () {
    test('every status has a row', () {
      expect(
        CoreStepItemStyle.defaultsByStatus.keys,
        unorderedEquals(CoreStepStatus.values),
      );
    });

    test('each row states the glyph, title and note colours', () {
      const rows = CoreStepItemStyle.defaultsByStatus;
      ({CoreColor? icon, CoreColor? title, CoreColor? note}) inks(
        CoreStepStatus s,
      ) => (
        icon: rows[s]!.iconStyle?.color,
        title: rows[s]!.titleStyle?.color,
        note: rows[s]!.trailingStyle?.color,
      );

      expect(
        inks(CoreStepStatus.done),
        (icon: _kSuccess, title: _kOnSurface, note: _kOnSurfaceSubtle),
      );
      expect(
        inks(CoreStepStatus.current),
        (icon: _kPrimary, title: _kOnSurface, note: _kOnSurfaceSubtle),
      );
      expect(
        inks(CoreStepStatus.todo),
        // The not-yet-reached glyph is content, not a border: it reads the
        // content token, so a preset that bends the outline does not move it.
        (
          icon: _kOnSurfaceSubtle,
          title: _kOnSurfaceVariant,
          note: _kOnSurfaceSubtle,
        ),
      );
      expect(
        inks(CoreStepStatus.failed),
        (icon: _kError, title: _kOnSurface, note: _kOnErrorContainer),
      );
    });

    test('a status row over the defaults keeps the role and the size', () {
      final row = CoreStepItemStyle.defaultsByStatus[CoreStepStatus.failed]!;
      final title = CoreStepItemStyle.defaultTitleStyle.merge(row.titleStyle);
      final icon = CoreStepItemStyle.defaultIconStyle.merge(row.iconStyle);
      expect(title.token, CoreTextStyles.labelLarge);
      expect(title.color, _kOnSurface);
      expect(icon.size, 16);
      expect(icon.color, _kError);
    });
  });

  group('CoreStepItemStyle.merge', () {
    test('null other returns this', () {
      const a = CoreStepItemStyle(minHeight: 40);
      expect(identical(a.merge(null), a), isTrue);
    });

    test('scalars: right side wins, nulls keep the receiver', () {
      const base = CoreStepItemStyle(
        minHeight: 32,
        padding: CoreEdgeInsets.all(CoreSpace.space4),
      );
      const other = CoreStepItemStyle(minHeight: 40);
      final merged = base.merge(other);
      expect(merged.minHeight, 40);
      expect(merged.padding, const CoreEdgeInsets.all(CoreSpace.space4));
    });

    test('nested slots merge field by field', () {
      const base = CoreStepItemStyle(
        iconStyle: CoreIconStyle(size: 20),
        titleStyle: CoreTextStyle.token(CoreTextStyles.labelLarge),
        iconTitleGapStyle: CoreGapStyle(size: 8),
      );
      const other = CoreStepItemStyle(
        iconStyle: CoreIconStyle(color: _kError),
        titleStyle: CoreTextStyle(color: _kError),
        iconTitleGapStyle: CoreGapStyle(color: _kError),
      );
      final merged = base.merge(other);
      expect(merged.iconStyle?.size, 20);
      expect(merged.iconStyle?.color, _kError);
      expect(merged.titleStyle?.token, CoreTextStyles.labelLarge);
      expect(merged.titleStyle?.color, _kError);
      expect(merged.iconTitleGapStyle?.size, 8);
      expect(merged.iconTitleGapStyle?.color, _kError);
    });
  });

  group('CoreStepItemStyle copyWith / equality', () {
    const full = CoreStepItemStyle(
      minHeight: 40,
      padding: CoreEdgeInsets.all(CoreSpace.space4),
      iconTitleGapStyle: CoreGapStyle(size: 8),
      titleTrailingGapStyle: CoreGapStyle(size: 12),
      iconStyle: CoreIconStyle(size: 20),
      titleStyle: CoreTextStyle(color: _kError),
      trailingStyle: CoreTextStyle(color: _kOutline),
    );

    test('copyWith on an empty style rebuilds every field', () {
      expect(
        const CoreStepItemStyle().copyWith(
          minHeight: full.minHeight,
          padding: full.padding,
          iconTitleGapStyle: full.iconTitleGapStyle,
          titleTrailingGapStyle: full.titleTrailingGapStyle,
          iconStyle: full.iconStyle,
          titleStyle: full.titleStyle,
          trailingStyle: full.trailingStyle,
        ),
        equals(full),
      );
    });

    test('every field takes part in equality and hashCode', () {
      final variants = [
        full.copyWith(minHeight: 48),
        full.copyWith(padding: const CoreEdgeInsets.all(CoreSpace.space8)),
        full.copyWith(iconTitleGapStyle: const CoreGapStyle(size: 4)),
        full.copyWith(titleTrailingGapStyle: const CoreGapStyle(size: 4)),
        full.copyWith(iconStyle: const CoreIconStyle(size: 24)),
        full.copyWith(titleStyle: const CoreTextStyle(color: _kSuccess)),
        full.copyWith(trailingStyle: const CoreTextStyle(color: _kSuccess)),
      ];
      for (final v in variants) {
        expect(v, isNot(equals(full)));
        expect(v.hashCode, isNot(full.hashCode));
      }
    });
  });

  group('CoreStepItemTheme', () {
    test('equal status maps compare and hash alike', () {
      const a = CoreStepItemTheme(
        statusStyles: {
          CoreStepStatus.failed: CoreStepItemStyle(
            iconStyle: CoreIconStyle(color: _kPrimary),
          ),
        },
      );
      const b = CoreStepItemTheme(
        statusStyles: {
          CoreStepStatus.failed: CoreStepItemStyle(
            iconStyle: CoreIconStyle(color: _kPrimary),
          ),
        },
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(const CoreStepItemTheme())));
    });

    test('CoreComponentTheme carries the stepItem slot', () {
      const stepItem = CoreStepItemTheme(
        style: CoreStepItemStyle(minHeight: 40),
      );
      const a = CoreComponentTheme(stepItem: stepItem);
      expect(a.stepItem, stepItem);
      expect(a, isNot(equals(const CoreComponentTheme())));
      expect(const CoreComponentTheme().mergeWith(a).stepItem, stepItem);
      expect(const CoreComponentTheme().copyWith(stepItem: stepItem), a);
    });
  });
}
