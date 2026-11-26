// Tests for CoreStatusStyle.defaultsBySize — #3773.
//
// Scope: the `defaultsBySize` (size axis) regression net only (issue
// #3773's completion definition). `CoreStatusStyle` also has a
// `defaultsByColor` map, but that is a different axis (color, not
// size) and out of scope here. Before this file, CoreStatusStyle had
// zero tests pinning `defaultsBySize` coverage — a `CoreStatusSize`
// member could be added without a matching entry and the only signal
// would be a runtime crash the first time some resolver hit
// `defaultsBySize[size]!` (a Map lookup, not a `switch`, so Dart's
// exhaustiveness checker never sees it).

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreStatusStyle.defaultsBySize (#3773)', () {
    test('covers every CoreStatusSize member', () {
      for (final size in CoreStatusSize.values) {
        expect(
          CoreStatusStyle.defaultsBySize[size],
          isNotNull,
          reason:
              'missing size chrome for CoreStatusSize.${size.name} — '
              'every `defaultsBySize[size]!` lookup in the resolvers '
              'assumes full coverage and would crash at runtime',
        );
      }
    });

    test('has exactly one entry per CoreStatusSize member', () {
      // Guards the other direction: a stale entry left behind after a
      // member is removed from CoreStatusSize.
      expect(
        CoreStatusStyle.defaultsBySize.length,
        CoreStatusSize.values.length,
      );
    });

    test('every entry sets a non-null size', () {
      // The Flutter resolver chains a *second* `!` onto this lookup —
      // `defaultsBySize[size]!.size!` — so coverage of the map key
      // alone is not the whole story: the `size` field on every entry
      // must also be non-null, or that second `!` throws even though
      // the key exists.
      for (final size in CoreStatusSize.values) {
        expect(
          CoreStatusStyle.defaultsBySize[size]!.size,
          isNotNull,
          reason:
              'CoreStatusSize.${size.name} entry has no `size` — '
              '`defaultsBySize[size]!.size!` would crash at runtime',
        );
      }
    });
  });

  group('CoreStatusStyle designer values (#5879)', () {
    test('busy bar length runs 4 · 4 · 6 · 8 · 8 from xs to xl', () {
      expect(
        [
          for (final size in CoreStatusSize.values)
            CoreStatusStyle.defaultsBySize[size]!.barLength,
        ],
        [4, 4, 6, 8, 8],
      );
    });

    test(
      'every state label reads on-surface, offline alone on-surface-variant',
      () {
        for (final size in CoreStatusSize.values) {
          expect(
            CoreStatusStyle.defaultsBySize[size]!.labelStyle!.color,
            const CoreColor.token(CoreColors.onSurface),
          );
        }
        for (final state in CoreStatusVariant.values) {
          final label = CoreStatusStyle.defaultsByVariant[state]!.labelStyle;
          if (state == CoreStatusVariant.offline) {
            expect(
              label?.color,
              const CoreColor.token(CoreColors.onSurfaceVariant),
            );
          } else {
            expect(label, isNull, reason: '$state keeps the size row colour');
          }
        }
      },
    );

    test('the offline ring is outline, not on-surface-variant', () {
      expect(
        CoreStatusStyle.defaultsByVariant[CoreStatusVariant.offline]!.color,
        const CoreColor.token(CoreColors.outline),
      );
    });
  });

  group('busy bar corners', () {
    test('round ends by default — the full radius', () {
      expect(
        CoreStatusStyle.defaultBarBorderRadius,
        const CoreBorderRadius.all(CoreRadius.radius9999),
      );
    });

    test('barBorderRadius takes part in merge, copyWith and ==', () {
      const stated = CoreBorderRadius.zero;
      const a = CoreStatusStyle(barBorderRadius: stated);
      expect(const CoreStatusStyle().merge(a).barBorderRadius, stated);
      expect(const CoreStatusStyle().copyWith(barBorderRadius: stated), a);
      expect(a == const CoreStatusStyle(), isFalse);
      expect(a.hashCode == const CoreStatusStyle().hashCode, isFalse);
    });
  });
}
