import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:jaspr_test/server_test.dart' show testServer;

/// The 8 % focus layer has to land on a selector the browser can match
/// (#5740). The scope class rides the chrome `<div>`, which never takes
/// focus; the focusable element is its parent, the `Clickable` root. A rule
/// written `.scope:focus-visible` read correctly as text and never painted.
///
/// Reads the rendered markup: every focus rule names a scope through the
/// child combinator, and every chrome that carries that scope sits directly
/// under the element that takes focus (`tabindex="0"`). The paint itself is
/// measured in a real Chrome by `tool/parity/test/web/
/// navigation_bar_focus_layer_probe_test.dart`.
void main() {
  for (final mode in [CoreNavigationBarMode.bar, CoreNavigationBarMode.rail]) {
    testServer('${mode.name} — the focus rule matches the focused root', (
      tester,
    ) async {
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          child: NavigationBar(
            id: 'nav',
            mode: mode,
            selectedIndex: 0,
            onSelected: (_) {},
            items: const [
              CoreNavigationBarItem.destination(
                icon: Icon(LucideIcons.house),
                label: 'Home',
              ),
              CoreNavigationBarItem.destination(
                icon: Icon(LucideIcons.search),
                label: 'Search',
              ),
            ],
          ),
        ),
      );
      final document = (await tester.request('/')).document!;
      final css = document
          .querySelectorAll('style')
          .map((style) => style.text)
          .join();
      final focusScopes = RegExp(
        r':focus-visible>\.(co-navbar-sl-[\w-]+)\{background-color:',
      ).allMatches(css).map((m) => m.group(1)!).toSet();
      expect(focusScopes, isNotEmpty, reason: css);
      // No focus rule is left on the chrome itself.
      expect(
        RegExp(r'\.co-navbar-sl-[\w-]+:focus-visible').hasMatch(css),
        isFalse,
      );
      final chromes = document.querySelectorAll('[data-coui-nav-chrome]');
      expect(chromes, hasLength(2));
      for (final chrome in chromes) {
        final scope = chrome.classes.firstWhere(
          (c) => c.startsWith('co-navbar-sl-'),
        );
        // The selected destination's scope (its own base) and the bar's both
        // carry a focus rule.
        expect(focusScopes, contains(scope));
        expect(chrome.attributes['tabindex'], isNull);
        expect(chrome.parent!.attributes['tabindex'], '0');
      }
      // A clear selected face (the `color` indicator the bar takes) states
      // no inline background — an inline one outranks the scoped layer.
      expect(
        chromes.first.attributes['style'] ?? '',
        isNot(contains('background-color')),
      );
    });
  }
}
