import 'package:coui_web/coui_web.dart';
// navigation_bar_style.dart is not re-exported by the barrel (the resolver is
// internal chrome) — import it directly for resolver-level assertions.
import 'package:coui_web/src/components/navigation/navigation_bar/navigation_bar_style.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:jaspr_test/server_test.dart' show testServer;

import '../../helpers/pump_with_theme.dart';

/// The Web twin of the Flutter `liquid_glass_navigation_rail_test`: under
/// liquid glass the rail is the floating icon-only capsule the bar already
/// was — read back off the resolver and the server markup. What the browser
/// then does with the lens (measuring, dragging, the transform) is the
/// runtime's and is not visible to this test.
class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

const _glass = CoreNavigationBarStyle(
  surfaceStyle: CoreSurfaceStyleId.liquidGlass,
);

ResolvedNavigationBar _resolve(
  ComponentTester tester,
  CoreNavigationBarMode mode, {
  CoreNavigationBarStyle? style,
  CoreNavigationSelectionIndicator? indicator,
}) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return resolveNavigationBar(
    context,
    mode: mode,
    variant: CoreNavigationBarVariant.defaultVariant,
    overflow: CoreNavigationOverflow.ellipsis,
    labelPosition: mode.defaultLabelPosition,
    indicator: indicator,
    navigationBarStyle: style,
  );
}

Map<String, String> _inline(WebElementChrome chrome) =>
    chrome.inlineStyles?.properties ?? const {};

List<String> _classes(WebElementChrome chrome) =>
    chrome.className.split(' ').where((c) => c.isNotEmpty).toList();

Component _host(Component child) => CoUIWeb(theme: .coui, child: child);

NavigationBar _rail({
  CoreNavigationBarStyle? style = _glass,
  CoreNavigationLabelMode? labelMode,
  Component? header,
  List<CoreNavigationBarItem<Component>>? items,
}) => NavigationBar(
  id: 'nav',
  mode: CoreNavigationBarMode.rail,
  selectedIndex: 0,
  onSelected: (_) {},
  labelMode: labelMode,
  header: header,
  navigationBarStyle: style,
  items:
      items ??
      const [
        CoreNavigationBarItem.destination(
          icon: Icon(LucideIcons.house),
          label: 'Home',
        ),
        CoreNavigationBarItem.destination(
          icon: Icon(LucideIcons.search),
          label: 'Search',
        ),
        CoreNavigationBarItem.destination(
          icon: Icon(LucideIcons.bell),
          label: 'Alerts',
        ),
      ],
);

void main() {
  group('the resolver', () {
    testComponents('the glass rail takes the rail capsule', (tester) {
      final resolved = _resolve(tester, .rail, style: _glass);
      const preset = CoreNavigationBarStyle.glassRailStyle;
      final root = _inline(resolved.root);

      // The pane is the resolver's word for "the capsule applies".
      expect(resolved.glassPane, isNotNull);
      expect(_classes(resolved.glassPane!), contains('coui-navigation-pane'));
      expect(root['border-radius'], preset.barRadius!.toValue());
      expect(root['margin'], preset.barMargin!.toValue());
      expect(root['padding'], preset.padding!.toValue());
      expect(root['gap'], spaceCss(preset.itemSpacing!));
      expect(root['--coui-navigation-radius'], preset.itemRadius!.toValue());
      // Detached: the content-facing hairline is not drawn.
      expect(
        root.keys.where((key) => key.startsWith('border-inline')),
        isEmpty,
      );
      // The lens is the selected face — the icon box paints nothing.
      expect(_inline(resolved.iconAnchor)['border-radius'], isNull);
      expect(
        _classes(resolved.iconAnchor).where((c) => c.startsWith('bg-')),
        isEmpty,
      );
      // The icon-only destination is the 40×48 cell.
      final cell = _inline(resolved.iconOnlyDestinationSelected);
      expect(cell['min-height'], '${preset.itemMinHeight! / kRemDivisor}rem');
      expect(
        cell['min-width'],
        'min(${preset.iconOnlyItemMinWidth! / kRemDivisor}rem, 100%)',
      );
    });

    testComponents('a stated indicator still wins in the capsule', (tester) {
      final resolved = _resolve(
        tester,
        .rail,
        style: _glass,
        indicator: .fill,
      );

      final defaulted = _resolve(tester, .rail, style: _glass);

      expect(resolved.glassPane, isNotNull);
      // `fill` lays the hover wash the capsule's `color` default does not.
      expect(
        _classes(resolved.destinationSelected),
        isNot(equals(_classes(defaulted.destinationSelected))),
      );
    });

    testComponents('the opaque rail is the docked rail it was', (tester) {
      final resolved = _resolve(tester, .rail);
      final root = _inline(resolved.root);

      expect(resolved.glassPane, isNull);
      expect(root.containsKey('border-radius'), isFalse);
      expect(root.containsKey('margin'), isFalse);
      expect(root['border-inline-end-style'], 'solid');
    });

    testComponents('the sidebar takes the material and stays docked', (
      tester,
    ) {
      // The announced mode keeps its docked chrome until it is removed.
      // ignore: deprecated_member_use
      final resolved = _resolve(tester, .sidebar, style: _glass);
      final root = _inline(resolved.root);

      expect(root['--coui-navigation-material'], 'liquidGlass');
      expect(resolved.glassPane, isNull);
      expect(root.containsKey('border-radius'), isFalse);
      expect(root.containsKey('margin'), isFalse);
    });

    testComponents('the glass bar keeps the bar capsule', (tester) {
      final resolved = _resolve(tester, .bar, style: _glass);

      expect(resolved.glassPane, isNotNull);
      expect(
        _inline(resolved.root)['padding'],
        CoreNavigationBarStyle.glassBarStyle.padding!.toValue(),
      );
    });
  });

  group('the markup', () {
    testServer('the glass rail is icon-only, with the lens parts in place', (
      tester,
    ) async {
      tester.pumpComponent(_host(_rail()));
      final document = (await tester.request('/')).document!;
      // Icon-only: the caption is kept for assistive technology and not
      // drawn; the destination is still named by it.
      final items = document.querySelectorAll('[data-coui-nav-index]');
      expect(items, hasLength(3));
      for (final (index, item) in items.indexed) {
        final label = document.querySelector('#nav-item-$index-label')!;
        expect(label.classes, contains('sr-only'));
        expect(item.attributes['aria-labelledby'], label.id);
      }
      expect(document.querySelector('#nav-item-0-label')!.text, 'Home');
      // No pill behind the icon: the lens is the selected face.
      expect(
        items.first.querySelectorAll('.bg-primary-container'),
        isEmpty,
      );

      // The pane, the resting selection and the lens the runtime drives.
      expect(document.querySelector('#nav-pane'), isNotNull);
      expect(document.querySelector('#nav-selection'), isNotNull);
      expect(document.querySelector('#nav-lens'), isNotNull);
      // The capsule's own rules travel with it, the column's among them.
      expect(
        document.outerHtml,
        contains('.coui-navigation-glass-vertical'),
      );
      // Each destination is the pill the lens rests on.
      final pill = CoreNavigationBarStyle.glassRailStyle.itemRadius!.toValue();
      for (final item in items) {
        expect(item.attributes['style'], contains('border-radius: $pill'));
      }
    });

    testServer('a stated label mode names the destinations again', (
      tester,
    ) async {
      tester.pumpComponent(
        _host(_rail(labelMode: CoreNavigationLabelMode.all)),
      );
      final document = (await tester.request('/')).document!;

      for (final index in [0, 1, 2]) {
        expect(
          document.querySelector('#nav-item-$index-label')!.classes,
          isNot(contains('sr-only')),
        );
      }
    });

    testServer('the opaque rail names its destinations and has no lens', (
      tester,
    ) async {
      tester.pumpComponent(_host(_rail(style: null)));
      final document = (await tester.request('/')).document!;

      expect(
        document.querySelector('#nav-item-0-label')!.classes,
        isNot(contains('sr-only')),
      );
      // The opaque rail marks the selected destination's whole tile.
      expect(
        document
            .querySelector('[data-coui-nav-index="0"]')!
            .querySelectorAll('.bg-surface-container-high'),
        hasLength(1),
      );
      expect(document.querySelector('#nav-pane'), isNull);
      // The selection parts stay so the runtime can take the capsule up
      // when the page's material changes; without the pane they draw
      // nothing.
      expect(document.querySelector('#nav-selection'), isNotNull);
    });

    testServer('a header keeps the capsule and drops the moving lens', (
      tester,
    ) async {
      tester.pumpComponent(
        _host(_rail(header: const div(id: 'brand', []))),
      );
      final document = (await tester.request('/')).document!;

      expect(document.querySelector('#brand'), isNotNull);
      expect(document.querySelector('#nav-lens'), isNull);
      expect(document.querySelector('#nav-selection'), isNull);
      // Still the capsule.
      expect(
        document.querySelector('#nav')!.attributes['style'],
        contains(
          'border-radius: '
          '${CoreNavigationBarStyle.glassRailStyle.barRadius!.toValue()}',
        ),
      );
    });

    testServer('a divider among the destinations drops the moving lens', (
      tester,
    ) async {
      tester.pumpComponent(
        _host(
          _rail(
            items: const [
              CoreNavigationBarItem.destination(
                icon: Icon(LucideIcons.house),
                label: 'Home',
              ),
              CoreNavigationBarItem.divider(),
              CoreNavigationBarItem.destination(
                icon: Icon(LucideIcons.bell),
                label: 'Alerts',
              ),
            ],
          ),
        ),
      );
      final document = (await tester.request('/')).document!;

      expect(document.querySelector('#nav-lens'), isNull);
    });
  });

  group('a hidden label is a tooltip beside the destination', () {
    NavigationBar navigation(CoreNavigationBarMode mode) => NavigationBar(
      id: 'nav',
      mode: mode,
      selectedIndex: 0,
      onSelected: (_) {},
      labelMode: .none,
      navigationBarStyle: _glass,
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
    );

    Iterable<CoreTooltipPosition> positions() => find
        .byType(Tooltip)
        .evaluate()
        .map((element) => (element.component as Tooltip).position);

    testComponents('a column asks for the side', (tester) {
      pumpWithTheme(tester, navigation(.rail));

      expect(positions(), [
        CoreTooltipPosition.right,
        CoreTooltipPosition.right,
      ]);
    });

    testComponents('a row asks for the top', (tester) {
      pumpWithTheme(tester, navigation(.bar));

      expect(positions(), [CoreTooltipPosition.top, CoreTooltipPosition.top]);
    });
  });

  test('the column leaves sideways panning to the page', () {
    // A drag down the column moves the lens; the page keeps the other axis.
    expect(
      kNavigationGlassCss,
      contains(
        '.coui-navigation-glass-active.coui-navigation-glass-vertical'
        '{touch-action:pan-x;}',
      ),
    );
  });
}
