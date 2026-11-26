// The shadow colours as the Figma export publishes them — in the library
// brand's colour collection, a row per layer of the shadow scale
// (`effect/shadow/<step>/<layer>`), each the mode's `shadow` slot at the
// layer's own alpha — × `CoreShadow.darkStrength` (capped at 1) in the two
// dark modes, the strength both platforms' geometry seat applies.
//
// Runs the real exporter (in a temp directory, because it writes
// `build/tokens.figma.json` relative to its working directory): the rows are a
// property of the whole emitted document, so a fixture would only prove the
// fixture. The gate is held the same way — the exporter is copied, one line
// of it is broken, and the copy must refuse to write.
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kModes = ['Light', 'Dark', 'HCLight', 'HCDark'];

/// The modes that read the dark brightness.
const _kDarkModes = {'Dark', 'HCDark'};

/// The shadow scale by the name the canvas gives each step — every step
/// but `none`, which has no layer.
final Map<String, List<CoreShadowLayer>> _kSteps = {
  CoreShadow.scale.xs: CoreShadow.xs,
  CoreShadow.scale.sm: CoreShadow.sm,
  CoreShadow.scale.md: CoreShadow.md,
  CoreShadow.scale.lg: CoreShadow.lg,
  CoreShadow.scale.xl: CoreShadow.xl,
  CoreShadow.scale.xl2: CoreShadow.xl2,
  CoreShadow.scale.xl3: CoreShadow.xl3,
  CoreShadow.scale.inset: CoreShadow.inset,
};

/// Runs [script] in a fresh temp directory with the test's own package
/// resolution, so a copy of the exporter outside the package still resolves
/// `package:coui_core`.
Future<ProcessResult> _runExporter(String script, Directory tmp) async {
  final packages = await Isolate.packageConfig;

  return Process.runSync(Platform.resolvedExecutable, [
    'run',
    if (packages != null) '--packages=${packages.toFilePath()}',
    script,
  ], workingDirectory: tmp.path);
}

void main() {
  // Primitive name -> row.
  late Map<String, Map<String, dynamic>> primitivesByName;
  // Brand id -> that brand's rows by name.
  late Map<String, Map<String, Map<String, dynamic>>> semanticColour;

  setUpAll(() async {
    final script = File('bin/export_figma_tokens.dart').absolute.path;
    final tmp = Directory.systemTemp.createTempSync('coui_shadow_colours_');
    addTearDown(() => tmp.deleteSync(recursive: true));

    final result = await _runExporter(script, tmp);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');

    final doc =
        jsonDecode(
              File('${tmp.path}/build/tokens.figma.json').readAsStringSync(),
            )
            as Map<String, dynamic>;
    final collections = (doc['collections'] as List)
        .cast<Map<String, dynamic>>();
    primitivesByName = {
      for (final v
          in (collections.singleWhere(
                    (c) => c['name'] == 'Primitives',
                  )['variables']
                  as List)
              .cast<Map<String, dynamic>>())
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
  });

  Map<String, Map<String, dynamic>> shadowRows(String brand) => {
    for (final MapEntry(key: name, :value) in semanticColour[brand]!.entries)
      if (name.startsWith('effect/shadow/')) name: value,
  };

  test('the library brand publishes the colour collection', () {
    expect(semanticColour.keys, ['coui']);
  });

  test('the rows are the layers of the shadow scale, numbered from 0', () {
    final expected = [
      for (final MapEntry(key: step, value: layers) in _kSteps.entries)
        for (var i = 0; i < layers.length; i++) 'effect/shadow/$step/$i',
    ];
    expect(expected, isNotEmpty);
    for (final brand in ['coui']) {
      expect(shadowRows(brand).keys, expected, reason: brand);
    }
  });

  test('each row is a colour value in all four modes, offered to effects '
      'only', () {
    for (final brand in ['coui']) {
      for (final row in shadowRows(brand).values) {
        expect(row['type'], 'COLOR');
        expect(row['scopes'], ['EFFECT_COLOR'], reason: '${row['name']}');
        final values = row['valuesByMode'] as Map<String, dynamic>;
        expect(values.keys, _kModes, reason: '${row['name']}');
        for (final value in values.values) {
          // A value, not an alias: an alias cannot carry the alpha.
          expect(value, isNot(contains('alias')), reason: '${row['name']}');
        }
      }
    }
  });

  test("RGB is the mode's color/shadow", () {
    for (final brand in ['coui']) {
      final shadow = semanticColour[brand]!['color/shadow']!;
      for (final mode in _kModes) {
        final alias =
            ((shadow['valuesByMode'] as Map<String, dynamic>)[mode]
                    as Map<String, dynamic>)['alias']
                as String;
        final slot =
            (primitivesByName[alias.substring(
                      'Primitives/'.length,
                    )]!['valuesByMode']
                    as Map<String, dynamic>)['Value']
                as Map<String, dynamic>;
        for (final row in shadowRows(brand).values) {
          final value =
              (row['valuesByMode'] as Map<String, dynamic>)[mode]
                  as Map<String, dynamic>;
          expect(
            [value['r'], value['g'], value['b']],
            [slot['r'], slot['g'], slot['b']],
            reason: '$brand ${row['name']} $mode',
          );
        }
      }
    }
  });

  test("alpha is the layer's opacity, strengthened in a dark mode", () {
    for (final brand in ['coui']) {
      final rows = shadowRows(brand);
      for (final MapEntry(key: step, value: layers) in _kSteps.entries) {
        for (var i = 0; i < layers.length; i++) {
          final row = rows['effect/shadow/$step/$i']!;
          for (final mode in _kModes) {
            final value =
                (row['valuesByMode'] as Map<String, dynamic>)[mode]
                    as Map<String, dynamic>;
            final expected = _kDarkModes.contains(mode)
                ? math.min<double>(
                    1,
                    layers[i].opacity * CoreShadow.darkStrength,
                  )
                : layers[i].opacity;
            expect(
              value['a'],
              closeTo(expected, 1e-9),
              reason: '$brand $step/$i $mode',
            );
          }
        }
      }
    }
  });

  group('the gate refuses a row that does not say what the brand says', () {
    // Each case breaks one line of a copy of the exporter. The line must be
    // there exactly once — a rename that drops it fails here rather than
    // letting the case pass without breaking anything.
    Future<ProcessResult> runBroken(String line, String broken) {
      final source = File('bin/export_figma_tokens.dart').readAsStringSync();
      expect(line.allMatches(source), hasLength(1), reason: line);
      final tmp = Directory.systemTemp.createTempSync('coui_shadow_gate_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      // The copy still has to compile: the files it imports by relative path
      // go beside it at the same paths. Read off the source, so a helper the
      // exporter starts importing comes along without this test naming it.
      for (final m in RegExp(
        "^import '([^:']+)';",
        multiLine: true,
      ).allMatches(source)) {
        final rel = m[1]!;
        File('bin/$rel').copySync(
          (File('${tmp.path}/$rel')..parent.createSync(recursive: true)).path,
        );
      }
      final script = File('${tmp.path}/export_figma_tokens.dart')
        ..writeAsStringSync(source.replaceFirst(line, broken));

      return _runExporter(script.path, tmp);
    }

    test("a colour that is not the mode's shadow slot", () async {
      final result = await runBroken(
        'final color = scheme.shadow;',
        'final color = scheme.onSurface;',
      );
      expect(result.exitCode, isNot(0));
      expect(result.stderr, contains('effect/shadow/'));
      expect(result.stderr, contains('shadow colour row(s)'));
    });

    test('an alpha that is not the derived one', () async {
      final result = await runBroken(
        "mode: shadowRowsByMode[mode]![i]['value'],",
        "mode: {...shadowRowsByMode[mode]![i]['value'] as Map, 'a': 1.0},",
      );
      expect(result.exitCode, isNot(0));
      expect(result.stderr, contains('effect/shadow/'));
      expect(result.stderr, contains('shadow colour row(s)'));
    });
  });
}
