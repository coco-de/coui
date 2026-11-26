import 'package:coui_web/coui_web.dart';
import 'package:test/test.dart';

/// `CoreLayout` reaches the browser through two doors — the `:root`
/// variable a class resolves to, and the Tailwind axis key that names it.
/// A step present in one and absent from the other renders as nothing
/// (an unknown utility class emits no rule), which is invisible until a
/// dialog fails to stop at 640.
void main() {
  final config = ThemeConfig.defaults();

  test('every CoreLayout step is a :root variable in rem', () {
    final css = config.cssVariables;
    for (final v in CoreLayout.values) {
      expect(css, contains('--coui-layout-${v.toInt()}:${v / 16}rem;'));
    }
  });

  test(
    'every CoreLayout step is a Tailwind key on all six dimensional axes',
    () {
      final tw = config.tailwindConfig;
      for (final axis in [
        'width',
        'height',
        'minWidth',
        'minHeight',
        'maxWidth',
        'maxHeight',
      ]) {
        final start = tw.indexOf('$axis:{');
        expect(start, greaterThanOrEqualTo(0), reason: axis);
        final block = tw.substring(start, tw.indexOf('}', start));
        for (final v in CoreLayout.values) {
          expect(
            block,
            contains('layout${v.toInt()}:"var(--coui-layout-${v.toInt()})"'),
            reason: '$axis lacks layout${v.toInt()}',
          );
        }
      }
    },
  );
}
