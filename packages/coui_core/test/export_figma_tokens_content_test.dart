// The content-colour collections (`Semantic/ Content` ·
// `Semantic/ Content Status`) as the Figma export publishes them: the colour a
// glyph takes from the slot frame that pins a mode.
//
// Runs the real exporter (in a temp directory, because it writes
// `build/tokens.figma.json` and the plugin's data files relative to its working
// directory): a mode's alias is a property of the whole emitted document, so a
// fixture would only prove the fixture. What the plugin bundles
// (`content-colors.json`) is read from the same run, so the two cannot name
// different modes.
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

/// Most modes one Figma collection can hold.
const _kFigmaModeLimit = 20;
const _kContent = 'Semantic/ Content';
const _kStatus = 'Semantic/ Content Status';

void main() {
  late Map<String, dynamic> doc;
  late Map<String, dynamic> bundled;
  late Map<String, Map<String, dynamic>> collections;

  setUpAll(() {
    final script = File('bin/export_figma_tokens.dart').absolute.path;
    final tmp = Directory.systemTemp.createTempSync('coui_content_colors_');
    addTearDown(() => tmp.deleteSync(recursive: true));

    final result = Process.runSync(Platform.resolvedExecutable, [
      'run',
      script,
    ], workingDirectory: tmp.path);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');

    doc =
        jsonDecode(
              File('${tmp.path}/build/tokens.figma.json').readAsStringSync(),
            )
            as Map<String, dynamic>;
    bundled =
        jsonDecode(
              File(
                '${tmp.path}/tools/figma-token-sync/src/data/'
                'content-colors.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    collections = {
      for (final c in (doc['collections'] as List).cast<Map<String, dynamic>>())
        c['name'] as String: c,
    };
  });

  Map<String, dynamic> only(String collection) {
    final variables = (collections[collection]!['variables'] as List)
        .cast<Map<String, dynamic>>();
    expect(variables, hasLength(1), reason: collection);

    return variables.single;
  }

  List<String> modes(String collection) =>
      (collections[collection]!['modes'] as List).cast<String>();

  Map<String, dynamic> values(String collection) =>
      only(collection)['valuesByMode'] as Map<String, dynamic>;

  /// Every `<Collection>/<variable>` path the document holds.
  Set<String> paths() => {
    for (final c in collections.values)
      for (final v in (c['variables'] as List).cast<Map<String, dynamic>>())
        '${c['name']}/${v['name']}',
  };

  /// The library brand's colour collection — the first one the document lists,
  /// the one an extension in a consumer file extends.
  String colourCollection() => collections.keys.firstWhere(
    (name) => name.startsWith('Semantic/ Color · '),
  );

  test('two collections, one variable each, inside the plan limit', () {
    expect(collections, contains(_kContent));
    expect(collections, contains(_kStatus));
    expect(only(_kContent)['name'], 'content/current');
    expect(only(_kStatus)['name'], 'content/status');
    expect(modes(_kContent), hasLength(13));
    expect(modes(_kStatus), hasLength(12));
    for (final name in [_kContent, _kStatus]) {
      expect(modes(name).length, lessThanOrEqualTo(_kFigmaModeLimit));
      expect(modes(name).toSet(), hasLength(modes(name).length), reason: name);
    }
  });

  test('every content tone is a mode named for the slot it aliases', () {
    final colour = colourCollection();
    final tones = modes(_kContent).where((m) => m != 'status').toList();
    expect(tones, hasLength(12));
    for (final tone in tones) {
      final value = values(_kContent)[tone] as Map<String, dynamic>;
      expect(value['alias'], '$colour/color/$tone', reason: tone);
      expect(paths(), contains('$colour/color/$tone'), reason: tone);
    }
  });

  test('the status mode hands the choice to the status collection', () {
    expect(
      (values(_kContent)['status'] as Map<String, dynamic>)['alias'],
      '$_kStatus/content/status',
    );
    expect(paths(), contains('$_kStatus/content/status'));
    // The default mode of the status collection is never the hand-off's own.
    expect(modes(_kStatus), isNot(contains('status')));
  });

  test('every status tone aliases the slot of the same name, and the on- '
      'and on-container tones of each status family come with it', () {
    final colour = colourCollection();
    for (final family in ['success', 'info', 'warning', 'error']) {
      for (final tone in [family, 'on-$family', 'on-$family-container']) {
        expect(modes(_kStatus), contains(tone));
        final value = values(_kStatus)[tone] as Map<String, dynamic>;
        expect(value['alias'], '$colour/color/$tone', reason: tone);
        expect(paths(), contains('$colour/color/$tone'), reason: tone);
      }
    }
    expect(modes(_kStatus), hasLength(12));
  });

  test('a neutral tone is never also a status tone — a token is one mode of '
      'exactly one collection', () {
    final neutral = modes(_kContent).where((m) => m != 'status').toSet();
    expect(neutral.intersection(modes(_kStatus).toSet()), isEmpty);
  });

  test('every mode carries a value and every alias lands on a variable the '
      'document holds', () {
    for (final name in [_kContent, _kStatus]) {
      expect(values(name).keys.toSet(), modes(name).toSet(), reason: name);
      for (final value in values(name).values) {
        expect(paths(), contains((value as Map<String, dynamic>)['alias']));
      }
    }
  });

  test('the glyph stroke can be bound: the variables are colour variables '
      'scoped to a stroke and a shape fill', () {
    for (final name in [_kContent, _kStatus]) {
      expect(only(name)['type'], 'COLOR');
      expect(only(name)['scopes'], ['SHAPE_FILL', 'STROKE_COLOR']);
    }
  });

  test('content is one collection, not one per brand: no brand adds a '
      'content collection', () {
    final content = collections.keys.where(
      (n) => n.startsWith('Semantic/ Content'),
    );
    expect(content.toSet(), {_kContent, _kStatus});
  });

  test('what the plugin bundles is what the collections say', () {
    expect(bundled['colorCollection'], colourCollection());
    final content = bundled['content'] as Map<String, dynamic>;
    final status = bundled['status'] as Map<String, dynamic>;
    expect(content['collection'], _kContent);
    expect(content['variable'], only(_kContent)['name']);
    expect(content['statusMode'], 'status');
    expect(content['modes'], modes(_kContent));
    expect(status['collection'], _kStatus);
    expect(status['variable'], only(_kStatus)['name']);
    expect(status['modes'], modes(_kStatus));
  });
}
