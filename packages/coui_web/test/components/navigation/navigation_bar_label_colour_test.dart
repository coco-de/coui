import 'package:coui_web/coui_web.dart';
// navigation_bar_style.dart is not re-exported by the barrel (the resolver is
// internal chrome) — import it directly for resolver-level assertions.
import 'package:coui_web/src/components/navigation/navigation_bar/navigation_bar_style.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:jaspr_test/server_test.dart' show ServerTester, testServer;

import '../../helpers/pump_with_theme.dart';

/// A destination label is its own element, and the role class it carries
/// states a colour of its own — so the colour a state is meant to read in has
/// to be stated on that element too. A colour only the destination states is
/// inherited by the label and then beaten by the label's own class.
///
/// These tests read the colour off the label `<span>` as the page renders it,
/// for every state the label can take, so the page cannot say one colour on
/// the destination and another on the text.

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
  CoreNavigationBarStyle? style,
}) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return resolveNavigationBar(
    context,
    mode: mode,
    variant: CoreNavigationBarVariant.defaultVariant,
    overflow: CoreNavigationOverflow.ellipsis,
    labelPosition: mode == CoreNavigationBarMode.sidebar
        ? CoreNavigationLabelPosition.end
        : CoreNavigationLabelPosition.bottom,
    navigationBarStyle: style,
  );
}

List<String> _classes(WebElementChrome chrome) =>
    chrome.className.split(' ').where((c) => c.isNotEmpty).toList();

Map<String, String> _inline(WebElementChrome chrome) =>
    chrome.inlineStyles?.properties ?? const {};

/// The colour utilities among [classes] — a `text-` class that is neither a
/// typography role nor the inherit marker.
Set<String> _colourClasses(Iterable<String> classes) => {
  for (final name in classes)
    if (name.startsWith('text-') &&
        !name.startsWith('text-label-') &&
        name != 'text-inherit')
      name,
};

Component _host(Component child) => CoUIWeb(theme: .coui, child: child);

/// Selected, resting and disabled destinations, with a section header in
/// between — every state a label or header can take, in one bar.
NavigationBar _bar(
  CoreNavigationBarMode mode, {
  CoreNavigationBarStyle? style,
}) {
  return NavigationBar(
    id: 'nav',
    mode: mode,
    labelMode: CoreNavigationLabelMode.all,
    selectedIndex: 0,
    onSelected: (_) {},
    navigationBarStyle: style,
    items: const [
      CoreNavigationBarItem.destination(
        icon: Icon(LucideIcons.inbox),
        label: 'Inbox',
      ),
      CoreNavigationBarItem.label('Workspace'),
      CoreNavigationBarItem.destination(
        icon: Icon(LucideIcons.star),
        label: 'Stars',
      ),
      CoreNavigationBarItem.destination(
        icon: Icon(LucideIcons.search),
        label: 'Search',
        enabled: false,
      ),
    ],
  );
}

/// One destination as the page renders it, read off the DOM into plain data.
class _Destination {
  const _Destination({
    required this.labelClasses,
    required this.labelStyle,
    required this.chromeClasses,
    required this.buttonClasses,
    required this.iconClasses,
    required this.ariaDisabled,
    required this.ariaCurrent,
    required this.hasTabindex,
  });

  /// Classes of the visible label `<span>`.
  final Set<String> labelClasses;

  /// Inline style of the visible label `<span>`.
  final String labelStyle;

  /// Classes of the destination chrome `<div>` the label sits in.
  final Set<String> chromeClasses;

  /// Classes of the `role="button"` element.
  final Set<String> buttonClasses;

  /// Classes of the glyph `<svg>`.
  final Set<String> iconClasses;

  final String? ariaDisabled;
  final String? ariaCurrent;
  final bool hasTabindex;
}

/// A rendered bar: its destinations in order, and the section header.
class _Page {
  const _Page({required this.destinations, required this.headerClasses});

  final List<_Destination> destinations;
  final Set<String> headerClasses;
}

const _selected = 0;
const _resting = 1;
const _disabled = 2;

Future<_Page> _render(
  ServerTester tester,
  CoreNavigationBarMode mode, {
  CoreNavigationBarStyle? style,
}) async {
  tester.pumpComponent(_host(_bar(mode, style: style)));
  final document = (await tester.request('/')).document!;
  final destinations = <_Destination>[];
  for (final button in document.querySelectorAll('[data-coui-nav-index]')) {
    final label = button.querySelector(r'[id$="-label"]')!;
    destinations.add(
      _Destination(
        labelClasses: {...label.classes},
        labelStyle: label.attributes['style'] ?? '',
        chromeClasses: {
          ...button.querySelector('[data-coui-nav-chrome]')!.classes,
        },
        buttonClasses: {...button.classes},
        iconClasses: {...button.querySelector('svg')!.classes},
        ariaDisabled: button.attributes['aria-disabled'],
        ariaCurrent: button.attributes['aria-current'],
        hasTabindex: button.attributes.containsKey('tabindex'),
      ),
    );
  }
  final header = document
      .querySelectorAll('div')
      .firstWhere((element) => element.text == 'Workspace');
  return _Page(
    destinations: destinations,
    headerClasses: {...header.classes},
  );
}

/// Every placement marks the selected label `primary`, stacked or a row,
/// under either indicator (#6358).
String _selectedColour(CoreNavigationBarMode mode) => 'text-primary';

void main() {
  group('a disabled label reads in the disabled tone', () {
    for (final mode in CoreNavigationBarMode.values) {
      testComponents('${mode.name} resolves a disabled label chrome', (
        tester,
      ) async {
        final resolved = _resolve(tester, mode);

        expect(_colourClasses(_classes(resolved.labelDisabled)), {
          'text-disabled-content',
        });
        // The same role the resting label draws in, so a disabled label is
        // the same size as the destinations around it.
        expect(
          _classes(resolved.labelDisabled),
          contains(
            mode == CoreNavigationBarMode.sidebar
                ? 'text-label-large'
                : 'text-label-small',
          ),
        );
        // Weight is the selected state's signal, not a disabled one.
        expect(_inline(resolved.labelDisabled)['font-weight'], isNull);
      });

      testServer('${mode.name} paints the label span in disabledContent', (
        tester,
      ) async {
        final page = await _render(tester, mode);
        final label = page.destinations[_disabled].labelClasses;

        expect(label, contains('text-disabled-content'));
        expect(label, isNot(contains('text-on-surface-variant')));
        expect(label, isNot(contains('text-on-surface')));
      });
    }
  });

  group('every label states one colour, the one its destination states', () {
    for (final mode in CoreNavigationBarMode.values) {
      testServer('${mode.name}: selected, resting and disabled', (
        tester,
      ) async {
        final page = await _render(tester, mode);
        final expected = {
          // The selected label is `primary` in every placement (#6358).
          _selected: _selectedColour(mode),
          _resting: 'text-on-surface-subtle',
          _disabled: 'text-disabled-content',
        };

        for (final MapEntry(:key, :value) in expected.entries) {
          final destination = page.destinations[key];
          expect(
            _colourClasses(destination.labelClasses),
            {value},
            reason: '${mode.name} / destination $key label',
          );
          expect(
            _colourClasses(destination.chromeClasses),
            {value},
            reason: '${mode.name} / destination $key chrome',
          );
        }
      });
    }

    testServer('the section header states its own colour once', (
      tester,
    ) async {
      final page = await _render(tester, CoreNavigationBarMode.sidebar);

      expect(_colourClasses(page.headerClasses), {'text-on-surface-subtle'});
    });
  });

  group('an instance disabledLabelTextStyle reaches the disabled label', () {
    const error = CoreColor.token(CoreColors.error);

    for (final mode in CoreNavigationBarMode.values) {
      testServer('${mode.name}: a token colour', (tester) async {
        final page = await _render(
          tester,
          mode,
          style: const CoreNavigationBarStyle(
            disabledLabelTextStyle: CoreTextStyle(color: error),
          ),
        );
        final disabled = page.destinations[_disabled];

        expect(_colourClasses(disabled.labelClasses), {'text-error'});
        expect(_colourClasses(disabled.chromeClasses), {'text-error'});
        // The other states keep their own tone.
        expect(_colourClasses(page.destinations[_resting].labelClasses), {
          'text-on-surface-subtle',
        });
        expect(_colourClasses(page.destinations[_selected].labelClasses), {
          _selectedColour(mode),
        });
      });
    }

    testServer('a raw colour travels inline on the label span', (
      tester,
    ) async {
      final page = await _render(
        tester,
        CoreNavigationBarMode.rail,
        style: const CoreNavigationBarStyle(
          disabledLabelTextStyle: CoreTextStyle(color: CoreColor(0xFF112233)),
        ),
      );
      final disabled = page.destinations[_disabled];

      expect(_colourClasses(disabled.labelClasses), isEmpty);
      expect(disabled.labelStyle, contains('color: rgb(17, 34, 51)'));
    });

    testServer('a non-colour field keeps the disabled tone', (tester) async {
      final page = await _render(
        tester,
        CoreNavigationBarMode.rail,
        style: const CoreNavigationBarStyle(
          disabledLabelTextStyle: CoreTextStyle(
            fontWeight: CoreFontWeight.bold,
          ),
        ),
      );
      final disabled = page.destinations[_disabled];

      expect(_colourClasses(disabled.labelClasses), {'text-disabled-content'});
      expect(disabled.labelStyle, contains('font-weight: 700'));
    });

    testServer('the resting label style does not reach the disabled label', (
      tester,
    ) async {
      final page = await _render(
        tester,
        CoreNavigationBarMode.rail,
        style: const CoreNavigationBarStyle(
          labelTextStyle: CoreTextStyle(color: error),
        ),
      );

      expect(_colourClasses(page.destinations[_resting].labelClasses), {
        'text-error',
      });
      expect(_colourClasses(page.destinations[_disabled].labelClasses), {
        'text-disabled-content',
      });
    });
  });

  group('the selected label and its destination state one colour', () {
    for (final mode in CoreNavigationBarMode.values) {
      testServer('${mode.name}: an instance selectedLabelTextStyle', (
        tester,
      ) async {
        final page = await _render(
          tester,
          mode,
          // `primary` is the default now, so the instance states a colour
          // the default does not.
          style: const CoreNavigationBarStyle(
            selectedLabelTextStyle: CoreTextStyle(
              color: CoreColor.token(CoreColors.error),
            ),
          ),
        );
        final selected = page.destinations[_selected];

        expect(_colourClasses(selected.labelClasses), {'text-error'});
        expect(_colourClasses(selected.chromeClasses), {'text-error'});
        // Selection stays legible without colour — the bold weight.
        expect(
          selected.labelStyle,
          contains('font-weight: ${CoreFontWeight.bold}'),
        );
      });
    }
  });

  group('the rest of a disabled destination agrees with the label', () {
    for (final mode in CoreNavigationBarMode.values) {
      testServer('${mode.name}: icon, aria and interaction', (tester) async {
        final page = await _render(tester, mode);
        final disabled = page.destinations[_disabled];

        // The icon takes the same tone as the label beside it.
        expect(disabled.iconClasses, contains('text-disabled-content'));
        expect(disabled.ariaDisabled, 'true');
        expect(disabled.hasTabindex, isFalse);
        expect(disabled.ariaCurrent, isNull);
        expect(disabled.buttonClasses, contains('cursor-not-allowed'));
        // No hover fill, state layer or press feedback on a destination that
        // is off.
        expect(
          disabled.chromeClasses.where((name) => name.startsWith('hover:')),
          isEmpty,
        );
        expect(
          disabled.chromeClasses.where(
            (name) => name.startsWith('co-navbar-sl-'),
          ),
          isEmpty,
        );
        expect(disabled.buttonClasses, isNot(contains('coui-clickable-press')));
      });
    }

    for (final mode in CoreNavigationBarMode.values) {
      for (final labelMode in [
        CoreNavigationLabelMode.all,
        CoreNavigationLabelMode.none,
      ]) {
        testServer('${mode.name} / labels ${labelMode.name}: the badge, the '
            'name and the tooltip stay with a disabled destination', (
          tester,
        ) async {
          tester.pumpComponent(
            _host(
              NavigationBar(
                id: 'nav',
                mode: mode,
                labelMode: labelMode,
                selectedIndex: 0,
                onSelected: (_) {},
                items: const [
                  CoreNavigationBarItem.destination(
                    icon: Icon(LucideIcons.inbox),
                    label: 'Inbox',
                  ),
                  CoreNavigationBarItem.destination(
                    icon: Icon(LucideIcons.search),
                    label: 'Search',
                    enabled: false,
                    badge: Text('3'),
                  ),
                ],
              ),
            ),
          );
          final document = (await tester.request('/')).document!;
          final button = document
              .querySelectorAll('[data-coui-nav-index]')
              .last;

          expect(button.attributes['aria-disabled'], 'true');
          expect(
            button.attributes['aria-labelledby'],
            'nav-item-1-label nav-item-1-badge',
          );
          expect(document.getElementById('nav-item-1-badge')!.text, '3');
          // A disabled destination stays reachable for its tooltip: nothing
          // turns pointer events off on it.
          expect(button.attributes['style'] ?? '', isNot(contains('pointer')));
          // The tooltip wraps the destination exactly when its label is
          // hidden — disabled or not.
          expect(
            button.parent!.id,
            labelMode == CoreNavigationLabelMode.none
                ? startsWith('co-tooltip-trigger')
                : isNot(startsWith('co-tooltip-trigger')),
          );
        });
      }
    }

    testServer('an instance disabledIconStyle colour reaches the glyph', (
      tester,
    ) async {
      final page = await _render(
        tester,
        CoreNavigationBarMode.rail,
        style: const CoreNavigationBarStyle(
          disabledIconStyle: CoreIconStyle(
            color: CoreColor.token(CoreColors.error),
          ),
        ),
      );

      expect(page.destinations[_disabled].iconClasses, contains('text-error'));
    });
  });
}
