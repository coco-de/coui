import 'package:coui_web/coui_web.dart';
// navigation_bar_style.dart is not re-exported by the barrel (the resolver is
// internal chrome) — import it directly for resolver-level assertions.
import 'package:coui_web/src/components/navigation/navigation_bar/navigation_bar_style.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:jaspr_test/server_test.dart' show testServer;

import '../../helpers/pump_with_theme.dart';

/// The Web twin of the Flutter `navigation_bar_item_selection_face_test`
/// (#5740, #6358): the designer's answers for `NavigationBarItem`, read off
/// the resolver, the scoped rules and the rendered markup.
///
/// A selected destination — a row or stacked, under either indicator —
/// paints its whole tile in [CoreNavigationBarStyle.defaultSelectedFaceColor]
/// with a `primary` glyph and label; the icon box paints nothing.
class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

BuildContext _context(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return context;
}

ResolvedNavigationBar _resolve(
  ComponentTester tester,
  CoreNavigationBarMode mode, {
  required CoreNavigationLabelPosition labelPosition,
  CoreNavigationSelectionIndicator? indicator,
  CoreNavigationBarStyle? style,
}) => resolveNavigationBar(
  _context(tester),
  mode: mode,
  variant: CoreNavigationBarVariant.defaultVariant,
  overflow: CoreNavigationOverflow.ellipsis,
  labelPosition: labelPosition,
  indicator: indicator,
  navigationBarStyle: style,
);

List<String> _classes(WebElementChrome chrome) =>
    chrome.className.split(' ').where((c) => c.isNotEmpty).toList();

Map<String, String> _inline(WebElementChrome chrome) =>
    chrome.inlineStyles?.properties ?? const {};

Component _host(Component child) => CoUIWeb(theme: .coui, child: child);

/// The selected tile's class, named off the Core constant both platforms
/// read.
final String _faceClass =
    'bg-${CoreNavigationBarStyle.defaultSelectedFaceColor.tailwindColor}';

/// The selection every placement states: the tile face on the selected
/// destination under `fill` — none under `color` (#6393) — a `primary`
/// label and glyph, and an icon box that paints nothing.
void _expectSelected(ResolvedNavigationBar resolved, {bool face = true}) {
  for (final chrome in [
    resolved.destinationSelected,
    resolved.iconOnlyDestinationSelected,
  ]) {
    final classes = _classes(chrome);
    if (face) {
      expect(classes, contains(_faceClass));
    } else {
      expect(
        classes.where((c) => c.startsWith('bg-') && c != 'bg-transparent'),
        isEmpty,
      );
      expect(_inline(chrome)['background-color'], isNull);
    }
  }
  expect(_classes(resolved.labelSelected), contains('text-primary'));
  expect(
    resolved.selectedIconStyle!.color,
    const CoreColor.token(CoreColors.primary),
  );
  expect(_classes(resolved.iconAnchor), isNot(contains(_faceClass)));
  expect(_inline(resolved.iconAnchor)['border-radius'], isNull);
  expect(_inline(resolved.iconAnchor)['background-color'], isNull);
}

void main() {
  group('every placement marks the selection', () {
    for (final indicator in CoreNavigationSelectionIndicator.values) {
      for (final labelPosition in [
        CoreNavigationLabelPosition.end,
        CoreNavigationLabelPosition.bottom,
      ]) {
        testComponents('${indicator.name}, label ${labelPosition.name}', (
          tester,
        ) {
          _expectSelected(
            _resolve(
              tester,
              .rail,
              labelPosition: labelPosition,
              indicator: indicator,
            ),
            face: indicator == CoreNavigationSelectionIndicator.fill,
          );
        });
      }
    }

    testComponents('the layer lies over the selection', (tester) {
      final row = _resolve(tester, .rail, labelPosition: .end);
      final stacked = _resolve(tester, .rail, labelPosition: .bottom);
      Iterable<String> layer(WebElementChrome chrome) =>
          _classes(chrome).where((c) => c.startsWith('co-navbar-sl-'));
      final rowLayer = layer(row.destinationSelected);
      final barLayer = layer(row.destinationEnabledIdle);
      // A selected destination's layer is blended over its own face — its
      // own class, one for a row and a stacked tile alike.
      expect(rowLayer, hasLength(1));
      expect(rowLayer, isNot(barLayer));
      expect(layer(stacked.destinationSelected), rowLayer);
      final css = resolveNavigationBarRules(
        _context(tester),
        mode: .rail,
        variant: CoreNavigationBarVariant.defaultVariant,
      ).css;
      const face = CoreNavigationBarStyle.defaultSelectedFaceColor;
      expect(
        css,
        contains(
          ':focus-visible>.${rowLayer.single}{background-color:color-mix(in '
          'srgb, rgb(var(--coui-on-surface)) 8%, '
          'rgb(var(--coui-${face.tailwindColor}) / 100%));}',
        ),
      );
    });

    for (final labelPosition in [
      CoreNavigationLabelPosition.end,
      CoreNavigationLabelPosition.bottom,
    ]) {
      testComponents('a caller face still outranks the default '
          '(${labelPosition.name})', (tester) {
        final resolved = _resolve(
          tester,
          .rail,
          labelPosition: labelPosition,
          style: const CoreNavigationBarStyle(
            selectedBackgroundColor: CoreColor.token(CoreColors.error),
          ),
        );
        expect(_classes(resolved.destinationSelected), contains('bg-error'));
        expect(
          _classes(resolved.destinationSelected),
          isNot(contains(_faceClass)),
        );
      });
    }

    testComponents('the deprecated pill fields paint nothing', (tester) {
      final resolved = _resolve(
        tester,
        .rail,
        labelPosition: .bottom,
        style: const CoreNavigationBarStyle(
          // The no-op is what is under test.
          // ignore: deprecated_member_use
          selectedIconAnchorColor: CoreColor.token(CoreColors.error),
          // The no-op is what is under test.
          // ignore: deprecated_member_use
          selectedIconAnchorIconStyle: CoreIconStyle(
            color: CoreColor.token(CoreColors.error),
          ),
          // The no-op is what is under test.
          // ignore: deprecated_member_use
          iconAnchorRadius: CoreBorderRadius.all(CoreRadius.radius9999),
        ),
      );
      _expectSelected(resolved);
      expect(_classes(resolved.iconAnchor), isNot(contains('bg-error')));
    });

    testServer('the markup paints the face on the selected tile alone', (
      tester,
    ) async {
      tester.pumpComponent(
        _host(
          NavigationBar(
            id: 'nav',
            mode: CoreNavigationBarMode.rail,
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
      final faces = document.querySelectorAll('.$_faceClass');
      expect(faces, hasLength(1));
      expect(faces.single.attributes['data-coui-nav-chrome'], isNotNull);
    });
  });

  group('focus lays the 8 % wash under every indicator', () {
    for (final indicator in CoreNavigationSelectionIndicator.values) {
      testComponents(indicator.name, (tester) {
        final css = resolveNavigationBarRules(
          _context(tester),
          mode: .bar,
          variant: CoreNavigationBarVariant.defaultVariant,
          indicator: indicator,
        ).css;
        final focus = RegExp(
          r':focus-visible>\.[\w-]+\{background-color:([^;]+);\}',
        ).firstMatch(css);
        expect(focus, isNotNull, reason: css);
        expect(focus!.group(1), contains('8%'));
      });
    }
  });

  group('an icon-only destination paints 64 × 40 and accepts 48', () {
    testComponents('the icon-only chrome states its own floor', (tester) {
      final resolved = _resolve(tester, .bar, labelPosition: .bottom);

      for (final chrome in [
        resolved.iconOnlyDestinationSelected,
        resolved.iconOnlyDestinationEnabledIdle,
        resolved.iconOnlyDestinationEnabledHovered,
        resolved.iconOnlyDestinationDisabled,
      ]) {
        expect(_inline(chrome)['min-height'], '2.5rem');
        expect(_inline(chrome)['min-width'], 'min(4.0rem, 100%)');
        expect(_classes(chrome), contains(kWebTouchTargetMarker));
        expect(_inline(chrome)[kWebTouchTargetVar], '3.0rem');
      }
      // A labelled destination keeps the 64 floor.
      expect(_inline(resolved.destinationEnabledIdle)['min-height'], '4.0rem');
      expect(_inline(resolved.destinationEnabledIdle)['min-width'], isNull);
    });

    testComponents('a row keeps its own box and no pointer floor', (tester) {
      final resolved = _resolve(tester, .rail, labelPosition: .end);
      expect(
        _classes(resolved.destinationEnabledIdle),
        isNot(contains(kWebTouchTargetMarker)),
      );
      expect(
        _inline(resolved.destinationEnabledIdle)[kWebTouchTargetVar],
        isNull,
      );
    });

    testComponents('a stated itemMinHeight still reaches it', (tester) {
      final resolved = _resolve(
        tester,
        .bar,
        labelPosition: .bottom,
        style: const CoreNavigationBarStyle(itemMinHeight: 56),
      );
      expect(
        _inline(resolved.iconOnlyDestinationEnabledIdle)['min-height'],
        '3.5rem',
      );
    });

    testServer('the markup draws the icon-only chrome', (tester) async {
      tester.pumpComponent(
        _host(
          NavigationBar(
            id: 'nav',
            labelMode: CoreNavigationLabelMode.none,
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
      final chromes = document.querySelectorAll('[data-coui-nav-chrome]');
      expect(chromes, hasLength(2));
      for (final chrome in chromes) {
        final style = chrome.attributes['style'] ?? '';
        expect(style, contains('min-height: 2.5rem'));
        expect(style, contains('$kWebTouchTargetVar: 3.0rem'));
        expect(chrome.classes, contains(kWebTouchTargetMarker));
      }
    });
  });
}
