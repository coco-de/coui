// The brand value tables as the Figma export publishes them
// (`tools/figma-token-sync/src/data/brands.json`) — and what that makes of
// the library.
//
// A brand is not a collection of the library: the library carries ONE
// `Semantic/ Color · <library brand>` collection and its primitives, and every
// other brand in `kFigmaBrands` is a table of the values that differ from it,
// which the plugin writes into an extension of that one collection in a
// consumer file. So the library brand's colours are read through the exported
// token document, and a table brand's through the table laid over them — and
// the one property that matters is that doing so gives back exactly what the
// brand's own source says.
//
// Runs the real exporter (in a temp directory, because it writes
// `build/tokens.figma.json` and `brands.json` relative to its working
// directory): the tables are a property of the whole emitted document, so a
// fixture would only prove the fixture.
import 'dart:convert';
import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

import '../bin/figma_brands/brands.dart';

const _kModes = ['Light', 'Dark', 'HCLight', 'HCDark'];

/// A Figma colour `{r, g, b, a}` (0–1) as `RRGGBB`, plus `@alpha` when it is
/// not opaque.
String _hex(Map<String, dynamic> c) {
  String channel(String k) =>
      ((c[k] as num) * 255).round().toRadixString(16).padLeft(2, '0');
  final a = (c['a'] as num).toDouble();

  return '${channel('r')}${channel('g')}${channel('b')}'.toUpperCase() +
      (a == 1.0 ? '' : '@${a.toStringAsFixed(4)}');
}

/// `'R G B'` as `RRGGBB`.
String _hexOf(String triplet) => triplet
    .trim()
    .split(RegExp(r'\s+'))
    .map((x) => int.parse(x).toRadixString(16).padLeft(2, '0'))
    .join()
    .toUpperCase();

void main() {
  late Map<String, dynamic> tokens;
  late Map<String, dynamic> brandsDoc;
  late List<Map<String, dynamic>> collections;
  // Primitive name -> `{r, g, b, a}`.
  late Map<String, Map<String, dynamic>> primitiveValue;
  // Library slot name -> mode -> resolved `{r, g, b, a}`.
  late Map<String, Map<String, Map<String, dynamic>>> library;
  // Brand id -> slot name -> mode -> `{r, g, b, a}`.
  late Map<String, Map<String, Map<String, Map<String, dynamic>>>> overrides;

  final libraryBrand = kFigmaBrands.all.first;
  final tableBrands = kFigmaBrands.all.skip(1).toList();

  setUpAll(() {
    final script = File('bin/export_figma_tokens.dart').absolute.path;
    final tmp = Directory.systemTemp.createTempSync('coui_brand_table_');
    addTearDown(() => tmp.deleteSync(recursive: true));

    final result = Process.runSync(Platform.resolvedExecutable, [
      'run',
      script,
    ], workingDirectory: tmp.path);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');

    tokens =
        jsonDecode(
              File('${tmp.path}/build/tokens.figma.json').readAsStringSync(),
            )
            as Map<String, dynamic>;
    brandsDoc =
        jsonDecode(
              File(
                '${tmp.path}/tools/figma-token-sync/src/data/brands.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    collections = (tokens['collections'] as List).cast<Map<String, dynamic>>();

    final primitives = collections.singleWhere(
      (c) => c['name'] == 'Primitives',
    );
    primitiveValue = {
      for (final v
          in (primitives['variables'] as List).cast<Map<String, dynamic>>())
        if ((v['name'] as String).startsWith('color/'))
          v['name'] as String:
              (v['valuesByMode'] as Map<String, dynamic>)['Value']
                  as Map<String, dynamic>,
    };

    final semantic = collections.singleWhere(
      (c) => c['name'] == 'Semantic/ Color · ${libraryBrand.displayName}',
    );
    Map<String, dynamic> resolve(Map<String, dynamic> value) {
      final alias = value['alias'] as String?;
      if (alias == null) return value;
      const prefix = 'Primitives/';
      expect(alias, startsWith(prefix));

      return primitiveValue[alias.substring(prefix.length)]!;
    }

    library = {
      for (final v
          in (semantic['variables'] as List).cast<Map<String, dynamic>>())
        v['name'] as String: {
          for (final MapEntry(key: mode, :value)
              in (v['valuesByMode'] as Map<String, dynamic>).entries)
            mode: resolve(value as Map<String, dynamic>),
        },
    };

    overrides = {
      for (final b
          in (brandsDoc['brands'] as List).cast<Map<String, dynamic>>())
        b['id'] as String: {
          for (final o in (b['overrides'] as List).cast<Map<String, dynamic>>())
            o['name'] as String: {
              for (final MapEntry(key: mode, :value)
                  in (o['valuesByMode'] as Map<String, dynamic>).entries)
                mode: value as Map<String, dynamic>,
            },
        },
    };
  });

  /// The value [brandId] has for [slot] in [mode]: its own override, else the
  /// library brand's.
  Map<String, dynamic> valueOf(String brandId, String slot, String mode) =>
      overrides[brandId]![slot]?[mode] ?? library[slot]![mode]!;

  Map<String, ResolvedColorScheme> schemesOf(CoreBrand brand) {
    final source = brand.source;

    return {
      'Light': source.light().resolved(.light),
      'Dark': source.dark().resolved(.dark),
      'HCLight': source.highContrastLight().resolved(.light),
      'HCDark': source.highContrastDark().resolved(.dark),
    };
  }

  group('the library', () {
    test('carries one Semantic/Color collection — the library brand', () {
      expect(libraryBrand.id, 'coui');
      expect(
        [
          for (final c in collections)
            if ((c['name'] as String).startsWith('Semantic/ Color')) c['name'],
        ],
        ['Semantic/ Color · ${libraryBrand.displayName}'],
      );
    });

    test('carries no primitive of a table brand', () {
      for (final brand in tableBrands) {
        expect(
          [
            for (final name in primitiveValue.keys)
              if (name.startsWith('color/${brand.id}/')) name,
          ],
          isEmpty,
          reason: brand.id,
        );
      }
    });

    test('the table document says which collection it extends and in which '
        'modes', () {
      expect(brandsDoc['library'], {
        'brand': libraryBrand.id,
        'collection': 'Semantic/ Color · ${libraryBrand.displayName}',
        'modes': _kModes,
      });
      expect(
        [for (final b in brandsDoc['brands'] as List) (b as Map)['id']],
        [for (final b in tableBrands) b.id],
      );
    });
  });

  group('a table laid over the library gives back the brand', () {
    for (final brand in tableBrands) {
      test('${brand.displayName}: every Semantic slot, in every mode', () {
        final schemes = schemesOf(brand);
        var checked = 0;
        for (final mode in _kModes) {
          final vars = PrimitiveCssGenerator.semanticVars(schemes[mode]!);
          for (final MapEntry(key: cssVar, value: triplet) in vars.entries) {
            final slot = 'color/${cssVar.replaceFirst('--coui-', '')}';
            expect(library, contains(slot), reason: slot);
            expect(
              _hex(valueOf(brand.id, slot, mode)),
              _hexOf(triplet),
              reason: '${brand.id} $slot $mode',
            );
            checked++;
          }
        }
        expect(checked, greaterThan(400));
      });

      test('${brand.displayName}: every shadow colour row, in every mode', () {
        final schemes = schemesOf(brand);
        var checked = 0;
        for (final mode in _kModes) {
          final dark = mode.endsWith('Dark') || mode == 'Dark';
          final shadow = schemes[mode]!.shadow;
          for (final slot in library.keys.where(
            (n) => n.startsWith('effect/shadow/'),
          )) {
            final lib = library[slot]![mode]!;
            final got = valueOf(brand.id, slot, mode);
            // The brand's own `shadow` slot at the library row's alpha — the
            // alpha is the layer's, whoever the brand is.
            final argb = shadow.argb;
            final want = {
              'r': ((argb >> 16) & 0xFF) / 255,
              'g': ((argb >> 8) & 0xFF) / 255,
              'b': (argb & 0xFF) / 255,
              'a': lib['a'],
            };
            expect(
              _hex(got),
              _hex(want),
              reason: '${brand.id} $slot $mode (dark: $dark)',
            );
            checked++;
          }
        }
        expect(checked, 10 * 4);
      });
    }
  });

  group('a table is a difference, not a second copy', () {
    for (final brand in tableBrands) {
      test('${brand.displayName}: no row repeats the library, in any mode', () {
        final table = overrides[brand.id]!;
        expect(table, isNotEmpty);
        for (final MapEntry(key: slot, value: byMode) in table.entries) {
          expect(byMode, isNotEmpty, reason: slot);
          for (final MapEntry(key: mode, :value) in byMode.entries) {
            expect(
              _hex(value),
              isNot(_hex(library[slot]![mode]!)),
              reason: '${brand.id} $slot $mode',
            );
          }
        }
      });

      test('${brand.displayName}: only a slot the library states, in a mode '
          'the library has', () {
        for (final MapEntry(key: slot, value: byMode)
            in overrides[brand.id]!.entries) {
          expect(library, contains(slot));
          expect(_kModes, containsAll(byMode.keys), reason: slot);
        }
      });

      test('${brand.displayName}: states nothing a shared group links — the '
          'category and syntax tones are the same in every brand', () {
        // The links are by name to a tone of the group; a brand-owned value
        // there would be a brand pretending to own a shared colour. (A slot a
        // group does NOT link — the strong label, the syntax function — reads
        // the brand's own ramps and belongs in its table.)
        final linked = <String>{
          for (final brightness in CoreBrightness.values) ...[
            ...CoreSyntaxPalette.primitiveLinks(brightness).keys,
            for (final highContrast in [false, true])
              ...CoreCategoryPalette.primitiveLinks(
                brightness,
                highContrast: highContrast,
              ).keys,
          ],
        };
        expect(linked, isNotEmpty);
        for (final slot in overrides[brand.id]!.keys) {
          expect(
            linked,
            isNot(contains(slot.replaceFirst('color/', ''))),
            reason: slot,
          );
        }
      });
    }
  });

  group('what the brands read', () {
    // The moved intents of the per-brand alias tests: a brand reads its OWN
    // ramps where the standard mapping says it does. The value a brand ends
    // up with is the colour of that step of the brand's own palette. A brand
    // made from one colour reads CoUI's mapping instead — its group follows.
    Map<String, String> primitivesOf(CoreBrand brand) => {
      for (final MapEntry(key: cssVar, value: triplet)
          in PrimitiveCssGenerator.primitiveVars(brand.source).entries)
        cssVar.replaceFirst('--coui-', ''): _hexOf(triplet),
    };

    for (final brand in tableBrands.where(
      (b) => b.source is CorePrimitiveSchemeSource,
    )) {
      final steps = primitivesOf(brand);
      String at(String slot, String mode) =>
          _hex(valueOf(brand.id, slot, mode));

      test('${brand.displayName}: link reads its info ramp, one step off the '
          'status colour', () {
        expect(
          [for (final mode in _kModes) at('color/link', mode)],
          [
            steps['info-darker'],
            steps['info-lighter'],
            steps['info-darkest'],
            steps['info-lightest'],
          ],
        );
        for (final mode in ['Light', 'Dark']) {
          expect(at('color/link', mode), isNot(at('color/info', mode)));
        }
      });

      test('${brand.displayName}: outline-subtle is its outline-variant', () {
        for (final mode in _kModes) {
          expect(
            at('color/outline-subtle', mode),
            at('color/outline-variant', mode),
            reason: mode,
          );
        }
      });

      test('${brand.displayName}: the status icons read its own ramps — '
          'warning one step darker', () {
        for (final family in ['success', 'info', 'warning', 'error']) {
          final light = family == 'warning' ? 'dark' : 'base';
          expect(
            [for (final mode in _kModes) at('color/$family-icon', mode)],
            [
              steps['$family-$light'],
              steps['$family-light'],
              steps['$family-darkest'],
              steps['$family-lightest'],
            ],
            reason: family,
          );
        }
      });

      test('${brand.displayName}: syntax function is its link step, and high '
          'contrast keeps the normal one', () {
        const normalOf = {
          'Light': 'Light',
          'Dark': 'Dark',
          'HCLight': 'Light',
          'HCDark': 'Dark',
        };
        for (final mode in _kModes) {
          expect(
            at('color/syntax-function', mode),
            at('color/link', normalOf[mode]!),
            reason: mode,
          );
        }
      });

      test('${brand.displayName}: the strong category label is its own pure '
          'white — and pure black in HC dark', () {
        for (final color in CoreCategoryColor.values) {
          for (final mode in _kModes) {
            expect(
              at('color/on-category-${color.name}', mode),
              mode == 'HCDark'
                  ? steps['neutral-pure-black']
                  : steps['neutral-pure-white'],
              reason: '${color.name} $mode',
            );
          }
        }
      });
    }
  });

  group('a brand made from one colour', () {
    // CoUI's mapping reads every shared slot, so the table of a colour brand
    // can differ from the library only in the primary family (which the CTA
    // rule fills from the brand's ramp) and in the status families the rule
    // turned away from the brand colour. Anything else in the table is a
    // shared slot that drifted.
    const primaryFamily = ['primary', 'tertiary', 'accent'];
    const primaryRuleSlots = {
      'color/surface-tint',
      'color/focus-ring',
    };

    for (final brand in tableBrands.where(
      (b) => b.source is CoreBrandSchemeSource,
    )) {
      test('${brand.displayName}: only the primary family and the turned '
          'status families differ from the library', () {
        final shifted =
            (brand.source as CoreBrandSchemeSource).palette.statusShifts.keys;
        final stray = [
          for (final slot in overrides[brand.id]!.keys)
            if (!primaryRuleSlots.contains(slot) &&
                !primaryFamily.any(slot.contains) &&
                !shifted.any(slot.contains))
              slot,
        ];
        expect(stray, isEmpty);
      });
    }
  });
  group('Medibooks is the values the designer put in the Figma DS file', () {
    // Read from the DS file (9FgsLhiWz0aLsVqcoI6nYJ) on 2026-11-10, read-only:
    // `Primitives/color/medibooks/*` and `Semantic/ Color · Medibooks` resolved
    // through its aliases. They were put there to be lifted into code, so code
    // has to be them.
    late Map<String, dynamic> figma;
    setUpAll(() {
      figma =
          jsonDecode(
                File(
                  'test/fixtures/medibooks_figma_values.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
    });

    final medibooks = kFigmaBrands['medibooks'];

    test('the 64 primitives are byte-exact', () {
      final want = (figma['primitives'] as Map).cast<String, String>();
      final got = {
        for (final MapEntry(key: cssVar, value: triplet)
            in PrimitiveCssGenerator.primitiveVars(medibooks.source).entries)
          cssVar.replaceFirst('--coui-', '').replaceFirst('-', '/'): _hexOf(
            triplet,
          ),
      };
      // `--coui-neutral-pure-white` -> `neutral/pure-white`: only the family
      // is separated from the step by a slash in the Figma name.
      expect(want, hasLength(64));
      expect(got.length, 64);
      for (final MapEntry(key: name, value: hex) in want.entries) {
        expect(got[name], hex, reason: name);
      }
    });

    test('every semantic slot the designer states is the same colour, in '
        'every mode — but the two a later code rule reads another way', () {
      final semantic = (figma['semantic'] as Map)
          .cast<String, Map<String, dynamic>>();
      final differs = <String>[];
      for (final MapEntry(key: slot, value: byMode) in semantic.entries) {
        for (final mode in _kModes) {
          final got = _hex(valueOf('medibooks', slot, mode));
          if (got != byMode[mode]) differs.add('$slot @ $mode');
        }
      }
      expect(differs, [
        // The designer's collection was written when this slot read the
        // light surface's grey ramp one step off; code now states the border
        // a brand has none of as its outline-variant (and the test above pins
        // that for every brand).
        'color/outline-subtle @ Light',
        'color/outline-subtle @ Dark',
        'color/outline-subtle @ HCLight',
        'color/outline-subtle @ HCDark',
        // The shadow colour is black in every mode ("the colour is not
        // flipped"); the collection flipped it to white in the dark modes.
        'color/shadow @ Dark',
        'color/shadow @ HCDark',
      ]);
    });
  });
}
