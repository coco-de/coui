import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ResolvedCard> _resolveCard(
  WidgetTester tester,
  CoreSurfaceStyleId style,
  CoreCardStyle? cardStyle,
) async {
  late ResolvedCard seen;

  final _ = await tester.pumpWidget(
    CoUIApp(
      surfaceStyle: style,
      home: Builder(
        builder: (context) {
          seen = resolveCard(
            context,
            variant: .defaultVariant,
            mediaPresent: false,
            cardStyle: cardStyle,
          );

          return const SizedBox.shrink();
        },
      ),
      theme: ThemeData.fromCore(CoreThemePresets.light),
    ),
  );
  // The app cross-fades themes, so the first frame after a style change
  // is still the old geometry.
  final _ = await tester.pumpAndSettle();

  return seen;
}

void main() {
  group('a card with no authored shadow takes the active style\'s cast', () {
    testWidgets('neo-brutalism boxes a rest-elevation card', (tester) async {
      // `elevation: .none` (the default) authors nothing, and
      // neo-brutalism's identity is that every plain surface looks
      // boxed — so `OutlinedContainer` substitutes its `controlShadow`.
      // This is intentional, pre-existing behaviour independent of any
      // caller override.
      final resolved = await _resolveCard(
        tester,
        .neoBrutalism,
        null,
      );

      expect(resolved.containerStyle.boxShadow, isNull);
    });
  });

  group('an explicit empty boxShadow suppresses the ambient cast too', () {
    testWidgets(
      'CoreCardStyle(boxShadow: CoreShadow.none) forwards a real empty '
      'list, not null',
      (tester) async {
        // `null` still falls through to the style's `controlShadow` — the
        // suppression has to travel as a real (if empty) list, the same
        // way Web's `Card` gates its ambient-shadow class off
        // `merged.boxShadow == null` rather than "is the value empty".
        // Wrapping a card that already opts out like this in
        // `Hover(effect: .shadow)` used to show two hard, offset shadows
        // stacked under neo-brutalism — one from this ambient cast, one
        // from Hover's own — because the ambient one had no way to be
        // switched off through `CoreCardStyle`'s public API.
        final resolved = await _resolveCard(
          tester,
          .neoBrutalism,
          const CoreCardStyle(boxShadow: CoreShadow.none),
        );

        expect(resolved.containerStyle.boxShadow, const <CoreShadowLayer>[]);
      },
    );

    testWidgets('under the default style there is nothing to suppress', (
      tester,
    ) async {
      // The default style states no ambient cast at all, so an explicit
      // empty override and "authored nothing" already agree — this pins
      // that the forwarding does not introduce a *new* shadow where the
      // default style never drew one.
      final withOverride = await _resolveCard(
        tester,
        .defaultStyle,
        const CoreCardStyle(boxShadow: CoreShadow.none),
      );
      final withoutOverride = await _resolveCard(
        tester,
        .defaultStyle,
        null,
      );

      expect(withOverride.containerStyle.boxShadow, const <CoreShadowLayer>[]);
      expect(withoutOverride.containerStyle.boxShadow, isNull);
    });
  });

  group('a real custom override is not forwarded — it keeps its own path', () {
    testWidgets(
      'a non-empty boxShadow stays out of containerStyle (paints via the '
      'caller-override DecoratedBox instead)',
      (tester) async {
        // Only the *explicit empty* signal travels into
        // `containerStyle.boxShadow` — a real stack keeps painting
        // through `ResolvedCard.boxShadowOverride`'s separate
        // `DecoratedBox`, unchanged. Forwarding it here too would bend
        // it a second time (`OutlinedContainer`'s own `theme.geometry
        // .shadow` call) and paint it twice.
        final resolved = await _resolveCard(
          tester,
          .neoBrutalism,
          const CoreCardStyle(boxShadow: CoreShadow.xl),
        );

        expect(resolved.containerStyle.boxShadow, isNull);
        expect(resolved.boxShadowOverride, isNotNull);
        expect(resolved.boxShadowOverride, isNotEmpty);
      },
    );
  });
}
