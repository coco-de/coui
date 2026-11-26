// The density axis has to move the whole box, not part of it.
//
// `OutlinedContainer` is composed by 41 components, and the reason they
// hand it Core values rather than resolved ones is stated in its own
// resolver: "passing Core values keeps the scheme-resolve / geometry /
// scaling bend applied exactly once — `OutlinedContainer` runs those steps
// itself." It ran two of the three. `borderWidth`, `dashLength` and
// `dashSpacing` took `* scaling`; `padding` and `borderRadius` did not.
//
// So in an app scaled to 1.25× — every composed surface got a 25 % thicker
// border around padding and corners that had not moved. Not a wrong number
// anyone would report: the box just looks slightly tight, on one platform,
// at one density.
//
// The border width is asserted alongside as a control. Without it, a fix
// that scaled nothing at all would still pass the two assertions that
// matter, by making them agree at the wrong value.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

// A caller-supplied padding, because the default is zero — 41 components
// hand this one (Card, Alert, and the rest), and a test that read the
// default would be asserting that nothing scales nothing.
const _kPadding = CoreEdgeInsets.all(CoreSpace.space16);

// A scaling that is not 1. `AdaptiveScaling.mobile` is 1, and a test of the
// density axis at 1 compares the unscaled value with itself.
const _kPhone = AdaptiveScaling(1.25);

Future<ResolvedOutlinedContainer> _resolve(
  WidgetTester tester,
  AdaptiveScaling scaling,
) async {
  ResolvedOutlinedContainer? resolved;
  // Unmount first. `buildTestApp` puts the child in an
  // `Overlay(initialEntries:)`, and those are honoured on the FIRST mount
  // only — a second `pumpWidget` reuses the existing overlay state and
  // silently keeps showing the first tree. The reading then comes back
  // null, which reads as a broken harness rather than a stale tree.
  await tester.pumpWidget(const SizedBox.shrink());

  // `buildTestApp`, not `CoUIApp`: the app widget picks the density from
  // the target platform and overrides whatever theme it is handed, so both
  // densities come back 1.25 under it and the test would compare a value
  // with itself.
  await tester.pumpWidget(
    buildTestApp(
      Builder(
        builder: (context) {
          resolved = resolveOutlinedContainer(
            context,
            containerStyle: const CoreOutlinedContainerStyle(
              padding: _kPadding,
            ),
          );
          return const SizedBox.shrink();
        },
      ),
      theme: scaling.scale(ThemeData.fromCore(CoreThemePresets.light)),
    ),
  );
  expect(resolved, isNotNull, reason: 'the builder never ran');
  return resolved!;
}

void main() {
  group('the density axis moves the whole box', () {
    testWidgets('padding scales', (tester) async {
      final desktop = await _resolve(tester, AdaptiveScaling.desktop);
      final mobile = await _resolve(tester, _kPhone);

      final factor = _kPhone.sizeScaling;
      final d = desktop.padding.resolve(TextDirection.ltr);
      final m = mobile.padding.resolve(TextDirection.ltr);

      expect(d.left, greaterThan(0), reason: 'nothing to scale');
      expect(m.left, closeTo(d.left * factor, 0.01));
      expect(m.top, closeTo(d.top * factor, 0.01));
      expect(m.right, closeTo(d.right * factor, 0.01));
      expect(m.bottom, closeTo(d.bottom * factor, 0.01));
    });

    testWidgets('corner radius scales', (tester) async {
      final desktop = await _resolve(tester, AdaptiveScaling.desktop);
      final mobile = await _resolve(tester, _kPhone);

      final factor = _kPhone.sizeScaling;

      expect(desktop.borderRadius.topLeft.x, greaterThan(0));
      expect(
        mobile.borderRadius.topLeft.x,
        closeTo(desktop.borderRadius.topLeft.x * factor, 0.01),
      );
      expect(
        mobile.borderRadius.bottomRight.x,
        closeTo(desktop.borderRadius.bottomRight.x * factor, 0.01),
      );
    });

    testWidgets('border width already did — the control', (tester) async {
      // Present so that "scaled nothing" cannot pass as "scaled
      // everything": if the fix were to drop `* scaling` from the border
      // instead of adding it to the other two, the assertions above would
      // still hold and this one would fail.
      final desktop = await _resolve(tester, AdaptiveScaling.desktop);
      final mobile = await _resolve(tester, _kPhone);

      expect(desktop.borderWidth, greaterThan(0));
      expect(
        mobile.borderWidth,
        closeTo(
          desktop.borderWidth * _kPhone.sizeScaling,
          0.01,
        ),
      );
    });
  });
}
