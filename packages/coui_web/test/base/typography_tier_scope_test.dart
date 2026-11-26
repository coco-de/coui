// The typography tier's handles on Web — the attribute `CoUIWeb` writes on
// the document, the wrapper `TypographyTierScope` puts around a subtree, and
// the components that state their own tier with it.
//
// The rules those attributes switch are `typography_tier_css_test.dart`'s;
// this file pins only that the attribute lands where the rules look for it.
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:jaspr_test/server_test.dart' show testServer;

import '../helpers/html_attributes.dart';
import '../helpers/panel_openers.dart';
import '../helpers/pump_with_theme.dart';

/// The attribute a pin writes — spelled out rather than read from
/// `kTypographyTierAttribute`, so the test is a second source for it.
const String _kAttribute = 'data-coui-typography-tier';

/// Collects every [TypographyTierScope] in a built-but-unmounted tree —
/// the time picker's panel only mounts once it opens, which this harness
/// cannot do, but `Popover` keeps the built panel as a field.
List<TypographyTierScope> _scopesIn(Component component) {
  final found = <TypographyTierScope>[];
  void visit(Component node) {
    if (node is TypographyTierScope) {
      found.add(node);
      visit(node.child);
      return;
    }
    if (node is DomComponent) node.children?.forEach(visit);
  }

  visit(component);
  return found;
}

/// Counts the segment `<input>`s — one per numeric segment — in [component].
int _segmentsIn(Component component) {
  var count = 0;
  void visit(Component node) {
    if (node is DomComponent && node.tag == 'input') {
      count++;
      return;
    }
    if (node is TypographyTierScope) visit(node.child);
    if (node is DomComponent) node.children?.forEach(visit);
  }

  visit(component);
  return count;
}

/// The typography tier the app declares on `<html>` — what jaspr puts on
/// the document — or `null` when it declares none.
String? _declaredTier(ComponentTester tester) =>
    declaredHtmlAttributes(tester)[_kAttribute];

/// A `CoUIWeb` pinned to desktop, with a button that rebuilds it with no
/// tier and back.
class _PinToggle extends StatefulComponent {
  const _PinToggle();

  @override
  State<_PinToggle> createState() => _PinToggleState();
}

class _PinToggleState extends State<_PinToggle> {
  CoreBreakpointTier? _tier = .desktop;

  @override
  Component build(BuildContext context) => CoUIWeb(
    theme: .coui,
    typographyTier: _tier,
    child: button(
      const [],
      onClick: () => setState(() => _tier = _tier == null ? .desktop : null),
    ),
  );
}

/// How many times a [_CountedPanel] has been mounted. A panel that is
/// mounted again has lost what its state held — focus, scroll, an input's
/// text.
int _panelMounts = 0;

/// Panel content that counts its mounts in [_panelMounts].
class _CountedPanel extends StatefulComponent {
  const _CountedPanel();

  @override
  State<_CountedPanel> createState() => _CountedPanelState();
}

class _CountedPanelState extends State<_CountedPanel> {
  @override
  void initState() {
    super.initState();
    _panelMounts++;
  }

  @override
  Component build(BuildContext context) => const Text('panel');
}

/// A [TypographyTierScope] whose tier the test changes — [onReady] hands
/// it the setter once the scope is mounted.
class _TierSwitch extends StatefulComponent {
  const _TierSwitch({
    required this.initial,
    required this.onReady,
    required this.child,
  });

  final CoreBreakpointTier initial;
  final void Function(void Function(CoreBreakpointTier tier) setTier) onReady;
  final Component child;

  @override
  State<_TierSwitch> createState() => _TierSwitchState();
}

class _TierSwitchState extends State<_TierSwitch> {
  late CoreBreakpointTier _tier = component.initial;

  @override
  void initState() {
    super.initState();
    component.onReady((tier) => setState(() => _tier = tier));
  }

  @override
  Component build(BuildContext context) =>
      TypographyTierScope(tier: _tier, child: component.child);
}

void main() {
  group('CoUIWeb writes a pinned tier on <html>', () {
    testServer('a stated tier is on the server-rendered document', (
      tester,
    ) async {
      tester.pumpComponent(
        CoUIWeb(theme: .coui, typographyTier: .desktop, child: const div([])),
      );
      final response = await tester.request('/');
      final html = response.document?.documentElement;
      expect(html?.attributes[_kAttribute], 'desktop');
    });

    testServer('no tier writes nothing, so the viewport chooses', (
      tester,
    ) async {
      tester.pumpComponent(CoUIWeb(theme: .coui, child: const div([])));
      final response = await tester.request('/');
      final html = response.document?.documentElement;
      expect(html?.attributes.containsKey(_kAttribute), isFalse);
    });

    testServer("no tier leaves a host page's pin on the document", (
      tester,
    ) async {
      // A host that pins the tier itself — its own `Document.html`, as a
      // page outside any CoUIWeb island would — keeps it through an island
      // that states none.
      tester.pumpComponent(
        Component.fragment([
          const Document.html(attributes: {_kAttribute: 'mobile'}),
          CoUIWeb(theme: .coui, child: const div([])),
        ]),
      );
      final response = await tester.request('/');
      final html = response.document?.documentElement;
      expect(html?.attributes[_kAttribute], 'mobile');
    });
  });

  group('CoUIWeb lifts a pin it wrote', () {
    testComponents('rebuilt with no tier, the document names none', (
      tester,
    ) async {
      tester.pumpComponent(const _PinToggle());
      expect(_declaredTier(tester), 'desktop');

      await tester.click(find.tag('button'));
      final lifted = _declaredTier(tester);
      // On the client jaspr keeps every attribute a `Document.html` ever
      // declared on `<html>`, so leaving it out would keep the pin. A value
      // that names no tier is one the viewport rules take.
      expect(lifted, isNotNull);
      expect(
        CoreBreakpointTier.values.map((tier) => tier.name),
        isNot(contains(lifted)),
        reason: 'a lifted pin names no tier',
      );

      await tester.click(find.tag('button'));
      expect(_declaredTier(tester), 'desktop');
    });
  });

  group('TypographyTierScope pins a subtree', () {
    testServer('a wrapper with no box carries the tier', (tester) async {
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          child: const TypographyTierScope(
            tier: .mobile,
            child: div([], id: 'inside'),
          ),
        ),
      );
      final response = await tester.request('/');
      final scope = response.document?.querySelector('[$_kAttribute]');
      expect(scope, isNotNull);
      expect(scope!.attributes[_kAttribute], 'mobile');
      expect(scope.attributes['style'], contains('display: contents'));
      expect(scope.querySelector('#inside'), isNotNull);
    });
  });

  group('a panel opened inside a scope renders at its tier', () {
    // The panel is portalled to the overlay host, outside the scope's
    // wrapper, so the attribute around the trigger does not reach it. The
    // component states the scope again around the panel — what Flutter's
    // `InheritedTheme.capture` does for a panel opened there.

    /// The tiers the elements around [finder] name, nearest first — what
    /// the stylesheet's rules see from inside the panel.
    List<String> tiersAround(Finder finder) => [
      for (final element
          in find
              .ancestor(
                of: finder,
                matching: find.byComponentPredicate(
                  (component) =>
                      component is div &&
                      (component.attributes?.containsKey(_kAttribute) ?? false),
                ),
              )
              .evaluate())
        (element.component as div).attributes![_kAttribute]!,
    ];

    /// A popover opened from inside [around], its panel holding [panel].
    Future<void> openPopover(
      ComponentTester tester,
      Component Function(Component popover) around, {
      Component panel = const Text('panel'),
    }) async {
      final controller = PopoverController();
      tester.pumpComponent(
        around(
          Popover(
            controller: controller,
            trigger: const Text('trigger'),
            content: panel,
          ),
        ),
      );
      await tester.pump();
      controller.show();
      await tester.pump();
      await tester.pump();
    }

    testComponents('a popover', (tester) async {
      await openPopover(
        tester,
        (popover) =>
            hosted(TypographyTierScope(tier: .desktop, child: popover)),
      );

      expect(tiersAround(find.text('trigger')), ['desktop']);
      // One pin only: the trigger's scope is not an ancestor of the panel,
      // so this is the one stated again around it.
      expect(tiersAround(find.text('panel')), ['desktop']);
    });

    testComponents('a dialog, and a popover opened inside it', (
      tester,
    ) async {
      // The dialog's content renders in the host's layer too, so the scope
      // the popover inside it finds is the one stated around the dialog.
      final controller = PopoverController();
      tester.pumpComponent(
        hosted(
          TypographyTierScope(
            tier: .mobile,
            child: Dialog(
              title: const Text('title'),
              content: Popover(
                controller: controller,
                trigger: const Text('trigger'),
                content: const Text('panel'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      controller.show();
      await tester.pump();
      await tester.pump();

      expect(tiersAround(find.text('title')), ['mobile']);
      expect(tiersAround(find.text('panel')), ['mobile']);
    });

    testComponents('no scope states nothing around the panel', (tester) async {
      await openPopover(tester, hosted);

      expect(find.text('panel'), findsOneComponent);
      expect(tiersAround(find.text('panel')), isEmpty);
    });

    testComponents('a scope around the host is not stated twice', (
      tester,
    ) async {
      // The host's layers are inside that scope already — a preview pane
      // that pins its whole app is one.
      await openPopover(
        tester,
        (popover) =>
            TypographyTierScope(tier: .desktop, child: hosted(popover)),
      );

      expect(tiersAround(find.text('panel')), ['desktop']);
    });

    testComponents('the nearer scope is the one stated', (tester) async {
      await openPopover(
        tester,
        (popover) => TypographyTierScope(
          tier: .desktop,
          child: hosted(TypographyTierScope(tier: .mobile, child: popover)),
        ),
      );

      expect(tiersAround(find.text('panel')), ['mobile', 'desktop']);
    });

    testComponents(
      "an open panel keeps its state when its tier meets the host's",
      (tester) async {
        // Whether the scope is stated again depends on where the scope sits,
        // not on its tier: a wrapper that dropped out once the tier equals
        // the host's would remount the open panel.
        _panelMounts = 0;
        late void Function(CoreBreakpointTier tier) setTier;
        await openPopover(
          tester,
          (popover) => TypographyTierScope(
            tier: .desktop,
            child: hosted(
              _TierSwitch(
                initial: .mobile,
                onReady: (set) => setTier = set,
                child: popover,
              ),
            ),
          ),
          panel: const _CountedPanel(),
        );
        expect(_panelMounts, 1);
        expect(tiersAround(find.text('panel')), ['mobile', 'desktop']);

        setTier(.desktop);
        await tester.pump();
        await tester.pump();
        expect(_panelMounts, 1, reason: 'the panel was not mounted again');
        expect(tiersAround(find.text('panel')), ['desktop', 'desktop']);

        setTier(.mobile);
        await tester.pump();
        await tester.pump();
        expect(_panelMounts, 1, reason: 'the panel was not mounted again');
        expect(tiersAround(find.text('panel')), ['mobile', 'desktop']);
      },
    );

    // Every component that portals a panel states the scope again around
    // it. ContextMenu opens only on a browser `contextmenu` event, which the
    // VM cannot build — the Chrome probe (`typography_tier_probe_test.dart`)
    // opens that one.
    for (final opener in panelOpeners) {
      testComponents('${opener.name} states the scope around its panel', (
        tester,
      ) async {
        await opener.open(
          tester,
          (child) => hosted(TypographyTierScope(tier: .desktop, child: child)),
        );

        expect(find.text(opener.panel), findsOneComponent);
        expect(
          hostLayerAround(find.text(opener.panel)),
          isNotNull,
          reason: 'the panel is portalled, not rendered under the scope',
        );
        expect(tiersAround(find.text(opener.panel)), ['desktop']);
      });
    }
  });

  group('a box that its text fills holds the desktop tier', () {
    for (final (size, role) in [
      (CoreComponentSize.xl, 'headline-small'),
      (CoreComponentSize.xl2, 'headline-large'),
    ]) {
      testServer('Avatar ${size.name} initials (text-$role)', (tester) async {
        tester.pumpComponent(
          CoUIWeb(
            theme: .coui,
            child: Avatar(initials: 'JD', size: size),
          ),
        );
        final response = await tester.request('/');
        final initials = response.document?.querySelector(
          '[$_kAttribute="desktop"] .text-$role',
        );
        expect(
          initials,
          isNotNull,
          reason: 'the initials sit inside a desktop pin',
        );
        expect(initials!.text, 'JD');
      });
    }

    testServer('the Avatar pin sits inside its box, not around it', (
      tester,
    ) async {
      // Around the root it would be the sibling a parent's `space-x-*` or
      // `:first-child` reaches — a wrapper with no box takes no margin.
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          child: div([
            Avatar(id: 'avatar', initials: 'JD', size: .xl2),
          ], id: 'row'),
        ),
      );
      final response = await tester.request('/');
      final row = response.document!.querySelector('#row')!;
      expect(row.children.single.id, 'avatar');
      expect(
        row.querySelector('#avatar [$_kAttribute="desktop"]'),
        isNotNull,
      );
    });

    testServer('the Avatar badge slot is inside a pin too', (tester) async {
      // The Flutter twin pins the whole avatar, badge included, so a
      // caller's heading in the badge draws at desktop on both platforms.
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          child: Avatar(
            initials: 'JD',
            size: .xl,
            badge: const span([Text('9')], id: 'badge'),
          ),
        ),
      );
      final response = await tester.request('/');
      expect(
        response.document?.querySelector('[$_kAttribute="desktop"] #badge'),
        isNotNull,
      );
    });

    testComponents('TimePicker digits, inside the panel', (tester) async {
      pumpWithTheme(
        tester,
        const TimePicker(value: '14:30:45', showSeconds: true),
      );
      final popover =
          find.byType(Popover).evaluate().single.component as Popover;
      // The panel is portalled to the overlay host, outside anything that
      // wraps the picker — so the pin is in the panel's own content.
      final scopes = _scopesIn(popover.content);
      expect(scopes, hasLength(1));
      expect(scopes.single.tier, CoreBreakpointTier.desktop);
      expect(
        _segmentsIn(scopes.single.child),
        3,
        reason: 'hour, minute and second sit inside the pin',
      );
    });
  });
}
