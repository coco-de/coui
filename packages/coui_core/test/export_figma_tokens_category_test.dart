// The category colours as the Figma export publishes them — one shared
// primitive group (`color/category/<hue>/<tone>`) outside every brand's path,
// and each brand's semantic slots aliasing it by name.
//
// Runs the real exporter (in a temp directory, because it writes
// `build/tokens.figma.json` relative to its working directory): which rows the
// Primitives collection carries, and under what names, is a property of the
// whole emitted document, so a fixture would only prove the fixture.
import 'dart:convert';
import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kSharedPrefix = 'color/${CoreCategoryPalette.namespace}/';

/// The Figma mode names, by the mode each states.
const Map<String, (CoreBrightness, bool)> _kModes = {
  'Light': (CoreBrightness.light, false),
  'Dark': (CoreBrightness.dark, false),
  'HCLight': (CoreBrightness.light, true),
  'HCDark': (CoreBrightness.dark, true),
};

/// The alias a semantic slot states for [tone] of [color].
String _shared(CoreCategoryColor color, CoreCategoryTone tone) =>
    'Primitives/color/${CoreCategoryPalette.primitiveName(color, tone)}';

void main() {
  late List<Map<String, dynamic>> colourRows;
  late List<Map<String, dynamic>> categoryRows;
  late Set<String> primitiveNames;
  // Brand id -> that brand's `color/...` rows by name.
  late Map<String, Map<String, Map<String, dynamic>>> semanticColour;

  setUpAll(() {
    final script = File('bin/export_figma_tokens.dart').absolute.path;
    final tmp = Directory.systemTemp.createTempSync('coui_category_');
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
    primitiveNames = {
      for (final v
          in (primitives['variables'] as List).cast<Map<String, dynamic>>())
        v['name'] as String,
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
      for (final v
          in (primitives['variables'] as List).cast<Map<String, dynamic>>())
        if ((v['name'] as String).startsWith('color/')) v,
    ];
    categoryRows = [
      for (final v in colourRows)
        if ((v['name'] as String).startsWith(_kSharedPrefix)) v,
    ];
  });

  test('the shared group carries every category primitive, once', () {
    expect(categoryRows, hasLength(CoreCategoryPalette.primitives.length));
    expect(
      [for (final v in categoryRows) v['name']],
      [for (final name in CoreCategoryPalette.primitives.keys) 'color/$name'],
    );
  });

  test('each row holds the value the category table states', () {
    final triplets = PrimitiveCssGenerator.categoryPrimitiveTriplets();
    for (final v in categoryRows) {
      final name = (v['name'] as String).substring('color/'.length);
      final value =
          (v['valuesByMode'] as Map<String, dynamic>)['Value']
              as Map<String, dynamic>;
      final channels = [
        for (final channel in ['r', 'g', 'b'])
          ((value[channel] as num) * 255).round(),
      ];
      expect(channels.join(' '), triplets[name], reason: name);
    }
  });

  test('no category primitive lands under a brand, or with hue and tone '
      'joined into one segment', () {
    // `_brandColorPath` would file a category name under the brand
    // (`color/coui/category/...`) and fold hue and tone into one segment
    // (`red-light-fill`) — the shared group must never go through it.
    final brandScoped = RegExp(
      '^color/[^/]+/${CoreCategoryPalette.namespace}[/-]',
    );
    final joined = {
      for (final colour in CoreCategoryColor.values)
        for (final tone in CoreCategoryTone.values)
          '${colour.name}-${tone.key}',
    };
    for (final v in colourRows) {
      final name = v['name'] as String;
      expect(name, isNot(matches(brandScoped)));
      for (final segment in joined) {
        expect(name, isNot(contains(segment)));
      }
    }
    for (final v in categoryRows) {
      expect((v['name'] as String).split('/'), hasLength(4));
    }
  });

  test('every shared row is published, and says so', () {
    // Stated even though `false`: the importer only touches a variable whose
    // spec carries the key, so a missing key would leave the file's hand-set
    // flag in charge. Every row is published because every brand's
    // semantic slots read the group.
    expect(
      [
        for (final v in categoryRows)
          if (v['hiddenFromPublishing'] != false) v['name'],
      ],
      isEmpty,
    );
  });

  String aliasOf(String brand, String variable, String mode) {
    final row = semanticColour[brand]![variable];
    expect(row, isNotNull, reason: '$brand has no $variable');
    final values = row!['valuesByMode'] as Map<String, dynamic>;
    expect(values, contains(mode), reason: '$brand $variable');

    return (values[mode] as Map<String, dynamic>)['alias'] as String;
  }

  test('the library publishes one semantic colour collection — the library '
      "brand's; every other brand is a value table (brands.json)", () {
    expect(semanticColour.keys, ['coui']);
  });

  test('every linked slot aliases the tone its mode reads, by name', () {
    // Linked by name rather than matched by value: gray's light container
    // and light on-container equal CoUI's neutral 200 and 800, and purple's
    // and pink's on-container is the same colour in light and high-contrast
    // light — a value match would alias the wrong variable without a word.
    for (final brand in ['coui']) {
      for (final MapEntry(key: mode, value: (brightness, highContrast))
          in _kModes.entries) {
        for (final color in CoreCategoryColor.values) {
          for (final slot in CoreCategorySlot.values) {
            final tone = slot.toneIn(brightness, highContrast: highContrast);
            if (tone == null) continue;
            expect(
              aliasOf(brand, 'color/${slot.cssName(color)}', mode),
              _shared(color, tone),
              reason: '$brand ${slot.cssName(color)} $mode',
            );
          }
        }
      }
    }
  });

  group('the cells a value match would get wrong', () {
    test('a value the group states under two names links each by its own '
        'name', () {
      // Read off the table rather than listed: every tone whose value another
      // tone of the group also holds. A value match could only pick one of
      // the two names.
      final triplets = PrimitiveCssGenerator.categoryPrimitiveTriplets();
      final holders = <String, List<String>>{};
      for (final MapEntry(key: name, value: triplet) in triplets.entries) {
        (holders[triplet] ??= []).add(name);
      }
      final shared = {
        for (final names in holders.values)
          if (names.length > 1) ...names,
      };
      expect(shared, isNotEmpty, reason: 'the premise no longer holds');

      var checked = 0;
      for (final MapEntry(key: mode, value: (brightness, highContrast))
          in _kModes.entries) {
        final links = CoreCategoryPalette.primitiveLinks(
          brightness,
          highContrast: highContrast,
        );
        for (final MapEntry(key: slot, value: name) in links.entries) {
          if (!shared.contains(name)) continue;
          for (final brand in ['coui']) {
            expect(
              aliasOf(brand, 'color/$slot', mode),
              'Primitives/color/$name',
              reason: '$brand $slot $mode',
            );
            checked++;
          }
        }
      }
      expect(checked, isPositive);
    });

    test('purple and pink on-container keep two names for one colour', () {
      for (final color in [CoreCategoryColor.purple, CoreCategoryColor.pink]) {
        expect(
          CoreCategoryPalette.tone(color, .lightOnContainer).argb,
          CoreCategoryPalette.tone(color, .hcLightOnContainer).argb,
          reason: color.name,
        );
        for (final brand in ['coui']) {
          final name = 'color/on-category-${color.name}-container';
          expect(
            aliasOf(brand, name, 'Light'),
            _shared(color, .lightOnContainer),
          );
          expect(
            aliasOf(brand, name, 'HCLight'),
            _shared(color, .hcLightOnContainer),
          );
        }
      }
    });

    test('high-contrast light borrows the light container and the '
        'high-contrast fill', () {
      for (final brand in ['coui']) {
        for (final color in CoreCategoryColor.values) {
          final base = 'color/category-${color.name}';
          expect(
            aliasOf(brand, '$base-container', 'HCLight'),
            _shared(color, .lightContainer),
          );
          expect(
            aliasOf(brand, '$base-outline', 'HCLight'),
            _shared(color, .hcLightFill),
          );
          expect(
            aliasOf(brand, '$base-outline', 'Light'),
            _shared(color, .lightContainer),
          );
        }
      }
    });
  });

  test("the strong label reads the library brand's own white and black", () {
    // Another brand's own pure white and black are in its value table
    // (`export_figma_tokens_brand_table_test.dart`).
    const expected = {
      'coui': (
        'Primitives/color/coui/base/white',
        'Primitives/color/coui/base/black',
      ),
    };
    for (final MapEntry(key: brand, value: (white, black))
        in expected.entries) {
      for (final color in CoreCategoryColor.values) {
        final name = 'color/on-category-${color.name}';
        for (final mode in _kModes.keys) {
          final alias = aliasOf(brand, name, mode);
          expect(
            alias,
            mode == 'HCDark' ? black : white,
            reason: '$name $mode',
          );
          // The standard mapping's off-white falls under the label's 3.5:1
          // on the lowest light fill.
          expect(alias, isNot(endsWith('/neutral/white')));
        }
      }
    }
  });

  test('every semantic colour alias names a primitive the export has', () {
    // A value match finds its target among the primitives by construction;
    // a name link does not, so a target that is not there is caught here.
    const prefix = 'Primitives/';
    final dangling = <String>[];
    for (final MapEntry(key: brand, value: rows) in semanticColour.entries) {
      for (final row in rows.values) {
        final values = row['valuesByMode'] as Map<String, dynamic>;
        for (final MapEntry(key: mode, :value) in values.entries) {
          final alias = (value as Map<String, dynamic>)['alias'] as String?;
          if (alias == null) continue;
          if (!alias.startsWith(prefix) ||
              !primitiveNames.contains(alias.substring(prefix.length))) {
            dangling.add('$brand ${row['name']} $mode -> $alias');
          }
        }
      }
    }

    expect(semanticColour.values.expand((rows) => rows.values), isNotEmpty);
    expect(dangling, isEmpty, reason: dangling.join('\n'));
  });
}
