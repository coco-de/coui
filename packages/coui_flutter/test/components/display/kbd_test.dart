import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

/// Pumps [kbd] inside a resolved light theme — `const ThemeData()` leaves
/// colour tokens unresolved, which the key box's fill and shadow need.
Future<void> _pump(WidgetTester tester, Widget kbd) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    buildTestApp(kbd, theme: ThemeData.fromCore(CoreThemePresets.light)),
  );
}

/// The key boxes of the one [Kbd] on screen, left to right.
Iterable<Rect> _keyRects(WidgetTester tester) => [
  for (var i = 0; i < tester.widgetList(find.byType(InjectedCast)).length; i++)
    tester.getRect(find.byType(InjectedCast).at(i)),
];

SemanticsData _semanticsOf(WidgetTester tester) =>
    tester.getSemantics(find.byType(Kbd)).getSemanticsData();

/// Runs [body] with semantics on. The handle is released here, not in a
/// teardown: the framework checks for leaked handles before teardowns run.
Future<void> _withSemantics(
  WidgetTester tester,
  Future<void> Function() body,
) async {
  final handle = tester.ensureSemantics();
  try {
    await body();
  } finally {
    handle.dispose();
  }
}

void main() {
  group('Kbd minimum size is inside the border', () {
    for (final dark in [false, true]) {
      for (final surface in [
        CoreSurfaceStyleId.defaultStyle,
        CoreSurfaceStyleId.neoBrutalism,
      ]) {
        for (final hidden in [false, true]) {
          testWidgets('dark=$dark / ${surface.name} / hidden=$hidden', (
            tester,
          ) async {
            for (final width in [0.0, 0.5, 1.0, 2.0]) {
              await tester.pumpWidget(const SizedBox.shrink());
              await tester.pumpWidget(
                buildTestApp(
                  Kbd(
                    keys: const ['I', 'J'],
                    kbdStyle: CoreKbdStyle(
                      keyMinSize: 40,
                      keyBorderWidth: width,
                      keyBorderColor: hidden ? CoreColor.transparent : null,
                    ),
                  ),
                  theme: ThemeData.fromCore(
                    dark ? CoreThemePresets.dark : CoreThemePresets.light,
                  ),
                  surfaceStyle: surface,
                ),
              );
              final stroke = hidden
                  ? 0.0
                  : CoreSurfaceRecipe.of(surface).geometry.stroke(width);
              final caps = _keyRects(tester).toList();
              for (final cap in caps) {
                expect(cap.size, Size.square(40 + stroke * 2));
              }
              expect(caps[1].left - caps[0].right, 4);
              expect(tester.takeException(), isNull);
            }
          });
        }
      }
    }
  });

  group('Kbd draws keys side by side', () {
    testWidgets('no glyph sits between the keys', (tester) async {
      await _pump(tester, const Kbd(keys: ['Ctrl', 'Shift', 'K']));

      expect(find.text('Ctrl'), findsOneWidget);
      expect(find.text('Shift'), findsOneWidget);
      expect(find.text('K'), findsOneWidget);
      expect(find.text('+'), findsNothing);
      expect(find.byType(InjectedCast), findsNWidgets(3));
    });

    testWidgets('one, two, three and four keys all draw', (tester) async {
      const combos = [
        ['Esc'],
        ['Ctrl', 'S'],
        ['⌘', 'Shift', 'F'],
        ['⌃', '⇧', '⌘', '4'],
      ];
      for (final keys in combos) {
        await _pump(tester, Kbd(keys: keys));

        expect(find.byType(InjectedCast), findsNWidgets(keys.length));
        for (final key in keys) {
          expect(find.text(key), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('the keys are space/4 apart by default', (tester) async {
      await _pump(tester, const Kbd(keys: ['Ctrl', 'Shift', 'K']));

      final rects = _keyRects(tester).toList();
      expect(rects, hasLength(3));
      for (var i = 1; i < rects.length; i++) {
        expect(
          rects[i].left - rects[i - 1].right,
          CoreKbdStyle.defaultKeySeparatorSpacing,
        );
      }
      expect(CoreKbdStyle.defaultKeySeparatorSpacing, CoreSpace.space4);
    });

    testWidgets('keySeparatorSpacing moves the keys', (tester) async {
      await _pump(
        tester,
        const Kbd(
          keys: ['Ctrl', 'S'],
          kbdStyle: CoreKbdStyle(keySeparatorSpacing: 12),
        ),
      );

      final rects = _keyRects(tester).toList();
      expect(rects[1].left - rects[0].right, 12);
    });

    testWidgets('keys keep the order they were given', (tester) async {
      await _pump(tester, const Kbd(keys: ['B', 'A', 'C']));

      final lefts = [
        for (final key in ['B', 'A', 'C']) tester.getTopLeft(find.text(key)).dx,
      ];
      expect(lefts, orderedEquals([...lefts]..sort()));
    });
  });

  group('Kbd is announced as one name', () {
    testWidgets('a combination reads as its keys joined by a space', (
      tester,
    ) async {
      await _withSemantics(tester, () async {
        await _pump(tester, const Kbd(keys: ['Ctrl', 'S']));

        expect(_semanticsOf(tester).label, 'Ctrl S');
        // No fragment per key and no "+" for a reader to stumble over.
        expect(find.bySemanticsLabel('Ctrl'), findsNothing);
        expect(find.bySemanticsLabel('S'), findsNothing);
        expect(find.bySemanticsLabel('+'), findsNothing);
      });
    });

    testWidgets('a four-key combination is still one name', (tester) async {
      await _withSemantics(tester, () async {
        await _pump(tester, const Kbd(keys: ['⌃', '⇧', '⌘', '4']));

        expect(_semanticsOf(tester).label, '⌃ ⇧ ⌘ 4');
      });
    });

    testWidgets('Kbd.single reads as its key', (tester) async {
      await _withSemantics(tester, () async {
        await _pump(tester, Kbd.single(keyText: 'Esc'));

        expect(_semanticsOf(tester).label, 'Esc');
      });
    });

    testWidgets('Kbd.icon reads as its label', (tester) async {
      await _withSemantics(tester, () async {
        await _pump(
          tester,
          const Kbd.icon(
            keyContent: Icon(LucideIcons.arrowUp),
            label: '위로',
          ),
        );

        expect(_semanticsOf(tester).label, '위로');
      });
    });

    testWidgets('Kbd.icon without a label adds no name of its own', (
      tester,
    ) async {
      await _withSemantics(tester, () async {
        await _pump(
          tester,
          const Kbd.icon(keyContent: Icon(LucideIcons.arrowUp)),
        );

        // A hint such as the Command footer's arrow keys sits beside a text
        // that already names the action; a made-up name here would be read
        // twice.
        final named = find.descendant(
          of: find.byType(Kbd),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                (widget.properties.label ?? '').isNotEmpty,
          ),
        );
        expect(named, findsNothing);
      });
    });

    testWidgets('copyWith keeps the label of an icon key', (tester) async {
      const kbd = Kbd.icon(
        keyContent: Icon(LucideIcons.arrowUp),
        label: '위로',
      );

      expect(kbd.copyWith().label, '위로');
      expect(kbd.copyWith(kbdStyle: const CoreKbdStyle()).label, '위로');
    });
  });
}
