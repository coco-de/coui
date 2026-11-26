import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'dart:ui' show Color;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// The inset stack an `OutlinedContainer` resolves under [style].
Future<List<BoxShadow>> _insetUnder(
  WidgetTester tester,
  CoreSurfaceStyleId style,
) async {
  late List<BoxShadow> seen;

  await tester.pumpWidget(
    CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      surfaceStyle: style,
      home: Builder(
        builder: (context) {
          seen = resolveOutlinedContainer(
            context,
            containerStyle: const CoreOutlinedContainerStyle(
              elevation: .medium,
            ),
          ).insetBoxShadow;

          return const SizedBox.shrink();
        },
      ),
    ),
  );
  // The style reaches the tree through a document attribute and a theme
  // cross-fade; reading on the first frame catches the previous value.
  await tester.pumpAndSettle();

  return seen;
}

/// The rim a panel resolver produces under [style].
Future<List<BoxShadow>> _popupRimUnder(
  WidgetTester tester,
  CoreSurfaceStyleId style,
) async {
  late List<BoxShadow> seen;

  await tester.pumpWidget(
    CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      surfaceStyle: style,
      home: Builder(
        builder: (context) {
          seen = resolvePopup(context).insetBoxShadow;

          return const SizedBox.shrink();
        },
      ),
    ),
  );
  await tester.pumpAndSettle();

  return seen;
}

void main() {
  group('the rim reaches panels, not just one component', () {
    testWidgets('a popup panel gets one under clay', (tester) async {
      // The measured parity bug: this panel carries a rim on Web — its
      // stack is a scale step routed through `var(--shadow-md)`, which
      // the style rewrites — and carried nothing on Flutter, because the
      // rim lived inside OutlinedContainer's resolver and a popup does
      // not pass through it.
      expect(await _popupRimUnder(tester, .claymorphism), isNotEmpty);
    });

    testWidgets('and none under a style that states none', (tester) async {
      expect(
        await _popupRimUnder(tester, CoreSurfaceStyleId.defaultId),
        isEmpty,
      );
    });
  });

  testWidgets('a style that states a rim puts one in the painted stack', (
    tester,
  ) async {
    // The recipe reading complete is not the same as a rim reaching the
    // canvas, and this axis has shipped the first without the second
    // more than once. Only the resolved stack tells them apart.
    final clay = await _insetUnder(tester, .claymorphism);

    expect(clay, isNotEmpty);
  });

  testWidgets('a surface that casts nothing gets no rim', (tester) async {
    // The parity fence. Web reaches this structurally — there the rim
    // rides the `--shadow-*` variables and a surface stating no
    // elevation never references them — so Flutter has to agree
    // explicitly. Without it the same card carried a rim on one
    // platform and nothing on the other, and neither platform's own
    // tests could see it.
    late List<BoxShadow> inset;

    await tester.pumpWidget(
      CoUIApp(
        theme: ThemeData.fromCore(CoreThemePresets.light),
        surfaceStyle: .claymorphism,
        home: Builder(
          builder: (context) {
            inset = resolveOutlinedContainer(
              context,
              containerStyle: const CoreOutlinedContainerStyle(
                elevation: .none,
              ),
            ).insetBoxShadow;

            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(inset, isEmpty);
  });

  testWidgets('a style that states none leaves the stack alone', (
    tester,
  ) async {
    // The rim is a statement, not a default that every surface acquires.
    final plain = await _insetUnder(tester, CoreSurfaceStyleId.defaultId);

    expect(plain, isEmpty);
  });

  testWidgets('the rim is drawn in the highlight, not the shadow', (
    tester,
  ) async {
    // The whole reason the rim travels beside the stack rather than
    // inside it: one list, two tints. A rim wearing the shadow's colour
    // is a second inner shadow, which is not what light does.
    final clay = await _insetUnder(tester, .claymorphism);
    final scheme = CoreThemePresets.lightColorScheme;
    final shadow = scheme
        .resolve(const CoreColor.token(CoreColors.shadow))
        .toValue();
    final highlight = scheme
        .resolve(const CoreColor.token(CoreColors.surfaceHighlight))
        .toValue();

    // Channels, not the packed value: the layer's own opacity rewrites
    // the alpha, so comparing the whole colour never matches either
    // candidate and the check passes on a rim wearing the wrong tint.
    // That is how this test was written first, and it did.
    bool sameRgb(Color a, Color b) => a.r == b.r && a.g == b.g && a.b == b.b;

    expect(
      clay.any((s) => sameRgb(s.color, highlight)),
      isTrue,
      reason: 'no rim layer carries the highlight tint',
    );
    expect(
      clay.every((s) => !sameRgb(s.color, shadow)),
      isTrue,
      reason:
          'a rim layer carries the shadow tint, so the highlight '
          'never reached the conversion',
    );
  });

  testWidgets('a palette that states no highlight still paints a rim', (
    tester,
  ) async {
    // The A → B switch, at the far end of the pipeline. A palette that
    // says nothing must not paint at alpha 0 — that is the Flutter half
    // of the failure the derivation exists to prevent.
    late List<BoxShadow> seen;

    await tester.pumpWidget(
      CoUIApp(
        theme: ThemeData.fromCore(
          CoreThemePresets.light.copyWith(
            colorScheme: CoreThemePresets.lightColorScheme.copyWith(
              surface: const CoreColor.fromARGB(255, 244, 243, 248),
            ),
          ),
        ),
        surfaceStyle: .claymorphism,
        home: Builder(
          builder: (context) {
            seen = resolveOutlinedContainer(
              context,
              containerStyle: const CoreOutlinedContainerStyle(
                elevation: .medium,
              ),
            ).insetBoxShadow;

            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(seen, isNotEmpty);
    expect(
      seen.every((s) => s.color.a > 0),
      isTrue,
      reason:
          'a rim resolved to a fully transparent colour, which is what '
          'an unreachable highlight token looks like on this platform',
    );
  });
}
