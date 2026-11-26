// `Semantic/ Dimension` — a density on the canvas.
//
// The collection carries one mode per density, and each row aliases what
// that density draws. The values must be the ones both platforms render,
// so the expectations are read from the seat Web and Flutter read
// (`resolveThemeGeometry(density:)`) — and a few are also written out as
// numbers, a second source that fails if the seat and the export drift
// together.
import 'dart:convert';
import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  late Map<String, dynamic> dimension;
  late Map<String, dynamic> component;
  late Set<String> names;

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
    dimension = collections.singleWhere(
      (c) => c['name'] == 'Semantic/ Dimension',
    );
    component = collections.singleWhere((c) => c['name'] == 'Component');
    names = {
      for (final c in collections)
        for (final v in (c['variables'] as List).cast<Map<String, dynamic>>())
          '${c['name']}/${v['name']}',
    };
  });

  Map<String, dynamic> rowOf(Map<String, dynamic> collection, String name) =>
      (collection['variables'] as List)
          .cast<Map<String, dynamic>>()
          .singleWhere((v) => v['name'] == name);

  String aliasOf(String name, CoreDensity density) =>
      ((rowOf(dimension, name)['valuesByMode'] as Map)[density.name]
              as Map)['alias']
          as String;

  String leaf(double value) =>
      value == value.roundToDouble() ? '${value.toInt()}' : '$value';

  test('one mode per density, the default first', () {
    expect(dimension['modes'], ['standard', 'compact', 'spacious']);
  });

  test('every alias names a variable the export has', () {
    for (final c in [dimension, component]) {
      for (final v in (c['variables'] as List).cast<Map<String, dynamic>>()) {
        for (final value in (v['valuesByMode'] as Map).values) {
          // A literal (a raw FLOAT the exporter writes) aliases nothing.
          if (value is! Map) continue;
          final alias = value['alias'];
          if (alias == null) continue;
          expect(
            names,
            contains(alias),
            reason: '${c['name']}/${v['name']} aliases $alias',
          );
        }
      }
    }
  });

  test('standard draws every value as authored', () {
    for (final step in CoreSpace.steps) {
      expect(
        aliasOf('space/${leaf(step)}', .standard),
        'Primitives/space/${leaf(step)}',
      );
    }
    for (final step in [0.0, ...CoreRadius.steps, CoreRadius.radius9999]) {
      expect(
        aliasOf('radius/${leaf(step)}', .standard),
        'Semantic/ Surface/radius/${leaf(step)}',
      );
    }
  });

  test('each density aliases what the shared seat draws', () {
    for (final density in CoreDensity.values) {
      final geometry = resolveThemeGeometry(density: density);
      for (final step in CoreSpace.steps) {
        expect(
          aliasOf('space/${leaf(step)}', density),
          'Primitives/space/${leaf(geometry.space(step))}',
          reason: '${density.name} space $step',
        );
      }
      for (final e in {
        'xs': CoreControlSize.heightXs,
        'sm': CoreControlSize.heightSm,
        'md': CoreControlSize.heightMd,
        'lg': CoreControlSize.heightLg,
        'xl': CoreControlSize.heightXl,
        'xl2': CoreControlSize.heightXl2,
      }.entries) {
        expect(
          aliasOf('control-size/${e.key}', density),
          'Primitives/size/${leaf(geometry.controlHeight(e.value))}',
          reason: '${density.name} control-size/${e.key}',
        );
      }
      for (final step in [0.0, ...CoreRadius.steps, CoreRadius.radius9999]) {
        expect(
          aliasOf('radius/${leaf(step)}', density),
          'Semantic/ Surface/radius/${leaf(density.radius(step))}',
          reason: '${density.name} radius $step',
        );
      }
    }
  });

  test('the compact rows land where the platforms draw them', () {
    // Written out: a compact md row is the sm row.
    expect(aliasOf('control-size/md', .compact), 'Primitives/size/32');
    expect(aliasOf('space/16', .compact), 'Primitives/space/12');
    expect(aliasOf('space/4', .compact), 'Primitives/space/4');
    expect(aliasOf('radius/10', .compact), 'Semantic/ Surface/radius/8');
    expect(aliasOf('radius/16', .spacious), 'Semantic/ Surface/radius/16');
    expect(aliasOf('control-size/xl2', .spacious), 'Primitives/size/64');
  });

  test('a density does not move the pointer floor or the touch target', () {
    for (final name in ['a11y/pointer-target-min', 'a11y/touch-target']) {
      final standard = aliasOf(name, .standard);
      for (final density in CoreDensity.values) {
        expect(aliasOf(name, density), standard, reason: name);
      }
    }
  });

  String componentAlias(String name) =>
      ((rowOf(component, name)['valuesByMode'] as Map).values.single
              as Map)['alias']
          as String;

  test('component spacing and row heights go through the density rows', () {
    expect(
      componentAlias('button/padding-x-md'),
      'Semantic/ Dimension/space/16',
    );
    expect(componentAlias('button/gap-md'), 'Semantic/ Dimension/space/6');
    // The sm / lg rows are rungs of the control ladder; the 36 md row is
    // not, so it aliases the primitive size and no density moves it.
    expect(
      componentAlias('menu-item/height-sm'),
      'Semantic/ Dimension/control-size/sm',
    );
    expect(componentAlias('menu-item/height-md'), 'Primitives/size/36');
    expect(
      componentAlias('menu-item/height-lg'),
      'Semantic/ Dimension/control-size/lg',
    );
    expect(
      componentAlias('select/height-md'),
      'Semantic/ Dimension/control-size/md',
    );
  });

  test(
    'the button glyph rows are two ladders, the shaped one a step larger',
    () {
      // Written out: the glyph beside a label and the glyph of a square or
      // circle button are different rows of one size tier, and both are
      // exported so the builder binds each by name.
      const beside = {
        'xs': 12,
        'sm': 14,
        'md': 16,
        'lg': 18,
        'xl': 20,
        'xl2': 24,
      };
      const shaped = {
        'xs': 14,
        'sm': 16,
        'md': 18,
        'lg': 20,
        'xl': 24,
        'xl2': 28,
      };
      for (final tier in beside.keys) {
        expect(
          componentAlias('button/icon-$tier'),
          'Primitives/size/${beside[tier]}',
          reason: 'button/icon-$tier',
        );
        expect(
          componentAlias('button/icon-shape-$tier'),
          'Primitives/size/${shaped[tier]}',
          reason: 'button/icon-shape-$tier',
        );
      }
    },
  );

  test('placement is not spacing — the select panel offset keeps the '
      'primitive', () {
    expect(componentAlias('select/panel-offset'), startsWith('Primitives/'));
  });
}
