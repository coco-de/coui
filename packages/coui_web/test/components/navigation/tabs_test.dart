import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/components/control/button/button.dart';
import 'package:coui_web/src/components/display/badge/badge.dart';
import 'package:coui_web/src/components/infra/clickable/clickable.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:coui_web/src/components/navigation/tabs/tab_pane.dart';
import 'package:coui_web/src/components/navigation/tabs/tabs.dart';
import 'package:coui_web/src/components/navigation/tabs/tabs_style.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/jaspr.dart' hide Text;
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// The per-tab Clickables carrying the `flex-1` spread class.
final Finder _spreadTabs = find.byComponentPredicate(
  (component) =>
      component is Clickable &&
      (component.classes ?? '').split(' ').contains(WebLayout.flex1),
  description: 'a tab Clickable with flex-1',
);

void main() {
  group('Tabs', () {
    testComponents('renders every tab label', (tester) async {
      pumpWithTheme(
        tester,
        const Tabs(
          tabs: [
            CoreTabItem<Component>(label: 'Account'),
            CoreTabItem<Component>(label: 'Password'),
          ],
          selectedIndex: 0,
        ),
      );

      expect(find.text('Account'), findsOneComponent);
      expect(find.text('Password'), findsOneComponent);
    });

    testComponents('renders via Tabs.labels convenience constructor', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Tabs.labels(labels: const ['One', 'Two'], selectedIndex: 1),
      );

      expect(find.text('One'), findsOneComponent);
      expect(find.text('Two'), findsOneComponent);
    });

    // The underline rule belongs to the tab-bar box: the ruled
    // `role="tablist"` root carries the full-width layout token in BOTH
    // `expand` states (the tabs inside keep hugging when `expand` is
    // false — `flex-1` on each Clickable stays gated), while the pill
    // track keeps hugging its tabs unless `expand` is set. Mirrors the
    // Flutter `Align(centerStart)` around a `.min` row inside the ruled
    // `DecoratedBox`.
    testComponents('underline root is full-width in both expand states', (
      tester,
    ) async {
      late ResolvedTabs hugging;
      late ResolvedTabs expanded;
      late ResolvedTabs pillHugging;
      pumpWithTheme(
        tester,
        Builder(
          builder: (context) {
            hugging = resolveTabs(
              context,
              variant: CoreTabVariant.underline,
              expand: false,
            );
            expanded = resolveTabs(
              context,
              variant: CoreTabVariant.underline,
              expand: true,
            );
            pillHugging = resolveTabs(
              context,
              variant: CoreTabVariant.pill,
              expand: false,
            );
            return const Component.text('ok');
          },
        ),
      );

      expect(hugging.root.className.split(' '), contains(WebLayout.wFull));
      expect(expanded.root.className.split(' '), contains(WebLayout.wFull));
      expect(
        pillHugging.root.className.split(' '),
        isNot(contains(WebLayout.wFull)),
      );
    });

    // The other half of the rule above: the full-width ruled root must
    // not drag the tabs with it. `flex-1` on each tab's Clickable stays
    // gated on `expand`, so a hugging bar keeps hugging tabs at the start
    // of the rule — and an expanded one spreads them.
    testComponents('a hugging underline bar keeps its tabs off flex-1', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Tabs(
          tabs: [
            CoreTabItem<Component>(label: 'Account'),
            CoreTabItem<Component>(label: 'Password'),
          ],
          selectedIndex: 0,
          variant: CoreTabVariant.underline,
        ),
      );

      expect(find.byType(Clickable), findsNComponents(2));
      expect(_spreadTabs, findsNothing);
    });

    testComponents('an expanded underline bar spreads its tabs', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Tabs(
          tabs: [
            CoreTabItem<Component>(label: 'Account'),
            CoreTabItem<Component>(label: 'Password'),
          ],
          selectedIndex: 0,
          variant: CoreTabVariant.underline,
          expand: true,
        ),
      );

      expect(_spreadTabs, findsNComponents(2));
    });

    test('accepts custom id', () {
      const tabs = Tabs(
        tabs: [CoreTabItem<Component>(label: 'A')],
        selectedIndex: 0,
        id: 'tabs-1',
      );
      expect(tabs.id, equals('tabs-1'));
    });

    test('copyWith preserves properties', () {
      // A non-default variant, so the copy is seen to carry it.
      const original = Tabs(
        tabs: [CoreTabItem<Component>(label: 'A')],
        selectedIndex: 0,
        variant: CoreTabVariant.underline,
        expand: true,
        id: 'tabs-orig',
      );

      final copy = original.copyWith(selectedIndex: 0, id: 'tabs-new');

      expect(copy.id, equals('tabs-new'));
      expect(copy.variant, equals(CoreTabVariant.underline));
      expect(copy.expand, isTrue);
    });

    test('implements CoreTabsContract', () {
      const tabs = Tabs(
        tabs: [
          CoreTabItem<Component>(label: 'A'),
          CoreTabItem<Component>(label: 'B', enabled: false),
        ],
        selectedIndex: 1,
      );

      expect(tabs, isA<CoreTabsContract<Component>>());
      expect(tabs.selectedIndex, equals(1));
      expect(tabs.tabs.last.enabled, isFalse);
    });

    // `CoreTabItem.badge` is a composition slot: the caller supplies the
    // styled component, the tab composes it after the label behind a
    // 1-off `Gap` carrying the resolver's `labelBadgeGapStyle` forward —
    // the same shape the Flutter `_labelWithBadge` row renders. An item
    // without a badge composes no `Gap` at all.
    group('badge slot', () {
      Finder labelBadgeGap(CoreGapStyle style) => find.byComponentPredicate(
        (component) => component is Gap && component.gapStyle == style,
        description: 'the label↔badge Gap carrying $style',
      );

      for (final variant in CoreTabVariant.values) {
        testComponents(
          '$variant renders the badge after the label behind a Gap',
          (
            tester,
          ) async {
            pumpWithTheme(
              tester,
              Tabs(
                tabs: const [
                  CoreTabItem<Component>(
                    label: 'Inbox',
                    badge: Badge(child: Text('3')),
                  ),
                  CoreTabItem<Component>(label: 'Sent'),
                ],
                selectedIndex: 0,
                variant: variant,
              ),
            );

            expect(find.byType(Badge), findsOneComponent);
            expect(find.text('3'), findsOneComponent);
            // One Gap for the one badge — the plain tab composes none.
            expect(
              labelBadgeGap(CoreTabsStyle.defaultLabelBadgeGapStyle),
              findsOneComponent,
            );
          },
        );
      }

      testComponents('a tabsStyle override reaches the Gap', (tester) async {
        const override = CoreGapStyle(size: CoreSpace.space12);
        pumpWithTheme(
          tester,
          const Tabs(
            tabs: [
              CoreTabItem<Component>(
                label: 'Inbox',
                badge: Badge(child: Text('3')),
              ),
            ],
            selectedIndex: 0,
            tabsStyle: CoreTabsStyle(labelBadgeGapStyle: override),
          ),
        );

        expect(
          labelBadgeGap(
            CoreTabsStyle.defaultLabelBadgeGapStyle.merge(override),
          ),
          findsOneComponent,
        );
      });

      testComponents('an item without a badge composes no Gap', (
        tester,
      ) async {
        pumpWithTheme(
          tester,
          const Tabs(
            tabs: [
              CoreTabItem<Component>(label: 'Account'),
              CoreTabItem<Component>(label: 'Password'),
            ],
            selectedIndex: 0,
          ),
        );

        expect(find.byType(Badge), findsNothing);
        expect(
          labelBadgeGap(CoreTabsStyle.defaultLabelBadgeGapStyle),
          findsNothing,
        );
      });

      testComponents('TabPane renders the badge behind its own Gap slot', (
        tester,
      ) async {
        pumpWithTheme(
          tester,
          const TabPane(
            tabs: [
              CoreTabItem<Component>(
                label: 'Inbox',
                badge: Badge(child: Text('3')),
              ),
              CoreTabItem<Component>(label: 'Sent'),
            ],
            selectedIndex: 0,
          ),
        );

        expect(find.byType(Badge), findsOneComponent);
        expect(
          labelBadgeGap(CoreTabPaneStyle.defaultLabelBadgeGapStyle),
          findsOneComponent,
        );
      });
    });

    // `tabPadding` is the chip's padding: the element that carries it holds
    // the whole chip — leading, label, trailing and the close × — so the ×
    // is measured from the chip edge like the label is (the Flutter twin and
    // the Figma tab frame wrap the same box). The select `Clickable` stays
    // the label region only, so the × never selects.
    group('TabPane tabPadding wraps the whole chip', () {
      // Symmetric padding is the `padding` shorthand; the editorStrip's is
      // directional, so it is the logical longhands (`padding-inline-*`).
      final paddedChip = find.byComponentPredicate(
        (c) =>
            c is DomComponent &&
            c.tag == 'span' &&
            ((c.styles?.properties ?? const {}).containsKey('padding') ||
                (c.styles?.properties ?? const {}).containsKey(
                  'padding-inline-start',
                )),
        description: 'the tab chip <span> carrying tabPadding',
      );

      testComponents('the close × and trailing sit inside the padded chip', (
        tester,
      ) async {
        pumpWithTheme(
          tester,
          TabPane(
            variant: .editorStrip,
            tabs: [
              CoreTabItem<Component>(
                label: 'main.dart',
                trailing: const Component.text('T'),
                onClose: () {},
              ),
            ],
            selectedIndex: 0,
            onChanged: (index) {},
          ),
        );

        expect(paddedChip, findsOneComponent);
        expect(
          find.descendant(of: paddedChip, matching: find.text('main.dart')),
          findsOneComponent,
        );
        expect(
          find.descendant(of: paddedChip, matching: find.text('T')),
          findsOneComponent,
        );
        expect(
          find.descendant(of: paddedChip, matching: find.byType(Button)),
          findsOneComponent,
        );
        // …and outside the select Clickable, which holds the label only.
        expect(
          find.descendant(
            of: find.byType(Clickable),
            matching: find.byType(Button),
          ),
          findsNothing,
        );
      });
    });

    // The tab is an underline tab in a bordered card (parity with the Flutter
    // twin): the root IS the card, the focused tab `<span>` carries no face and
    // no outline, and the tablist sits flush on the card's top, inset only by
    // the stated bar padding.
    group('TabPane fused outline', () {
      DomComponent domWhere(bool Function(DomComponent c) test) => find
          .byType(DomComponent)
          .evaluate()
          .map((e) => e.component as DomComponent)
          .firstWhere(test);

      Map<String, String> inline(DomComponent c) =>
          c.styles?.properties ?? const {};

      void pumpPane(ComponentTester tester) => pumpWithTheme(
        tester,
        TabPane(
          tabs: const [
            CoreTabItem<Component>(label: 'Account'),
            CoreTabItem<Component>(label: 'Password'),
          ],
          selectedIndex: 0,
          onChanged: (index) {},
        ),
      );

      testComponents('the focused tab carries no outline and no rounded face', (
        tester,
      ) async {
        pumpPane(tester);

        final tabs = find
            .byType(DomComponent)
            .evaluate()
            .map((e) => e.component as DomComponent)
            .where(
              (c) =>
                  c.tag == 'span' &&
                  inline(c).containsKey('padding') &&
                  (c.classes ?? '').split(' ').contains(WebLayout.selfStretch),
            );
        expect(tabs, isNotEmpty);
        for (final tab in tabs) {
          expect(inline(tab).containsKey('border-width'), isFalse);
          expect(inline(tab).containsKey('border-radius'), isFalse);
          expect((tab.classes ?? '').split(' '), isNot(contains('border')));
        }
      });

      testComponents('the root is the card and the tablist sits flush on it', (
        tester,
      ) async {
        pumpPane(tester);

        final root = domWhere(
          (c) => (c.classes ?? '').split(' ').contains(WebLayout.flexCol),
        );
        expect((root.classes ?? '').split(' '), contains('border'));
        expect(inline(root)['isolation'], 'isolate');
        expect(inline(root)['border-radius'], isNotNull);
        expect(inline(root)['border-width'], isNotNull);

        final bar = domWhere((c) => c.attributes?['role'] == 'tablist');
        final styles = inline(bar);
        // Nothing is dropped onto the panel's rule or stacked above it.
        expect(styles.containsKey('transform'), isFalse);
        expect(styles.containsKey('z-index'), isFalse);
      });

      testComponents('the focused tab label reads differently from the '
          'unfocused', (tester) async {
        pumpPane(tester);

        final spans = find
            .byType(DomComponent)
            .evaluate()
            .map((e) => e.component as DomComponent)
            .where((c) => c.tag == 'span')
            .toList();
        String classesOf(DomComponent c) => c.classes ?? '';
        final textClasses = spans
            .map(
              (c) => classesOf(
                c,
              ).split(' ').where((x) => x.startsWith('text-')).toSet(),
            )
            .where((set) => set.isNotEmpty)
            .toList();
        expect(textClasses.length, greaterThanOrEqualTo(2));
        // The RESULT: the focused span and an unfocused one must not carry
        // the same text-colour class. Identical states are the picture this
        // pair exists to fix.
        expect(textClasses.first, isNot(textClasses[1]));
      });

      testComponents('a stated separator emits a logical edge', (
        tester,
      ) async {
        pumpWithTheme(
          tester,
          TabPane(
            tabs: const [
              CoreTabItem<Component>(label: 'Account'),
              CoreTabItem<Component>(label: 'Password'),
            ],
            selectedIndex: 0,
            onChanged: (index) {},
            tabPaneStyle: const CoreTabPaneStyle(
              tabSeparatorColor: CoreColor.token(CoreColors.outline),
            ),
          ),
        );

        final withRule = find
            .byType(DomComponent)
            .evaluate()
            .map((e) => e.component as DomComponent)
            .where((c) => inline(c).containsKey('border-inline-end'))
            .toList();
        expect(withRule, isNotEmpty);
        // Logical, never `border-right`: an RTL document must flip it.
        for (final c in withRule) {
          expect(inline(c).containsKey('border-right'), isFalse);
        }
      });

      testComponents('empty item slots emit no widget and no gap', (
        tester,
      ) async {
        pumpPane(tester);
        final before = find.byType(DomComponent).evaluate().length;

        pumpWithTheme(
          tester,
          TabPane(
            tabs: const [
              CoreTabItem<Component>(label: 'Account', leading: Text('L')),
              CoreTabItem<Component>(label: 'Password'),
            ],
            selectedIndex: 0,
            onChanged: (index) {},
          ),
        );
        final after = find.byType(DomComponent).evaluate().length;

        // The RESULT: stating one slot adds nodes, so the slot is really
        // rendered — and the earlier pane, which stated none, emitted
        // fewer. A slot that always emitted a Gap would make these equal
        // and the "no widget AND no gap" promise silently false.
        expect(after, greaterThan(before));
      });

      testComponents('leading and trailing slots state the 16 icon size', (
        tester,
      ) async {
        pumpWithTheme(
          tester,
          TabPane(
            tabs: const [
              CoreTabItem<Component>(
                label: 'Account',
                leading: Text('L'),
                trailing: Text('T'),
              ),
            ],
            selectedIndex: 0,
            onChanged: (index) {},
          ),
        );
        final slots = find
            .byType(DomComponent)
            .evaluate()
            .map((e) => e.component as DomComponent)
            .where((c) => inline(c)['font-size'] == '${16 / kRemDivisor}rem')
            .toList();
        // The leading and the trailing wrapper, one each.
        expect(slots, hasLength(2));
      });

      testComponents('the strip band paints only when it is asked for', (
        tester,
      ) async {
        pumpPane(tester);

        // Default is the `transparent` sentinel, and a transparent band
        // emits NOTHING — no class, no inert `background-color`. The
        // canvas twin's `fillData` drops an alpha-0 fill for the same
        // reason, so the two agree on the default path.
        final bare = domWhere((c) => c.attributes?['role'] == 'tablist');
        expect(inline(bare).containsKey('background-color'), isFalse);
        expect(
          (bare.classes ?? '').split(' ').where((c) => c.startsWith('bg-')),
          isEmpty,
        );
      });

      testComponents('a token band reaches the tablist as a class', (
        tester,
      ) async {
        pumpWithTheme(
          tester,
          TabPane(
            tabs: const [
              CoreTabItem<Component>(label: 'Account'),
              CoreTabItem<Component>(label: 'Password'),
            ],
            selectedIndex: 0,
            onChanged: (index) {},
            tabPaneStyle: const CoreTabPaneStyle(
              stripBackgroundColor: CoreColor.token(
                CoreColors.surfaceContainer,
              ),
            ),
          ),
        );

        final bar = domWhere((c) => c.attributes?['role'] == 'tablist');
        const band = CoreColor.token(CoreColors.surfaceContainer);
        expect(
          (bar.classes ?? '').split(' '),
          contains('bg-${band.tailwindColor}'),
        );
        // Token → class, never inline: the emit doctrine, and an inline
        // fill would beat any `hover:`/preset class on specificity.
        expect(inline(bar).containsKey('background-color'), isFalse);
      });

      testComponents('the tablist is padded by barPadding, 16 either side', (
        tester,
      ) async {
        pumpPane(tester);

        final bar = domWhere((c) => c.attributes?['role'] == 'tablist');
        expect(
          inline(bar)['padding'],
          CoreTabPaneStyle.boxed.barPadding!.toValue(),
        );
        expect(inline(bar).containsKey('padding-left'), isFalse);
      });
    });

    group('TabPane editorStrip', () {
      DomComponent domWhere(bool Function(DomComponent c) test) => find
          .byType(DomComponent)
          .evaluate()
          .map((e) => e.component as DomComponent)
          .firstWhere(test);

      Map<String, String> inline(DomComponent c) =>
          c.styles?.properties ?? const {};

      testComponents('does not render the content tabpanel', (tester) async {
        pumpWithTheme(
          tester,
          TabPane(
            variant: .editorStrip,
            tabs: const [
              CoreTabItem<Component>(
                label: 'main.dart',
                content: Text('SHOULD_NOT_RENDER'),
              ),
              CoreTabItem<Component>(label: 'pubspec.yaml'),
            ],
            selectedIndex: 0,
            onChanged: (index) {},
          ),
        );

        expect(find.text('main.dart'), findsOneComponent);
        expect(find.text('SHOULD_NOT_RENDER'), findsNothing);
        expect(
          find.byComponentPredicate(
            (c) => c is DomComponent && c.attributes?['role'] == 'tabpanel',
          ),
          findsNothing,
        );
        final bar = domWhere((c) => c.attributes?['role'] == 'tablist');
        expect(inline(bar).containsKey('transform'), isFalse);
      });

      testComponents('editorStrip chain getter sets variant', (tester) async {
        final pane = TabPane(
          tabs: const [CoreTabItem<Component>(label: 'a')],
          selectedIndex: 0,
          onChanged: (index) {},
        ).editorStrip;
        expect(pane.variant, CoreTabPaneVariant.editorStrip);
      });

      testComponents(
        'onClose Button is composed outside the select Clickable',
        (
          tester,
        ) async {
          pumpWithTheme(
            tester,
            TabPane(
              variant: .editorStrip,
              tabs: [
                CoreTabItem<Component>(
                  label: 'main.dart',
                  onClose: () {},
                ),
              ],
              selectedIndex: 0,
              onChanged: (index) {},
            ),
          );

          // Select Clickable is the tab role; close is a separate Button.
          final tabClickables = find.byComponentPredicate(
            (c) => c is Clickable && (c.userAttributes?['role'] == 'tab'),
          );
          expect(tabClickables, findsOneComponent);
          expect(find.byType(Button), findsOneComponent);
        },
      );
    });
  });

  group('Tabs redesign (2026-09-14)', () {
    // Resolved directly (mirrors 'underline root is full-width in both
    // expand states' above) rather than located by DOM position — a
    // `Text(item.label)` composes its own inner `<span>`, so scanning
    // for `tag == 'span'` finds 2 per tab (the chrome root and the
    // label's own), and picking by list index is exactly the kind of
    // DOM-shape assumption this file's other tests avoid.
    testComponents('a disabled tab reads text-disabled-content, an '
        'enabled one does not', (tester) async {
      late ResolvedTabsTab enabledTab;
      late ResolvedTabsTab disabledTab;
      pumpWithTheme(
        tester,
        Builder(
          builder: (context) {
            final bar = resolveTabs(context, variant: .pill, expand: false);
            enabledTab = resolveTabsTab(
              tabs: bar,
              variant: .pill,
              size: .defaultSize,
              active: false,
              enabled: true,
              expand: false,
            );
            disabledTab = resolveTabsTab(
              tabs: bar,
              variant: .pill,
              size: .defaultSize,
              active: false,
              enabled: false,
              expand: false,
            );
            return const Component.text('ok');
          },
        ),
      );

      expect(enabledTab.root.className, isNot(contains('disabled-content')));
      expect(disabledTab.root.className, contains('text-disabled-content'));
    });

    testComponents('a disabled selected pill fills with disabled-container, '
        'not the active indicator token and not the label ink', (tester) async {
      late ResolvedTabsTab activeEnabled;
      late ResolvedTabsTab activeDisabled;
      pumpWithTheme(
        tester,
        Builder(
          builder: (context) {
            final bar = resolveTabs(context, variant: .pill, expand: false);
            activeEnabled = resolveTabsTab(
              tabs: bar,
              variant: .pill,
              size: .defaultSize,
              active: true,
              enabled: true,
              expand: false,
            );
            activeDisabled = resolveTabsTab(
              tabs: bar,
              variant: .pill,
              size: .defaultSize,
              active: true,
              enabled: false,
              expand: false,
            );
            return const Component.text('ok');
          },
        ),
      );

      // `pill`'s active fill is `surface-raised` (`defaultsByVariant`) — an
      // active *disabled* tab must not still show it, and must not borrow
      // the label's ink token either: the pill is an AREA, so it takes
      // `disabled-container` (the designer's preview, and what the token's
      // own doc says `disabled-content` is not for).
      expect(
        activeEnabled.root.className.split(' '),
        contains('bg-surface-raised'),
      );
      expect(activeDisabled.root.className, contains('bg-disabled-container'));
      expect(activeDisabled.root.className, isNot(contains('bg-surface')));
      expect(
        activeDisabled.root.className,
        isNot(contains('bg-disabled-content')),
      );
    });

    testComponents('a disabled selected underline keeps the rule and takes '
        'disabled-content — ink, not the container fill', (tester) async {
      late ResolvedTabsTab activeDisabled;
      pumpWithTheme(
        tester,
        Builder(
          builder: (context) {
            final bar = resolveTabs(
              context,
              variant: .underline,
              expand: false,
            );
            activeDisabled = resolveTabsTab(
              tabs: bar,
              variant: .underline,
              size: .defaultSize,
              active: true,
              enabled: false,
              expand: false,
            );
            return const Component.text('ok');
          },
        ),
      );

      // The underline's indicator is a 2px painted rule, and ink. The
      // two variants take different disabled tokens on purpose; a single
      // shared one is what put a container colour on a rule (or an ink
      // colour on the pill) depending on which way it was unified.
      expect(
        activeDisabled.underlineIndicator!.className,
        contains('bg-disabled-content'),
      );
      expect(
        activeDisabled.underlineIndicator!.className,
        isNot(contains('bg-disabled-container')),
      );
    });

    testComponents('an enabled tab carries scoped hover/press fills, '
        'a disabled one does not', (tester) async {
      late ResolvedTabsTab enabledTab;
      late ResolvedTabsTab disabledTab;
      pumpWithTheme(
        tester,
        Builder(
          builder: (context) {
            final bar = resolveTabs(context, variant: .pill, expand: false);
            enabledTab = resolveTabsTab(
              tabs: bar,
              variant: .pill,
              size: .defaultSize,
              active: false,
              enabled: true,
              expand: false,
            );
            disabledTab = resolveTabsTab(
              tabs: bar,
              variant: .pill,
              size: .defaultSize,
              active: false,
              enabled: false,
              expand: false,
            );
            return const Component.text('ok');
          },
        ),
      );

      expect(enabledTab.root.className, contains('co-tabs-state-'));
      expect(
        enabledTab.root.inlineStyles!.properties['--co-tabs-token-hover-fill'],
        contains('rgb(var(--coui-on-surface)) 8%'),
      );
      expect(
        enabledTab
            .root
            .inlineStyles!
            .properties['--co-tabs-token-pressed-fill'],
        contains('rgb(var(--coui-on-surface)) 16%'),
      );
      expect(
        disabledTab.root.className,
        isNot(contains('co-tabs-state-')),
      );
      expect(
        disabledTab.root.inlineStyles!.properties['--co-tabs-token-hover-fill'],
        isNull,
      );
      expect(
        disabledTab
            .root
            .inlineStyles!
            .properties['--co-tabs-token-pressed-fill'],
        isNull,
      );
    });
  });

  group('Tabs variant rows', () {
    /// Resolves one tab of a [variant] bar (and the bar itself) under
    /// [tabsStyle].
    ({ResolvedTabs bar, ResolvedTabsTab tab}) resolveOne(
      BuildContext context, {
      required CoreTabVariant variant,
      required bool active,
      CoreTabsSize size = .md,
      CoreTabsStyle? tabsStyle,
    }) {
      final bar = resolveTabs(
        context,
        variant: variant,
        expand: false,
        tabsStyle: tabsStyle,
      );
      final tab = resolveTabsTab(
        tabs: bar,
        variant: variant,
        size: size,
        active: active,
        enabled: true,
        expand: false,
      );
      return (bar: bar, tab: tab);
    }

    testComponents("underline: the rung's role, selected 600 · idle 500", (
      tester,
    ) async {
      final tabs = <String, ResolvedTabsTab>{};
      pumpWithTheme(
        tester,
        Builder(
          builder: (context) {
            for (final size in CoreTabsSize.values) {
              for (final active in [true, false]) {
                tabs['${size.name} $active'] = resolveOne(
                  context,
                  variant: .underline,
                  active: active,
                  size: size,
                ).tab;
              }
            }
            return const Component.text('ok');
          },
        ),
      );

      const roles = {
        CoreTabsSize.sm: 'text-label-medium',
        CoreTabsSize.md: 'text-label-large',
        CoreTabsSize.lg: 'text-label-xl',
      };
      for (final size in CoreTabsSize.values) {
        final selected = tabs['${size.name} true']!.root;
        final idle = tabs['${size.name} false']!.root;
        expect(selected.className.split(' '), contains(roles[size]));
        expect(idle.className.split(' '), contains(roles[size]));
        expect(selected.inlineStyles?.properties['font-weight'], '600');
        expect(idle.inlineStyles?.properties['font-weight'], '500');
      }
    });

    testComponents('pill: the rung role, selected 600 · idle 500', (
      tester,
    ) async {
      late ResolvedTabsTab sm;
      late ResolvedTabsTab selectedMd;
      late ResolvedTabsTab idleMd;
      late ResolvedTabsTab lg;
      pumpWithTheme(
        tester,
        Builder(
          builder: (context) {
            sm = resolveOne(
              context,
              variant: .pill,
              active: true,
              size: .sm,
            ).tab;
            selectedMd = resolveOne(context, variant: .pill, active: true).tab;
            idleMd = resolveOne(context, variant: .pill, active: false).tab;
            lg = resolveOne(
              context,
              variant: .pill,
              active: false,
              size: .lg,
            ).tab;
            return const Component.text('ok');
          },
        ),
      );

      expect(sm.root.className.split(' '), contains('text-label-medium'));
      expect(
        selectedMd.root.className.split(' '),
        contains('text-label-large'),
      );
      expect(idleMd.root.className.split(' '), contains('text-label-large'));
      expect(lg.root.className.split(' '), contains('text-label-xl'));
      for (final tab in [sm, selectedMd]) {
        expect(tab.root.inlineStyles?.properties['font-weight'], '600');
      }
      for (final tab in [idleMd, lg]) {
        expect(tab.root.inlineStyles?.properties['font-weight'], '500');
      }
    });

    testComponents('underline tabs carry no inset and sit 20 apart; pill tabs '
        'sit 2 apart in a track inset 2', (tester) async {
      late ({ResolvedTabs bar, ResolvedTabsTab tab}) underline;
      late ({ResolvedTabs bar, ResolvedTabsTab tab}) pill;
      pumpWithTheme(
        tester,
        Builder(
          builder: (context) {
            underline = resolveOne(
              context,
              variant: .underline,
              active: true,
            );
            pill = resolveOne(context, variant: .pill, active: true);
            return const Component.text('ok');
          },
        ),
      );

      expect(
        underline.bar.root.inlineStyles?.properties['gap'],
        spaceCss(CoreSpace.space20),
      );
      expect(
        underline.tab.root.inlineStyles?.properties['padding'],
        CoreEdgeInsets.zero.toValue(),
      );
      expect(
        pill.bar.root.inlineStyles?.properties['gap'],
        spaceCss(CoreSpace.space2),
      );
      expect(
        pill.bar.root.inlineStyles?.properties['padding'],
        const CoreEdgeInsets.all(CoreSpace.space2).toValue(),
      );
      expect(
        pill.tab.root.inlineStyles?.properties['border-radius'],
        const CoreBorderRadius.all(CoreRadius.radius6).toValue(),
      );
    });

    // The rung is the bar's outside height. The pill track states no height
    // of its own — it is the tab plus the track's `padding` — so the tab
    // takes the rung less that padding's top and bottom, spelled as the
    // same `spaceCss` values the track emits, and the track lands on the
    // rung. An underline tab is the rung.
    testComponents('pill tabs are the rung less the track inset; underline '
        'tabs are the rung', (tester) async {
      final pill = <CoreTabsSize, ({ResolvedTabs bar, ResolvedTabsTab tab})>{};
      final underline = <CoreTabsSize, ResolvedTabsTab>{};
      pumpWithTheme(
        tester,
        Builder(
          builder: (context) {
            for (final size in CoreTabsSize.values) {
              pill[size] = resolveOne(
                context,
                variant: .pill,
                active: true,
                size: size,
              );
              underline[size] = resolveOne(
                context,
                variant: .underline,
                active: true,
                size: size,
              ).tab;
            }
            return const Component.text('ok');
          },
        ),
      );

      final inset = spaceCss(CoreSpace.space2);
      const rungs = {
        CoreTabsSize.sm: 32.0,
        CoreTabsSize.md: 40.0,
        CoreTabsSize.lg: 48.0,
      };
      for (final MapEntry(key: size, value: rung) in rungs.entries) {
        final rem = '${rung / kRemDivisor}rem';
        expect(
          pill[size]!.tab.root.inlineStyles?.properties['height'],
          'calc($rem - $inset - $inset)',
          reason: 'pill ${size.name}',
        );
        // The track pads by the same values the tab subtracts, so its
        // border box is the rung.
        expect(
          pill[size]!.bar.root.inlineStyles?.properties['padding'],
          '$inset $inset $inset $inset',
          reason: 'pill ${size.name} track',
        );
        expect(
          underline[size]!.root.inlineStyles?.properties['height'],
          rem,
          reason: 'underline ${size.name}',
        );
      }
    });

    testComponents('a stated rung and inset reach the pill tab height', (
      tester,
    ) async {
      late ({ResolvedTabs bar, ResolvedTabsTab tab}) styled;
      late ({ResolvedTabs bar, ResolvedTabsTab tab}) flush;
      pumpWithTheme(
        tester,
        Builder(
          builder: (context) {
            styled = resolveOne(
              context,
              variant: .pill,
              active: true,
              tabsStyle: const CoreTabsStyle(
                itemHeight: 56,
                tabBarPadding: CoreEdgeInsets.symmetric(
                  vertical: CoreSpace.space4,
                ),
              ),
            );
            flush = resolveOne(
              context,
              variant: .pill,
              active: true,
              tabsStyle: const CoreTabsStyle(
                tabBarPadding: CoreEdgeInsets.zero,
              ),
            );
            return const Component.text('ok');
          },
        ),
      );

      final inset = spaceCss(CoreSpace.space4);
      expect(
        styled.tab.root.inlineStyles?.properties['height'],
        'calc(${56 / kRemDivisor}rem - $inset - $inset)',
      );
      // A track with no vertical inset leaves the tab at the rung.
      expect(
        flush.tab.root.inlineStyles?.properties['height'],
        '${40 / kRemDivisor}rem',
      );
    });

    // The variant row says whether the rung is the track's. An `underline`
    // bar has no track around its tabs, so a track inset stated on the
    // instance neither pads the bar nor comes out of the tab.
    testComponents('an underline tab stays at the rung when a track inset is '
        'stated', (tester) async {
      late ({ResolvedTabs bar, ResolvedTabsTab tab}) styled;
      pumpWithTheme(
        tester,
        Builder(
          builder: (context) {
            styled = resolveOne(
              context,
              variant: .underline,
              active: true,
              tabsStyle: const CoreTabsStyle(
                tabBarPadding: CoreEdgeInsets.all(CoreSpace.space4),
              ),
            );
            return const Component.text('ok');
          },
        ),
      );

      expect(
        styled.tab.root.inlineStyles?.properties['height'],
        '${40 / kRemDivisor}rem',
      );
      expect(styled.bar.root.inlineStyles?.properties['padding'], isNull);
    });

    testComponents('a tabsStyle override wins over the variant row', (
      tester,
    ) async {
      late ({ResolvedTabs bar, ResolvedTabsTab tab}) styled;
      pumpWithTheme(
        tester,
        Builder(
          builder: (context) {
            styled = resolveOne(
              context,
              variant: .underline,
              active: true,
              tabsStyle: const CoreTabsStyle(
                tabSpacing: CoreSpace.space4,
                contentTextStyle: CoreTextStyle(
                  fontWeight: CoreFontWeight.black,
                ),
              ),
            );
            return const Component.text('ok');
          },
        ),
      );

      expect(
        styled.bar.root.inlineStyles?.properties['gap'],
        spaceCss(CoreSpace.space4),
      );
      expect(
        styled.tab.root.inlineStyles?.properties['font-weight'],
        '900',
      );
      // The role is still the rung's (md).
      expect(
        styled.tab.root.className.split(' '),
        contains('text-label-large'),
      );
    });
  });

  group('Tabs underline rule colour', () {
    testComponents('the rule is the outlineSubtle hairline, a pill has none', (
      tester,
    ) async {
      late ResolvedTabs underline;
      late ResolvedTabs pill;
      pumpWithTheme(
        tester,
        Builder(
          builder: (context) {
            underline = resolveTabs(
              context,
              variant: .underline,
              expand: false,
            );
            pill = resolveTabs(context, variant: .pill, expand: false);
            return const Component.text('ok');
          },
        ),
      );

      final rule = underline.root.className.split(' ');
      expect(rule, contains('border-outline-subtle'));
      expect(rule, isNot(contains('border-outline-variant')));
      expect(rule, isNot(contains('border-outline')));
      expect(
        pill.root.className.split(' ').where((c) => c.startsWith('border-')),
        isEmpty,
      );
    });
  });
}
