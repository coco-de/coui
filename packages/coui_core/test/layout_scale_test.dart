import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// `CoreLayout` is the third dimension namespace, and its whole reason
/// to exist is that its numbers are NOT element sizes or spacing. These
/// pin the palette and the boundary: every step has a Tailwind key that
/// names its own value, and no step can be mistaken for a `CoreSize`.
void main() {
  group('CoreLayout', () {
    test('the palette is the stated bounds, ascending', () {
      expect(CoreLayout.values, [
        160.0,
        240.0,
        248.0,
        280.0,
        320.0,
        400.0,
        560.0,
        640.0,
      ]);
      expect(CoreLayout.layout160, 160.0);
      expect(CoreLayout.layout240, 240.0);
      expect(CoreLayout.layout248, 248.0);
      expect(CoreLayout.layout280, 280.0);
      expect(CoreLayout.layout320, 320.0);
      expect(CoreLayout.layout400, 400.0);
      expect(CoreLayout.layout560, 560.0);
      expect(CoreLayout.layout640, 640.0);
    });

    test('every step has a scale key that names its value', () {
      final keys = [
        CoreLayout.scale.layout160,
        CoreLayout.scale.layout240,
        CoreLayout.scale.layout248,
        CoreLayout.scale.layout280,
        CoreLayout.scale.layout320,
        CoreLayout.scale.layout400,
        CoreLayout.scale.layout560,
        CoreLayout.scale.layout640,
      ];
      for (var i = 0; i < keys.length; i++) {
        expect(keys[i], 'layout${CoreLayout.values[i].toInt()}');
      }
    });

    test('no layout bound is an element size', () {
      // The size ladder ends at 128 on purpose — a bound above it is a
      // panel, which is what this namespace holds. If a value ever lands
      // in both, the resolver has two variables for one number.
      for (final v in CoreLayout.values) {
        expect(v, greaterThan(CoreSize.size128));
      }
    });
  });
}
