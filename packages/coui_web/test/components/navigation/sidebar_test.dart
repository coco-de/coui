import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/navigation/sidebar/sidebar.dart';
import 'package:coui_web/src/components/navigation/sidebar_group/sidebar_group.dart';
import 'package:coui_web/src/components/navigation/sidebar_header/sidebar_header.dart';
import 'package:coui_web/src/components/navigation/sidebar_item/sidebar_item.dart';
import 'package:coui_web/src/components/navigation/sidebar_item/sidebar_item_style.dart';
import 'package:coui_web/src/components/navigation/sidebar_rail_item/sidebar_rail_item.dart';
import 'package:coui_web/src/components/navigation/sidebar_search/sidebar_search.dart';
import 'package:coui_web/src/components/navigation/sidebar_section/sidebar_section.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

Iterable<DomComponent> _elements(String tag) =>
    find.tag(tag).evaluate().map((e) => e.component as DomComponent);

DomComponent? _withAttribute(String name, [String? value]) {
  for (final tag in ['div', 'nav', 'span']) {
    for (final element in _elements(tag)) {
      final attribute = element.attributes?[name];
      if (attribute != null && (value == null || attribute == value)) {
        return element;
      }
    }
  }
  return null;
}

String _rem(double px) => '${px / kRemDivisor}rem';

void main() {
  group('Sidebar', () {
    testComponents('preserves caller keydown handlers', (tester) async {
      var calls = 0;
      pumpWithTheme(
        tester,
        Sidebar(
          eventHandlers: {
            'keydown': [(_) => calls++],
          },
        ),
      );
      // The VM web stub throws when the built-in handler reads event.key.
      // Catch that platform limitation after checking the caller runs first.
      try {
        tester.dispatchEvent(find.tag('nav'), 'keydown');
        // The VM web stub deliberately throws this Error for DOM access.
        // ignore: avoid_catching_errors
      } on UnsupportedError {
        // KeyboardEvent properties are only available in a real browser.
      }
      expect(calls, 1);
    });

    testComponents('is a named navigation landmark', (tester) async {
      pumpWithTheme(
        tester,
        const Sidebar(semanticLabel: '주 메뉴', children: [Component.text('본문')]),
      );
      final nav = _elements('nav').single;
      expect(nav.attributes?['aria-label'], '주 메뉴');
      expect(nav.events?.containsKey('keydown'), isTrue);
    });

    for (final (type, rail, panel) in [
      (CoreSidebarType.standard, false, true),
      (CoreSidebarType.twoPane, true, true),
      (CoreSidebarType.collapsed, true, false),
    ]) {
      testComponents('${type.name} draws the rail $rail, the panel $panel', (
        tester,
      ) async {
        pumpWithTheme(
          tester,
          Sidebar(
            type: type,
            railItems: const [Component.text('레일')],
            children: const [Component.text('본문')],
          ),
        );
        final widths = _elements('div')
            .map((e) => e.styles?.properties['width'])
            .whereType<String>()
            .toList();
        expect(widths.contains(_rem(CoreSize.size64)), rail, reason: 'rail');
        final panelWidth = CoreSidebarStyle.defaultsByType[type]!.panelWidth!;
        expect(widths.contains(_rem(panelWidth)), panel, reason: 'panel');
        expect(find.text('본문').evaluate().isNotEmpty, panel);
      });
    }

    testComponents('the panel carries the face and the end line', (
      tester,
    ) async {
      pumpWithTheme(tester, const Sidebar(children: [Component.text('본문')]));
      final panel = _elements('div').firstWhere(
        (e) => e.styles?.properties['width'] == _rem(CoreLayout.layout248),
      );
      expect(panel.classes, contains('bg-surface-container-low'));
      expect(panel.classes, contains('border-outline-variant'));
      expect(panel.styles?.properties['border-inline-end-style'], 'solid');
    });
  });

  group('SidebarItem', () {
    testComponents('the current place states aria-current and its face', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        SidebarItem(
          label: const Component.text('메뉴'),
          selected: true,
          onPressed: () {},
        ),
      );
      final root = _withAttribute('aria-current', 'page')!;
      expect(root.classes, contains('bg-surface-container'));
      expect(root.classes, isNot(contains('bg-surface-container-high')));
      expect(root.classes, contains('text-on-surface'));
    });

    testComponents('a resting row reads in onSurfaceSubtle', (tester) async {
      pumpWithTheme(
        tester,
        SidebarItem(label: const Component.text('메뉴'), onPressed: () {}),
      );
      expect(_withAttribute('aria-current'), isNull);
      final resolved = resolveSidebarItem(
        find.byType(SidebarItem).evaluate().single,
        level: CoreSidebarItemLevel.top,
      );
      expect(resolved.root.className, contains('text-on-surface-subtle'));
      expect(resolved.label.className, contains('text-on-surface-subtle'));
      expect(
        resolved.root.inlineStyles?.properties['min-height'],
        _rem(CoreSize.size36),
      );
      expect(find.tag('style'), findsOneComponent);
    });

    testComponents('a disabled row dims its trailing glyph with the rest', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        SidebarItem(
          label: const Component.text('메뉴'),
          trailing: const Component.text('›'),
          onPressed: () {},
        ),
      );
      final resting = resolveSidebarItem(
        find.byType(SidebarItem).evaluate().single,
        level: CoreSidebarItemLevel.top,
      );
      expect(resting.trailing.className, contains('text-on-surface-subtle'));

      pumpWithTheme(
        tester,
        const SidebarItem(
          label: Component.text('메뉴'),
          trailing: Component.text('›'),
        ),
      );
      final disabled = resolveSidebarItem(
        find.byType(SidebarItem).evaluate().single,
        level: CoreSidebarItemLevel.top,
        enabled: false,
      );
      expect(disabled.trailing.className, contains('text-disabled-content'));
      expect(disabled.trailing.className, isNot(contains('on-surface-subtle')));
      expect(disabled.label.className, contains('text-disabled-content'));
      // The glyph keeps its size — only the ink changed.
      expect(disabled.trailingIconStyle.size, resting.trailingIconStyle.size);
    });

    testComponents('a disabled row is never current and has no wash', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const SidebarItem(label: Component.text('메뉴'), selected: true),
      );
      expect(_withAttribute('aria-current'), isNull);
      expect(_withAttribute('aria-disabled', 'true'), isNotNull);
      expect(find.tag('style'), findsNothing);
    });
  });

  group('the rest of the family', () {
    testComponents('a rail item is named by its label', (tester) async {
      pumpWithTheme(
        tester,
        SidebarRailItem(
          icon: const Component.text('◆'),
          label: '홈',
          onPressed: () {},
        ),
      );
      expect(_withAttribute('aria-label', '홈'), isNotNull);
    });

    testComponents('a section is a heading', (tester) async {
      pumpWithTheme(tester, const SidebarSection(label: Component.text('구역')));
      expect(find.tag('h2'), findsOneComponent);
    });

    testComponents('a card header draws a line, a plain one none', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const SidebarHeader(
          variant: CoreSidebarHeaderVariant.card,
          title: Component.text('나음'),
        ),
      );
      final card = _elements('div').first;
      expect(card.classes, contains('border-outline-subtle'));
      expect(card.classes, contains('bg-surface'));
    });

    testComponents('the search trigger is named by its placeholder', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        SidebarSearch(
          placeholder: '검색',
          shortcut: const ['⌘', 'K'],
          onPressed: () {},
        ),
      );
      final root = _withAttribute('aria-label', '검색')!;
      expect(root.attributes?['aria-keyshortcuts'], '⌘+K');
    });

    testComponents('a group states aria-expanded and closes its rows', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const SidebarGroup(
          label: Component.text('프로젝트'),
          expanded: false,
          children: [Component.text('하위')],
        ),
      );
      expect(_withAttribute('aria-expanded', 'false'), isNotNull);
      expect(_withAttribute('inert'), isNotNull);
    });
  });
}
