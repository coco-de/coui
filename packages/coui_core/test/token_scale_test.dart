import 'package:test/test.dart';

import '../bin/figma_reader/token_scale.dart';

void main() {
  group('resolveNamespaces — against the real coui_core namespace sources', () {
    late Map<String, TokenEntry> table;

    setUpAll(() {
      table = resolveNamespaces(repoRoot: '.', srcRoot: 'lib/src');
    });

    test('resolves a plain literal with no alias hops', () {
      final e = table['CoreSpace.space16']!;
      expect(e.value, 16.0);
      expect(e.ref, 'Primitives/space/16');
      expect(e.via, isEmpty);
    });

    test('a fractional step keys its Figma variable with an underscore', () {
      // Figma refuses a `.` in a variable name (`createVariable` throws
      // "invalid variable name"), so the hairline is `stroke/0_5` — the
      // member's own spelling, not `stroke/0.5`.
      final e = table['CoreStrokeWidth.stroke0_5']!;
      expect(e.value, 0.5);
      expect(e.ref, 'Primitives/stroke/0_5');
      expect(e.via, isEmpty);
    });

    test('the whole-number strokes are not touched by it', () {
      expect(table['CoreStrokeWidth.stroke1']!.ref, 'Primitives/stroke/1');
      expect(table['CoreStrokeWidth.stroke0']!.ref, 'Primitives/stroke/0');
    });

    test('the step between 4 and 6 resolves to its own variable', () {
      final e = table['CoreStrokeWidth.stroke5']!;
      expect(e.value, 5.0);
      expect(e.ref, 'Primitives/stroke/5');
      expect(e.via, isEmpty);
    });

    test('resolves a same-class alias (1 hop) and records via', () {
      // CoreDuration.fast = ms150 — the exact example from #3747's spec.
      final e = table['CoreDuration.fast']!;
      expect(e.value, 150);
      expect(e.ref, 'Primitives/duration/150');
      expect(e.via, ['ms150']);
    });

    test('resolves a cross-namespace alias chain (2 hops)', () {
      // CoreIconSize.defaultSize -> size24 -> CoreSize.size24.
      final e = table['CoreIconSize.defaultSize']!;
      expect(e.value, 24.0);
      expect(e.via, ['size24', 'CoreSize.size24']);
      // The hop chain is what this test is about; the `ref` it lands on is
      // asserted by the test below, which owns that decision.
      expect(e.ref, 'Component/icon-size/24');
    });

    test('the icon-size ladder is its own group in code AND in Figma', () {
      // Two different questions, and they have different answers.
      //
      // In Dart the ladder is its own namespace, and that is deliberate —
      // `size/icon_size.dart` says naming the ladder is what lets a new
      // component pick a step instead of a number. `via` records the hop, so
      // the distinction survives.
      expect(table['CoreIconSize.size24']!.via, ['CoreSize.size24']);
      // In Figma it now has a group of its own, in a different COLLECTION:
      // `Component / icon-size/24`. That reverses what this test used to
      // assert, and the reason is worth keeping: it bound to `Primitives/space`
      // because no `icon-size` group existed in Figma (#3736 F1 declined to
      // ship one — `CoreSize` duplicates 45 of its 46 values with `CoreSpace`),
      // and emitting a name that resolved to nothing made `lk.size(...)` throw,
      // which rolled 33 of 101 entries back. The seven-collection alignment
      // shipped the group, so the name resolves and the ladder is where the
      // exporter puts it.
      //
      // Asserted against the exporter's own output below rather than trusted
      // from here: a ref that resolves to nothing is exactly the failure above.
      expect(table['CoreIconSize.size24']!.ref, 'Component/icon-size/24');
      // `CoreSize` also has its own group now (`Primitives / size/24`, 24
      // members) rather than folding into `space`. Same reversal, same reason:
      // the fold existed because the group did not.
      expect(table['CoreSize.size24']!.ref, 'Primitives/size/24');
    });

    test('String-typed leaf (CoreZIndex.zAuto) resolves and lowercases', () {
      final e = table['CoreZIndex.zAuto']!;
      expect(e.value, 'auto');
      expect(e.ref, 'Primitives/z-index/auto');
    });

    test('semantic (non-numeric-suffix) member passes leaf key through', () {
      final e = table['CoreOpacity.hover']!;
      expect(e.ref, 'Primitives/opacity/3');
      expect(e.via, ['opacity3']);
    });

    test('font-weight leaf key is fully lowercased, not just first char', () {
      final e = table['CoreFontWeight.semiBold']!;
      // `font/weight/*`, not `font-weight/*`. Both exist in Figma and they are
      // different tiers: `Primitives / font/weight/semibold` is the raw ladder
      // this class IS, while `Semantic/ Typography / font-weight/body` is a
      // role alias pointing INTO it. Naming the semantic one here resolved to a
      // variable that does not carry a weight for `semiBold` at all.
      expect(e.ref, 'Primitives/font/weight/semibold');
    });

    test('.scale record members are not scalar primitives — skipped', () {
      expect(table.containsKey('CoreZIndex.scale'), isFalse);
    });

    test('two consecutive resolutions are byte-identical (determinism)', () {
      final second = resolveNamespaces(repoRoot: '.', srcRoot: 'lib/src');
      expect(second.keys.toList(), table.keys.toList());
      for (final key in table.keys) {
        expect(second[key]!.value, table[key]!.value);
        expect(second[key]!.ref, table[key]!.ref);
        expect(second[key]!.via, table[key]!.via);
      }
    });
  });

  group('resolveNamespaces — forward-only contract', () {
    test('throws rather than silently resolving to nothing when a '
        "namespace source can't be found (stale spec must fail loudly)", () {
      expect(
        () => resolveNamespaces(repoRoot: '.', srcRoot: 'lib/does_not_exist'),
        throwsA(anything),
      );
    });
  });
}
