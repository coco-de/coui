import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

/// Chip's `castMotion` twin of `button_cast_motion_test.dart` — Chip has
/// no authored-shadow slot (unlike Button), so `resolveChip` reads
/// `castMotion` directly with nothing to gate it on. `defaultMotion` is
/// what every chip already did; [CoreCastMotion.noShadow] withholds the
/// cast and its travel outright; [CoreCastMotion.reverse] keeps the same
/// injected cast but hides it at rest instead of at engage, and travels
/// the opposite diagonal.
class _Capture extends StatelessWidget {
  const _Capture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Widget build(BuildContext context) {
    onBuild(context);

    return const SizedBox.shrink();
  }
}

void main() {
  Future<ResolvedChip> resolveUnder(
    WidgetTester tester, {
    CoreCastMotion? castMotion,
    CoreSurfaceStyleId style = .neoBrutalism,
  }) async {
    late BuildContext captured;
    // Tear the tree down first — pumping a second app over the first
    // reuses the elements, and the reused ones keep answering with the
    // previous configuration.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      CoUIApp(
        surfaceStyle: style,
        home: _Capture((context) => captured = context),
        theme: ThemeData.fromCore(CoreThemePresets.light),
      ),
    );

    return resolveChip(
      captured,
      variant: CoreChipVariant.outlined,
      chipColor: .defaultColor,
      size: .md,
      selected: false,
      emphasis: .defaultEmphasis,
      enabled: true,
      chipStyle: castMotion == null
          ? null
          : CoreChipStyle(castMotion: castMotion),
    );
  }

  group('castMotion reaches what the chip paints', () {
    testWidgets('a chip casts when nothing is said', (tester) async {
      final resolved = await resolveUnder(tester);

      expect(resolved.boxShadow, isNotEmpty);
      expect(resolved.reverseCastMotion, isFalse);
    });

    testWidgets('noShadow withholds the cast', (tester) async {
      final resolved = await resolveUnder(tester, castMotion: .noShadow);

      expect(
        resolved.boxShadow,
        isEmpty,
        reason: 'a chip that asks for no cast still got one',
      );
    });

    testWidgets(
      'reverse still throws the injected cast but travels the opposite '
      'diagonal from defaultMotion',
      (tester) async {
        final sunk = await resolveUnder(tester);
        final reversed = await resolveUnder(tester, castMotion: .reverse);

        expect(
          reversed.boxShadow,
          isNotEmpty,
          reason:
              'reverse still has a cast to grow on engage — only '
              'when it is hidden changes, not whether it exists',
        );
        expect(
          reversed.reverseCastMotion,
          isTrue,
          reason:
              'co_chip.dart reads this to flip the InjectedCast '
              'visibility formula',
        );
        expect(sunk.reverseCastMotion, isFalse);
        expect(
          reversed.clickableStyle.pressedTranslate,
          isNot(sunk.clickableStyle.pressedTranslate),
          reason:
              'reverse negates the diagonal — same distance, opposite '
              'sign',
        );
        expect(
          reversed.clickableStyle.pressedTranslate,
          CoreOffset(
            -sunk.clickableStyle.pressedTranslate!.dx,
            -sunk.clickableStyle.pressedTranslate!.dy,
          ),
        );
      },
    );

    testWidgets('the axis is inert under a style that states no cast', (
      tester,
    ) async {
      final plain = await resolveUnder(tester, style: .defaultStyle);
      final reversed = await resolveUnder(
        tester,
        castMotion: .reverse,
        style: .defaultStyle,
      );

      expect(reversed.boxShadow, plain.boxShadow);
      expect(
        reversed.clickableStyle.pressedTranslate,
        plain.clickableStyle.pressedTranslate,
      );
    });
  });
}
