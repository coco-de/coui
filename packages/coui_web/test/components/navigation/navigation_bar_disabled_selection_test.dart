import 'package:coui_web/coui_web.dart';
// navigation_bar_style.dart is not re-exported by the barrel (the resolver is
// internal chrome) — import it directly for resolver-level assertions.
import 'package:coui_web/src/components/navigation/navigation_bar/navigation_bar_style.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:jaspr_test/server_test.dart' show testServer;

import '../../helpers/pump_with_theme.dart';

/// The Web twin of the Flutter `navigation_bar_disabled_selection_test`
/// (#5740, #6358): a destination that is selected AND disabled keeps its
/// selection mark, dimmed — the whole tile, stacked or a row, under either
/// indicator, in [CoreNavigationBarStyle.defaultDisabledSelectedFaceColor];
/// read off the resolver and the rendered markup.
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
  required CoreNavigationLabelPosition labelPosition,
  CoreNavigationSelectionIndicator? indicator,
  CoreNavigationBarStyle? style,
}) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return resolveNavigationBar(
    context,
    mode: mode,
    variant: CoreNavigationBarVariant.defaultVariant,
    overflow: CoreNavigationOverflow.ellipsis,
    labelPosition: labelPosition,
    indicator: indicator,
    navigationBarStyle: style,
  );
}

List<String> _classes(WebElementChrome chrome) =>
    chrome.className.split(' ').where((c) => c.isNotEmpty).toList();

Map<String, String> _inline(WebElementChrome chrome) =>
    chrome.inlineStyles?.properties ?? const {};

Component _host(Component child) => CoUIWeb(theme: .coui, child: child);

const CoreColor _dimmedFaceColor =
    CoreNavigationBarStyle.defaultDisabledSelectedFaceColor;

final String _dimmedFace = 'bg-${_dimmedFaceColor.tailwindColor}';

/// The selected weight both platforms read off Core (bold).
const String _boldWeight = '${CoreFontWeight.bold}';

void main() {
  group('the resolver', () {
    for (final indicator in CoreNavigationSelectionIndicator.values) {
      for (final labelPosition in [
        CoreNavigationLabelPosition.bottom,
        CoreNavigationLabelPosition.end,
      ]) {
        final face = indicator == CoreNavigationSelectionIndicator.fill
            ? 'the tile dims'
            : 'no face';
        testComponents('${indicator.name}, label ${labelPosition.name}: '
            '$face, takes no layer', (tester) {
          final resolved = _resolve(
            tester,
            .rail,
            labelPosition: labelPosition,
            indicator: indicator,
          );
          for (final chrome in [
            resolved.destinationDisabledSelected,
            resolved.iconOnlyDestinationDisabledSelected,
          ]) {
            final classes = _classes(chrome);
            // `color` paints no face here either (#6393).
            expect(
              classes,
              indicator == CoreNavigationSelectionIndicator.fill
                  ? contains(_dimmedFace)
                  : isNot(contains(_dimmedFace)),
            );
            expect(classes, contains('text-disabled-content'));
            expect(
              classes.where((c) => c.startsWith('co-navbar-sl-')),
              isEmpty,
            );
            expect(classes.where((c) => c.startsWith('hover:')), isEmpty);
          }
          // No pill: the icon box paints nothing.
          expect(_classes(resolved.iconAnchor), isNot(contains(_dimmedFace)));
          expect(_inline(resolved.iconAnchor)['border-radius'], isNull);
        });
      }
    }

    testComponents('the label is disabledContent at the selected weight', (
      tester,
    ) {
      final resolved = _resolve(tester, .rail, labelPosition: .bottom);
      expect(
        _classes(resolved.labelDisabledSelected),
        contains('text-disabled-content'),
      );
      expect(
        _inline(resolved.labelDisabledSelected)['font-weight'],
        _boldWeight,
      );
      // An unselected disabled label keeps the resting weight.
      expect(
        _inline(resolved.labelDisabled)['font-weight'],
        isNot(_boldWeight),
      );
    });

    testComponents('a caller face wins', (tester) {
      final resolved = _resolve(
        tester,
        .rail,
        labelPosition: .bottom,
        style: const CoreNavigationBarStyle(
          disabledSelectedBackgroundColor: CoreColor.token(CoreColors.error),
        ),
      );
      final classes = _classes(resolved.destinationDisabledSelected);
      expect(classes, contains('bg-error'));
      expect(classes, isNot(contains(_dimmedFace)));
    });

    testComponents('the deprecated pill colour paints nothing', (tester) {
      final resolved = _resolve(
        tester,
        .rail,
        labelPosition: .bottom,
        style: const CoreNavigationBarStyle(
          // The no-op is what is under test.
          // ignore: deprecated_member_use
          disabledSelectedIconAnchorColor: CoreColor.token(CoreColors.error),
        ),
      );
      expect(
        _classes(resolved.destinationDisabledSelected),
        contains(_dimmedFace),
      );
      for (final chrome in [
        resolved.destinationDisabledSelected,
        resolved.iconAnchor,
      ]) {
        expect(_classes(chrome), isNot(contains('bg-error')));
      }
    });
  });

  testServer('the bar dims the tile of its disabled current place', (
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
              enabled: false,
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
    final first = chromes.first;
    // The tile itself carries the dimmed face; nothing inside it paints one.
    expect(first.classes, contains(_dimmedFace));
    expect(first.querySelectorAll('.$_dimmedFace'), isEmpty);
    final label = first.querySelector('#nav-item-0-label')!;
    expect(label.classes, contains('text-disabled-content'));
    expect(label.attributes['style'], contains('font-weight: $_boldWeight'));
    // A disabled destination states no selection.
    expect(first.parent!.attributes['aria-current'], isNull);
    expect(chromes.last.classes, isNot(contains(_dimmedFace)));
  });

  testComponents('the selection dot stays, dimmed', (tester) {
    final resolved = _resolve(tester, .rail, labelPosition: .bottom);
    expect(
      resolved.disabledSelectionMarkStyle.backgroundColor,
      const CoreColor.token(CoreColors.disabledContent),
    );
    // The same dot — only the colour moves.
    expect(
      resolved.disabledSelectionMarkStyle.dotSize,
      resolved.selectionMarkStyle.dotSize,
    );
  });

  testServer('a disabled current place shows the dimmed dot', (tester) async {
    tester.pumpComponent(
      _host(
        NavigationBar(
          id: 'nav',
          mode: CoreNavigationBarMode.rail,
          selectionMark: CoreNavigationSelectionMark.dot,
          selectedIndex: 0,
          onSelected: (_) {},
          items: const [
            CoreNavigationBarItem.destination(
              icon: Icon(LucideIcons.house),
              label: 'Home',
              enabled: false,
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
    String markOpacity(int i) =>
        chromes[i].querySelector('[aria-hidden="true"]')!.attributes['style']!;
    expect(markOpacity(0), contains('opacity: 1'));
    expect(markOpacity(1), contains('opacity: 0'));
    final dot = chromes.first.querySelector('[aria-hidden="true"]')!;
    expect(dot.innerHtml, contains('disabled-content'));
  });
}
