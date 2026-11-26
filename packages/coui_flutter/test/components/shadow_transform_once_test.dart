import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

/// One outer layer and one inset layer, so the split is exercised.
const _mixed = [
  (
    offsetX: 0.0,
    offsetY: 4.0,
    blurRadius: 8.0,
    spreadRadius: 0.0,
    opacity: 0.4,
    inset: false,
  ),
  (
    offsetX: 0.0,
    offsetY: 2.0,
    blurRadius: 6.0,
    spreadRadius: 0.0,
    opacity: 0.3,
    inset: true,
  ),
];

Future<ResolvedOutlinedContainer> _resolve(
  WidgetTester tester,
  CoreSurfaceStyleId style,
) async {
  late ResolvedOutlinedContainer seen;

  await tester.pumpWidget(
    CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      surfaceStyle: style,
      home: Builder(
        builder: (context) {
          seen = resolveOutlinedContainer(
            context,
            containerStyle: const CoreOutlinedContainerStyle(
              boxShadow: _mixed,
            ),
          );

          return const SizedBox.shrink();
        },
      ),
    ),
  );
  // The app cross-fades themes, so the first frame after a style change
  // is still the old geometry — settling is what makes this read the
  // style under test rather than the one before it.
  await tester.pumpAndSettle();

  return seen;
}

void main() {
  group('the active style transforms the stack once', () {
    testWidgets('both halves are bent, and bent the same way', (tester) async {
      // The two halves go to different machinery — one to the decoration,
      // one to a painter over the surface — but they are halves of one
      // stack, so the style has to reach both and reach them equally.
      final plain = await _resolve(tester, CoreSurfaceStyleId.defaultStyle);
      final flat = await _resolve(tester, CoreSurfaceStyleId.neoBrutalism);

      expect(plain.boxShadow.single.blurRadius, greaterThan(0));
      expect(plain.insetBoxShadow.single.blurRadius, greaterThan(0));
      expect(flat.boxShadow.single.blurRadius, 0);
      expect(
        flat.insetBoxShadow.single.blurRadius,
        0,
        reason: 'an inset layer is not exempt from the style',
      );
    });

    testWidgets('the style is asked exactly once', (tester) async {
      _shadowCalls = 0;

      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(
            CoreThemePresets.light,
          ).copyWith(geometry: () => const _CountingGeometry()),
          home: Builder(
            builder: (context) {
              resolveOutlinedContainer(
                context,
                containerStyle: const CoreOutlinedContainerStyle(
                  boxShadow: _mixed,
                ),
              );

              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(
        _shadowCalls,
        1,
        reason:
            'one stack, one transform — a call per half runs the '
            'style twice on two different inputs',
      );
    });

    testWidgets('the split preserves every layer exactly once', (
      tester,
    ) async {
      // Applying the transform per half rather than once over the stack
      // is invisible while it maps layer to layer, and duplicates or drops
      // the moment it changes the stack as a whole.
      final resolved = await _resolve(tester, CoreSurfaceStyleId.neoBrutalism);

      expect(
        resolved.boxShadow.length + resolved.insetBoxShadow.length,
        _mixed.length,
      );
    });
  });
}

/// Counts how many times the active style is asked to bend the stack.
///
/// The property under test is not visible in the output while the
/// transform maps layer to layer — applying it once over the stack and
/// once per half give the same numbers. Counting is the only thing that
/// tells them apart, and the difference matters the moment a style does
/// anything to the stack as a whole.
/// Counted outside the class so it stays immutable like its parent.
int _shadowCalls = 0;

class _CountingGeometry extends CoreSurfaceGeometryConstraint {
  const _CountingGeometry() : super(shadowBlurScale: 0);

  @override
  List<CoreShadowLayer> shadow(List<CoreShadowLayer> value) {
    _shadowCalls++;

    return super.shadow(value);
  }
}
