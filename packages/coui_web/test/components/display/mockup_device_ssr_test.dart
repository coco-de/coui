// Whether the widget carries its axes into the geometry.
//
// The resolver's own rules are covered by `mockup_device_style_test.dart`,
// which calls `resolveMockupDevice` directly. That leaves one seam untested:
// a widget that accepts `orientation` and then hands the resolver a constant
// would pass every one of those tests and still draw upright. This file
// renders the component, so the value has to survive the trip.
//
// `testServer` (not `testComponents`) because only the real SSR binding hands
// back markup, and the claim here is about the pixels the root box states.
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/server_test.dart';

/// Widths chosen so each screen is an integer multiple of its aspect
/// numerator — the same widths the canvas preview drew.
const _kPhonePortraitWidth = 160.0;
const _kPhoneLandscapeWidth = 328.0;

/// The screen is the one box that is clipped (`overflow-hidden`) and states
/// both of the turned dimensions.
Future<(String? width, String? height)> _screenBox(
  ServerTester tester, {
  required CoreMockupOrientation orientation,
  required double width,
}) async {
  final response = await _render(
    tester,
    MockupDevice(orientation: orientation, width: width, child: const div([])),
  );
  final screen = response.document
      ?.querySelectorAll('div')
      .where((el) => el.className.split(' ').contains('overflow-hidden'))
      .firstOrNull;
  final style = screen?.attributes['style'] ?? '';
  String? pick(String prop) {
    for (final part in style.split(';')) {
      final bits = part.split(':');
      if (bits.length == 2 && bits.first.trim() == prop) return bits[1].trim();
    }
    return null;
  }

  return (pick('width'), pick('height'));
}

Future<DocumentResponse> _render(
  ServerTester tester,
  Component component,
) {
  tester.pumpComponent(CoUIWeb(theme: .coui, child: component));

  return tester.request('/');
}

void main() {
  group('MockupDevice SSR — the widget carries orientation', () {
    testServer('upright draws taller than wide', (tester) async {
      final (w, h) = await _screenBox(
        tester,
        orientation: .portrait,
        width: _kPhonePortraitWidth,
      );
      expect(w, isNotNull);
      expect(h, isNotNull);
      expect(_rem(h!), greaterThan(_rem(w!)));
    });

    testServer('turned draws wider than tall — a hard-coded axis fails here', (
      tester,
    ) async {
      final (w, h) = await _screenBox(
        tester,
        orientation: .landscape,
        width: _kPhoneLandscapeWidth,
      );
      expect(w, isNotNull);
      expect(h, isNotNull);
      expect(_rem(w!), greaterThan(_rem(h!)));
    });
  });

  group('MockupDevice SSR — the markup the browser receives', () {
    testServer('the status bar is drawn, hidden from assistive technology', (
      tester,
    ) async {
      final response = await _render(
        tester,
        const MockupDevice(width: _kPhonePortraitWidth, child: div([])),
      );
      // The span that carries the role, around the `Text` that inherits it.
      final clock = response.document
          ?.querySelectorAll('span')
          .where(
            (el) =>
                el.text == '9:41' && el.className.contains('text-title-small'),
          );
      expect(clock, hasLength(1));
      expect(
        clock!.single.attributes['style'],
        contains('font-size: calc(var(--coui-text-title-small-size) * '),
      );
      // The picture of an operating system is not content.
      final bar = clock.single.parent!.parent!;
      expect(bar.attributes['aria-hidden'], 'true');
      // A device does not mirror when the text does.
      expect(bar.attributes['style'], contains('direction: ltr'));
    });

    testServer('the glyphs are inline svg with their own viewBox', (
      tester,
    ) async {
      final response = await _render(
        tester,
        const MockupDevice(width: _kPhonePortraitWidth, child: div([])),
      );
      final svgs = response.document!.querySelectorAll('svg');
      // cellular, wifi and the battery nub.
      expect(svgs, hasLength(3));
      expect(svgs.first.attributes['viewBox'], '0 0 19.2 12.2264');
      final path = svgs.first.querySelector('path')!;
      expect(path.attributes['fill'], 'currentColor');
      expect(path.attributes['fill-rule'], 'evenodd');
      expect(path.attributes['d'], startsWith('M 19.2 1.1462 C '));
      expect(
        svgs.last.querySelector('path')!.attributes['fill-rule'],
        'nonzero',
      );
    });

    testServer('the rim glow ring keeps its mask declarations in order', (
      tester,
    ) async {
      final response = await _render(
        tester,
        const MockupDevice(width: _kPhonePortraitWidth, child: div([])),
      );
      final ring = response.document!
          .querySelectorAll('div')
          .where(
            (el) => (el.attributes['style'] ?? '').contains('mask-composite'),
          )
          .single;
      final style = ring.attributes['style']!;
      // The composite follows the shorthand it belongs to, prefixed first and
      // unprefixed second, because a shorthand resets its longhands.
      final order = [
        '-webkit-mask:',
        '-webkit-mask-composite: xor',
        '; mask:',
        'mask-composite: exclude',
      ].map(style.indexOf).toList();
      expect(order, everyElement(isNonNegative));
      expect(order, orderedEquals([...order]..sort()));
    });

    testServer("the hardware reaches the markup as the copy's literals, in "
        'any mode', (
      tester,
    ) async {
      Future<String> deviceMarkup(CoreThemeMode mode) async {
        tester.pumpComponent(
          CoUIWeb(
            theme: .coui,
            darkTheme: .coui,
            themeMode: mode,
            child: const MockupDevice(
              width: _kPhonePortraitWidth,
              child: div([]),
            ),
          ),
        );
        final response = await tester.request('/');
        final device = response.document!
            .querySelectorAll('div')
            .where(
              (el) =>
                  el.className.contains('inline-flex') &&
                  el.className.contains('relative'),
            )
            .first;

        return device.outerHtml;
      }

      final light = await deviceMarkup(.light);
      final dark = await deviceMarkup(.dark);

      // The designer copy's literals, inline: the server writes the same
      // colours whatever the mode, so the two documents agree.
      expect(light, dark);
      // The fills of the hardware, at full strength …
      expect(light, contains('background-color: rgb(0, 0, 0)'));
      expect(light, contains('background-color: rgb(174, 175, 178)'));
      expect(light, contains('background-color: rgb(255, 255, 255)'));
      // … and its strokes and gradients.
      expect(light, contains('inset 0 0 0 0.5px rgb(255, 255, 255)'));
      expect(light, contains('0 0 0 0.5px rgb(39, 40, 43)'));
      expect(light, contains('rgb(195, 196, 198) 0%'));
      // No hardware colour names a variable, so no class or reference in the
      // markup moves with the mode or the palette — only the screen's.
      for (final slot in [
        'scrim',
        'primary-fixed',
        'secondary-fixed',
        'on-primary-fixed',
      ]) {
        expect(light, isNot(contains('--coui-$slot')), reason: slot);
        expect(light, isNot(contains('bg-$slot')), reason: slot);
      }
      // The cast under the body: the palette's `--coui-shadow` colour turns
      // over with the mode and `--shadow-*` is built from it, so neither
      // may be in the value the two modes share. Nor may the dark scope's
      // shadow strength — the device is pinned to v1's two layers at their
      // own alpha in every mode (#5485), so the dark page computes the same
      // cast as the light one.
      expect(light, isNot(contains('var(--coui-shadow)')));
      expect(light, isNot(contains('--shadow-')));
      expect(light, isNot(contains('--coui-shadow-strength')));
      expect(
        light,
        contains(
          'box-shadow: '
          '0.0rem 0.875rem 1.75rem -0.3125rem '
          'color-mix(in srgb, rgb(0, 0, 0) 8%, transparent), '
          '0.0rem 0.375rem 0.625rem -0.1875rem '
          'color-mix(in srgb, rgb(0, 0, 0) 5%, transparent)',
        ),
      );
    });

    testServer('a tablet draws its camera in the bezel, not on the screen', (
      tester,
    ) async {
      final response = await _render(
        tester,
        const MockupDevice(
          device: .tablet,
          width: 321,
          child: div([]),
        ),
      );
      final screen = response.document!
          .querySelectorAll('div')
          .where((el) => el.className.split(' ').contains('overflow-hidden'))
          .single;
      final bezel = screen.parent!;
      // camera, core, glint stand beside the screen in the bezel.
      final siblings = bezel.children.where((el) => el != screen).toList();
      expect(siblings, hasLength(3));
      // The markup carries the designer copy's literals inline, no fill
      // class: the round cut-out is the lens (black), the core is a gradient,
      // the glint is white.
      expect(siblings.map((part) => part.className), [
        'absolute',
        'absolute',
        'absolute',
      ]);
      expect(
        siblings[0].attributes['style'],
        contains('background-color: rgb(0, 0, 0)'),
      );
      expect(siblings[1].attributes['style'], contains('radial-gradient('));
      expect(siblings[1].attributes['style'], contains('rgb(0, 0, 0) 20%'));
      expect(
        siblings[2].attributes['style'],
        contains('background-color: rgb(255, 255, 255)'),
      );
    });
  });

  group('MockupDevice SSR — the flat finish', () {
    testServer('draws a bare frame: no hardware part, no zero-sized box', (
      tester,
    ) async {
      final response = await _render(
        tester,
        const MockupDevice(finish: .flat, child: div([])),
      );
      final device = response.document!
          .querySelectorAll('div')
          .where(
            (el) =>
                el.className.contains('inline-flex') &&
                el.className.contains('relative'),
          )
          .first;
      final html = device.outerHtml;

      // The ring follows the theme: a token class, no literal fill.
      expect(html, contains('bg-surface-container-highest'));
      expect(html, isNot(contains('rgb(0, 0, 0)')));
      // No rim light (ring mask, inset hairline), no band gradient, no
      // button gloss, no glyph and no clock.
      expect(html, isNot(contains('mask-composite')));
      expect(html, isNot(contains('linear-gradient')));
      expect(html, isNot(contains('background-image')));
      expect(html, isNot(contains('box-shadow: inset')));
      expect(html, isNot(contains('<svg')));
      expect(html, isNot(contains('9:41')));
      // Nothing on it is an empty box: every declared width / height is
      // positive.
      for (final el in device.querySelectorAll('div')) {
        final style = el.attributes['style'] ?? '';
        for (final match in RegExp(
          r'(?:^|;)\s*(width|height):\s*([0-9.]+)rem',
        ).allMatches(style)) {
          expect(
            double.parse(match.group(2)!),
            greaterThan(0),
            reason: '${match.group(1)} of <${el.className}>',
          );
        }
      }
      // The root states the 256 body.
      expect(device.attributes['style'], contains('width: 16.0rem'));
    });

    testServer('the screen is 240 wide with a derived 24 corner', (
      tester,
    ) async {
      final response = await _render(
        tester,
        const MockupDevice(finish: .flat, child: div([])),
      );
      final screen = response.document!
          .querySelectorAll('div')
          .where((el) => el.className.split(' ').contains('overflow-hidden'))
          .single;
      final style = screen.attributes['style']!;
      expect(style, contains('width: 15.0rem'));
      expect(style, contains('height: 30.0rem'));
    });

    testServer('realistic is untouched by the axis', (tester) async {
      final response = await _render(
        tester,
        const MockupDevice(width: _kPhonePortraitWidth, child: div([])),
      );
      final html = response.document!.outerHtml;
      expect(html, contains('9:41'));
      expect(html, contains('mask-composite'));
      expect(html, contains('background-color: rgb(0, 0, 0)'));
    });
  });
}

/// Parses a `Nrem` emit back to its number so two of them can be compared.
double _rem(String value) =>
    double.parse(value.replaceAll('rem', '').replaceAll('px', '').trim());
