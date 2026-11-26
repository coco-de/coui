import 'package:test/test.dart';

import '../../src/model/property_snapshot.dart';

void main() {
  final legacy = <String, Object?>{
    'offsetX': 0.0,
    'offsetY': 4.0,
    'blur': 6.0,
    'spread': -1.0,
    'color': {'r': 12, 'g': 34, 'b': 56, 'a': 0.125},
  };

  test('legacy layers retain geometry and omit default metadata on write', () {
    final layer = BoxShadowLayer.fromJson(legacy);
    expect(layer.inset, isFalse);
    expect(layer.blurStyle, 'normal');
    expect(layer.blur, 6); // No implicit legacy blur-unit conversion.
    expect(layer.toJson(), legacy);
  });

  test('placement and all SDK blur kinds survive snapshot JSON', () {
    final layers = [
      for (final inset in [false, true])
        for (final kind in ['normal', 'solid', 'outer', 'inner'])
          BoxShadowLayer.fromJson({
            ...legacy,
            'inset': inset,
            'blurStyle': kind,
          }),
    ];
    expect(layers.toSet(), hasLength(8));
    final original = PropertySnapshot(
      key: 'paint',
      platform: 'flutter',
      probeRole: 'root',
      boxShadow: layers,
    );
    final decoded = PropertySnapshot.fromJson(original.toJson());
    expect(decoded, original);
    expect(decoded.boxShadow, layers);
    expect(layers.first.toJson(), legacy);
    expect(layers.last.toJson(), {
      ...legacy,
      'inset': true,
      'blurStyle': 'inner',
    });
  });
}
