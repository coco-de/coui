// The category slots as the scheme carries them — the names, the readers,
// the map round-trip and the resolved scheme's narrowing getters.
//
// Every check walks CoreCategoryColor × CoreCategorySlot, so it covers each
// slot without listing one. Colours are compared by `argb`: a colour read
// off a scheme is tagged with its token, which a raw colour is not.
import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

import 'support/brand_fixture.dart';

/// Every (hue, slot) pair, hue by hue.
final List<(CoreCategoryColor, CoreCategorySlot)> _kPairs = [
  for (final color in CoreCategoryColor.values)
    for (final slot in CoreCategorySlot.values) (color, slot),
];

/// A colour no mapping states, different for every pair — so a reader that
/// reads another field returns another pair's probe, never its own.
CoreColor _probe(int index) => CoreColor(0xFF000000 | 0x010203 * (index + 1));

String _label(CoreCategoryColor color, CoreCategorySlot slot) =>
    slot.cssName(color);

void main() {
  test('the catalog literal, the slot name and the token name agree', () {
    // The catalog literal is what the stylesheet guard reads, the slot name
    // is what the emitters write and the token name is what a component
    // names — three spellings of one vocabulary, so each must be all of it.
    final source = File(
      'lib/src/color/core_color_token.dart',
    ).readAsStringSync();
    final literals = [
      for (final m in RegExp(
        r"CoreColorToken\._\(\s*'((?:on-)?category-[a-z-]+)'",
      ).allMatches(source))
        m.group(1)!,
    ];
    final cssNames = [for (final (c, s) in _kPairs) s.cssName(c)];
    final tokenNames = [for (final (c, s) in _kPairs) c.token(s).name];

    for (final names in [literals, cssNames, tokenNames]) {
      expect(names.toSet(), hasLength(_kPairs.length));
    }
    expect(literals.toSet(), cssNames.toSet());
    expect(tokenNames.toSet(), cssNames.toSet());
  });

  group('each slot is read, written and parsed as itself', () {
    // The base supplies the six required roots; every category slot then
    // carries a probe of its own.
    final probed = CoreColorScheme.fromMap({
      ...kBrandFixtureSource.light().toMap(),
      for (final (i, (c, s)) in _kPairs.indexed)
        s.cssName(c): _probe(i).toHex(),
    });

    test('each token reads the slot fromMap filled under its name', () {
      // A reader copied from its neighbour and left pointing at the
      // neighbour's field, or a key fromMap does not read, both land here.
      for (final (i, (c, s)) in _kPairs.indexed) {
        expect(
          c.token(s).read(probed)?.argb,
          _probe(i).argb,
          reason: _label(c, s),
        );
      }
    });

    test('toMap writes each slot under its name', () {
      final map = probed.toMap();
      for (final (i, (c, s)) in _kPairs.indexed) {
        expect(map[s.cssName(c)], _probe(i).toHex(), reason: _label(c, s));
      }
    });

    test('fromMap reads back what toMap wrote', () {
      final back = CoreColorScheme.fromMap(probed.toMap());
      for (final (c, s) in _kPairs) {
        expect(
          c.token(s).read(back)?.argb,
          c.token(s).read(probed)!.argb,
          reason: _label(c, s),
        );
      }
    });
  });

  test('the tokenized schemes name each slot by its own token', () {
    for (final (c, s) in _kPairs) {
      final token = c.token(s);
      expect(
        token.read(const CoreColorScheme.tokenized()),
        CoreColor.token(token),
        reason: token.name,
      );
      expect(
        token.read(const ResolvedColorScheme.tokenized()),
        CoreColor.token(token),
        reason: token.name,
      );
    }
  });

  test('a fill and a container name their label; nothing else does', () {
    for (final c in CoreCategoryColor.values) {
      expect(CoreColors.onColorOf(c.fill), c.onFill, reason: c.name);
      expect(CoreColors.onColorOf(c.container), c.onContainer, reason: c.name);
      for (final token in [c.outline, c.onFill, c.onContainer]) {
        expect(CoreColors.onColorOf(token), isNull, reason: token.name);
      }
    }
  });

  group('ResolvedColorScheme narrows every slot', () {
    // Read from source because the compiler holds only half of this class.
    // A constructor parameter left out fails to compile, but a narrowing
    // getter left out does not: the slot then reads as nullable through the
    // resolved type, and nothing fails until a consumer reads it. An
    // explicit parameter that is never handed to `super` compiles too, and
    // leaves the slot null for its getter to throw on.
    //
    // The six roots are excluded: the base class takes them non-null.
    const roots = {
      'primary',
      'secondary',
      'error',
      'success',
      'warning',
      'info',
    };
    final slots = RegExp(r'^\s+final CoreColor\??\s+(\w+);', multiLine: true)
        .allMatches(
          File('lib/src/color/color_scheme.dart').readAsStringSync(),
        )
        .map((m) => m.group(1)!)
        .toSet()
        .difference(roots);
    final resolved = File(
      'lib/src/color/resolved_color_scheme.dart',
    ).readAsStringSync();
    final explicit = RegExp(
      r'required CoreColor (\w+),',
    ).allMatches(resolved).map((m) => m.group(1)!).toSet();
    final typedSuper = RegExp(
      r'required CoreColor super\.(\w+),',
    ).allMatches(resolved).map((m) => m.group(1)!).toSet();

    test('the field scan finds every category slot', () {
      // Without this, a stale pattern would compare two empty sets.
      expect(slots, containsAll([for (final (c, s) in _kPairs) _field(c, s)]));
    });

    test('each slot has a narrowing getter', () {
      final getters = RegExp(
        r'CoreColor get (\w+) =>\s*super\.\1!;',
      ).allMatches(resolved).map((m) => m.group(1)!).toSet();

      expect(getters, slots);
    });

    test('each slot is a required non-null parameter', () {
      expect(explicit.intersection(typedSuper), isEmpty);
      expect(explicit.union(typedSuper), slots);
    });

    test('each explicit parameter is handed to super', () {
      expect(
        [
          for (final name in explicit)
            if (!resolved.contains('$name: $name,')) name,
        ],
        isEmpty,
      );
    });
  });
}

/// The scheme field of a pair — `on-category-red-container` →
/// `onCategoryRedContainer`.
String _field(CoreCategoryColor color, CoreCategorySlot slot) {
  final parts = slot.cssName(color).split('-');

  return [
    parts.first,
    for (final part in parts.skip(1))
      '${part[0].toUpperCase()}${part.substring(1)}',
  ].join();
}
