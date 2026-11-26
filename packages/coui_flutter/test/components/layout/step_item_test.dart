// Pins what a StepItem row paints, read off the rendered widgets: the glyph
// each status draws and the colour it reaches the icon with, the title and
// trailing colours, the 32 row, the one-line title and the pinned note.

import 'dart:math' as math;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

const double _kRowWidth = 320;

material.Widget _app(
  material.Widget child, {
  CoreComponentTheme? componentTheme,
}) => material.MaterialApp(
  home: Theme(
    data: ThemeData(coreComponentTheme: componentTheme),
    child: Center(
      child: SizedBox(width: _kRowWidth, child: child),
    ),
  ),
);

/// The colour [token] paints in the scheme the row was built under.
Color _paint(WidgetTester tester, CoreColorToken token) => Theme.of(
  tester.element(find.byType(StepItem)),
).colorScheme.resolve(CoreColor.token(token)).toValue();

/// The colour and size the row's glyph reaches the screen with — the icon
/// resolver's answer for the style the row handed it.
ResolvedIcon _glyph(WidgetTester tester) {
  final icon = tester.widget<Icon>(find.byType(Icon));
  return resolveIcon(
    tester.element(find.byType(Icon)),
    icon: icon.icon,
    data: null,
    widgetStyle: icon.iconStyle,
  );
}

Text _text(WidgetTester tester, String data) =>
    tester.widget<Text>(find.text(data));

void main() {
  group('StepItem status', () {
    final expected =
        <
          CoreStepStatus,
          ({
            IconName glyph,
            CoreColorToken icon,
            CoreColorToken title,
            CoreColorToken note,
          })
        >{
          CoreStepStatus.done: (
            glyph: LucideIcons.circleCheck,
            icon: CoreColors.success,
            title: CoreColors.onSurface,
            note: CoreColors.onSurfaceSubtle,
          ),
          CoreStepStatus.current: (
            glyph: LucideIcons.circleDot,
            icon: CoreColors.primary,
            title: CoreColors.onSurface,
            note: CoreColors.onSurfaceSubtle,
          ),
          CoreStepStatus.todo: (
            glyph: LucideIcons.circle,
            icon: CoreColors.outline,
            title: CoreColors.onSurfaceVariant,
            note: CoreColors.onSurfaceSubtle,
          ),
          CoreStepStatus.failed: (
            glyph: LucideIcons.circleX,
            icon: CoreColors.error,
            title: CoreColors.onSurface,
            note: CoreColors.onErrorContainer,
          ),
        };

    for (final MapEntry(key: status, value: want) in expected.entries) {
      testWidgets('${status.name} draws its glyph and colours', (
        tester,
      ) async {
        await tester.pumpWidget(
          _app(StepItem(title: 'Build', status: status, trailing: '12s')),
        );

        expect(tester.widget<Icon>(find.byType(Icon)).icon, want.glyph);
        final glyph = _glyph(tester);
        expect(glyph.color, _paint(tester, want.icon));
        expect(glyph.size, 16);
        expect(_text(tester, 'Build').style?.color, _paint(tester, want.title));
        expect(_text(tester, '12s').style?.color, _paint(tester, want.note));
      });
    }
  });

  group('StepItem layout', () {
    testWidgets('a one-line row is 32 tall', (tester) async {
      await tester.pumpWidget(
        _app(const StepItem(title: 'Build', trailing: '12s')),
      );

      expect(tester.getSize(find.byType(StepItem)).height, 32);
    });

    testWidgets('the title is one line with an ellipsis', (tester) async {
      await tester.pumpWidget(_app(const StepItem(title: 'Build')));

      final title = _text(tester, 'Build');
      expect(title.maxLines, 1);
      expect(title.overflow, TextOverflow.ellipsis);
    });

    testWidgets('the trailing note pins to the end of the row', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(const StepItem(title: 'Build', trailing: '12s')),
      );

      final row = tester.getRect(find.byType(StepItem));
      expect(tester.getRect(find.text('12s')).right, row.right);
    });

    testWidgets('in a right-to-left locale the note pins to the left', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const Directionality(
            textDirection: TextDirection.rtl,
            child: StepItem(title: 'Build', trailing: '12s'),
          ),
        ),
      );

      final row = tester.getRect(find.byType(StepItem));
      expect(tester.getRect(find.text('12s')).left, row.left);
      expect(tester.getRect(find.byType(Icon)).right, row.right);
    });

    testWidgets('a long title is cut before it reaches the note', (
      tester,
    ) async {
      const long =
          'A step title long enough that it cannot fit the row it sits in';
      await tester.pumpWidget(
        _app(const StepItem(title: long, trailing: '12s')),
      );

      final title = tester.getRect(find.text(long));
      final note = tester.getRect(find.text('12s'));
      // The title ends before the note starts, the title/trailing gap (10)
      // between them.
      expect(note.left - title.right, 10);
      expect(tester.getSize(find.byType(StepItem)).height, 32);
    });

    testWidgets('with no note the row draws the glyph and the title only', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const StepItem(title: 'Build')));

      expect(find.byType(Text), findsOneWidget);
      expect(find.byType(Gap), findsOneWidget);
    });
  });

  group('StepItem overrides', () {
    testWidgets('a theme status row recolours that status only', (
      tester,
    ) async {
      const theme = CoreComponentTheme(
        stepItem: CoreStepItemTheme(
          statusStyles: {
            CoreStepStatus.failed: CoreStepItemStyle(
              iconStyle: CoreIconStyle(
                color: CoreColor.token(CoreColors.warning),
              ),
            ),
          },
        ),
      );
      await tester.pumpWidget(
        _app(
          const StepItem(title: 'Deploy', status: CoreStepStatus.failed),
          componentTheme: theme,
        ),
      );
      expect(_glyph(tester).color, _paint(tester, CoreColors.warning));

      await tester.pumpWidget(
        _app(
          const StepItem(title: 'Deploy', status: CoreStepStatus.done),
          componentTheme: theme,
        ),
      );
      expect(_glyph(tester).color, _paint(tester, CoreColors.success));
    });

    testWidgets('withStyle patches a colour and keeps the role and size', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const StepItem(title: 'Build').withStyle(
            const CoreStepItemStyle(
              titleStyle: CoreTextStyle(
                color: CoreColor.token(CoreColors.error),
              ),
              minHeight: 40,
            ),
          ),
        ),
      );

      final title = _text(tester, 'Build');
      expect(title.style?.color, _paint(tester, CoreColors.error));
      // The role (labelLarge, 14) survives the colour-only patch.
      expect(title.style?.fontSize, 14);
      expect(tester.getSize(find.byType(StepItem)).height, 40);
    });
  });
  group('StepItem under a density', () {
    // The padding (6) and the glyph gap (10) are spacing, so the density
    // moves them a step on the 4 grid; the 32 row is the row's own and does
    // not move — it holds compact's shorter content and spacious' taller
    // content grows past it.
    for (final (density, padding, gap, grows) in [
      (CoreDensity.compact, 4.0, 8.0, false),
      (CoreDensity.standard, 6.0, 10.0, false),
      (CoreDensity.spacious, 8.0, 12.0, true),
    ]) {
      testWidgets(
        '${density.name}: padding $padding, gap $gap, '
        '${grows ? 'row grows past' : 'row holds'} 32',
        (tester) async {
          await tester.pumpWidget(
            CoUIApp(
              theme: ThemeData.fromCore(
                CoreThemePresets.previewLight.copyWith(
                  textScaling: 1,
                  sizeScaling: 1,
                  radiusScaling: 1,
                ),
              ),
              density: density,
              home: const Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: _kRowWidth,
                  child: StepItem(title: 'Build'),
                ),
              ),
            ),
          );

          final row = tester.getRect(find.byType(StepItem));
          final icon = tester.getRect(find.byType(Icon));
          final title = tester.getRect(find.text('Build'));
          // The row is its own 32 minimum, or the title's line box between
          // the (density-moved) padding when that is taller.
          expect(
            row.height,
            closeTo(
              math.max(
                CoreStepItemStyle.defaultMinHeight,
                padding * 2 + title.height,
              ),
              0.01,
            ),
          );
          expect(
            row.height > CoreStepItemStyle.defaultMinHeight,
            grows,
            reason: 'only spacious pushes the content past the 32 minimum',
          );
          expect(title.left - icon.right, closeTo(gap, 0.01));
          // The title sits centred in the row; when the content is what sets
          // the height, the padding is what is left either side of it.
          expect(
            title.top - row.top,
            closeTo((row.height - title.height) / 2, 0.01),
          );
          if (grows) {
            expect(title.top - row.top, closeTo(padding, 0.01));
          }
        },
      );
    }
  });
}
