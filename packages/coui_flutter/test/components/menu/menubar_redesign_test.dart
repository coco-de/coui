import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

/// What the redesigned `Menubar` paints, read back from the widget tree
/// rather than from the style it was given.
///
/// A token can be wired into the Core defaults and the resolver and still
/// never reach a pixel, so every claim here is a painted `Color`, a
/// `BorderRadius` or a `FontWeight` on a widget that is on screen.
const _kMenus = [
  CoreMenubarMenu(
    label: 'File',
    entries: [CoreMenubarEntry.action(label: 'New')],
  ),
  CoreMenubarMenu(
    label: 'Edit',
    entries: [CoreMenubarEntry.action(label: 'Cut')],
  ),
  CoreMenubarMenu(
    label: 'View',
    entries: [CoreMenubarEntry.action(label: 'Zoom')],
  ),
];

void main() {
  late BuildContext context;

  Future<void> pump(WidgetTester tester, {int? activeIndex}) async {
    await pumpTestApp(
      tester,
      Builder(
        builder: (c) {
          context = c;
          return Menubar(menus: _kMenus, activeIndex: activeIndex);
        },
      ),
    );
    await tester.pump();
  }

  Color resolve(CoreColorToken token) =>
      Theme.of(context).colorScheme.resolve(CoreColor.token(token)).toValue();

  /// The bar's own box — the one decoration around the trigger row that
  /// draws a border (the composed trigger `Button`s draw none).
  BoxDecoration barBox(WidgetTester tester) {
    final boxes = tester
        .widgetList<DecoratedBox>(
          find.ancestor(
            of: find.text('File'),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((b) => b.decoration)
        .whereType<BoxDecoration>()
        .where((d) => d.border != null);
    expect(boxes, hasLength(1));
    return boxes.single;
  }

  FontWeight? weightOf(WidgetTester tester, String label) =>
      tester.widget<Text>(find.text(label)).style?.fontWeight;

  group('the bar', () {
    testWidgets('is the raised face with a quiet hairline and an 8 corner', (
      tester,
    ) async {
      await pump(tester);
      final box = barBox(tester);

      expect(box.color, resolve(CoreColors.surfaceBright));
      final border = box.border! as Border;
      expect(border.top.color, resolve(CoreColors.outlineSubtle));
      expect(border.top.width, 1);
      expect(box.borderRadius, BorderRadius.circular(8));
    });

    for (final (name, core) in [
      ('light', CoreThemePresets.light),
      ('dark', CoreThemePresets.dark),
    ]) {
      testWidgets('keeps a hairline distinct from its face and the page in '
          '$name', (tester) async {
        await pumpTestApp(
          tester,
          theme: ThemeData.fromCore(core),
          Builder(
            builder: (c) {
              context = c;
              return const Menubar(menus: _kMenus);
            },
          ),
        );
        final box = barBox(tester);
        final border = box.border! as Border;

        // The bar's edge has to read against the face inside it and the page
        // outside it — a hairline equal to either would vanish.
        expect(border.top.color, isNot(box.color), reason: name);
        expect(
          border.top.color,
          isNot(resolve(CoreColors.surface)),
          reason: name,
        );
        expect(
          border.top.color,
          resolve(CoreColors.outlineSubtle),
          reason: name,
        );
      });
    }
  });

  group('the trigger labels', () {
    testWidgets('read regular while the bar is at rest', (tester) async {
      await pump(tester);

      for (final label in ['File', 'Edit', 'View']) {
        expect(weightOf(tester, label), FontWeight.w400, reason: label);
      }
    });

    testWidgets('the open trigger reads medium, its siblings stay regular', (
      tester,
    ) async {
      await pump(tester, activeIndex: 0);

      expect(weightOf(tester, 'File'), FontWeight.w500);
      expect(weightOf(tester, 'Edit'), FontWeight.w400);
      expect(weightOf(tester, 'View'), FontWeight.w400);
    });

    testWidgets('a caller-stated label style reaches every trigger', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        const Menubar(
          menus: _kMenus,
          activeIndex: 1,
          menubarStyle: CoreMenubarStyle(
            labelTextStyle: CoreTextStyle(fontWeight: CoreFontWeight.bold),
            openTriggerButtonStyle: CoreButtonStyle(
              labelStyle: CoreTextStyle(fontWeight: CoreFontWeight.semiBold),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(weightOf(tester, 'File'), FontWeight.w700);
      expect(weightOf(tester, 'Edit'), FontWeight.w600);
      expect(weightOf(tester, 'View'), FontWeight.w700);
    });
  });

  group('the open trigger', () {
    /// The fill the trigger's own `Button` paints — read off the box it
    /// draws, so it counts only if the selected state reached the pixel.
    Color? paintedFill(WidgetTester tester, String label) {
      final box = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.widgetWithText(Button, label),
          matching: find.byType(AnimatedContainer),
        ),
      );
      return (box.decoration as BoxDecoration?)?.color;
    }

    testWidgets('wears the softer fill, a resting sibling stays clear', (
      tester,
    ) async {
      await pump(tester, activeIndex: 0);
      // Let the Button's fill transition land before reading it.
      await tester.pump(const Duration(seconds: 1));

      expect(
        paintedFill(tester, 'File'),
        resolve(CoreColors.surfaceContainerHigh),
      );
      // A resting trigger paints the hover colour at zero alpha — clear.
      expect(paintedFill(tester, 'Edit')?.a, 0);
    });

    testWidgets('is one step under the hover fill', (tester) async {
      await pump(tester);
      final row = resolveButton(
        context,
        variant: .menubar,
        size: .xs,
        shape: .rectangle,
      );
      final selected =
          row.decoration.resolve({WidgetState.selected}) as BoxDecoration;
      final hovered =
          row.decoration.resolve({WidgetState.hovered}) as BoxDecoration;

      expect(selected.color, resolve(CoreColors.surfaceContainerHigh));
      expect(hovered.color, resolve(CoreColors.surfaceContainerHighest));
      expect(selected.color, isNot(hovered.color));
    });
  });

  group('what stays', () {
    testWidgets('the triggers keep their padding, height and corner', (
      tester,
    ) async {
      await pump(tester);
      final resolved = resolveMenubar(context, variant: .standard);

      expect(resolved.barPadding, const EdgeInsets.all(4));
      expect(resolved.barBorderWidth, 1);
      expect(
        resolved.triggerButtonStyle.borderRadius,
        CoreMenubarStyle.defaultItemBorderRadius,
      );
      expect(
        resolved.triggerButtonStyle.padding,
        CoreMenubarStyle.defaultItemPadding,
      );
    });
  });
}
