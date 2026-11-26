import 'package:coui_web/coui_web.dart';
import 'package:test/test.dart';

// `CoreDuration.indeterminate`'s pinned value — named so the assertions
// below don't read as an unexplained magic number.
const _kIndeterminateMs = 1500;

void main() {
  final css = ThemeConfig.defaults().cssVariables;
  final tailwind = ThemeConfig.defaults().tailwindConfig;

  group('duration tokens are addressable', () {
    test(':root defines a variable per duration token', () {
      for (final ms in [
        0,
        50,
        100,
        150,
        200,
        250,
        300,
        350,
        400,
        450,
        500,
        1000,
        2000,
        3000,
        4000,
        5000,
        1500,
      ]) {
        expect(
          css,
          contains('--coui-duration-$ms:${ms}ms;'),
          reason: 'duration-$ms has no variable to override.',
        );
      }
    });

    test('the Tailwind duration scale resolves through those variables', () {
      // Without this indirection the utilities bake literal milliseconds and
      // no media query can retime them.
      expect(tailwind, contains('"150":"var(--coui-duration-150)"'));
      expect(tailwind, contains('"1000":"var(--coui-duration-1000)"'));
      expect(
        tailwind,
        isNot(contains('"150":"150ms"')),
        reason: 'a literal duration is unreachable by the override.',
      );
    });

    test('indeterminate (1500ms) is not a dead Tailwind key (#3470)', () {
      // `CoreDuration.indeterminate.tailwindDuration` (the adapter
      // `Loading`/`Progress` indeterminate fills would use) resolves to
      // the scale key `'1500'` — that key has to exist here too, or
      // `duration-${…tailwindDuration}` compiles and emits a class
      // Tailwind's config never defines, which does nothing.
      expect(CoreDuration.indeterminate, equals(_kIndeterminateMs));
      expect(tailwind, contains('"1500":"var(--coui-duration-1500)"'));
    });
  });

  group('prefers-reduced-motion override', () {
    final block = RegExp(
      r'@media \(prefers-reduced-motion:reduce\)\{:root\{(.*?)\}\}',
      dotAll: true,
    ).firstMatch(css);

    test('the media query exists', () {
      expect(block, isNotNull);
    });

    test('zeroes every transition-tier duration', () {
      expect(block!.group(1), contains('--coui-transition-motion-factor:0;'));
      for (final ms in [50, 100, 150, 200, 250, 300, 350, 400, 450, 500]) {
        expect(
          block.group(1),
          contains('--coui-duration-$ms:0ms;'),
          reason: '${ms}ms is transition motion and should collapse.',
        );
      }
    });

    test('leaves display-tier durations alone', () {
      // Freezing these would stop a spinner mid-cycle, which reads as a hang
      // rather than as respect for the preference. 1500 (indeterminate) is
      // display-tier too, same as the numbered 1000+ steps.
      for (final ms in [1000, 2000, 3000, 4000, 5000, 1500]) {
        expect(
          block!.group(1),
          isNot(contains('--coui-duration-$ms:')),
          reason: '${ms}ms is display timing, not motion.',
        );
      }
    });

    test('does not override an already-zero duration', () {
      expect(block!.group(1), isNot(contains('--coui-duration-0:')));
    });

    test('the boundary matches the shared policy', () {
      // Both platforms read CoreReducedMotion.transitionCeilingMs, so the
      // web cut-off and the Flutter cut-off cannot drift apart.
      expect(CoreReducedMotion.transitionCeilingMs, equals(CoreDuration.ms500));
      expect(
        block!.group(1),
        contains(
          '--coui-duration-${CoreReducedMotion.transitionCeilingMs}:0ms;',
        ),
      );
    });
  });
}
