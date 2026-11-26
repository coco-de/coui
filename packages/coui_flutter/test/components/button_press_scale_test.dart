import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/clickable_feedback.dart';

import '../helpers/test_app.dart';

/// Every `Button` shrinks while pressed — on desktop as on mobile, and to
/// the value `CoreButtonStyle.pressedScale` states (#4427).
///
/// The press shrink used to ride `enableFeedback`'s mobile-only default,
/// so a desktop build showed no press at all under every style without a
/// cast, while the same button on a phone (and now on Web) shrank. These
/// tests pin the platform-independent answer; the Web half is
/// `packages/coui_web/test/components/control/button_press_scale_test.dart`.
void main() {
  Future<void> pumpButton(
    WidgetTester tester, {
    required TargetPlatform platform,
    bool? enableFeedback,
    CoreButtonStyle? buttonStyle,
    CoreSurfaceStyleId surfaceStyle = .defaultId,
  }) => pumpTestApp(
    tester,
    Button(
      onPressed: () {},
      enableFeedback: enableFeedback,
      buttonStyle: buttonStyle,
      child: const Text('Submit'),
    ),
    theme: ThemeData.fromCore(CoreThemePresets.light, platform: platform),
    surfaceStyle: surfaceStyle,
  );

  double pressScale(WidgetTester tester) =>
      clickableFeedback(tester).single.scale;

  Future<TestGesture> press(WidgetTester tester) async {
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(Button)),
    );
    addTearDown(() async {
      await gesture.up();
    });
    await tester.pumpAndSettle();
    return gesture;
  }

  for (final platform in [TargetPlatform.macOS, TargetPlatform.iOS]) {
    group('on ${platform.name}', () {
      testWidgets('the rest render is untouched', (tester) async {
        await pumpButton(tester, platform: platform);

        expect(pressScale(tester), 1.0);
      });

      testWidgets('a press shrinks to the Core default', (tester) async {
        await pumpButton(tester, platform: platform);
        await press(tester);

        expect(pressScale(tester), CoreButtonStyle.defaultPressedScale);
      });

      testWidgets('a per-instance pressedScale is honoured', (tester) async {
        const scale = 0.9;
        await pumpButton(
          tester,
          platform: platform,
          buttonStyle: const CoreButtonStyle(pressedScale: scale),
        );
        await press(tester);

        expect(pressScale(tester), scale);
      });

      testWidgets('enableFeedback: false still turns it off', (tester) async {
        await pumpButton(tester, platform: platform, enableFeedback: false);
        await press(tester);

        expect(pressScale(tester), 1.0);
      });

      testWidgets(
        'a style whose travel carries the press pins it — on a button '
        'that casts',
        (tester) async {
          await pumpButton(
            tester,
            platform: platform,
            surfaceStyle: .neoBrutalism,
          );
          await press(tester);

          expect(
            pressScale(tester),
            1.0,
            reason: 'DDR-1 — the shift and the shrink never compound',
          );
        },
      );

      testWidgets(
        'and leaves it on for a button with nothing to travel into',
        (tester) async {
          await pumpTestApp(
            tester,
            Button(
              variant: CoreButtonVariant.ghost,
              onPressed: () {},
              child: const Text('Submit'),
            ),
            theme: ThemeData.fromCore(
              CoreThemePresets.light,
              platform: platform,
            ),
            surfaceStyle: .neoBrutalism,
          );
          await press(tester);

          expect(
            pressScale(tester),
            CoreButtonStyle.defaultPressedScale,
            reason:
                'a ghost casts nothing, so it does not travel — without '
                'the shrink it would show no press at all. The Web twin '
                'restores its style gate for the same reason.',
          );
        },
      );
    });
  }
}
