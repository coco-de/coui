import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreFileInputStyle redesign defaults', () {
    test('the drop zone takes the panel corner', () {
      expect(
        CoreFileInputStyle.defaultBorderRadius,
        const CoreBorderRadius.all(CoreRadiusRole.panel),
      );
    });

    test(
      'the dashes run 6 on / 4 off at 1px, in the drop zone own rhythm',
      () {
        expect(CoreFileInputStyle.defaultDashLength, 6);
        expect(CoreFileInputStyle.defaultDashSpacing, 4);
        expect(CoreFileInputStyle.defaultBorderWidth, 1);
        // The shared baseline other dashed borders read is not moved.
        expect(CoreDashedBorder.dashLength, 3);
        expect(CoreDashedBorder.dashGap, 2);
      },
    );

    test('the idle edge is outlineVariant and a drag over it is primary', () {
      expect(
        CoreFileInputStyle.defaultBorderColor,
        const CoreColor.token(CoreColors.outlineVariant),
      );
      expect(
        CoreFileInputStyle.defaultDragOverBorderColor,
        const CoreColor.token(CoreColors.primary),
      );
    });

    test('the zone pads 32 above and below, 24 at the sides', () {
      expect(
        CoreFileInputStyle.defaultPadding,
        const CoreEdgeInsets.symmetric(
          vertical: CoreSpace.space32,
          horizontal: CoreSpace.space24,
        ),
      );
    });

    test('icon box 48 round, 24 glyph, 12 -> text(4) -> 16 -> buttons', () {
      expect(CoreFileInputStyle.defaultIconBoxSize, 48);
      expect(
        CoreFileInputStyle.defaultIconBoxBorderRadius,
        const CoreBorderRadius.all(CoreRadius.radius9999),
      );
      expect(CoreFileInputStyle.defaultIconStyle.size, 24);
      expect(CoreFileInputStyle.defaultItemSpacing, 12);
      expect(CoreFileInputStyle.defaultTextSpacing, 4);
      expect(CoreFileInputStyle.defaultActionSpacing, 16);
      expect(
        CoreFileInputStyle.defaultIconBoxColor,
        const CoreColor.token(CoreColors.surfaceContainerHigh),
      );
      expect(
        CoreFileInputStyle.defaultDragActiveIconBoxColor,
        const CoreColor.token(CoreColors.primaryContainer),
      );
    });

    test(
      'the drag-active icon colour is primary and merges, copies, compares',
      () {
        expect(
          CoreFileInputStyle.defaultDragActiveIconColor,
          const CoreColor.token(CoreColors.primary),
        );
        const custom = CoreColor.token(CoreColors.error);
        const a = CoreFileInputStyle(dragActiveIconColor: custom);
        expect(a.merge(const CoreFileInputStyle()).dragActiveIconColor, custom);
        expect(
          const CoreFileInputStyle().merge(a).dragActiveIconColor,
          custom,
        );
        expect(a.copyWith().dragActiveIconColor, custom);
        expect(
          const CoreFileInputStyle().copyWith(dragActiveIconColor: custom),
          a,
        );
        expect(a.hashCode, isNot(const CoreFileInputStyle().hashCode));
        expect(a, isNot(const CoreFileInputStyle()));
      },
    );

    test('the icon box fields merge, copy and compare', () {
      const a = CoreFileInputStyle(iconBoxSize: 40, textSpacing: 2);
      final b = a.merge(const CoreFileInputStyle(actionSpacing: 20));
      expect(b.iconBoxSize, 40);
      expect(b.actionSpacing, 20);
      expect(b.copyWith(iconBoxSize: 56).iconBoxSize, 56);
      expect(a, isNot(a.copyWith(iconBoxColor: CoreColor.transparent)));
    });
  });

  group('CoreFileInputStyle disabled tokens', () {
    test('disabled fill, edge and content are the disabled tokens', () {
      expect(
        CoreFileInputStyle.defaultDisabledBackgroundColor,
        const CoreColor.token(CoreColors.disabledContainer),
      );
      expect(
        CoreFileInputStyle.defaultDisabledIconBoxColor,
        const CoreColor.token(CoreColors.disabledContainer),
      );
      expect(
        CoreFileInputStyle.defaultDisabledBorderColor,
        const CoreColor.token(CoreColors.disabledOutline),
      );
      expect(
        CoreFileInputStyle.defaultDisabledContentColor,
        const CoreColor.token(CoreColors.disabledContent),
      );
    });

    test('the disabled fields survive merge / copyWith / == / hashCode', () {
      const fill = CoreColor.token(CoreColors.tertiary);
      const box = CoreColor.token(CoreColors.secondary);
      const a = CoreFileInputStyle(disabledBackgroundColor: fill);
      final merged = a.merge(
        const CoreFileInputStyle(disabledIconBoxColor: box),
      );
      expect(merged.disabledBackgroundColor, fill);
      expect(merged.disabledIconBoxColor, box);
      expect(a.copyWith(disabledIconBoxColor: box), merged);
      expect(a.copyWith(disabledIconBoxColor: box).hashCode, merged.hashCode);
      expect(a, isNot(merged));
      expect(
        a,
        isNot(const CoreFileInputStyle(disabledIconBoxColor: box)),
      );
    });
  });
}
