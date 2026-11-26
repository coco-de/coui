// Tests for CoreValidationBadgeStyle defaults — `defaultsBySize` coverage
// (#3773) and the border token category of `defaultsByState` (#3325).
//
// `defaultsBySize` net: before this file, CoreValidationBadgeStyle
// had zero tests pinning `defaultsBySize` coverage — a
// `CoreValidationBadgeSize` member could be added without a matching
// entry and the only signal would be a runtime crash the first time
// some resolver hit `defaultsBySize[size]!` (a Map lookup, not a
// `switch`, so Dart's exhaustiveness checker never sees it).

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreValidationBadgeStyle.defaultsBySize (#3773)', () {
    test('covers every CoreValidationBadgeSize member', () {
      for (final size in CoreValidationBadgeSize.values) {
        expect(
          CoreValidationBadgeStyle.defaultsBySize[size],
          isNotNull,
          reason:
              'missing size chrome for CoreValidationBadgeSize.${size.name}'
              ' — every `defaultsBySize[size]!` lookup in the resolvers '
              'assumes full coverage and would crash at runtime',
        );
      }
    });

    test('has exactly one entry per CoreValidationBadgeSize member', () {
      // Guards the other direction: a stale entry left behind after a
      // member is removed from CoreValidationBadgeSize.
      expect(
        CoreValidationBadgeStyle.defaultsBySize.length,
        CoreValidationBadgeSize.values.length,
      );
    });
  });

  // Issue #3325 — where a border colour may come from.
  //
  // `pending` used to draw its border from `surfaceContainerHigh` over a
  // `surfaceContainer` fill. The surface ramp is a run of adjacent steps,
  // so the stroke sat ~1.1:1 against its own fill (and vanished entirely
  // in a consumer theme that mapped both tiers to one primitive). Nothing
  // in the type system prevents that, so guard it — the same invariant the
  // Button outline variant carries.
  group('token category (#3325)', () {
    test('no state reads its border from a surface alias', () {
      for (final MapEntry(key: state, value: colors)
          in CoreValidationBadgeStyle.defaultsByState.entries) {
        final token = colors.borderColor.token;
        if (token == null) continue;

        expect(
          token.name.startsWith('surface'),
          isFalse,
          reason:
              '${state.name}.borderColor references the surface alias '
              '"${token.name}". A surface tier sits one step from the fill '
              'and vanishes in themes that fold adjacent tiers together.',
        );
      }
    });
  });

  // Designer decision (2026-10-01) — the three state borders carry the
  // same weight. Each is the state's representative colour at 20%:
  // `success` for valid, `error` for invalid, and — pending having no state
  // colour of its own — the pending label colour. A solid `outline` on
  // pending measured 4.6:1 against its fill while valid / invalid sit near
  // 1.3:1, which made "not judged yet" the loudest of the three.
  group('state border weight', () {
    test('every state border is a 20% tint', () {
      for (final MapEntry(key: state, value: colors)
          in CoreValidationBadgeStyle.defaultsByState.entries) {
        expect(
          colors.borderColor.opacity,
          CoreOpacity.opacity20,
          reason:
              '${state.name}.borderColor is not a 20% tint — the three '
              'state borders must carry the same weight.',
        );
      }
    });

    test('pending border is its label colour at 20%, fill stays a surface', () {
      final pending = CoreValidationBadgeStyle
          .defaultsByState[CoreValidationState.pending]!;

      expect(
        pending.borderColor.token,
        CoreValidationBadgeStyle.defaultPendingForegroundColor.token,
      );
      expect(
        CoreValidationBadgeStyle.defaultPendingBorderColor,
        const CoreColor.token(
          CoreColors.onSurfaceVariant,
          opacity: CoreOpacity.opacity20,
        ),
      );
      // The fill is correct as a surface token — only the border moved.
      expect(pending.backgroundColor.token, CoreColors.surfaceContainer);
    });
  });
}
