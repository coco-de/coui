// The syntax colours as the Figma export publishes them — one shared
// primitive group (`color/syntax/<hue>/<shade>`) outside every brand's path,
// three of each brand's four syntax slots aliasing it by name, and function
// names aliasing the brand's own info step by value.
//
// Runs the real exporter (in a temp directory, because it writes
// `build/tokens.figma.json` relative to its working directory): which rows the
// Primitives collection carries, and under what names, is a property of the
// whole emitted document, so a fixture would only prove the fixture.
import 'dart:convert';
import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kSharedPrefix = 'color/${CoreSyntaxPalette.namespace}/';

/// The Figma mode names, by the brightness each reads. High contrast reads
/// the same syntax tones as the normal mode of its brightness.
const Map<String, CoreBrightness> _kModes = {
  'Light': CoreBrightness.light,
  'Dark': CoreBrightness.dark,
  'HCLight': CoreBrightness.light,
  'HCDark': CoreBrightness.dark,
};

void main() {
  late List<Map<String, dynamic>> colourRows;
  late List<Map<String, dynamic>> syntaxRows;
  // Primitive name -> row.
  late Map<String, Map<String, dynamic>> primitivesByName;
  // Brand id -> that brand's rows by name.
  late Map<String, Map<String, Map<String, dynamic>>> semanticColour;

  setUpAll(() {
    final script = File('bin/export_figma_tokens.dart').absolute.path;
    final tmp = Directory.systemTemp.createTempSync('coui_syntax_');
    addTearDown(() => tmp.deleteSync(recursive: true));

    final result = Process.runSync(Platform.resolvedExecutable, [
      'run',
      script,
    ], workingDirectory: tmp.path);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');

    final doc =
        jsonDecode(
              File('${tmp.path}/build/tokens.figma.json').readAsStringSync(),
            )
            as Map<String, dynamic>;
    final collections = (doc['collections'] as List)
        .cast<Map<String, dynamic>>();
    final primitives = collections.singleWhere(
      (c) => c['name'] == 'Primitives',
    );
    primitivesByName = {
      for (final v
          in (primitives['variables'] as List).cast<Map<String, dynamic>>())
        v['name'] as String: v,
    };
    semanticColour = {
      for (final c in collections)
        if ((c['name'] as String).startsWith('Semantic/ Color · '))
          (c['name'] as String).split(' · ').last.toLowerCase(): {
            for (final v
                in (c['variables'] as List).cast<Map<String, dynamic>>())
              v['name'] as String: v,
          },
    };

    colourRows = [
      for (final v in primitivesByName.values)
        if ((v['name'] as String).startsWith('color/')) v,
    ];
    syntaxRows = [
      for (final v in colourRows)
        if ((v['name'] as String).startsWith(_kSharedPrefix)) v,
    ];
  });

  String tripletOf(Map<String, dynamic> row, String mode) {
    final value =
        (row['valuesByMode'] as Map<String, dynamic>)[mode]
            as Map<String, dynamic>;

    return [
      for (final channel in ['r', 'g', 'b'])
        ((value[channel] as num) * 255).round(),
    ].join(' ');
  }

  String aliasOf(String brand, String variable, String mode) {
    final row = semanticColour[brand]![variable];
    expect(row, isNotNull, reason: '$brand has no $variable');
    final values = row!['valuesByMode'] as Map<String, dynamic>;
    expect(values, contains(mode), reason: '$brand $variable');

    return (values[mode] as Map<String, dynamic>)['alias'] as String;
  }

  test('the shared group carries every syntax primitive, once', () {
    expect(syntaxRows, hasLength(CoreSyntaxPalette.primitives.length));
    expect(
      [for (final v in syntaxRows) v['name']],
      [for (final name in CoreSyntaxPalette.primitives.keys) 'color/$name'],
    );
  });

  test('each row holds the value the syntax table states', () {
    final triplets = PrimitiveCssGenerator.syntaxPrimitiveTriplets();
    for (final v in syntaxRows) {
      final name = (v['name'] as String).substring('color/'.length);
      expect(tripletOf(v, 'Value'), triplets[name], reason: name);
    }
  });

  test('no syntax primitive lands under a brand, or with hue and shade '
      'joined into one segment', () {
    final brandScoped = RegExp(
      '^color/[^/]+/${CoreSyntaxPalette.namespace}[/-]',
    );
    for (final v in colourRows) {
      final name = v['name'] as String;
      expect(name, isNot(matches(brandScoped)));
      for (final hue in CoreSyntaxHue.values) {
        for (final shade in CoreSyntaxShade.values) {
          expect(name, isNot(contains('${hue.name}-${shade.name}')));
        }
      }
    }
    for (final v in syntaxRows) {
      expect((v['name'] as String).split('/'), hasLength(4));
    }
  });

  test('every shared row is published, and says so', () {
    // Stated even though `false`: the importer only touches a variable whose
    // spec carries the key. Every row is published because every brand's
    // syntax slots read the group.
    expect(
      [
        for (final v in syntaxRows)
          if (v['hiddenFromPublishing'] != false) v['name'],
      ],
      isEmpty,
    );
  });

  test('the library brand publishes all four syntax slots', () {
    expect(semanticColour.keys, ['coui']);
    for (final brand in ['coui']) {
      for (final slot in CoreSyntaxSlot.values) {
        expect(
          semanticColour[brand],
          contains('color/${slot.token.name}'),
          reason: '$brand ${slot.token.name}',
        );
      }
    }
  });

  test('keyword, type and string alias the shade their mode reads, by '
      'name', () {
    for (final brand in ['coui']) {
      for (final MapEntry(key: mode, value: brightness) in _kModes.entries) {
        final links = CoreSyntaxPalette.primitiveLinks(brightness);
        expect(links, hasLength(3));
        for (final slot in CoreSyntaxSlot.values) {
          final hue = slot.hue;
          if (hue == null) continue;
          final name = CoreSyntaxPalette.primitiveName(
            hue,
            CoreSyntaxShade.of(brightness),
          );
          expect(links[slot.token.name], name);
          expect(
            aliasOf(brand, 'color/${slot.token.name}', mode),
            'Primitives/color/$name',
            reason: '$brand ${slot.token.name} $mode',
          );
        }
      }
    }
  });

  group('function names read the brand, by value', () {
    const function = 'color/syntax-function';

    test('no link names function — it is absent from every mode', () {
      for (final brightness in CoreBrightness.values) {
        expect(
          CoreSyntaxPalette.primitiveLinks(brightness),
          isNot(contains(CoreSyntaxSlot.function.token.name)),
        );
      }
    });

    test('the library brand aliases its own info ramp, never the shared '
        'group', () {
      for (final brand in ['coui']) {
        for (final mode in _kModes.keys) {
          final alias = aliasOf(brand, function, mode);
          expect(
            alias,
            startsWith('Primitives/color/$brand/info/'),
            reason: '$brand $mode',
          );
        }
      }
    });

    test('CoUI aliases info 700 on light and info 400 on dark', () {
      expect(
        [for (final mode in _kModes.keys) aliasOf('coui', function, mode)],
        [
          'Primitives/color/coui/info/700',
          'Primitives/color/coui/info/400',
          'Primitives/color/coui/info/700',
          'Primitives/color/coui/info/400',
        ],
      );
    });

    test("the aliased step holds the colour CoUI's scheme states", () {
      const source = CouiColorPresets.source;
      final schemes = {
        'Light': source.light().resolved(.light),
        'Dark': source.dark().resolved(.dark),
        'HCLight': source.highContrastLight().resolved(.light),
        'HCDark': source.highContrastDark().resolved(.dark),
      };
      for (final MapEntry(key: mode, value: scheme) in schemes.entries) {
        final target = aliasOf(
          'coui',
          function,
          mode,
        ).substring('Primitives/'.length);
        final argb = scheme.syntaxFunction.argb;
        expect(
          tripletOf(primitivesByName[target]!, 'Value'),
          [
            (argb >> 16) & 0xFF,
            (argb >> 8) & 0xFF,
            argb & 0xFF,
          ].join(' '),
          reason: mode,
        );
      }
    });
  });

  group('the namespace is reserved', () {
    test('it is its own — not the category group', () {
      expect(CoreSyntaxPalette.namespace, isNot(CoreCategoryPalette.namespace));
    });

    test('no brand publishes under it', () {
      expect(semanticColour.keys, isNot(contains(CoreSyntaxPalette.namespace)));
      final ownedByBrand = [
        for (final v in colourRows)
          if ((v['name'] as String).split('/')[1] ==
                  CoreSyntaxPalette.namespace &&
              !syntaxRows.contains(v))
            v['name'],
      ];
      expect(ownedByBrand, isEmpty);
    });

    test('no brand primitive family takes its CSS name space', () {
      // `--coui-syntax-*` holds the syntax slots; a brand family named
      // `syntax` would emit its primitives under the same names.
      expect(
        [
          for (final cssVar in PrimitiveCssGenerator.primitiveVars(
            CouiColorPresets.source,
          ).keys)
            if (cssVar.startsWith('--coui-${CoreSyntaxPalette.namespace}-'))
              cssVar,
        ],
        isEmpty,
      );
      for (final brand in semanticColour.keys) {
        expect(
          colourRows.where(
            (v) => (v['name'] as String).startsWith(
              'color/$brand/${CoreSyntaxPalette.namespace}',
            ),
          ),
          isEmpty,
          reason: brand,
        );
      }
    });
  });
}
