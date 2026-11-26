import 'package:coui_web/coui_web.dart';
import 'package:test/test.dart';

void main() {
  final css = ThemeConfig.defaults().cssVariables;

  group('Skeleton pulse keyframes', () {
    // Tailwind's built-in `animate-pulse` utility hardcodes
    // `opacity: 1 → 0.5 → 1` and never reads a CSS variable, so a
    // `Skeleton` fromOpacity/toOpacity override had nowhere to land.
    // These keyframes are the single global definition every Skeleton
    // node's inline `animation-name` points at instead.
    //
    // It animates the FILL, not the element. Flutter pulses the fill's alpha
    // between the same two ends (skeleton.dart), which fades the surface and
    // leaves everything else alone; animating `opacity` faded the node AND
    // every descendant with it — identical on a bare block,
    // different the moment a skeleton has a border or a child, and different
    // against whatever sits behind it in both cases. This test asserted the
    // opacity form, which is why the two platforms could diverge here while it
    // stayed green.
    test('defines the keyframes once, reading the pulse variables', () {
      expect(css, contains('@keyframes $kSkeletonPulseAnimationName{'));
      expect(css, contains('background-color:var(--pulse-from)'));
      expect(css, contains('background-color:var(--pulse-to)'));
    });

    test('is emitted exactly once', () {
      final matches = RegExp(
        '@keyframes $kSkeletonPulseAnimationName',
      ).allMatches(css);
      expect(matches.length, equals(1));
    });
  });

  // A display-tier loop reduced motion stops
  // (`CoreReducedMotion.runsPlaceholderPulse`): the query points every
  // Skeleton's `animation-name` variable at keyframes that hold the resting
  // end, so the placeholder neither pulses nor jumps to its peak fill.
  group('Skeleton under reduced motion', () {
    test('the rest keyframes hold --pulse-from', () {
      expect(
        css,
        contains(
          '@keyframes $kSkeletonRestAnimationName{ '
          'from,to{background-color:var(--pulse-from)}}',
        ),
      );
    });

    test('the reduced-motion query swaps the pulse for the rest', () {
      final query = RegExp(
        r'@media \(prefers-reduced-motion:reduce\)\{:root\{([^}]*)\}\}',
      ).firstMatch(css);
      expect(query, isNotNull);
      expect(
        query!.group(1),
        contains('$kSkeletonPulseNameVar:$kSkeletonRestAnimationName;'),
      );
    });

    test('the swap follows the Core policy', () {
      expect(CoreReducedMotion.runsPlaceholderPulse(reduce: true), isFalse);
      expect(CoreReducedMotion.runsPlaceholderPulse(reduce: false), isTrue);
    });
  });
}
