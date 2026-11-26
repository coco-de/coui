// `Semantic/ Surface` — a surface style's geometry on the canvas.
//
// The collection carries one mode per surface style, and each row aliases the
// primitive that style lands on. The values must be the ones both platforms
// render, so the expectations below are read from the same seat Web and
// Flutter read (`resolveThemeGeometry`) — and a few are also written out as
// numbers, a second source that fails if the seat and the export drift
// together.
import 'dart:convert';
import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  late Map<String, dynamic> surface;
  late Set<String> primitiveNames;

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
    surface = collections.singleWhere((c) => c['name'] == 'Semantic/ Surface');
    primitiveNames = {
      for (final v
          in (collections.singleWhere(
                    (c) => c['name'] == 'Primitives',
                  )['variables']
                  as List)
              .cast<Map<String, dynamic>>())
        'Primitives/${v['name']}',
    };
  });

  Map<String, dynamic> row(String name) => (surface['variables'] as List)
      .cast<Map<String, dynamic>>()
      .singleWhere((v) => v['name'] == name);

  // The geometry rows — the ones that land on a primitive step. The same
  // collection also carries the bent casts (`shadow/*`) and the material
  // (`material/*`), whose values are per-style numbers no primitive holds;
  // their own tests read those. Excluded by family rather than included, so a
  // geometry family added later is held to the alias rule without a change
  // here.
  const literalFamilies = {'shadow', 'material'};
  Iterable<Map<String, dynamic>> geometryRows() =>
      (surface['variables'] as List).cast<Map<String, dynamic>>().where(
        (v) =>
            !literalFamilies.contains((v['name'] as String).split('/').first),
      );

  String aliasOf(String name, CoreSurfaceStyleId id) =>
      ((row(name)['valuesByMode'] as Map)[id.name] as Map)['alias'] as String;

  test('one mode per surface style, named as code names it', () {
    expect(surface['modes'], [
      for (final id in CoreSurfaceStyleId.values) id.name,
    ]);
  });

  test('every geometry row aliases a primitive that exists', () {
    expect(geometryRows(), isNotEmpty);
    for (final v in geometryRows()) {
      for (final value in (v['valuesByMode'] as Map).values) {
        expect(
          primitiveNames,
          contains((value as Map)['alias']),
          reason: '${v['name']} aliases a primitive the export does not have',
        );
      }
    }
  });

  test('the default style is the primitive itself', () {
    for (final v in geometryRows()) {
      final name = v['name'] as String;
      expect(aliasOf(name, .defaultStyle), 'Primitives/$name');
    }
  });

  test('each style aliases what the shared seat bends the step to', () {
    for (final id in CoreSurfaceStyleId.values) {
      final geometry = resolveThemeGeometry(surfaceStyle: id);
      for (final step in [...CoreRadius.steps, 0.0, CoreRadius.radius9999]) {
        final leaf = step.toInt();
        expect(
          aliasOf('radius/$leaf', id),
          'Primitives/radius/${geometry.radius(step).toInt()}',
          reason: '${id.name} radius/$leaf',
        );
      }
    }
  });

  test('each style aliases what the shared seat bends a stroke to', () {
    // The stroke ladder is walked through the code's own members, so a step
    // added to `CoreStrokeWidth` that the export forgot fails here.
    const steps = {
      '0': CoreStrokeWidth.stroke0,
      '0_5': CoreStrokeWidth.stroke0_5,
      '1': CoreStrokeWidth.stroke1,
      '1_5': CoreStrokeWidth.stroke1_5,
      '2': CoreStrokeWidth.stroke2,
      '3': CoreStrokeWidth.stroke3,
      '4': CoreStrokeWidth.stroke4,
      '5': CoreStrokeWidth.stroke5,
      '6': CoreStrokeWidth.stroke6,
      '8': CoreStrokeWidth.stroke8,
    };
    // The aliased primitive has to exist for the step the code names.
    expect(primitiveNames, contains('Primitives/stroke/5'));
    for (final id in CoreSurfaceStyleId.values) {
      final geometry = resolveThemeGeometry(surfaceStyle: id);
      for (final MapEntry(key: leaf, value: step) in steps.entries) {
        final bent = geometry.stroke(step);
        final bentLeaf = steps.entries.singleWhere((e) => e.value == bent).key;
        expect(
          aliasOf('stroke/$leaf', id),
          'Primitives/stroke/$bentLeaf',
          reason: '${id.name} stroke/$leaf',
        );
      }
    }
  });

  test('the shipped styles land where Web draws them', () {
    // Written out: the surface-role corner (16) under each style, and a
    // hairline floored by the heavy style.
    expect(aliasOf('radius/16', .neoBrutalism), 'Primitives/radius/4');
    expect(aliasOf('radius/16', .claymorphism), 'Primitives/radius/24');
    expect(aliasOf('radius/16', .liquidGlass), 'Primitives/radius/16');
    expect(aliasOf('stroke/1', .neoBrutalism), 'Primitives/stroke/4');
    expect(aliasOf('stroke/0', .neoBrutalism), 'Primitives/stroke/0');
    // 5 sits above the heavy style's floor, so it stays; 3 is raised to it.
    expect(aliasOf('stroke/5', .neoBrutalism), 'Primitives/stroke/5');
    expect(aliasOf('stroke/3', .neoBrutalism), 'Primitives/stroke/4');
    expect(aliasOf('stroke/5', .defaultStyle), 'Primitives/stroke/5');
    expect(aliasOf('radius/9999', .neoBrutalism), 'Primitives/radius/9999');
  });
}
