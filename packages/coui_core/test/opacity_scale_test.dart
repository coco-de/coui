import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreOpacity primitives (18개)', () {
    test('values are within [0, 1]', () {
      const all = [
        CoreOpacity.opacity0,
        CoreOpacity.opacity3,
        CoreOpacity.opacity5,
        CoreOpacity.opacity10,
        CoreOpacity.opacity15,
        CoreOpacity.opacity20,
        CoreOpacity.opacity25,
        CoreOpacity.opacity30,
        CoreOpacity.opacity40,
        CoreOpacity.opacity50,
        CoreOpacity.opacity60,
        CoreOpacity.opacity70,
        CoreOpacity.opacity75,
        CoreOpacity.opacity80,
        CoreOpacity.opacity85,
        CoreOpacity.opacity90,
        CoreOpacity.opacity95,
        CoreOpacity.opacity100,
      ];
      expect(all, hasLength(18));
      for (final v in all) {
        expect(v >= 0 && v <= 1, isTrue, reason: '$v out of [0,1]');
      }
    });

    test('exact spec values', () {
      expect(CoreOpacity.opacity0, equals(0));
      expect(CoreOpacity.opacity3, equals(0.03));
      expect(CoreOpacity.opacity5, equals(0.05));
      expect(CoreOpacity.opacity10, equals(0.1));
      expect(CoreOpacity.opacity15, equals(0.15));
      expect(CoreOpacity.opacity50, equals(0.5));
      expect(CoreOpacity.opacity75, equals(0.75));
      expect(CoreOpacity.opacity100, equals(1));
    });

    test('values are monotonically non-decreasing', () {
      const all = [
        CoreOpacity.opacity0,
        CoreOpacity.opacity3,
        CoreOpacity.opacity5,
        CoreOpacity.opacity10,
        CoreOpacity.opacity15,
        CoreOpacity.opacity20,
        CoreOpacity.opacity25,
        CoreOpacity.opacity30,
        CoreOpacity.opacity40,
        CoreOpacity.opacity50,
        CoreOpacity.opacity60,
        CoreOpacity.opacity70,
        CoreOpacity.opacity75,
        CoreOpacity.opacity80,
        CoreOpacity.opacity85,
        CoreOpacity.opacity90,
        CoreOpacity.opacity95,
        CoreOpacity.opacity100,
      ];
      for (var i = 1; i < all.length; i++) {
        expect(all[i] > all[i - 1], isTrue);
      }
    });
  });

  group('CoreOpacity semantic tokens reference primitives', () {
    test('disabled = opacity40', () {
      expect(CoreOpacity.disabled, equals(CoreOpacity.opacity40));
    });

    test('hover = opacity3', () {
      expect(CoreOpacity.hover, equals(CoreOpacity.opacity3));
    });

    test('focus = opacity8', () {
      expect(CoreOpacity.focus, equals(CoreOpacity.opacity8));
    });

    test('pressed = opacity12', () {
      expect(CoreOpacity.pressed, equals(CoreOpacity.opacity12));
    });

    // The three are the ramp `CoreStateLayer.subtle` paints, and they are
    // published to Figma as `opacity/hover|focus|pressed`. Until 0.130 the
    // trio said 3 / 10 / 15 while the layer painted 3 / 8 / 12 — a second
    // ramp, and the one designers could bind to on the canvas.
    test('the trio IS the subtle state ramp — one source, not two', () {
      expect(CoreStateLayer.subtle.hover, equals(CoreOpacity.hover));
      expect(CoreStateLayer.subtle.focus, equals(CoreOpacity.focus));
      expect(CoreStateLayer.subtle.pressed, equals(CoreOpacity.pressed));
    });

    test('scrim = opacity30', () {
      expect(CoreOpacity.scrim, equals(CoreOpacity.opacity30));
    });

    test('hover < focus < pressed (state ladder)', () {
      expect(CoreOpacity.hover < CoreOpacity.focus, isTrue);
      expect(CoreOpacity.focus < CoreOpacity.pressed, isTrue);
    });
  });

  group('CoreOpacity scale record', () {
    test('primitive keys', () {
      expect(CoreOpacity.scale.opacity0, equals('0'));
      expect(CoreOpacity.scale.opacity50, equals('50'));
      expect(CoreOpacity.scale.opacity100, equals('100'));
    });

    test('semantic keys', () {
      expect(CoreOpacity.scale.disabled, equals('disabled'));
      expect(CoreOpacity.scale.hover, equals('hover'));
      expect(CoreOpacity.scale.focus, equals('focus'));
      expect(CoreOpacity.scale.pressed, equals('pressed'));
      expect(CoreOpacity.scale.scrim, equals('scrim'));
    });
  });
}
