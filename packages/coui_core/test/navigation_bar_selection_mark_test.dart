import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreNavigationSelectionMark', () {
    test('defaults to none, so a bar draws what it drew before', () {
      expect(
        CoreNavigationSelectionMark.defaultSelectionMark,
        CoreNavigationSelectionMark.none,
      );
    });

    test('a dot marks a destination that stacks its label with its icon', () {
      for (final position in CoreNavigationLabelPosition.values) {
        expect(
          CoreNavigationSelectionMark.dot.marksAt(position),
          !position.isHorizontal,
          reason: '$position',
        );
        expect(
          CoreNavigationSelectionMark.none.marksAt(position),
          isFalse,
          reason: '$position',
        );
      }
    });
  });

  group('CoreNavigationBarStyle selection mark slots', () {
    test('the dot is a 4px onSurface badge dot, 6 above the content', () {
      expect(
        CoreNavigationBarStyle.defaultSelectionMarkStyle.dotSize,
        CoreSize.size4,
      );
      expect(
        CoreNavigationBarStyle.defaultSelectionMarkStyle.backgroundColor,
        const CoreColor.token(CoreColors.onSurface),
      );
      expect(
        CoreNavigationBarStyle.defaultSelectionMarkGapStyle.size,
        CoreSpace.space6,
      );
    });

    test('the dot takes the selected label colour', () {
      // A mark in another colour than the label it sits over reads as a
      // second signal; the two say the same thing.
      expect(
        CoreNavigationBarStyle.defaultSelectionMarkStyle.backgroundColor,
        CoreNavigationBarStyle.defaultSelectedLabelTextStyle.color,
      );
      expect(
        CoreNavigationBarStyle
            .glassBarStyle
            .selectionMarkStyle
            ?.backgroundColor,
        CoreNavigationBarStyle.glassBarStyle.selectedLabelTextStyle?.color,
      );
    });

    test('merge folds the nested slots field by field', () {
      const base = CoreNavigationBarStyle(
        selectionMarkStyle: CoreBadgeStyle(dotSize: CoreSize.size6),
        selectionMarkGapStyle: CoreGapStyle(size: CoreSpace.space4),
      );
      const patch = CoreNavigationBarStyle(
        selectionMarkStyle: CoreBadgeStyle(
          backgroundColor: CoreColor.token(CoreColors.primary),
        ),
      );
      final merged = base.merge(patch);
      expect(merged.selectionMarkStyle?.dotSize, CoreSize.size6);
      expect(
        merged.selectionMarkStyle?.backgroundColor,
        const CoreColor.token(CoreColors.primary),
      );
      expect(merged.selectionMarkGapStyle?.size, CoreSpace.space4);
      // A patch that states nothing keeps both slots.
      expect(
        base.merge(const CoreNavigationBarStyle()).selectionMarkStyle,
        base.selectionMarkStyle,
      );
    });

    test('copyWith, == and hashCode carry both slots', () {
      const a = CoreNavigationBarStyle();
      final b = a.copyWith(
        selectionMarkStyle: const CoreBadgeStyle(dotSize: CoreSize.size6),
      );
      final c = a.copyWith(
        selectionMarkGapStyle: const CoreGapStyle(size: CoreSpace.space8),
      );
      expect(b, isNot(a));
      expect(c, isNot(a));
      // Both slots reach the hash too — a theme swap that changes only the
      // dot must not hash like the theme before it.
      expect(b.hashCode, isNot(a.hashCode));
      expect(c.hashCode, isNot(a.hashCode));
      expect(b.selectionMarkStyle?.dotSize, CoreSize.size6);
      expect(c.selectionMarkGapStyle?.size, CoreSpace.space8);
      expect(
        b,
        a.copyWith(
          selectionMarkStyle: const CoreBadgeStyle(dotSize: CoreSize.size6),
        ),
      );
      expect(
        b.hashCode,
        a
            .copyWith(
              selectionMarkStyle: const CoreBadgeStyle(dotSize: CoreSize.size6),
            )
            .hashCode,
      );
    });
  });
}
