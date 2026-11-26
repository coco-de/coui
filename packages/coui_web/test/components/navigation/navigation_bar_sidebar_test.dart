import 'package:coui_web/coui_web.dart';
// navigation_bar_style.dart is not re-exported by the barrel (the resolver is
// internal chrome) — import it directly for resolver-level assertions.
import 'package:coui_web/src/components/navigation/navigation_bar/navigation_bar_style.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:jaspr_test/server_test.dart' show testServer;

import '../../helpers/pump_with_theme.dart';

/// The Web twin of the Flutter `navigation_bar_sidebar_test`: every cell of
/// the per-mode table read back where it lands, the bar's tones, the badge
/// placement and the destination's accessible name.
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

Map<String, String> _inline(WebElementChrome chrome) =>
    chrome.inlineStyles?.properties ?? const {};

List<String> _classes(WebElementChrome chrome) =>
    chrome.className.split(' ').where((c) => c.isNotEmpty).toList();

Component _host(Component child) => CoUIWeb(theme: .coui, child: child);

const _badge = Badge(
  form: CoreBadgeForm.count,
  tone: CoreBadgeTone.info,
  variant: CoreBadgeVariant.filled,
  size: CoreComponentSize.xs,
  child: Text('3'),
);

NavigationBar _bar(
  CoreNavigationBarMode mode, {
  CoreNavigationLabelMode? labelMode,
  Component? badge = _badge,
  Component? footer,
}) {
  return NavigationBar(
    id: 'nav',
    mode: mode,
    labelMode: labelMode,
    selectedIndex: 0,
    onSelected: (_) {},
    footer: footer,
    items: [
      CoreNavigationBarItem.destination(
        icon: const Icon(LucideIcons.inbox),
        label: 'Inbox',
        badge: badge,
      ),
      const CoreNavigationBarItem.label('Workspace'),
      const CoreNavigationBarItem.destination(
        icon: Icon(LucideIcons.search),
        label: 'Search',
        enabled: false,
      ),
    ],
  );
}

/// The selected tile face both platforms read off Core (#6358).
const CoreColor _selectedFace = CoreNavigationBarStyle.defaultSelectedFaceColor;

void main() {
  group('the per-mode density table reaches the resolver', () {
    testComponents('sidebar draws its own density', (tester) async {
      final resolved = _resolve(tester, CoreNavigationBarMode.sidebar);

      expect(
        _inline(resolved.root)['padding'],
        const CoreEdgeInsets.symmetric(vertical: 16, horizontal: 12).toValue(),
      );
      expect(_inline(resolved.root)['gap'], spaceCss(2));
      for (final state in [
        resolved.destinationSelected,
        resolved.destinationEnabledIdle,
        resolved.destinationDisabled,
      ]) {
        expect(_inline(state)['min-height'], '2.5rem');
        expect(
          _inline(state)['padding'],
          const CoreEdgeInsets.symmetric(
            vertical: 10,
            horizontal: 12,
          ).toValue(),
        );
      }
      expect(_inline(resolved.inner)['gap'], spaceCss(10));
      expect(_inline(resolved.icon)['width'], '1.25rem');
      expect(resolved.iconStyle.size, 20);
      for (final label in [resolved.label, resolved.labelSelected]) {
        expect(_classes(label), contains('text-label-large'));
      }
      // The selected weight (bold) stays an overlay on the new role.
      expect(
        _inline(resolved.labelSelected)['font-weight'],
        '${CoreFontWeight.bold}',
      );
      // A row — the label beside the icon — paints the selected tile face
      // every placement paints (#6358).
      expect(
        _classes(resolved.destinationSelected),
        contains('bg-${_selectedFace.tailwindColor}'),
      );
    });

    for (final mode in [
      CoreNavigationBarMode.bar,
      CoreNavigationBarMode.rail,
    ]) {
      testComponents('${mode.name} keeps the flat defaults', (tester) async {
        final resolved = _resolve(tester, mode);

        expect(
          _inline(resolved.destinationEnabledIdle)['min-height'],
          '4.0rem',
        );
        expect(_inline(resolved.icon)['width'], '1.5rem');
        expect(_classes(resolved.label), contains('text-label-small'));
        // The rail (`fill`) paints the selected tile face (#6358); the bar
        // (`color`) paints none (#6393).
        expect(
          _classes(resolved.destinationSelected),
          mode == CoreNavigationBarMode.rail
              ? contains('bg-${_selectedFace.tailwindColor}')
              : isNot(contains('bg-${_selectedFace.tailwindColor}')),
        );
      });
    }

    testComponents('an instance value outranks the mode cell', (tester) async {
      final resolved = _resolve(
        tester,
        CoreNavigationBarMode.sidebar,
        style: const CoreNavigationBarStyle(
          padding: CoreEdgeInsets.all(CoreSpace.space4),
          itemMinHeight: CoreSize.size40,
          itemPadding: CoreEdgeInsets.all(CoreSpace.space6),
          iconStyle: CoreIconStyle(size: CoreIconSize.size20),
          labelSpacing: CoreSpace.space8,
          labelTextStyle: CoreTextStyle.token(CoreTextStyles.labelMedium),
          selectedBackgroundColor: CoreColor.token(CoreColors.surface),
        ),
      );

      expect(
        _inline(resolved.root)['padding'],
        const CoreEdgeInsets.all(CoreSpace.space4).toValue(),
      );
      expect(_inline(resolved.destinationEnabledIdle)['min-height'], '2.5rem');
      expect(
        _inline(resolved.destinationEnabledIdle)['padding'],
        const CoreEdgeInsets.all(CoreSpace.space6).toValue(),
      );
      expect(_inline(resolved.icon)['width'], '1.25rem');
      expect(_inline(resolved.inner)['gap'], spaceCss(8));
      expect(_classes(resolved.destinationSelected), contains('bg-surface'));
      // The instance's role reaches the slot it states; the selected state
      // keeps the mode cell's role.
      expect(_classes(resolved.label), contains('text-label-medium'));
      expect(_classes(resolved.labelSelected), contains('text-label-large'));
    });
  });

  group('the bar reads its own tones', () {
    for (final mode in CoreNavigationBarMode.values) {
      // The bottom bar sits on the page's own tone (its mode cell); the rail
      // and the sidebar on the chrome tier (the variant face).
      final face = mode == CoreNavigationBarMode.bar
          ? 'bg-surface'
          : 'bg-surface-container-low';
      testComponents('${mode.name} sits on $face', (tester) async {
        final resolved = _resolve(tester, mode);

        expect(_classes(resolved.root), contains(face));
        expect(
          _classes(resolved.destinationDisabled),
          contains('text-disabled-content'),
        );
        expect(
          resolved.disabledIconStyle.color,
          const CoreColor.token(CoreColors.disabledContent),
        );
        expect(
          _classes(resolved.sectionLabel),
          contains('text-on-surface-subtle'),
        );
        expect(
          _inline(resolved.sectionLabel)['padding'],
          const CoreEdgeInsets.fromLTRB(10, 18, 10, 6).toValue(),
        );
      });
    }
  });

  group('the docked bar consumes the bottom safe area', () {
    testComponents('bar adds env(safe-area-inset-bottom) to its bottom', (
      tester,
    ) async {
      final inline = _inline(_resolve(tester, CoreNavigationBarMode.bar).root);

      expect(
        inline['padding'],
        const CoreEdgeInsets.symmetric(vertical: 8, horizontal: 12).toValue(),
      );
      expect(
        inline['padding-bottom'],
        'calc(${spaceCss(CoreSpace.space8)} + env(safe-area-inset-bottom))',
      );
      // After the shorthand, so the cascade lets it win.
      final keys = inline.keys.toList();
      expect(
        keys.indexOf('padding-bottom'),
        greaterThan(keys.indexOf('padding')),
      );
    });

    for (final mode in [
      CoreNavigationBarMode.rail,
      CoreNavigationBarMode.sidebar,
    ]) {
      testComponents('${mode.name} takes none', (tester) async {
        final inline = _inline(_resolve(tester, mode).root);

        expect(inline.containsKey('padding-bottom'), isFalse);
      });
    }

    testComponents('a bar detached by barMargin takes none', (tester) async {
      final inline = _inline(
        _resolve(
          tester,
          CoreNavigationBarMode.bar,
          style: const CoreNavigationBarStyle(
            barMargin: CoreEdgeInsets.all(CoreSpace.space8),
          ),
        ).root,
      );

      expect(inline.containsKey('padding-bottom'), isFalse);
    });
  });

  group('a destination badge and its name', () {
    testServer('a sidebar row carries the badge at its trailing end', (
      tester,
    ) async {
      tester.pumpComponent(_host(_bar(CoreNavigationBarMode.sidebar)));
      final document = (await tester.request('/')).document!;
      final badge = document.getElementById('nav-item-0-badge')!;

      expect(badge.attributes['style'], contains('margin-inline-start: auto'));
      expect(badge.text, '3');
    });

    for (final mode in [
      CoreNavigationBarMode.bar,
      CoreNavigationBarMode.rail,
    ]) {
      testServer('${mode.name} lays the badge over the icon', (tester) async {
        tester.pumpComponent(_host(_bar(mode)));
        final document = (await tester.request('/')).document!;
        final badge = document.getElementById('nav-item-0-badge')!;
        final overlay = badge.parent!;

        expect(overlay.attributes['style'], contains('right: -0.375rem'));
        expect(overlay.attributes['style'], contains('top: -0.375rem'));
      });
    }

    for (final mode in CoreNavigationBarMode.values) {
      for (final labelMode in [
        CoreNavigationLabelMode.all,
        CoreNavigationLabelMode.none,
      ]) {
        testServer('${mode.name} / labels ${labelMode.name} names the '
            'destination once, label then badge', (tester) async {
          tester.pumpComponent(_host(_bar(mode, labelMode: labelMode)));
          final document = (await tester.request('/')).document!;
          final buttons = document.querySelectorAll('[data-coui-nav-index]');

          expect(buttons, hasLength(2));
          final first = buttons.first;
          expect(first.attributes['aria-label'], isNull);
          expect(
            first.attributes['aria-labelledby'],
            'nav-item-0-label nav-item-0-badge',
          );
          expect(document.getElementById('nav-item-0-label')!.text, 'Inbox');
          expect(document.getElementById('nav-item-0-badge')!.text, '3');
          expect(
            buttons.last.attributes['aria-labelledby'],
            'nav-item-1-label',
          );
        });
      }
    }

    testServer('a hidden label stays in the tree to name the destination', (
      tester,
    ) async {
      tester.pumpComponent(
        _host(
          _bar(CoreNavigationBarMode.rail, labelMode: .none, badge: null),
        ),
      );
      final document = (await tester.request('/')).document!;
      final label = document.getElementById('nav-item-0-label')!;

      expect(label.classes, containsAll(['sr-only', 'fixed']));
      expect(label.text, 'Inbox');
    });
  });

  group('the footer', () {
    for (final mode in CoreNavigationBarMode.values) {
      testServer('${mode.name} places it inside the bar after the items', (
        tester,
      ) async {
        tester.pumpComponent(
          _host(
            _bar(
              mode,
              footer: const div(id: 'footer', [Text('Plan')]),
            ),
          ),
        );
        final document = (await tester.request('/')).document!;
        final nav = document.getElementById('nav')!;
        final children = nav.children;

        expect(children, hasLength(2));
        expect(children.last.id, 'footer');
        expect(
          children.first.querySelectorAll('[data-coui-nav-index]'),
          hasLength(2),
        );
        expect(children.first.attributes['style'], contains('flex: 1 1 auto'));
        // The face, hairline and padding stay on the bar itself.
        expect(
          nav.classes,
          contains(
            mode == CoreNavigationBarMode.bar
                ? 'bg-surface'
                : 'bg-surface-container-low',
          ),
        );
        expect(nav.attributes['style'], contains('padding'));
      });
    }

    testServer('without a footer the bar keeps its single layout', (
      tester,
    ) async {
      tester.pumpComponent(_host(_bar(CoreNavigationBarMode.sidebar)));
      final document = (await tester.request('/')).document!;
      final nav = document.getElementById('nav')!;

      expect(
        nav.children.where((c) => c.attributes['data-coui-nav-index'] != null),
        hasLength(2),
      );
    });
  });
}
