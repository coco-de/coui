// A screen in its own brightness, as the server renders it.
//
// `BrightnessScope` is a box-less wrapper carrying `data-theme`; the scoped
// rules in the stylesheet (`ThemeConfig.brightnessScopeBlock`, read by
// `brightness_scope_css_test.dart`) do the rest. What is left to check here
// is the markup: the wrapper is there, it draws no box, and `MockupDevice`
// puts it around the screen and nothing else.
//
// `testServer` (not `testComponents`) because only the real SSR binding hands
// back markup.
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/server_test.dart';

Future<DocumentResponse> _render(ServerTester tester, Component component) {
  tester.pumpComponent(CoUIWeb(theme: .coui, child: component));

  return tester.request('/');
}

/// The value of [property] in an inline `style` attribute.
String? _style(String? style, String property) {
  for (final part in (style ?? '').split(';')) {
    final bits = part.split(':');
    if (bits.length == 2 && bits.first.trim() == property) {
      return bits[1].trim();
    }
  }

  return null;
}

/// The mockup's screen — the one clipped box.
const _kScreen = 'div.overflow-hidden';

void main() {
  group('BrightnessScope', () {
    for (final brightness in CoreBrightness.values) {
      testServer('$brightness: a wrapper naming it, drawing no box', (
        tester,
      ) async {
        final response = await _render(
          tester,
          BrightnessScope(
            brightness: brightness,
            child: const div([], id: 'inside'),
          ),
        );
        final scopes = response.document!.querySelectorAll(
          'div[data-theme]',
        );

        expect(scopes, hasLength(1));
        expect(scopes.single.attributes['data-theme'], brightness.name);
        expect(
          _style(scopes.single.attributes['style'], 'display'),
          'contents',
        );
        expect(scopes.single.querySelector('#inside'), isNotNull);
      });
    }
  });

  group('MockupDevice screenBrightness', () {
    testServer('the scope wraps the screen, and only the screen', (
      tester,
    ) async {
      final response = await _render(
        tester,
        const MockupDevice(
          screenBrightness: CoreBrightness.light,
          child: div([], id: 'content'),
        ),
      );
      final scopes = response.document!.querySelectorAll('div[data-theme]');
      final screen = response.document!.querySelectorAll(_kScreen).single;

      expect(scopes, hasLength(1));
      expect(scopes.single.attributes['data-theme'], 'light');
      // The screen is the wrapper's only child, and the content is inside.
      expect(scopes.single.children, [screen]);
      expect(screen.querySelector('#content'), isNotNull);
      // The bezel and the body are outside it.
      expect(scopes.single.parent, isNot(screen));
      expect(
        scopes.single.parent?.querySelectorAll('div[data-theme]'),
        hasLength(1),
      );
    });

    testServer('stated nowhere, there is no scope', (tester) async {
      final response = await _render(
        tester,
        const MockupDevice(child: div([], id: 'content')),
      );

      expect(response.document!.querySelectorAll('div[data-theme]'), isEmpty);
      expect(
        response.document!.querySelector('$_kScreen #content'),
        isNotNull,
      );
    });

    testServer('the screen box is the same either way', (tester) async {
      // The wrapper draws no box, so the screen keeps the bezel as its
      // containing block — its own inline geometry is untouched.
      final plain = (await _render(
        tester,
        const MockupDevice(child: div([])),
      )).document!.querySelectorAll(_kScreen).single.attributes['style'];
      final scoped = (await _render(
        tester,
        const MockupDevice(
          screenBrightness: CoreBrightness.dark,
          child: div([]),
        ),
      )).document!.querySelectorAll(_kScreen).single.attributes['style'];

      expect(scoped, plain);
    });
  });

  test('copyWith carries the brightness', () {
    const device = MockupDevice(
      screenBrightness: CoreBrightness.light,
      child: div([]),
    );

    expect(device.copyWith(width: 200).screenBrightness, CoreBrightness.light);
    expect(
      device.copyWith(screenBrightness: CoreBrightness.dark).screenBrightness,
      CoreBrightness.dark,
    );
  });
}
