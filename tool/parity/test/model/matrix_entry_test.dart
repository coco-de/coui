import 'package:coui_web/coui_web.dart' show CoreSurfaceStyleId;
import 'package:test/test.dart';

import '../../src/model/matrix_entry.dart';
import '../../src/model/parity_theme.dart';
import '../../src/model/parity_tier.dart';
import '../../src/model/probe_spec.dart';

void main() {
  group('MatrixEntry', () {
    MatrixEntry build() => MatrixEntry(
      component: 'dialog',
      variant: 'default',
      theme: ParityTheme.dark,
      surfaceStyle: CoreSurfaceStyleId.neoBrutalism,
      tier: ParityTier.t1,
      probes: [rootProbeSpec(key: 'x', flutterClassName: 'Dialog')],
    );

    test('key is component-variant-theme-surfaceStyle', () {
      expect(build().key, 'dialog-default-dark-neoBrutalism');
    });

    test('round-trips through JSON', () {
      final entry = build();
      final decoded = MatrixEntry.fromJson(entry.toJson());
      expect(decoded.key, entry.key);
      expect(decoded.component, entry.component);
      expect(decoded.variant, entry.variant);
      expect(decoded.theme, entry.theme);
      expect(decoded.surfaceStyle, entry.surfaceStyle);
      expect(decoded.tier, entry.tier);
      expect(decoded.probes.single, entry.probes.single);
    });

    test('fromJson rejects an unknown theme', () {
      final json = build().toJson()..['theme'] = 'sepia';
      expect(() => MatrixEntry.fromJson(json), throwsFormatException);
    });

    test('fromJson rejects an unknown tier', () {
      final json = build().toJson()..['tier'] = 't3';
      expect(() => MatrixEntry.fromJson(json), throwsFormatException);
    });

    test('fromJson rejects an unknown surfaceStyle', () {
      final json = build().toJson()..['surfaceStyle'] = 'skeuomorphism';
      expect(() => MatrixEntry.fromJson(json), throwsFormatException);
    });
  });
}
