import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:jaspr_test/server_test.dart' show testServer;

/// The Web twin of the Flutter `navigation_bar_focus_ring_test`.
///
/// The destination's ring is the `Clickable` root's `outline`, which
/// follows the root's own `border-radius` out by the outline's offset and
/// width. So the ring is concentric with the tile only when the root
/// carries the tile's corner — the Clickable's generic small corner drew a
/// ring tighter than the tile it surrounds (r8 around an r10 tile).
Component _host(Component child) => CoUIWeb(theme: .coui, child: child);

NavigationBar _bar(
  CoreNavigationBarMode mode, {
  CoreNavigationBarStyle? navigationBarStyle,
}) => NavigationBar(
  id: 'nav',
  mode: mode,
  selectedIndex: 0,
  onSelected: (_) {},
  navigationBarStyle: navigationBarStyle,
  items: const [
    CoreNavigationBarItem.destination(label: 'Home'),
    CoreNavigationBarItem.destination(label: 'Search'),
  ],
);

void main() {
  for (final mode in CoreNavigationBarMode.values) {
    testServer('${mode.name} — the ring starts from the tile corner', (
      tester,
    ) async {
      tester.pumpComponent(_host(_bar(mode)));
      final document = (await tester.request('/')).document!;
      final items = document.querySelectorAll('[data-coui-nav-index]');
      final chrome = document.querySelectorAll('[data-coui-nav-chrome]');

      expect(items, isNotEmpty);
      final tile = CoreNavigationBarStyle.defaultItemRadius.toValue();
      for (final item in items) {
        expect(
          item.attributes['style'],
          contains('border-radius: $tile'),
          reason: 'the ring follows the root corner — the tile corner',
        );
      }
      // The tile itself is the same corner, so ring and tile share a centre.
      expect(
        chrome.first.attributes['style'],
        contains('border-radius: $tile'),
      );
    });
  }

  testServer('the glass bar — a pill item takes a pill ring', (tester) async {
    tester.pumpComponent(
      _host(
        _bar(
          CoreNavigationBarMode.bar,
          navigationBarStyle: const CoreNavigationBarStyle(
            surfaceStyle: CoreSurfaceStyleId.liquidGlass,
          ),
        ),
      ),
    );
    final document = (await tester.request('/')).document!;
    final pill = CoreNavigationBarStyle.glassBarStyle.itemRadius!.toValue();

    for (final item in document.querySelectorAll('[data-coui-nav-index]')) {
      expect(item.attributes['style'], contains('border-radius: $pill'));
    }
  });
}
