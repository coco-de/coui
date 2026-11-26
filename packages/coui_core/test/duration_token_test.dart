import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreDuration spec primitives — Transition (50ms 단위)', () {
    test('ms0..ms500 values', () {
      expect(CoreDuration.ms0, equals(0));
      expect(CoreDuration.ms50, equals(50));
      expect(CoreDuration.ms100, equals(100));
      expect(CoreDuration.ms150, equals(150));
      expect(CoreDuration.ms200, equals(200));
      expect(CoreDuration.ms250, equals(250));
      expect(CoreDuration.ms300, equals(300));
      expect(CoreDuration.ms350, equals(350));
      expect(CoreDuration.ms400, equals(400));
      expect(CoreDuration.ms450, equals(450));
      expect(CoreDuration.ms500, equals(500));
    });
  });

  group('CoreDuration spec primitives — Display (1000ms 단위)', () {
    test('ms1000..ms5000 values', () {
      expect(CoreDuration.ms1000, equals(1000));
      expect(CoreDuration.ms2000, equals(2000));
      expect(CoreDuration.ms3000, equals(3000));
      expect(CoreDuration.ms4000, equals(4000));
      expect(CoreDuration.ms5000, equals(5000));
    });
  });

  group('CoreDuration component-specific tokens (spec 외)', () {
    test('indeterminate retains 1500ms', () {
      expect(CoreDuration.indeterminate, equals(1500));
    });
  });

  group('CoreDuration alias tier (semantic)', () {
    test('each alias is pinned to its raw token', () {
      expect(CoreDuration.instant, equals(CoreDuration.ms100));
      expect(CoreDuration.fast, equals(CoreDuration.ms150));
      expect(CoreDuration.normal, equals(CoreDuration.ms200));
      expect(CoreDuration.moderate, equals(CoreDuration.ms300));
      expect(CoreDuration.slow, equals(CoreDuration.ms500));
    });

    test('alias values match the timings they replaced', () {
      // Introducing the alias tier must not have retimed anything, so these
      // are asserted against literals rather than the raw tokens above.
      expect(CoreDuration.instant, equals(100));
      expect(CoreDuration.fast, equals(150));
      expect(CoreDuration.normal, equals(200));
      expect(CoreDuration.moderate, equals(300));
      expect(CoreDuration.slow, equals(500));
    });

    test('aliases stay inside the transition tier', () {
      // Display-tier values describe how long content stays on screen, not
      // how fast it moves. An alias pointing at one would put it in reach of
      // a motion override that has no business changing it.
      const aliases = <int>[
        CoreDuration.instant,
        CoreDuration.fast,
        CoreDuration.normal,
        CoreDuration.moderate,
        CoreDuration.slow,
      ];
      for (final alias in aliases) {
        expect(alias, inInclusiveRange(CoreDuration.ms0, CoreDuration.ms500));
      }
    });

    test('aliases are ordered fastest to slowest', () {
      expect(CoreDuration.instant, lessThan(CoreDuration.fast));
      expect(CoreDuration.fast, lessThan(CoreDuration.normal));
      expect(CoreDuration.normal, lessThan(CoreDuration.moderate));
      expect(CoreDuration.moderate, lessThan(CoreDuration.slow));
    });
  });

  group('CoreDuration scale record', () {
    test('spec primitive keys', () {
      expect(CoreDuration.scale.ms0, equals('0'));
      expect(CoreDuration.scale.ms200, equals('200'));
      expect(CoreDuration.scale.ms3000, equals('3000'));
    });
  });
}
