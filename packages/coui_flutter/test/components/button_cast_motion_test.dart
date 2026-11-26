import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

/// The axis has to reach the value the button paints with, not merely
/// exist on the style.
///
/// A field can be threaded through the constructor, `copyWith`, `merge`
/// and `==`, serialize cleanly, and pass its unit tests while nothing
/// downstream ever reads it — and that failure looks *complete* from the
/// authoring side. So these assertions read the resolver's output back
/// rather than the style they were given.
///
/// `defaultMotion` is what every button already did. [CoreCastMotion
/// .noShadow] withholds the cast and its travel outright;
/// [CoreCastMotion.reverse] keeps the same injected cast but hides it at
/// rest instead of at engage, and travels the opposite diagonal.
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
  Future<ResolvedButton> resolveUnder(
    WidgetTester tester, {
    CoreCastMotion? castMotion,
    CoreSurfaceStyleId style = .neoBrutalism,
    List<CoreShadowLayer>? boxShadow,
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

    return resolveButton(
      captured,
      variant: .primary,
      size: .md,
      shape: .rectangle,
      buttonStyle: castMotion == null && boxShadow == null
          ? null
          : CoreButtonStyle(boxShadow: boxShadow, castMotion: castMotion),
    );
  }

  group('castMotion reaches what the button paints', () {
    testWidgets('a filled button casts and travels when nothing is said', (
      tester,
    ) async {
      final resolved = await resolveUnder(tester);

      expect(resolved.boxShadow, isNotNull);
      expect(resolved.pressedTranslateOffset, isNot(CoreOffset.zero));
    });

    testWidgets('noShadow withholds both halves of the affordance', (
      tester,
    ) async {
      final resolved = await resolveUnder(tester, castMotion: .noShadow);

      expect(
        resolved.boxShadow,
        isNull,
        reason: 'a control that asks for no cast still got one',
      );
      expect(
        resolved.pressedTranslateOffset,
        CoreOffset.zero,
        reason:
            'travel is the paired half — with no cast there is no '
            'vacated space to move into',
      );
    });

    /// The axis withholds the cast the *style* injects, never one the
    /// caller wrote down. A control handed a shadow was handed it on
    /// purpose, and taking it away would be two fields of one style
    /// object contradicting with the newer one winning silently — the
    /// precedence #4269 already set for the fill gate.
    testWidgets('a stated shadow outranks noShadow', (tester) async {
      final resolved = await resolveUnder(
        tester,
        castMotion: .noShadow,
        boxShadow: CoreShadow.md,
      );

      expect(
        resolved.boxShadow,
        isNotNull,
        reason: 'a caller who stated a shadow lost it to the motion axis',
      );
      expect(
        resolved.pressedTranslateOffset,
        isNot(CoreOffset.zero),
        reason:
            'the travel is the paired half — a surviving cast still '
            'has space to vacate',
      );
    });

    testWidgets('the axis is inert under a style that states no cast', (
      tester,
    ) async {
      final plain = await resolveUnder(tester, style: .defaultStyle);
      final asked = await resolveUnder(
        tester,
        castMotion: .noShadow,
        style: .defaultStyle,
      );

      expect(asked.boxShadow, plain.boxShadow);
      expect(asked.pressedTranslateOffset, plain.pressedTranslateOffset);
    });

    testWidgets(
      'reverse still throws the injected cast but travels the opposite '
      'diagonal from defaultMotion',
      (tester) async {
        final sunk = await resolveUnder(tester);
        final reversed = await resolveUnder(tester, castMotion: .reverse);

        expect(
          reversed.boxShadow,
          isNotNull,
          reason:
              'reverse still has a cast to grow on engage — only when '
              'it is hidden changes, not whether it exists',
        );
        expect(
          reversed.reverseCastMotion,
          isTrue,
          reason:
              'co_button.dart reads this to flip the InjectedCast '
              'visibility formula',
        );
        expect(
          sunk.reverseCastMotion,
          isFalse,
          reason: 'defaultMotion keeps the hide-on-engage polarity',
        );
        expect(
          reversed.pressedTranslateOffset,
          CoreOffset(
            -sunk.pressedTranslateOffset.dx,
            -sunk.pressedTranslateOffset.dy,
          ),
          reason:
              'the reference\'s reverseBoxShadowX/Y tokens are the '
              'negated boxShadowX/Y, not an independent pair',
        );
      },
    );

    /// A control handed its own shadow already casts at rest — reverse
    /// has nothing to invert there, so it keeps `defaultMotion`'s
    /// hide-and-travel exactly the way [noShadow] does above.
    testWidgets('a stated shadow outranks reverse', (tester) async {
      final resolved = await resolveUnder(
        tester,
        castMotion: .reverse,
        boxShadow: CoreShadow.md,
      );

      expect(
        resolved.reverseCastMotion,
        isFalse,
        reason:
            'an authored shadow already casts at rest — there is '
            'nothing left for reverse to invert',
      );
      expect(resolved.boxShadow, isNotNull);
      expect(
        resolved.pressedTranslateOffset,
        isNot(CoreOffset.zero),
        reason: 'the surviving cast still travels the defaultMotion way',
      );
    });
  });
}
