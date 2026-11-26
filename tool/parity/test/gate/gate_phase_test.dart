import 'package:test/test.dart';

import '../../src/gate/gate_phase.dart';

void main() {
  group('GatePhase', () {
    test('current phase is a — Phase A, not yet promoted', () {
      expect(GatePhase.current, GatePhase.a);
    });

    test('phase a requires neither signal (fully advisory)', () {
      expect(GatePhase.a.requiresProperty, isFalse);
      expect(GatePhase.a.requiresPixel, isFalse);
    });

    test('phase b requires property only', () {
      expect(GatePhase.b.requiresProperty, isTrue);
      expect(GatePhase.b.requiresPixel, isFalse);
    });

    test('phase c requires both signals', () {
      expect(GatePhase.c.requiresProperty, isTrue);
      expect(GatePhase.c.requiresPixel, isTrue);
    });

    test('tryParse round-trips every wire name', () {
      for (final phase in GatePhase.values) {
        expect(GatePhase.tryParse(phase.wireName), phase);
      }
    });

    test('tryParse returns null for an unknown value', () {
      expect(GatePhase.tryParse('d'), isNull);
    });
  });
}
