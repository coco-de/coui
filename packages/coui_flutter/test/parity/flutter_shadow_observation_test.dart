import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import 'flutter_property_snapshot.dart';

Map<String, Object?> _snapshot(List<BoxShadow>? shadows) =>
    buildFlutterPropertySnapshotJson(
      key: 'shadow-observation',
      probeRole: 'root',
      decoration: BoxDecoration(boxShadow: shadows),
    );

List<Map<String, Object?>> _layers(Map<String, Object?> snapshot) =>
    (snapshot['boxShadow']! as List).cast<Map<String, Object?>>();

void main() {
  for (final cssBlur in [2.0, 4.0, 6.0, 8.0, 15.0, 25.0]) {
    test('observes the Core CSS blur $cssBlur after SDK conversion', () {
      final snapshot = _snapshot([
        BoxShadow(blurRadius: cssBlurRadiusToFlutter(cssBlur)),
      ]);
      expect(_layers(snapshot).single['blur'], cssBlur);
      expect(snapshot['shadowBlurUnit'], 'css-radius');
    });
  }

  test('a direct SDK shadow reports its actual painted Gaussian sigma', () {
    final snapshot = _snapshot(const [BoxShadow(blurRadius: 12)]);
    expect(_layers(snapshot).single['blur'], 14.86);
  });

  test('zero SDK radius stays sharp without inventing an inverse input', () {
    final snapshot = _snapshot(const [BoxShadow()]);
    expect(_layers(snapshot).single['blur'], 0);
  });

  test('sub-intercept Core radii report the sharp SDK paint', () {
    final snapshot = _snapshot([
      BoxShadow(blurRadius: cssBlurRadiusToFlutter(0.75)),
    ]);
    expect(_layers(snapshot).single['blur'], 0);
  });

  test('only exactly transparent raw shadows are absent', () {
    final snapshot = _snapshot([
      const BoxShadow(
        color: Color(0x00ABCDEF),
        offset: Offset(10, -7),
        blurRadius: 20,
        spreadRadius: 5,
      ),
      const BoxShadow(
        color: Color.from(alpha: 0.0004, red: 1, green: 0, blue: 0),
      ),
    ]);
    expect(_layers(snapshot), hasLength(1));
    // Its rounded canonical alpha is zero; raw positive paint still exists.
    expect((_layers(snapshot).single['color']! as Map)['a'], 0);
  });

  test('no attributed chrome remains unknown, not a measured empty list', () {
    final snapshot = buildFlutterPropertySnapshotJson(
      key: 'unknown',
      probeRole: 'root',
    );
    expect(snapshot['boxShadow'], isNull);
    expect(snapshot.containsKey('shadowBlurUnit'), isFalse);
  });

  test('filtering keeps visible layer order and all other geometry', () {
    final snapshot = _snapshot(const [
      BoxShadow(offset: Offset(1, 2), spreadRadius: -3),
      BoxShadow(color: Color(0x00000000)),
      BoxShadow(offset: Offset(4, 5), spreadRadius: 6),
    ]);
    final layers = _layers(snapshot);
    expect(layers.map((x) => x['offsetX']), [1, 4]);
    expect(layers.map((x) => x['offsetY']), [2, 5]);
    expect(layers.map((x) => x['spread']), [-3, 6]);
  });

  for (final style in BlurStyle.values) {
    test('preserves SDK blur paint style ${style.name}', () {
      final layer = _layers(_snapshot([BoxShadow(blurStyle: style)])).single;
      if (style == BlurStyle.normal) {
        expect(layer.containsKey('blurStyle'), isFalse);
      } else {
        expect(layer['blurStyle'], style.name);
      }
    });
  }
}
