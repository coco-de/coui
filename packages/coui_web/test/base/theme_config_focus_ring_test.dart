import 'package:coui_web/coui_web.dart';
import 'package:test/test.dart';

// The focus ring is an outline. Its class-path steps must reach the ring
// token variables, and every transition that fades the ring must name
// `outline-color` — Tailwind's stock `transition` list names only the
// `box-shadow` its own ring utilities use.

void main() {
  final config = ThemeConfig.defaults();

  test('outline-2 / outline-offset-2 route through the ring variables', () {
    expect(
      config.tailwindConfig,
      contains('outlineWidth:{2:"var(--coui-ring-width)"}'),
    );
    expect(
      config.tailwindConfig,
      contains('outlineOffset:{2:"var(--coui-ring-offset)"}'),
    );
  });

  test('the stock transition list names outline-color', () {
    final match = RegExp(
      r'transitionProperty:\{DEFAULT:"([^"]*)"\}',
    ).firstMatch(config.tailwindConfig);
    expect(match, isNotNull);
    final properties = match!.group(1)!.split(', ');
    expect(properties, contains('outline-color'));
    // Still everything Tailwind's own default names.
    expect(
      properties,
      containsAll(<String>[
        'color',
        'background-color',
        'border-color',
        'text-decoration-color',
        'fill',
        'stroke',
        'opacity',
        'box-shadow',
        'transform',
        'filter',
        'backdrop-filter',
      ]),
    );
  });

  test("the control rule's transition fades the ring's outline colour", () {
    final css = config.cssVariables;
    final start = css.indexOf('.$kControlShadowPressMarker{transition:');
    expect(start, isNonNegative);
    final declaration = css.substring(start, css.indexOf('}', start));
    expect(declaration, contains('outline-color var('));
  });
}
