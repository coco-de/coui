// Real Flutter render objects plus the current capture helper. These fixtures
// test measurement fidelity, not a rendered CoUI design or expected-style hook.
import 'dart:convert';
import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/coui_flutter.dart' show CoreColorToFlutter;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'flutter_property_snapshot.dart';

double _roundAlpha(double value) => double.parse(value.toStringAsFixed(3));

final _observations = <Map<String, Object?>>[];

void _record(String name, Color color, Map<String, Object?> snapshot) {
  _observations.add({
    'case': name,
    'actualColorA': color.a,
    'actualARGB32': color.toARGB32(),
    'roundedActualA': _roundAlpha(color.a),
    'measured': snapshot,
  });
}

void main() {
  tearDownAll(() {
    final path = Platform.environment['ALPHA_NATIVE_OBSERVATIONS'];
    if (path != null) {
      File(path).writeAsStringSync(jsonEncode(_observations));
    }
  });

  testWidgets('real text Color.a is preserved by the measurement', (
    tester,
  ) async {
    const color = Color.from(alpha: .3, red: .1, green: .2, blue: .3);
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Text('alpha', style: TextStyle(color: color)),
      ),
    );
    final paragraph = tester.renderObject<RenderParagraph>(
      find.byType(RichText),
    );
    final actual = paragraph.text.style!.color!;
    final json = normalizedColorJson(actual);
    _record('text float alpha', actual, json);
    expect(actual.a, .3);
    expect(json['r'], 26);
    expect(json['g'], 51);
    expect(json['b'], 77);
    expect(json['a'], _roundAlpha(actual.a));
  });

  testWidgets('real Core colour fill border shadow retain actual alpha', (
    tester,
  ) async {
    final color = const CoreColor.token(
      CoreColors.primary,
      opacity: .3,
    ).toValue();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: color),
            boxShadow: [BoxShadow(color: color)],
          ),
          child: const SizedBox(width: 24, height: 24),
        ),
      ),
    );
    final render = tester.renderObject<RenderDecoratedBox>(
      find.byType(DecoratedBox),
    );
    final actual = render.decoration as BoxDecoration;
    final json = buildFlutterPropertySnapshotJson(
      key: 'alpha-measurement',
      probeRole: 'root',
      decoration: actual,
    );
    _record('Core token decoration actual', actual.color!, json);
    expect(actual.color!.a, .3);
    expect(actual.border!.top.color.a, .3);
    expect(actual.boxShadow!.single.color.a, .3);
    for (final field in ['backgroundColor', 'borderColor']) {
      expect((json[field]! as Map)['a'], _roundAlpha(color.a));
    }
    final shadow = (json['boxShadow']! as List).single as Map;
    expect((shadow['color'] as Map)['a'], _roundAlpha(color.a));
  });

  for (final byte in [6, 7, 0, 255]) {
    testWidgets('actual ARGB byte$byte keeps its existing interpretation', (
      tester,
    ) async {
      final color = Color.fromARGB(byte, 1, 2, 3);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text('raw alpha', style: TextStyle(color: color)),
        ),
      );
      final paragraph = tester.renderObject<RenderParagraph>(
        find.byType(RichText),
      );
      final actual = paragraph.text.style!.color!;
      final json = normalizedColorJson(actual);
      _record('ARGB byte$byte', actual, json);
      expect(actual.a, byte / 255);
      expect(json, {'r': 1, 'g': 2, 'b': 3, 'a': _roundAlpha(actual.a)});
    });
  }

  testWidgets('a float matching an old lattice point remains a float', (
    tester,
  ) async {
    const color = Color.from(alpha: .302, red: .1, green: .2, blue: .3);
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Text('coincidence', style: TextStyle(color: color)),
      ),
    );
    final paragraph = tester.renderObject<RenderParagraph>(
      find.byType(RichText),
    );
    final actual = paragraph.text.style!.color!;
    final json = normalizedColorJson(actual);
    _record('float coincident point302', actual, json);
    expect(actual.a, .302);
    expect(json['a'], _roundAlpha(actual.a));
  });

  testWidgets('root opacity observation keeps its continuous property', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Opacity(opacity: .303, child: SizedBox(width: 24, height: 24)),
      ),
    );
    final render = tester.renderObject<RenderOpacity>(find.byType(Opacity));
    final json = buildFlutterPropertySnapshotJson(
      key: 'alpha-measurement',
      probeRole: 'root',
      opacity: render.opacity,
    );
    _observations.add({
      'case': 'continuous root opacity',
      'actualRenderOpacity': render.opacity,
      'measured': json,
    });
    expect(render.opacity, .303);
    expect(json['opacity'], .303);
  });
}
