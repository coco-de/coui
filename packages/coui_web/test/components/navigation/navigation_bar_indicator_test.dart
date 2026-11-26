import 'package:coui_web/coui_web.dart';
// navigation_bar_style.dart is not re-exported by the barrel (the resolver is
// internal chrome) — import it directly for resolver-level assertions.
import 'package:coui_web/src/components/navigation/navigation_bar/navigation_bar_style.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:jaspr_test/server_test.dart' show testServer;

import '../../helpers/pump_with_theme.dart';

/// The Web twin of the Flutter `navigation_bar_indicator_test` (#5740,
/// #6358): how a destination marks the current place, read back off the
/// resolver and the rendered markup.
///
/// Both indicators paint the selected tile in
/// [CoreNavigationBarStyle.defaultSelectedFaceColor] with a `primary` label
/// and glyph; they differ on hover only — `fill` lays the state layer's
/// wash, `color` lays none and darkens the foreground.
class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

ResolvedNavigationBar _resolve(
  ComponentTester tester,
  CoreNavigationBarMode mode, {
  CoreNavigationSelectionIndicator? indicator,
}) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return resolveNavigationBar(
    context,
    mode: mode,
    variant: CoreNavigationBarVariant.defaultVariant,
    overflow: CoreNavigationOverflow.ellipsis,
    labelPosition: CoreNavigationLabelPosition.bottom,
    indicator: indicator,
  );
}

List<String> _classes(WebElementChrome chrome) =>
    chrome.className.split(' ').where((c) => c.isNotEmpty).toList();

Map<String, String> _inline(WebElementChrome chrome) =>
    chrome.inlineStyles?.properties ?? const {};

Component _host(Component child) => CoUIWeb(theme: .coui, child: child);

final String _faceClass =
    'bg-${CoreNavigationBarStyle.defaultSelectedFaceColor.tailwindColor}';

/// A face on the selected destination — the `fill` tile, or none under
/// `color` (#6393): no background class and no inline background.
void _expectFace(WebElementChrome chrome, {required bool painted}) {
  final classes = _classes(chrome);
  if (painted) {
    expect(classes, contains(_faceClass));
  } else {
    expect(
      classes.where((c) => c.startsWith('bg-') && c != 'bg-transparent'),
      isEmpty,
    );
    expect(_inline(chrome)['background-color'], isNull);
  }
}

void _expectSelected(ResolvedNavigationBar resolved, {bool face = true}) {
  _expectFace(resolved.destinationSelected, painted: face);
  expect(_classes(resolved.labelSelected), contains('text-primary'));
  expect(
    resolved.selectedIconStyle!.color,
    const CoreColor.token(CoreColors.primary),
  );
  // The icon box keeps the destinations the same width; it paints nothing.
  expect(_classes(resolved.iconAnchor), isNot(contains(_faceClass)));
  expect(
    _inline(resolved.iconAnchor)['padding'],
    CoreNavigationBarStyle.defaultIconAnchorPadding.toValue(),
  );
  expect(_inline(resolved.iconAnchor)['border-radius'], isNull);
}

/// The ink-and-weight head of a state-layer wash, restated from Core.
String _inkAt(double weight) =>
    'color-mix(in srgb, rgb(var(--coui-'
    '${CoreNavigationBarStyle.defaultStateLayerColor.tailwindColor})) '
    '${(weight * 100).round()}%,';

/// The wash the scoped hover rule lays on a resting destination.
String? _hoverWash(
  ComponentTester tester,
  CoreNavigationBarMode mode,
  ResolvedNavigationBar resolved, {
  CoreNavigationSelectionIndicator? indicator,
}) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  final css = resolveNavigationBarRules(
    context,
    mode: mode,
    variant: CoreNavigationBarVariant.defaultVariant,
    indicator: indicator,
  ).css;
  final layer = _classes(
    resolved.destinationEnabledIdle,
  ).where((c) => c.startsWith('co-navbar-sl-'));
  expect(layer, hasLength(1));
  final match = RegExp(
    '\\.${layer.single}:hover\\{background-color:([^;]+);\\}',
  ).firstMatch(css);
  return match?.group(1);
}

NavigationBar _bar(
  CoreNavigationBarMode mode, {
  CoreNavigationLabelMode? labelMode,
  bool showDot = false,
  Component? header,
}) {
  return NavigationBar(
    id: 'nav',
    mode: mode,
    labelMode: labelMode,
    header: header,
    selectedIndex: 0,
    onSelected: (_) {},
    items: [
      const CoreNavigationBarItem.destination(
        icon: Icon(LucideIcons.house),
        label: 'Home',
      ),
      CoreNavigationBarItem.destination(
        icon: const Icon(LucideIcons.inbox),
        label: 'Inbox',
        showDot: showDot,
      ),
    ],
  );
}

void main() {
  group('the resolver', () {
    testComponents('color: no face, primary icon and label', (tester) {
      final resolved = _resolve(tester, .bar);

      _expectSelected(resolved, face: false);
      expect(
        resolved.iconStyle.color,
        const CoreColor.token(CoreColors.onSurfaceSubtle),
      );
      // Hover darkens the foreground instead of laying a wash.
      expect(_classes(resolved.labelHovered), contains('text-on-surface'));
      expect(
        resolved.hoverIconStyle.color,
        const CoreColor.token(CoreColors.onSurface),
      );
      // The `color` indicator states a 0 % hover weight: no wash.
      expect(_hoverWash(tester, .bar, resolved), startsWith(_inkAt(0)));
    });

    testComponents('fill: the same tile face', (tester) {
      _expectSelected(_resolve(tester, .rail));
    });

    testComponents('a bar asking for fill paints the same tile face and '
        'lays the wash on hover', (tester) {
      final resolved = _resolve(tester, .bar, indicator: .fill);

      _expectSelected(resolved);
      expect(
        _hoverWash(tester, .bar, resolved, indicator: .fill),
        startsWith(_inkAt(CoreNavigationBarStyle.defaultStateLayer.hover)),
      );
    });
  });

  group('the markup', () {
    testServer('a hidden label keeps the selection on the tile', (
      tester,
    ) async {
      tester.pumpComponent(_host(_bar(.rail, labelMode: .none)));
      final document = (await tester.request('/')).document!;

      final faces = document.querySelectorAll('.$_faceClass');
      expect(faces, hasLength(1));
      // The face is the destination's tile, not a box round its icon.
      expect(faces.single.attributes['data-coui-nav-chrome'], isNotNull);
    });

    testServer('showDot lays a dot on the icon', (tester) async {
      tester.pumpComponent(_host(_bar(.rail, showDot: true)));
      final document = (await tester.request('/')).document!;
      expect(document.querySelectorAll('.bg-error'), hasLength(1));
    });

    testServer('the header sits before the destinations', (tester) async {
      tester.pumpComponent(
        _host(_bar(.rail, header: const span(id: 'logo', []))),
      );
      final document = (await tester.request('/')).document!;
      final nav = document.getElementById('nav')!;
      expect(nav.children.first.id, 'logo');
    });
  });
}
