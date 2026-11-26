import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

/// [CoreCastMotion.reverse]'s widget-level twin of
/// `button_hover_engage_test.dart` / `chip_hover_engage_test.dart` —
/// those lock down that `defaultMotion` casts at rest and hides on
/// engage; this locks down that `reverse` does the mirror: nothing at
/// rest, the cast grows on engage, and the control travels the opposite
/// diagonal from a `defaultMotion` sibling under the identical style. A
/// resolver-level assertion (`button_cast_motion_test.dart` /
/// `chip_cast_motion_test.dart`) cannot see whether `co_button.dart` /
/// `co_chip.dart` actually wire `resolved.reverseCastMotion` into the
/// paint tree — only these widget-level assertions can.
void main() {
  InjectedCast castLayer(WidgetTester tester, Finder of) =>
      tester.widget<InjectedCast>(
        find.descendant(of: of, matching: find.byType(InjectedCast)).first,
      );

  /// The translation painted by the shared press feedback under [of].
  Matrix4 shiftTransform(WidgetTester tester, Finder of) => tester
      .widgetList<Container>(
        find.descendant(of: of, matching: find.byType(Container)),
      )
      .firstWhere((w) => w.transform != null)
      .transform!;

  /// Connects a mouse *before* pumping — `FocusableActionDetector`
  /// snapshots `FocusHighlightMode` in its first post-frame callback and
  /// a mouse pointer event alone never re-triggers that snapshot
  /// afterwards, so every hover test here must connect first, then pump
  /// (mirrors `button_hover_engage_test.dart`).
  Future<TestGesture> connectMouse(WidgetTester tester) async {
    final gesture = await tester.createGesture(kind: .mouse);
    await gesture.addPointer(location: .zero);
    addTearDown(gesture.removePointer);
    return gesture;
  }

  group('Button — reverse', () {
    testWidgets(
      'casts nothing at rest, grows the cast and travels backwards on '
      'hover',
      (tester) async {
        final gesture = await connectMouse(tester);
        await pumpTestApp(
          tester,
          Button(
            onPressed: () {},
            buttonStyle: const CoreButtonStyle(castMotion: .reverse),
            child: const Text('Submit'),
          ),
          theme: ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: .neoBrutalism,
        );
        final button = find.byType(Button);

        expect(
          castLayer(tester, button).visible,
          isFalse,
          reason: 'reverse casts nothing until engaged',
        );

        await gesture.moveTo(tester.getCenter(button));
        await tester.pumpAndSettle();

        expect(
          castLayer(tester, button).visible,
          isTrue,
          reason: 'hover grows the cast for reverse',
        );
        expect(
          shiftTransform(tester, button),
          isNot(Matrix4.identity()),
          reason:
              'reverse still travels on engage — only which half of '
              'the pair is visible flips',
        );

        await gesture.moveTo(.zero);
        await tester.pumpAndSettle();

        expect(castLayer(tester, button).visible, isFalse);
      },
    );

    testWidgets('travels the opposite diagonal from defaultMotion', (
      tester,
    ) async {
      final gesture = await connectMouse(tester);
      // A single finder reused across both pumps — `Finder` re-queries
      // the live tree at the point of use, so it stays valid across the
      // teardown between the two configs below.
      final button = find.byType(Button);

      // Pumps [castMotion] (`null` for defaultMotion), hovers, and
      // returns the shift. Parameterised so the two call sites below
      // are not two statements with an identical initializer expression
      // reading the same button at two different points in time.
      Future<Offset> pumpAndShift(CoreCastMotion? castMotion) async {
        await pumpTestApp(
          tester,
          Button(
            onPressed: () {},
            buttonStyle: castMotion == null
                ? null
                : CoreButtonStyle(castMotion: castMotion),
            child: const Text('Submit'),
          ),
          theme: ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: .neoBrutalism,
        );
        await gesture.moveTo(tester.getCenter(button));
        await tester.pumpAndSettle();
        final matrix = shiftTransform(tester, button);
        return Offset(matrix.storage[12], matrix.storage[13]);
      }

      final sunkShift = await pumpAndShift(null);

      // Tear down before pumping the second config — reusing the tree
      // would answer with the first button's configuration.
      await gesture.moveTo(.zero);
      await tester.pumpWidget(const SizedBox.shrink());

      final reversedShift = await pumpAndShift(.reverse);

      expect(
        sunkShift.dx,
        isNot(0),
        reason: 'the reference distance must itself be non-zero',
      );
      expect(reversedShift.dx, -sunkShift.dx);
      expect(reversedShift.dy, -sunkShift.dy);
    });
  });

  group('Chip — reverse', () {
    testWidgets(
      'casts nothing at rest, grows the cast and travels backwards on '
      'hover',
      (tester) async {
        final gesture = await connectMouse(tester);
        await pumpTestApp(
          tester,
          Chip(
            onTap: () {},
            label: 'Tag',
            chipStyle: const CoreChipStyle(castMotion: .reverse),
          ),
          theme: ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: .neoBrutalism,
        );
        final chip = find.byType(Chip);

        expect(castLayer(tester, chip).visible, isFalse);

        await gesture.moveTo(tester.getCenter(chip));
        await tester.pumpAndSettle();

        expect(castLayer(tester, chip).visible, isTrue);
        expect(shiftTransform(tester, chip), isNot(Matrix4.identity()));

        await gesture.moveTo(.zero);
        await tester.pumpAndSettle();

        expect(castLayer(tester, chip).visible, isFalse);
      },
    );

    testWidgets(
      'a display-only reverse chip never engages, so it never casts',
      (tester) async {
        // `onTap == null` (the chip-input case) has no Clickable at all,
        // so it can never reach an engaged state — reverse's "nothing at
        // rest, something on engage" premise collapses to "nothing,
        // permanently" there rather than showing a cast that reads as
        // neither at-rest nor engaged.
        await pumpTestApp(
          tester,
          const Chip(
            label: 'Tag',
            chipStyle: CoreChipStyle(castMotion: .reverse),
          ),
          theme: ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: .neoBrutalism,
        );
        final chip = find.byType(Chip);

        expect(castLayer(tester, chip).shadows, isNotEmpty);
        expect(castLayer(tester, chip).visible, isFalse);
      },
    );
  });
}
