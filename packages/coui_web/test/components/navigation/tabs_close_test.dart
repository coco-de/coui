// A tab given `CoreTabItem.onClose` draws a close × after its label and
// badge — the composition `TabPane` uses for the same item field: a ghost
// `Button` beside the select `Clickable` (`role="tab"`), not inside it, so a
// click on the × never selects. The tab's box holds both and carries the
// hover / press wash, so the wash covers the ×. The Flutter twin reads the
// same off its box (`tabs_close_test.dart` in coui_flutter).

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/components/control/button/button.dart';
import 'package:coui_web/src/components/display/badge/badge.dart';
import 'package:coui_web/src/components/infra/clickable/clickable.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations_scope.dart';
import 'package:coui_web/src/components/locale/coui_localizations/ko_coui_localizations.dart';
import 'package:coui_web/src/components/navigation/tabs/tab_pane.dart';
import 'package:coui_web/src/components/navigation/tabs/tabs.dart';
import 'package:coui_web/src/components/navigation/tabs/tabs_style.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:jaspr/jaspr.dart' hide Text;
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// The close `Button`.
final Finder _close = find.byType(Button);

/// The select region of the tab labelled [label].
Finder _select(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(Clickable));

/// The box of the closable tab — the `<span>` holding the select region
/// and the close ×.
Finder get _box => find
    .ancestor(
      of: _close,
      matching: find.byComponentPredicate(
        (component) => component is DomComponent && component.tag == 'span',
        description: 'a <span>',
      ),
    )
    .first;

DomComponent _dom(Finder finder) =>
    finder.evaluate().first.component as DomComponent;

Button _button(ComponentTester tester) =>
    _close.evaluate().single.component as Button;

void _expectOwnedChrome(DomComponent box, ResolvedTabsTab expected) {
  List<String> scopes(String classes) => classes
      .split(' ')
      .where((value) => value.startsWith('co-tabs-state-'))
      .toList();
  List<String> paintClasses(String classes) => classes
      .split(' ')
      .where((value) => !value.startsWith('co-tabs-state-'))
      .toList();

  // The Builder's resolver and the actual Tabs are different Elements.
  // Their complete paint payloads agree; their private identities must not.
  expect(scopes(box.classes!), hasLength(1));
  expect(scopes(expected.root.className), hasLength(1));
  expect(scopes(box.classes!), isNot(scopes(expected.root.className)));
  expect(paintClasses(box.classes!), paintClasses(expected.root.className));
  expect(box.styles!.properties, expected.root.inlineStyles!.properties);
}

List<CoreTabItem<Component>> _items({
  bool enabled = true,
  void Function()? onClose,
}) => [
  CoreTabItem<Component>(
    label: 'main.dart',
    badge: const Badge(child: Text('3')),
    enabled: enabled,
    onClose: onClose ?? () {},
  ),
  const CoreTabItem<Component>(label: 'pubspec.yaml'),
];

void main() {
  group('Tabs onClose', () {
    for (final variant in CoreTabVariant.values) {
      testComponents('$variant: the × sits in the box, outside the select', (
        tester,
      ) async {
        late ResolvedTabsTab tab;
        pumpWithTheme(
          tester,
          Builder(
            builder: (context) {
              tab = resolveTabsTab(
                tabs: resolveTabs(context, variant: variant, expand: false),
                variant: variant,
                size: .defaultSize,
                active: true,
                enabled: true,
                expand: false,
                closable: true,
              );
              return Tabs(
                variant: variant,
                selectedIndex: 0,
                onChanged: (_) {},
                tabs: _items(),
              );
            },
          ),
        );

        // One × for the one closable tab, and no tab's select holds it.
        expect(_close, findsOneComponent);
        expect(
          find.descendant(of: find.byType(Clickable), matching: _close),
          findsNothing,
        );
        // The label and the badge are the select region's.
        expect(
          find.descendant(
            of: _select('main.dart'),
            matching: find.byType(Badge),
          ),
          findsOneComponent,
        );
        // The box holds both, and it is the one carrying the tab's chrome —
        // the wash among it.
        expect(
          find.descendant(of: _box, matching: _select('main.dart')),
          findsOneComponent,
        );
        _expectOwnedChrome(_dom(_box), tab);
        expect(
          _dom(_box).styles!.properties['--co-tabs-token-hover-fill'],
          isNotNull,
        );
        // The select region is the tab: it keeps the role.
        final select = _select('main.dart').evaluate().first.component;
        expect((select as Clickable).componentAttributes['role'], 'tab');
      });
    }

    testComponents('clicking the × closes and does not select', (
      tester,
    ) async {
      final selected = <int>[];
      var closed = 0;
      pumpWithTheme(
        tester,
        Tabs(
          selectedIndex: 1,
          onChanged: selected.add,
          tabs: _items(onClose: () => closed++),
        ),
      );

      await tester.click(_close);
      expect(closed, 1);
      expect(selected, isEmpty);

      // The label still selects.
      await tester.click(_select('main.dart'));
      expect(selected, [0]);
      expect(closed, 1);
    });

    testComponents('a disabled tab still closes, and does not select', (
      tester,
    ) async {
      final selected = <int>[];
      var closed = 0;
      pumpWithTheme(
        tester,
        Tabs(
          selectedIndex: 1,
          onChanged: selected.add,
          tabs: _items(enabled: false, onClose: () => closed++),
        ),
      );

      await tester.click(_close);
      await tester.click(_select('main.dart'));
      expect(closed, 1);
      expect(selected, isEmpty);
    });

    testComponents('the × is named by the default locale', (tester) async {
      pumpWithTheme(
        tester,
        Tabs(selectedIndex: 0, onChanged: (_) {}, tabs: _items()),
      );

      expect(
        _button(tester).componentAttributes['aria-label'],
        DefaultCouiLocalizations.instance.buttonClose,
      );
    });

    testComponents('the × is named by the active locale', (tester) async {
      pumpWithTheme(
        tester,
        CouiLocalizationsScope(
          localizations: KoCouiLocalizations.instance,
          child: Tabs(selectedIndex: 0, onChanged: (_) {}, tabs: _items()),
        ),
      );

      expect(
        _button(tester).componentAttributes['aria-label'],
        KoCouiLocalizations.instance.buttonClose,
      );
    });

    testComponents('the close slots reach the Button and its glyph', (
      tester,
    ) async {
      const style = CoreTabsStyle(
        closeButtonStyle: CoreButtonStyle(
          width: CoreSize.size28,
          height: CoreSize.size28,
        ),
        closeIconStyle: CoreIconStyle(size: CoreIconSize.size16),
      );
      late ResolvedTabs bar;
      pumpWithTheme(
        tester,
        Builder(
          builder: (context) {
            bar = resolveTabs(
              context,
              variant: .pill,
              expand: false,
              tabsStyle: style,
            );
            return Tabs(
              selectedIndex: 0,
              onChanged: (_) {},
              tabsStyle: style,
              tabs: _items(),
            );
          },
        ),
      );

      // Merged over the default: the stated size wins, the unstated corner
      // and inset stay the default's.
      expect(
        bar.closeButtonStyle,
        CoreTabsStyle.defaultCloseButtonStyle.merge(style.closeButtonStyle),
      );
      expect(
        bar.closeButtonStyle.borderRadius,
        CoreTabsStyle.defaultCloseButtonStyle.borderRadius,
      );
      expect(
        bar.closeIconStyle,
        CoreTabsStyle.defaultCloseIconStyle.merge(style.closeIconStyle),
      );
      expect(_button(tester).buttonStyle, bar.closeButtonStyle);
    });

    testComponents('a tab without onClose keeps its markup', (tester) async {
      late ResolvedTabsTab plainChrome;
      pumpWithTheme(
        tester,
        Builder(
          builder: (context) {
            plainChrome = resolveTabsTab(
              tabs: resolveTabs(context, variant: .pill, expand: false),
              variant: .pill,
              size: .defaultSize,
              active: false,
              enabled: true,
              expand: false,
            );
            return Tabs(selectedIndex: 0, onChanged: (_) {}, tabs: _items());
          },
        ),
      );

      // Still one `Clickable` straight around its box, and nothing beside.
      final plain =
          _select('pubspec.yaml').evaluate().first.component as Clickable;
      final box = plain.child;
      expect(box, isA<DomComponent>());
      _expectOwnedChrome(box! as DomComponent, plainChrome);
      // And the resolver says the same thing it said before the flag existed.
      expect(plainChrome.root.className, isNot(contains(WebLayout.flex1)));
    });

    testComponents('an expanded bar spreads a closable tab by its box', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Tabs(
          expand: true,
          selectedIndex: 0,
          onChanged: (_) {},
          tabs: _items(),
        ),
      );

      // The box is the bar's flex item, so it spreads; its select region
      // only stretches to the box's height.
      expect(
        (_dom(_box).classes ?? '').split(' '),
        contains(WebLayout.flex1),
      );
      final select =
          _select('main.dart').evaluate().first.component as Clickable;
      expect(select.classes, WebLayout.selfStretch);
      // A plain tab still spreads by its Clickable, as before.
      final plain =
          _select('pubspec.yaml').evaluate().first.component as Clickable;
      expect(plain.classes, WebLayout.flex1);
    });
  });

  group('TabPane onClose', () {
    testComponents('the × is named by the active locale', (tester) async {
      pumpWithTheme(
        tester,
        CouiLocalizationsScope(
          localizations: KoCouiLocalizations.instance,
          child: TabPane(
            selectedIndex: 0,
            onChanged: (_) {},
            tabs: [CoreTabItem<Component>(label: 'main.dart', onClose: () {})],
          ),
        ),
      );

      expect(
        _button(tester).componentAttributes['aria-label'],
        KoCouiLocalizations.instance.buttonClose,
      );
    });
  });
}
