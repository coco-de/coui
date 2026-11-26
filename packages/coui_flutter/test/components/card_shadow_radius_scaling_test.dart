import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression test for good-teacher issue #1511 — a Card whose
/// `cardStyle.boxShadow` is overridden (directly, or inherited from the
/// active `CoreCardTheme.style.boxShadow`) paints that shadow through a
/// caller-override `DecoratedBox` clipped to [ResolvedCard
/// .interactiveBorderRadius]. That radius used to skip the `* scaling`
/// step that every other dimensional field on this resolver applies
/// (padding, hover shadow offsets, …) and that `OutlinedContainer` itself
/// applies to the radius of the surface this wrapper wraps. Under any
/// `theme.scaling` other than 1.0 the two nested rounded shapes disagreed
/// — straight edges still lined up (a radius mismatch has no effect
/// there), but the corner showed a visible seam where the (correctly
/// scaled) surface corner didn't nest inside the (unscaled) shadow-clip
/// corner. On a small-radius Card this read as a dark "shadow colour
/// poking out" artifact at each corner.
Future<ResolvedCard> _resolveCard(WidgetTester tester, double scaling) async {
  late ResolvedCard seen;

  const cardStyle = CoreCardStyle(
    borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    // Non-empty override so `boxShadowOverride` is populated and the
    // caller-override `DecoratedBox`/`interactiveBorderRadius` path is
    // actually exercised — mirrors an app theme's `card.style.boxShadow`,
    // which every Card inherits unless it opts out with an explicit
    // empty list (good-teacher issue #1511's actual trigger).
    boxShadow: CoreShadow.sm,
  );

  final _ = await tester.pumpWidget(
    CoUIApp(
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
      theme: ThemeData.fromCore(
        CoreThemePresets.light,
      ).copyWith(scaling: () => scaling),
    ),
  );
  final _ = await tester.pumpAndSettle();

  return seen;
}

void main() {
  testWidgets(
    'interactiveBorderRadius scales with theme.scaling, matching every '
    'other dimensional field this resolver scales',
    (tester) async {
      final atOneX = await _resolveCard(tester, 1);
      final atOnePointFiveX = await _resolveCard(tester, 1.5);

      // The un-scaled (buggy) formula would return the same BorderRadius
      // at both scaling factors — this pins that it does not.
      expect(
        atOnePointFiveX.interactiveBorderRadius,
        isNot(atOneX.interactiveBorderRadius),
        reason:
            'interactiveBorderRadius must not be identical at 1.0x and '
            '1.5x scaling — that was the bug (the shadow-clip radius '
            'stayed at the unscaled geometry value while the surface it '
            'wraps scaled its own radius, so the two nested rounded '
            'shapes disagreed at the corner)',
      );

      // And it must scale by exactly the same factor as every other
      // dimensional field on this resolver (mirrors `OutlinedContainer`'s
      // own `_resolveBorderRadius(...) * scaling`).
      final ratio =
          atOnePointFiveX.interactiveBorderRadius.topLeft.x /
          atOneX.interactiveBorderRadius.topLeft.x;
      expect(ratio, closeTo(1.5, 0.0001));
    },
  );
}
