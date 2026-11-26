// The variable names the Figma export publishes, checked against what Figma
// will actually create.
//
// Figma refuses a `.` in a variable name — `createVariable` throws "invalid
// variable name" — and the plugin's test double does not enforce it, so the
// first dotted name (`stroke/0.5`) passed every self-test and failed only when
// Import ran in a real file. The exporter is the one place every name goes
// through, so this is where the rule can be held.
//
// Runs the real exporter (in a temp directory, because it writes
// `build/tokens.figma.json` relative to its working directory): the names are
// a property of the whole emitted document, so a fixture would only prove the
// fixture.
import 'dart:convert';
import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  late List<({String collection, String name})> variables;

  setUpAll(() {
    final script = File('bin/export_figma_tokens.dart').absolute.path;
    final tmp = Directory.systemTemp.createTempSync('coui_variable_names_');
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

    variables = [
      for (final c in (doc['collections'] as List).cast<Map<String, dynamic>>())
        for (final v in (c['variables'] as List).cast<Map<String, dynamic>>())
          (collection: c['name'] as String, name: v['name'] as String),
    ];
  });

  test('the export publishes variables at all', () {
    // A scan that reads none can never fail.
    expect(variables, isNotEmpty);
  });

  test('no variable name contains a "." — Figma refuses to create it', () {
    final offenders = [
      for (final v in variables)
        if (v.name.contains('.')) '${v.collection} / ${v.name}',
    ];

    expect(
      offenders,
      isEmpty,
      reason:
          'Figma `createVariable` throws "invalid variable name" for these; '
          'spell the decimal point with "_" (the hairline is `stroke/0_5`).',
    );
  });

  test('the hairline stroke is published under its underscore spelling', () {
    final names = {for (final v in variables) v.name};

    expect(names, contains('stroke/0_5'));
    expect(names, isNot(contains('stroke/0.5')));
  });

  test('the library brand colour collection publishes every semantic slot, by '
      'its CSS name', () {
    // Read off the vocabulary rather than listed, so a slot added to the
    // scheme is held here without an edit — and a slot dropped from the
    // export fails.
    final slots = {
      for (final cssVar in PrimitiveCssGenerator.semanticVars(
        CouiColorPresets.source.light().resolved(CoreBrightness.light),
      ).keys)
        'color/${cssVar.replaceFirst('--coui-', '')}',
    };
    expect(
      slots,
      containsAll([
        'color/on-surface-subtle',
        'color/surface-raised',
        'color/syntax-keyword',
        'color/syntax-type',
        'color/syntax-function',
        'color/syntax-string',
      ]),
    );
    final brands = {
      for (final v in variables)
        if (v.collection.startsWith('Semantic/ Color · ')) v.collection,
    };
    // One: every other brand is a value table over it, not a collection.
    expect(brands, hasLength(1));
    for (final brand in brands) {
      final colours = {
        for (final v in variables)
          if (v.collection == brand && v.name.startsWith('color/')) v.name,
      };
      expect(colours, slots, reason: brand);
    }
  });
}
