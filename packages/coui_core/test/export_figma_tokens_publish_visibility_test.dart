// Holds the publish-visibility decision the exporter writes onto colour
// primitives — every brand's and every shared group's
// (`hiddenFromPublishing`) — the flag that used to exist only as a hand toggle
// in the Figma DS file, where a variable re-created by Import or a brand added
// later silently came back published.
//
// Runs the real exporter rather than a fixture: the decision is a property of
// the whole emitted document (which primitives any alias reads), so the only
// honest input is the document `coui_core` actually produces. It runs in a
// temp directory because the exporter writes `build/tokens.figma.json`
// relative to its working directory.
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

const _kPrimitives = 'Primitives';

void main() {
  late List<Map<String, dynamic>> colourRows;
  late List<Map<String, dynamic>> otherPrimitives;
  late Set<String> aliasTargets;

  setUpAll(() {
    final script = File('bin/export_figma_tokens.dart').absolute.path;
    final tmp = Directory.systemTemp.createTempSync('coui_tokens_');
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

    aliasTargets = {
      for (final c in collections)
        for (final v in (c['variables'] as List).cast<Map<String, dynamic>>())
          for (final value in (v['valuesByMode'] as Map).values)
            if (value is Map && value['alias'] is String)
              value['alias'] as String,
    };

    final primitives = collections.singleWhere(
      (c) => c['name'] == _kPrimitives,
    );
    colourRows = [
      for (final v
          in (primitives['variables'] as List).cast<Map<String, dynamic>>())
        if ((v['name'] as String).startsWith('color/')) v,
    ];
    otherPrimitives = [
      for (final v
          in (primitives['variables'] as List).cast<Map<String, dynamic>>())
        if (!(v['name'] as String).startsWith('color/')) v,
    ];
  });

  // `color/<brand>/<family>/<leaf>` -> `<brand>/<family>`, and
  // `color/<namespace>/<hue>/<tone>` -> `<namespace>/<hue>`.
  String rampOf(String name) => name.split('/').skip(1).take(2).join('/');

  Set<String> hiddenNames(String brandId) => {
    for (final v in colourRows)
      if ((v['name'] as String).startsWith('color/$brandId/') &&
          v['hiddenFromPublishing'] == true)
        v['name'] as String,
  };

  test('the fixture actually produced brand and shared colour rows', () {
    // Guards every assertion below against passing vacuously on an empty
    // list — and pins the library brand's primitive vocabulary: CoUI's fixed
    // tone ramps (no primary of its own) plus its two base colours — the
    // shared category group's nine hue ramps of thirteen tones, and the
    // shared syntax group's three hue ramps of two shades. No other brand has
    // primitives here: a brand is a value table over the library's
    // Semantic/Color collection.
    expect(
      colourRows.where((v) => rampOf(v['name'] as String) == 'coui/success'),
      hasLength(11),
    );
    expect(
      colourRows.where((v) => rampOf(v['name'] as String) == 'coui/primary'),
      isEmpty,
    );
    expect(
      colourRows.where((v) => rampOf(v['name'] as String) == 'coui/base'),
      hasLength(2),
    );
    expect(
      colourRows.where(
        (v) => ['unibook', 'medibooks'].contains(
          (v['name'] as String).split('/')[1],
        ),
      ),
      isEmpty,
    );
    expect(
      colourRows.where((v) => rampOf(v['name'] as String) == 'category/red'),
      hasLength(13),
    );
    expect(
      {
        for (final v in colourRows)
          if ((v['name'] as String).startsWith('color/category/'))
            rampOf(v['name'] as String),
      },
      hasLength(9),
    );
    expect(
      colourRows.where((v) => rampOf(v['name'] as String) == 'syntax/purple'),
      hasLength(2),
    );
    expect(
      {
        for (final v in colourRows)
          if ((v['name'] as String).startsWith('color/syntax/'))
            rampOf(v['name'] as String),
      },
      hasLength(3),
    );
  });

  test('every colour row states its visibility — false included', () {
    // The importer only touches a variable whose spec carries the key, so an
    // explicit `false` is what un-hides a ramp once a brand starts reading
    // it. A missing key would leave the file's hand-set flag in charge.
    final unstated = [
      for (final v in colourRows)
        if (v['hiddenFromPublishing'] is! bool) v['name'],
    ];
    expect(unstated, isEmpty);
  });

  test('CoUI hides nothing — its fixed palette carries only the ramps its '
      'semantics read', () {
    expect(hiddenNames('coui'), isEmpty);
  });

  test('the category group hides nothing — every hue is linked', () {
    expect(hiddenNames('category'), isEmpty);
  });

  test('the syntax group hides nothing — every hue is linked', () {
    expect(hiddenNames('syntax'), isEmpty);
  });

  test('non-colour primitives carry no key — their visibility stays the '
      "file's", () {
    expect(otherPrimitives, isNotEmpty);
    expect(
      [
        for (final v in otherPrimitives)
          if (v.containsKey('hiddenFromPublishing')) v['name'],
      ],
      isEmpty,
    );
  });

  test('hidden means "no alias reads any step of the ramp", both ways', () {
    final consumedRamps = {
      for (final target in aliasTargets)
        if (target.startsWith('$_kPrimitives/color/'))
          rampOf(target.substring(_kPrimitives.length + 1)),
    };
    for (final v in colourRows) {
      final ramp = rampOf(v['name'] as String);
      expect(
        v['hiddenFromPublishing'],
        !consumedRamps.contains(ramp),
        reason: '${v['name']} (ramp $ramp)',
      );
    }
  });
}
