import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pressing a chip moves it into the space its cast was holding.
///
/// The affordance is two halves on one clock: the box travels by the
/// distance the style throws its cast, and the cast hides while it does.
/// Either half alone is a defect — a travel without the hide reads as
/// the whole chip sliding (the cast rides inside the Clickable, so it
/// moves too), and a hide without the travel is a shadow blinking out
/// for no reason.
///
/// Read from the widget tree rather than from pixels on purpose: the
/// two halves are separate widgets with separate clocks, and a pixel
/// probe would tell you they disagreed without telling you which one
/// was wrong.

/// The offsets any press-translate wrapper under [of] is applying.
List<Offset> _translates(WidgetTester tester, Finder of) => tester
    .widgetList<Transform>(
      find.descendant(of: of, matching: find.byType(Transform)),
    )
    .map(
      (t) => Offset(
        t.transform.getTranslation().x,
        t.transform.getTranslation().y,
      ),
    )
    .where((o) => o != Offset.zero)
    .toList();

InjectedCast _cast(WidgetTester tester, Finder of) =>
    tester.widget<InjectedCast>(
      find.descendant(of: of, matching: find.byType(InjectedCast)).first,
    );

Future<void> _pump(
  WidgetTester tester,
  Widget child,
  CoreSurfaceStyleId style,
) async {
  await tester.pumpWidget(
    CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      surfaceStyle: style,
      home: Center(child: child),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('a chip sinks into its cast when pressed', () {
    testWidgets('it travels exactly as far as a button does', (tester) async {
      // Asserted against Button rather than against the raw token,
      // because the token is not the distance: `Clickable`'s resolver
      // multiplies `pressedTranslate` by `theme.scaling`, so the number
      // on screen depends on the platform the harness reports. Pinning
      // the literal would encode the harness; pinning the *agreement*
      // encodes the thing that was actually wrong, which is that these
      // two controls behaved differently under the same style.
      await _pump(
        tester,
        Chip(label: 'c', onTap: () {}),
        .neoBrutalism,
      );
      final chip = find.byType(Chip);

      expect(
        _translates(tester, chip),
        isEmpty,
        reason: 'at rest the chip sits where it was laid out',
      );

      final chipPress = await tester.startGesture(tester.getCenter(chip));
      await tester.pumpAndSettle();
      final chipTravel = _translates(tester, chip);
      await chipPress.up();
      await tester.pumpAndSettle();

      expect(_translates(tester, chip), isEmpty, reason: 'and returns');

      await _pump(
        tester,
        Button(onPressed: () {}, child: const Text('b')),
        .neoBrutalism,
      );
      final button = find.byType(Button);
      final buttonPress = await tester.startGesture(tester.getCenter(button));
      await tester.pumpAndSettle();
      final buttonTravel = _translates(tester, button);
      await buttonPress.up();
      await tester.pumpAndSettle();

      expect(
        buttonTravel,
        isNotEmpty,
        reason:
            'the control this is measured against must itself travel, '
            'or the comparison passes on two motionless widgets',
      );
      expect(chipTravel, buttonTravel);
    });

    testWidgets('the cast hides while it travels', (tester) async {
      await _pump(
        tester,
        Chip(label: 'c', onTap: () {}),
        .neoBrutalism,
      );
      final chip = find.byType(Chip);

      expect(_cast(tester, chip).visible, isTrue);
      // On the press clock, not the chip's hover/selected transition —
      // a cast fading on the slower one would trail the box.
      expect(
        _cast(tester, chip).duration,
        const Duration(milliseconds: CoreDuration.ms50),
      );

      final press = await tester.startGesture(tester.getCenter(chip));
      await tester.pumpAndSettle();
      expect(_cast(tester, chip).visible, isFalse);

      await press.up();
      await tester.pumpAndSettle();
      expect(_cast(tester, chip).visible, isTrue);
    });

    testWidgets('a style that throws nothing moves nothing', (tester) async {
      // The negative control, and the reason the travel is gated on the
      // cast rather than stated flat: with no shadow there is no space
      // to sink into, and a chip that slid anyway would be moving for a
      // reason the screen cannot show.
      await _pump(
        tester,
        Chip(label: 'c', onTap: () {}),
        .defaultStyle,
      );
      final chip = find.byType(Chip);

      final press = await tester.startGesture(tester.getCenter(chip));
      await tester.pumpAndSettle();

      expect(_translates(tester, chip), isEmpty);

      await press.up();
      await tester.pumpAndSettle();
    });

    testWidgets('a display-only chip takes no press machinery', (
      tester,
    ) async {
      // `onTap == null` is the chip-input case. It still carries the
      // cast — it is still a box under this style — but nothing presses
      // it, so it must not gain a hide that never fires.
      await _pump(tester, const Chip(label: 'c'), .neoBrutalism);
      final chip = find.byType(Chip);

      expect(_cast(tester, chip).shadows, isNotEmpty);
      expect(_cast(tester, chip).visible, isTrue);
      expect(_cast(tester, chip).duration, Duration.zero);
    });
  });
}
