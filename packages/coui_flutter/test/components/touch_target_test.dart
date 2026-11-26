import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      home: Align(child: child),
    ),
  );
  await tester.pumpAndSettle();
}

/// The remove button inside a chip — the X, not the pill.
Finder _removeButton() => find.descendant(
  of: find.byType(Chip),
  matching: find.byType(Button),
);

void main() {
  group('a small control accepts a pointer beyond what it draws', () {
    testWidgets('every checkbox size reaches the minimum', (tester) async {
      // Measured before this existed: 15, 17.5 and 20 for xs, sm and md
      // against a minimum of 24. The two larger sizes already passed,
      // and they are in the loop because a floor that only holds for the
      // sizes it was written for is not a floor.
      for (final size in CoreComponentSize.values) {
        var hit = false;
        await _pump(
          tester,
          Checkbox(
            size: size,
            checked: true,
            onChanged: (_) => hit = true,
          ),
        );

        // Just inside the minimum, on the diagonal — the corner is the
        // furthest point a target of this shape has to accept.
        const reach = CoreTouchTarget.minimum / 2 - 1;
        await tester.tapAt(
          tester.getCenter(find.byType(Checkbox)) + const Offset(reach, reach),
        );
        await tester.pumpAndSettle();

        expect(hit, isTrue, reason: 'checkbox ${size.name} did not reach');
      }
    });

    testWidgets('and the drawn size is unchanged', (tester) async {
      // The whole point. Padding to the minimum would also pass the test
      // above, and would move every label, row and dense table in the
      // kit. What is drawn stays exactly what the size table says.
      await _pump(
        tester,
        Checkbox(
          size: CoreComponentSize.xs,
          checked: true,
          onChanged: (_) {},
        ),
      );

      expect(tester.getSize(find.byType(Checkbox)).width, lessThan(16));
    });

    testWidgets('a chip reaches it too', (tester) async {
      var hit = false;
      await _pump(
        tester,
        Chip(size: CoreChipSize.sm, label: 'a', onTap: () => hit = true),
      );

      // A chip is wide and short, so only the cross axis falls short —
      // the ladder's smallest tier is 28 (`sm`; 24 is Badge's row now).
      const reach = CoreTouchTarget.minimum / 2 - 1;
      await tester.tapAt(
        tester.getCenter(find.byType(Chip)) + const Offset(0, reach),
      );
      await tester.pumpAndSettle();

      expect(hit, isTrue);
    });
  });

  group('the extension does not take what is not its own', () {
    testWidgets('a pointer past the minimum is declined', (tester) async {
      var hit = false;
      await _pump(
        tester,
        Checkbox(
          size: CoreComponentSize.xs,
          checked: true,
          onChanged: (_) => hit = true,
        ),
      );

      await tester.tapAt(
        tester.getCenter(find.byType(Checkbox)) +
            const Offset(CoreTouchTarget.minimum, 0),
      );
      await tester.pumpAndSettle();

      expect(hit, isFalse);
    });

    testWidgets('the margin blocks like the control does', (tester) async {
      // The surprising half, so it is written down rather than left to
      // be discovered: a pointer in the margin stops at the control, the
      // same as a pointer on its box. The expansion moves an existing
      // edge, it does not add a see-through one.
      //
      // What is behind has to be a *sibling* underneath, not an
      // ancestor: an ancestor is on the hit path either way, so a first
      // version of this test with a wrapping detector passed against
      // every implementation. It proved nothing, which is the same as
      // having no test.
      var behind = false;
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          home: Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
                onTap: () => behind = true,
                behavior: HitTestBehavior.opaque,
                child: const SizedBox(width: 200, height: 200),
              ),
              const Checkbox(
                size: CoreComponentSize.xs,
                checked: true,
                onChanged: null,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      const reach = CoreTouchTarget.minimum / 2 - 1;
      await tester.tapAt(
        tester.getCenter(find.byType(Checkbox)) + const Offset(reach, reach),
      );
      await tester.pumpAndSettle();

      expect(behind, isFalse);
    });

    testWidgets('neighbours each answer for themselves', (tester) async {
      // Two targets closer together than their expansions overlap, and
      // the later sibling wins. Ordinary spacing keeps them apart, and
      // this pins that the common case still works: a tap on one does
      // not activate the other.
      var first = false;
      var second = false;
      await _pump(
        tester,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              size: CoreComponentSize.xs,
              checked: true,
              onChanged: (_) => first = true,
            ),
            const SizedBox(width: 24),
            Checkbox(
              size: CoreComponentSize.xs,
              checked: false,
              onChanged: (_) => second = true,
            ),
          ],
        ),
      );

      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      expect(first, isTrue);
      expect(second, isFalse, reason: 'the neighbour answered as well');
    });
  });

  group('a chip remove button reaches the minimum on its own', () {
    // `ChipInput` renders every chip display-only (no `onTap`) and
    // overrides the remove button down to 16. The chip-wide floor wraps
    // only the tappable branch, so before this the X was a 16px target
    // with nothing around it — measured, and the reason this exists.
    testWidgets('a display-only chip — the X alone is the target', (
      tester,
    ) async {
      var removed = false;
      await _pump(
        tester,
        Chip(
          label: 'tag',
          onRemove: () => removed = true,
          chipStyle: const CoreChipStyle(
            closeButtonStyle: CoreButtonStyle(
              height: CoreSize.size16,
              width: CoreSize.size16,
              padding: .zero,
            ),
          ),
        ),
      );

      final x = _removeButton();
      expect(tester.getSize(x).width, lessThan(CoreTouchTarget.minimum));

      // Inward — toward the label. The X sits at the chip's end, so
      // outward the chip box itself ends and no floor can reach past it
      // (an ancestor has to hand the point down). Inward is the axis the
      // floor actually buys: measured before this, the 16px X answered
      // to ±8 and missed at -9; with the floor it answers to -11.
      const reach = CoreTouchTarget.minimum / 2 - 1;
      await tester.tapAt(tester.getCenter(x) - const Offset(reach, 0));
      await tester.pumpAndSettle();

      expect(removed, isTrue, reason: 'the 16px X did not reach the floor');
    });

    testWidgets('a tappable chip — the X gains no floor of its own', (
      tester,
    ) async {
      // The pill already carries the floor. A second one nested inside it
      // would extend the remove target over the label, so a tap meant for
      // the chip would remove it instead — the constraint the Web twin
      // documents (#3705). This pins that the floor stays conditional.
      var removed = false;
      var tapped = false;
      await _pump(
        tester,
        Chip(
          label: 'a long label',
          onTap: () => tapped = true,
          onRemove: () => removed = true,
        ),
      );

      expect(
        find.descendant(
          of: find.ancestor(of: _removeButton(), matching: find.byType(Row)),
          matching: find.byType(TouchTarget),
        ),
        findsNothing,
        reason: 'the tappable chip nests a second floor inside the pill',
      );
      // Well inside the label, away from the X — must select, not remove.
      await tester.tap(find.text('a long label'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
      expect(removed, isFalse);
    });
  });

  group('window panel controls reach the minimum on their own', () {
    // The three title-bar buttons draw at 20×20 — below the floor. They
    // sit 4px apart, so each floor reaches 2px into the gap and meets
    // its neighbour's there without overlapping. Desktop, where the
    // density scaling is 1 and the buttons are drawn at exactly their
    // token size — on mobile the density scaling already carries the
    // height past the floor.
    final desktop = TargetPlatformVariant.only(TargetPlatform.macOS);
    Future<List<String>> pumpPanel(WidgetTester tester) async {
      final pressed = <String>[];
      await _pump(
        tester,
        SizedBox(
          width: 320,
          child: WindowPanel(
            title: const Text('Editor'),
            minimizable: true,
            maximizable: true,
            onMinimize: () => pressed.add('minimize'),
            onMaximize: () => pressed.add('maximize'),
            onClose: () => pressed.add('close'),
          ),
        ),
      );
      return pressed;
    }

    Finder control(int index) => find
        .descendant(of: find.byType(WindowPanel), matching: find.byType(Button))
        .at(index);

    const reach = CoreTouchTarget.minimum / 2 - 1;
    const names = ['minimize', 'maximize', 'close'];

    testWidgets('above and below each button', variant: desktop, (
      tester,
    ) async {
      final pressed = await pumpPanel(tester);
      for (var i = 0; i < names.length; i++) {
        expect(
          tester.getSize(control(i)).height,
          lessThan(CoreTouchTarget.minimum),
        );
        for (final dy in const [-reach, reach]) {
          pressed.clear();
          await tester.tapAt(tester.getCenter(control(i)) + Offset(0, dy));
          await tester.pumpAndSettle();
          expect(
            pressed,
            [names[i]],
            reason: '${names[i]}: a tap ${dy < 0 ? 'above' : 'below'} missed',
          );
        }
      }
    });

    testWidgets(
      'toward a neighbour, each answers for itself',
      variant: desktop,
      (
        tester,
      ) async {
        final pressed = await pumpPanel(tester);
        // Into the gap from the left button, then from the right ones — the
        // two floors meet in the middle of the gap, so each side stays its
        // own.
        await tester.tapAt(
          tester.getCenter(control(0)) + const Offset(reach, 0),
        );
        await tester.pumpAndSettle();
        await tester.tapAt(
          tester.getCenter(control(1)) - const Offset(reach, 0),
        );
        await tester.pumpAndSettle();
        await tester.tapAt(
          tester.getCenter(control(2)) - const Offset(reach, 0),
        );
        await tester.pumpAndSettle();

        expect(pressed, names);
      },
    );

    testWidgets('and nothing moves', variant: desktop, (tester) async {
      // The strip grows to the floor so the buttons have room to reach,
      // but the title bar is taller still: the buttons keep their drawn
      // size and stay on the same centre line as the title.
      await pumpPanel(tester);
      final titleCentre = tester.getCenter(find.text('Editor')).dy;
      for (var i = 0; i < names.length; i++) {
        expect(
          tester.getSize(control(i)),
          const Size(CoreSpace.space20, CoreSpace.space20),
        );
        expect(
          tester.getCenter(control(i)).dy,
          moreOrLessEquals(titleCentre, epsilon: 0.01),
        );
      }
    });
  });
}
