import 'package:coui_web/coui_web.dart';
// navigation_bar_style.dart is not re-exported by the barrel (the resolver is
// internal chrome) — import it directly for resolver-level assertions.
import 'package:coui_web/src/components/navigation/navigation_bar/navigation_bar_style.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:jaspr_test/server_test.dart' show testServer;

import '../../helpers/pump_with_theme.dart';

/// The Web twin of the Flutter `navigation_bar_item_max_width_test` (#6406):
/// the bar's destination cell — the `<nav>`'s own flex item — stops growing
/// at 96, and the rail and the floating glass capsule state no cap. Where
/// the browser then puts the cells is layout and is not visible here; the
/// declaration and the root's `justify-center` are.
class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

const _kGlass = CoreNavigationBarStyle(
  surfaceStyle: CoreSurfaceStyleId.liquidGlass,
);

ResolvedNavigationBar _resolve(
  ComponentTester tester,
  CoreNavigationBarMode mode, {
  CoreNavigationBarStyle? style,
}) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return resolveNavigationBar(
    context,
    mode: mode,
    variant: CoreNavigationBarVariant.defaultVariant,
    overflow: CoreNavigationOverflow.ellipsis,
    labelPosition: mode.defaultLabelPosition,
    navigationBarStyle: style,
  );
}

Map<String, String> _inline(WebElementChrome chrome) =>
    chrome.inlineStyles?.properties ?? const {};

Component _host(Component child) => CoUIWeb(theme: .coui, child: child);

NavigationBar _bar({
  CoreNavigationBarMode mode = CoreNavigationBarMode.bar,
  CoreNavigationBarStyle? style,
  String? tooltip,
}) => NavigationBar(
  id: 'nav',
  mode: mode,
  selectedIndex: 0,
  onSelected: (_) {},
  navigationBarStyle: style,
  items: [
    CoreNavigationBarItem.destination(
      icon: const Icon(LucideIcons.house),
      label: 'Home',
      tooltip: tooltip,
    ),
    const CoreNavigationBarItem.destination(
      icon: Icon(LucideIcons.search),
      label: 'Search',
    ),
  ],
);

String _cap() => '${CoreSize.size96 / kRemDivisor}rem';

void main() {
  group('the resolver', () {
    testComponents('the bar caps its destination cell at 96', (tester) {
      final cell = _resolve(tester, CoreNavigationBarMode.bar).destinationCell;
      expect(cell.className, contains('flex-1'));
      expect(_inline(cell)['max-width'], _cap());
    });

    testComponents('the rail emits no cap', (tester) {
      final cell = _resolve(tester, CoreNavigationBarMode.rail).destinationCell;
      expect(cell.className, contains('w-full'));
      expect(_inline(cell).containsKey('max-width'), isFalse);
    });

    testComponents('the floating glass bar emits no cap', (tester) {
      final cell = _resolve(
        tester,
        CoreNavigationBarMode.bar,
        style: _kGlass,
      ).destinationCell;
      expect(_inline(cell).containsKey('max-width'), isFalse);
    });

    testComponents('a caller can lift the cap or state another', (tester) {
      expect(
        _inline(
          _resolve(
            tester,
            CoreNavigationBarMode.bar,
            style: const CoreNavigationBarStyle(itemMaxWidth: double.infinity),
          ).destinationCell,
        ).containsKey('max-width'),
        isFalse,
      );
      expect(
        _inline(
          _resolve(
            tester,
            CoreNavigationBarMode.bar,
            style: const CoreNavigationBarStyle(itemMaxWidth: 120),
          ).destinationCell,
        )['max-width'],
        '${120 / kRemDivisor}rem',
      );
    });
  });

  group('the markup', () {
    testServer('the bar destination flex item carries the cap', (
      tester,
    ) async {
      tester.pumpComponent(_host(_bar()));
      final document = (await tester.request('/')).document!;
      final nav = document.querySelector('nav#nav')!;
      expect(nav.classes, contains('justify-center'));
      final items = document.querySelectorAll('[data-coui-nav-index]');
      expect(items, hasLength(2));
      for (final item in items) {
        expect(item.parent, same(nav), reason: 'the flex item is the cell');
        expect(item.classes, contains('flex-1'));
        expect(item.attributes['style'], contains('max-width: ${_cap()}'));
      }
    });

    testServer('a tooltip wrapper is then the cell and carries the cap', (
      tester,
    ) async {
      tester.pumpComponent(
        _host(
          NavigationBar(
            id: 'nav',
            selectedIndex: 0,
            onSelected: (_) {},
            labelMode: CoreNavigationLabelMode.none,
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
      final nav = document.querySelector('nav#nav')!;
      final cells = nav.children
          .where((child) => child.classes.contains('flex-1'))
          .toList();
      expect(cells, hasLength(2));
      for (final cell in cells) {
        expect(cell.attributes['style'], contains('max-width: ${_cap()}'));
      }
    });

    testServer('the rail destination has no cap', (tester) async {
      tester.pumpComponent(_host(_bar(mode: CoreNavigationBarMode.rail)));
      final document = (await tester.request('/')).document!;
      for (final item in document.querySelectorAll('[data-coui-nav-index]')) {
        expect(item.attributes['style'] ?? '', isNot(contains('max-width')));
      }
    });
  });
}
