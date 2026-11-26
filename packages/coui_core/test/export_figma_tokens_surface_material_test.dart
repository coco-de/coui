// `Semantic/ Surface` material rows — the part of a surface style's material
// a number can carry, on the canvas.
//
// Per role: the share of the fill that shows, the backdrop blur as a Figma
// radius, and whether the role refracts. Shared: the inset rim. And what a
// style contributes to a surface or control that authors nothing — the
// boundary and the cast. The expectations are read from the seat both
// platforms ask (`resolveThemeRecipe` · `resolveThemeGeometry`), and a few are
// written out as numbers — a second source that fails if the seat and the
// export drift together.
import 'dart:convert';
import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  late Map<String, Map<String, dynamic>> rows;
  late Map<String, Map<String, dynamic>> primitives;

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
    Map<String, Map<String, dynamic>> collection(String name) => {
      for (final v
          in ((doc['collections'] as List)
                      .cast<Map<String, dynamic>>()
                      .singleWhere((c) => c['name'] == name)['variables']
                  as List)
              .cast<Map<String, dynamic>>())
        v['name'] as String: v,
    };
    rows = collection('Semantic/ Surface');
    primitives = collection('Primitives');
  });

  Object? valueOf(String name, CoreSurfaceStyleId id) =>
      (rows[name]!['valuesByMode'] as Map)[id.name];

  // An alias row resolved to the number its primitive holds.
  num aliased(String name, CoreSurfaceStyleId id) {
    final alias = (valueOf(name, id)! as Map)['alias'] as String;
    final leaf = alias.substring('Primitives/'.length);
    final primitive = primitives[leaf];
    expect(primitive, isNotNull, reason: '$name → $alias names no primitive');

    return (primitive!['valuesByMode'] as Map)['Value'] as num;
  }

  double alphaOf(String name, CoreSurfaceStyleId id) =>
      ((valueOf(name, id)! as Map)['a'] as num).toDouble();

  test('each role has its three rows, and every style a value for each', () {
    for (final role in CoreSurfaceRole.values) {
      for (final field in ['fill-opacity', 'backdrop-blur', 'glass']) {
        final name = 'material/${role.name}/$field';
        expect(rows, contains(name));
        expect(
          (rows[name]!['valuesByMode'] as Map).keys,
          unorderedEquals([
            for (final id in CoreSurfaceStyleId.values) id.name,
          ]),
        );
      }
      expect(rows['material/${role.name}/glass']!['type'], 'BOOLEAN');
    }
    expect(rows, contains('material/control-border'));
  });

  test('the default style is the material as the components paint it', () {
    for (final role in CoreSurfaceRole.values) {
      expect(aliased('material/${role.name}/fill-opacity', .defaultStyle), 100);
      expect(valueOf('material/${role.name}/backdrop-blur', .defaultStyle), 0);
      expect(valueOf('material/${role.name}/glass', .defaultStyle), isFalse);
    }
    for (final name in rows.keys.where(
      (n) =>
          (n.startsWith('material/rim/') ||
              n.startsWith('material/control-shadow/')) &&
          n.endsWith('/color'),
    )) {
      expect(alphaOf(name, .defaultStyle), 0, reason: name);
    }
    expect(aliased('material/control-border', .defaultStyle), 0);
  });

  test('each style carries what the shared seat states', () {
    for (final id in CoreSurfaceStyleId.values) {
      final recipe = resolveThemeRecipe(surfaceStyle: id);
      final geometry = resolveThemeGeometry(surfaceStyle: id);
      for (final role in CoreSurfaceRole.values) {
        final material = recipe.surfaceFor(role);
        final where = '${id.name} ${role.name}';
        expect(
          aliased('material/${role.name}/fill-opacity', id),
          closeTo(
            (material?.opacity.resolve(.light) ??
                    CoreSurfaceOpacity.opaqueValue) *
                100,
            1e-9,
          ),
          reason: where,
        );
        // The platforms' σ, as the radius Figma states (twice σ).
        expect(
          valueOf('material/${role.name}/backdrop-blur', id),
          (material?.blurRadius ?? 0) * 2,
          reason: where,
        );
        expect(
          valueOf('material/${role.name}/glass', id),
          recipe.refraction != null && material?.type == SurfaceType.glass,
          reason: where,
        );
      }

      final rim = geometry.highlightRim;
      for (var i = 0; rows.containsKey('material/rim/$i/x'); i++) {
        final layer = i < rim.length ? rim[i] : null;
        final where = '${id.name} rim $i';
        expect(valueOf('material/rim/$i/x', id), layer?.offsetX ?? 0);
        expect(valueOf('material/rim/$i/y', id), layer?.offsetY ?? 0);
        expect(valueOf('material/rim/$i/blur', id), layer?.blurRadius ?? 0);
        expect(
          alphaOf('material/rim/$i/color', id),
          layer?.opacity ?? 0,
          reason: where,
        );
      }

      expect(
        aliased('material/control-border', id),
        geometry.controlBorder ?? 0,
        reason: id.name,
      );

      final cast = geometry.controlShadow;
      for (var i = 0; rows.containsKey('material/control-shadow/$i/x'); i++) {
        final layer = i < cast.length ? cast[i] : null;
        final where = '${id.name} control shadow $i';
        expect(
          valueOf('material/control-shadow/$i/x', id),
          layer?.offsetX ?? 0,
        );
        expect(
          valueOf('material/control-shadow/$i/y', id),
          layer?.offsetY ?? 0,
        );
        expect(
          valueOf('material/control-shadow/$i/blur', id),
          layer?.blurRadius ?? 0,
        );
        expect(
          alphaOf('material/control-shadow/$i/color', id),
          layer?.opacity ?? 0,
          reason: where,
        );
      }
    }
  });

  test('every layer a style states has its rows', () {
    for (final id in CoreSurfaceStyleId.values) {
      final geometry = resolveThemeGeometry(surfaceStyle: id);
      for (var i = 0; i < geometry.highlightRim.length; i++) {
        expect(rows, contains('material/rim/$i/color'), reason: id.name);
      }
      for (var i = 0; i < geometry.controlShadow.length; i++) {
        expect(
          rows,
          contains('material/control-shadow/$i/color'),
          reason: id.name,
        );
      }
    }
  });

  test('the shipped styles land where the platforms draw them', () {
    // Written out: liquid glass shows half its fill through a frost of σ 4,
    // and bends at its rim; clay lights its top edge in the highlight;
    // neo-brutalism boxes what draws no boundary and casts a hard offset.
    expect(aliased('material/content/fill-opacity', .liquidGlass), 50);
    expect(aliased('material/functional/fill-opacity', .liquidGlass), 50);
    expect(valueOf('material/content/backdrop-blur', .liquidGlass), 8.0);
    expect(valueOf('material/functional/glass', .liquidGlass), isTrue);
    expect(valueOf('material/content/glass', .claymorphism), isFalse);
    expect(valueOf('material/rim/0/y', .claymorphism), 2.0);
    expect(valueOf('material/rim/0/blur', .claymorphism), 6.0);
    expect(alphaOf('material/rim/0/color', .claymorphism), 0.55);
    final rim = valueOf('material/rim/0/color', .claymorphism)! as Map;
    expect([rim['r'], rim['g'], rim['b']], [1.0, 1.0, 1.0]);
    expect(aliased('material/control-border', .neoBrutalism), 4);
    expect(valueOf('material/control-shadow/0/x', .neoBrutalism), 4.0);
    expect(valueOf('material/control-shadow/0/y', .neoBrutalism), 4.0);
    expect(valueOf('material/control-shadow/0/blur', .neoBrutalism), 0.0);
    expect(alphaOf('material/control-shadow/0/color', .neoBrutalism), 1.0);
  });
}
