import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreRadius spec primitive tokens', () {
    test('small group (0–16px, 2px interval)', () {
      expect(CoreRadius.radius0, equals(0));
      expect(CoreRadius.radius2, equals(2));
      expect(CoreRadius.radius4, equals(4));
      expect(CoreRadius.radius6, equals(6));
      expect(CoreRadius.radius8, equals(8));
      expect(CoreRadius.radius10, equals(10));
      expect(CoreRadius.radius12, equals(12));
      expect(CoreRadius.radius14, equals(14));
      expect(CoreRadius.radius16, equals(16));
    });

    test('medium group (20–36px, 4px interval)', () {
      expect(CoreRadius.radius20, equals(20));
      expect(CoreRadius.radius24, equals(24));
      expect(CoreRadius.radius28, equals(28));
      expect(CoreRadius.radius32, equals(32));
      expect(CoreRadius.radius36, equals(36));
    });

    test('large group (40–64px, 8px interval)', () {
      expect(CoreRadius.radius40, equals(40));
      expect(CoreRadius.radius48, equals(48));
      expect(CoreRadius.radius56, equals(56));
      expect(CoreRadius.radius64, equals(64));
    });

    test('full token', () {
      expect(CoreRadius.radius9999, equals(9999));
    });
  });

  group('CoreRadius scale record', () {
    test('contains spec primitive keys', () {
      expect(CoreRadius.scale.radius0, equals('radius0'));
      expect(CoreRadius.scale.radius8, equals('radius8'));
      expect(CoreRadius.scale.radius16, equals('radius16'));
      expect(CoreRadius.scale.radius9999, equals('radius9999'));
    });
  });
}
