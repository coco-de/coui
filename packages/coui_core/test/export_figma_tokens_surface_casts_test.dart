// `Semantic/ Surface` cast rows — what a surface style does to the shadows,
// on the canvas.
//
// Every layer of every step of the shadow scale gets an `x` · `y` · `blur` ·
// `color` row whose value in each style's mode is what the shared seat bends
// that layer to (`resolveThemeGeometry(surfaceStyle:).shadow`). The
// expectations are read from that seat, and a few are written out as numbers
// — a second source that fails if the seat and the export drift together.
import 'dart:convert';
import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  late Map<String, Map<String, dynamic>> rows;

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
    final surface = (doc['collections'] as List)
        .cast<Map<String, dynamic>>()
        .singleWhere((c) => c['name'] == 'Semantic/ Surface');
    rows = {
      for (final v
          in (surface['variables'] as List).cast<Map<String, dynamic>>())
        v['name'] as String: v,
    };
  });

  const scale = <String, List<CoreShadowLayer>>{
    'xs': CoreShadow.xs,
    'sm': CoreShadow.sm,
    'md': CoreShadow.md,
    'lg': CoreShadow.lg,
    'xl': CoreShadow.xl,
    '2xl': CoreShadow.xl2,
    '3xl': CoreShadow.xl3,
    'inset': CoreShadow.inset,
  };

  Object? valueOf(String name, CoreSurfaceStyleId id) =>
      (rows[name]!['valuesByMode'] as Map)[id.name];

  double alphaOf(String name, CoreSurfaceStyleId id) =>
      ((valueOf(name, id)! as Map)['a'] as num).toDouble();

  test('every layer of every step has its four rows, casts a mirror', () {
    for (final step in scale.entries) {
      for (var i = 0; i < step.value.length; i++) {
        for (final field in ['x', 'y', 'blur', 'color']) {
          expect(rows, contains('shadow/${step.key}/$i/$field'));
          expect(
            rows.containsKey('shadow/${step.key}/$i-mirror/$field'),
            !step.value[i].inset,
            reason: 'an inset layer has no twin; a cast does',
          );
        }
      }
    }
  });

  test(
    'the default style is the scale as authored, mirrors drawing nothing',
    () {
      for (final step in scale.entries) {
        for (var i = 0; i < step.value.length; i++) {
          final layer = step.value[i];
          expect(
            valueOf('shadow/${step.key}/$i/x', .defaultStyle),
            layer.offsetX,
          );
          expect(
            valueOf('shadow/${step.key}/$i/y', .defaultStyle),
            layer.offsetY,
          );
          expect(
            valueOf('shadow/${step.key}/$i/blur', .defaultStyle),
            layer.blurRadius,
          );
          expect(
            alphaOf('shadow/${step.key}/$i/color', .defaultStyle),
            layer.opacity,
          );
          if (!layer.inset) {
            expect(
              alphaOf('shadow/${step.key}/$i-mirror/color', .defaultStyle),
              0,
            );
          }
        }
      }
    },
  );

  test('each style carries what the shared seat bends each layer to', () {
    for (final id in CoreSurfaceStyleId.values) {
      final geometry = resolveThemeGeometry(surfaceStyle: id);
      for (final step in scale.entries) {
        final bent = geometry.shadow(step.value);
        var k = 0;
        for (var i = 0; i < step.value.length; i++) {
          final cast = bent[k++];
          final where = '${id.name} ${step.key}/$i';
          expect(
            valueOf('shadow/${step.key}/$i/x', id),
            cast.offsetX,
            reason: where,
          );
          expect(
            valueOf('shadow/${step.key}/$i/y', id),
            cast.offsetY,
            reason: where,
          );
          expect(
            valueOf('shadow/${step.key}/$i/blur', id),
            cast.blurRadius,
            reason: where,
          );
          expect(
            alphaOf('shadow/${step.key}/$i/color', id),
            cast.opacity,
            reason: where,
          );
          if (geometry.shadowMirror && !step.value[i].inset) {
            final twin = bent[k++];
            expect(
              valueOf('shadow/${step.key}/$i-mirror/x', id),
              twin.offsetX,
              reason: '$where mirror',
            );
            expect(
              valueOf('shadow/${step.key}/$i-mirror/y', id),
              twin.offsetY,
              reason: '$where mirror',
            );
            expect(
              alphaOf('shadow/${step.key}/$i-mirror/color', id),
              twin.opacity,
              reason: '$where mirror',
            );
          } else if (!step.value[i].inset) {
            expect(
              alphaOf('shadow/${step.key}/$i-mirror/color', id),
              0,
              reason: '$where mirror at rest',
            );
          }
        }
      }
    }
  });

  test('the shipped styles land where the platforms draw them', () {
    // Written out: a neo-brutalist md cast is a hard, solid offset copy, and
    // a neumorphic one throws its twin the other way in the highlight.
    expect(valueOf('shadow/md/0/x', .neoBrutalism), 4.0);
    expect(valueOf('shadow/md/0/y', .neoBrutalism), 12.0);
    expect(valueOf('shadow/md/0/blur', .neoBrutalism), 0.0);
    expect(alphaOf('shadow/md/0/color', .neoBrutalism), 1.0);
    expect(valueOf('shadow/md/0-mirror/y', .neumorphism), -8.0);
    final twin = valueOf('shadow/md/0-mirror/color', .neumorphism)! as Map;
    expect([twin['r'], twin['g'], twin['b']], [1.0, 1.0, 1.0]);
  });
}
