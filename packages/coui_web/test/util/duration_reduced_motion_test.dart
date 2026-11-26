import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:test/test.dart';

void main() {
  test('off-scale transitions follow the shared policy', () {
    for (final ms in [1, 37, 175, 499]) {
      expect(
        CoreReducedMotion.resolve(Duration(milliseconds: ms), reduce: true),
        Duration.zero,
      );
      expect(
        durationMsCss(ms),
        'calc(${ms}ms * var(--coui-transition-motion-factor, 1))',
      );
    }
  });

  test('token durations retain their existing CSS variable contract', () {
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
      1500,
      2000,
      3000,
      4000,
      5000,
    ]) {
      expect(durationMsCss(ms), 'var(--coui-duration-$ms)');
    }
  });

  test('display durations and negative values retain their literal value', () {
    for (final ms in [-1, 501, 730, 1234]) {
      expect(
        CoreReducedMotion.resolve(Duration(milliseconds: ms), reduce: true),
        Duration(milliseconds: ms),
      );
      expect(durationMsCss(ms), '${ms}ms');
    }
  });
}
