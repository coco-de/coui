import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/rendering.dart' show debugCheckIntrinsicSizes;
import 'package:flutter_test/flutter_test.dart';

const _kWidth = 400.0;
const _kHeight = 300.0;
const _kFlingDistance = 200.0;
const _kFlingVelocity = 500.0;

Widget _buildApp(Widget child) => material.MaterialApp(
  home: material.Scaffold(
    body: material.SizedBox(
      width: _kWidth,
      height: _kHeight,
      child: Theme(data: const ThemeData(), child: child),
    ),
  ),
);

const _kTabs = [
  CoreTabItem<Widget>(label: 'Tab 1'),
  CoreTabItem<Widget>(label: 'Tab 2'),
  CoreTabItem<Widget>(label: 'Tab 3'),
];

/// A parent that offers [child] the harness width without stretching it
/// — loose cross-axis constraints, so a hugging child can stay narrower
/// than the box it sits in.
Widget _hugging(Widget child) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [child],
);

/// The `DecoratedBox` that draws the underline variant's bottom rule —
/// the nearest one above the tab row (`IntrinsicHeight`); the per-tab
/// boxes sit below it.
Finder _underlineRule() => find
    .ancestor(
      of: find.byType(IntrinsicHeight),
      matching: find.byType(DecoratedBox),
    )
    .first;

void main() {
  group('CoreTabItem', () {
    test('stores label and defaults', () {
      const item = CoreTabItem<Widget>(label: 'Account');

      expect(item.label, equals('Account'));
      expect(item.enabled, isTrue);
      expect(item.content, isNull);
    });
  });

  group('Tabs widget', () {
    // `RenderFlex` bills spacing as `spacing * (childCount - 1)`, and the
    // strip spaces its tabs, so an empty `tabs` list billed one gap
    // backwards and reported an illegal negative intrinsic. Nothing
    // reveals that until something measures the strip — this flag, or an
    // `IntrinsicWidth` ancestor.
    testWidgets('an empty tab strip reports a legal intrinsic size', (
      tester,
    ) async {
      debugCheckIntrinsicSizes = true;
      try {
        await tester.pumpWidget(
          _buildApp(const Tabs(tabs: [], selectedIndex: 0)),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
      } finally {
        debugCheckIntrinsicSizes = false;
      }
    });

    testWidgets('renders the tab labels', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Tabs(
            onChanged: (index) {},
            selectedIndex: 0,
            tabs: _kTabs,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Tabs), findsOneWidget);
      expect(find.text('Tab 1'), findsOneWidget);
      expect(find.text('Tab 2'), findsOneWidget);
      expect(find.text('Tab 3'), findsOneWidget);
    });

    testWidgets('calls onChanged when a tab is tapped', (tester) async {
      int? changedIndex;

      await tester.pumpWidget(
        _buildApp(
          Tabs(
            onChanged: (index) {
              changedIndex = index;
            },
            selectedIndex: 0,
            tabs: _kTabs,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Tab 2'));
      await tester.pump();

      expect(changedIndex, equals(1));
    });

    testWidgets('renders with a non-zero selectedIndex', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Tabs(
            onChanged: (index) {},
            selectedIndex: 1,
            tabs: _kTabs,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Tabs), findsOneWidget);
    });

    testWidgets('Tabs.labels shortcut renders each label', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Tabs.labels(
            onChanged: (index) {},
            selectedIndex: 0,
            labels: const ['Account', 'Password'],
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('renders with the underline variant', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Tabs(
            onChanged: (index) {},
            selectedIndex: 0,
            tabs: _kTabs,
            variant: CoreTabVariant.underline,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Tabs), findsOneWidget);
    });

    // The underline rule belongs to the tab-bar box, not the tab row:
    // with `expand: false` the row still hugs its tabs, but the
    // `DecoratedBox` carrying the bottom border spans the width the
    // parent offers (Material's `TabBar` rules the whole bar the same
    // way). A parent that does not stretch its child is what lets the
    // two widths differ — the default harness hands `Tabs` tight
    // constraints, under which the row was full-width already.
    testWidgets(
      'underline rule spans the box while the row hugs when expand is false',
      (tester) async {
        await tester.pumpWidget(
          _buildApp(
            _hugging(
              Tabs(
                onChanged: (index) {},
                selectedIndex: 0,
                tabs: _kTabs,
                variant: CoreTabVariant.underline,
              ),
            ),
          ),
        );
        await tester.pump();

        final rule = _underlineRule();
        final row = find.byType(IntrinsicHeight);
        expect(tester.getSize(rule).width, equals(_kWidth));
        expect(tester.getSize(row).width, lessThan(_kWidth));
        // The ruled box hugs the row's height — a bare `Align` would
        // stretch to the bounded height and drop the rule to its bottom.
        expect(tester.getSize(rule).height, equals(tester.getSize(row).height));
        expect(tester.getTopLeft(row).dx, equals(tester.getTopLeft(rule).dx));
      },
    );

    testWidgets(
      'a hugging underline row sits at the reading-direction end under RTL',
      (tester) async {
        await tester.pumpWidget(
          _buildApp(
            Directionality(
              textDirection: TextDirection.rtl,
              child: _hugging(
                Tabs(
                  onChanged: (index) {},
                  selectedIndex: 0,
                  tabs: _kTabs,
                  variant: CoreTabVariant.underline,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final rule = _underlineRule();
        final row = find.byType(IntrinsicHeight);
        expect(tester.getSize(rule).width, equals(_kWidth));
        expect(tester.getSize(row).width, lessThan(_kWidth));
        expect(tester.getTopRight(row).dx, equals(tester.getTopRight(rule).dx));
      },
    );

    testWidgets('an expanded underline row fills the ruled box', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          _hugging(
            Tabs(
              onChanged: (index) {},
              selectedIndex: 0,
              tabs: _kTabs,
              variant: CoreTabVariant.underline,
              expand: true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.getSize(_underlineRule()).width, equals(_kWidth));
      expect(
        tester.getSize(find.byType(IntrinsicHeight)).width,
        equals(_kWidth),
      );
    });

    for (final direction in TextDirection.values) {
      testWidgets('swipe skips disabled tabs in $direction', (tester) async {
        int? selected;
        await tester.pumpWidget(
          _buildApp(
            Directionality(
              textDirection: direction,
              child: Tabs(
                selectedIndex: 0,
                tabs: const [
                  CoreTabItem<Widget>(label: 'First'),
                  CoreTabItem<Widget>(label: 'Disabled', enabled: false),
                  CoreTabItem<Widget>(label: 'Last'),
                ],
                onChanged: (index) => selected = index,
              ),
            ),
          ),
        );
        await tester.fling(
          find.byType(Tabs),
          Offset(direction == TextDirection.rtl ? 100 : -100, 0),
          _kFlingVelocity,
        );
        await tester.pumpAndSettle();
        expect(selected, 2);
      });
    }

    testWidgets('swipe is disabled when swipeable is false', (tester) async {
      int? changedIndex;

      await tester.pumpWidget(
        _buildApp(
          Tabs(
            onChanged: (index) {
              changedIndex = index;
            },
            selectedIndex: 0,
            swipeable: false,
            tabs: _kTabs,
          ),
        ),
      );
      await tester.pump();

      await tester.fling(
        find.byType(Tabs),
        const Offset(-_kFlingDistance, 0),
        _kFlingVelocity,
      );
      final _ = await tester.pumpAndSettle();

      expect(changedIndex, isNull);
    });
  });

  group('Tabs redesign (2026-09-14)', () {
    TextStyle labelStyle(WidgetTester tester, String label) => tester
        .widget<DefaultTextStyle>(
          find
              .ancestor(
                of: find.text(label),
                matching: find.byType(DefaultTextStyle),
              )
              .first,
        )
        .style;

    testWidgets(
      'a disabled selected underline tab draws disabled-content, not '
      'primary',
      (tester) async {
        await tester.pumpWidget(
          _buildApp(
            Tabs(
              variant: .underline,
              selectedIndex: 0,
              onChanged: (_) {},
              tabs: const [
                CoreTabItem<Widget>(label: 'Disabled', enabled: false),
                CoreTabItem<Widget>(label: 'Tab 2'),
              ],
            ),
          ),
        );

        final resolved = resolveTabs(
          tester.element(find.byType(Tabs)),
          variant: .underline,
          size: .defaultSize,
        );
        final style = labelStyle(tester, 'Disabled');
        expect(style.color, resolved.disabledContentColor);
        expect(style.color, isNot(resolved.activeContentColor));
        final foreground = tester.widget<DecoratedBox>(
          find
              .ancestor(
                of: find.text('Disabled'),
                matching: find.byWidgetPredicate(
                  (widget) =>
                      widget is DecoratedBox &&
                      widget.position == DecorationPosition.foreground,
                ),
              )
              .first,
        );
        final rule = (foreground.decoration as BoxDecoration).border! as Border;
        expect(rule.bottom.color, resolved.disabledIndicatorColor);
        expect(rule.bottom.width, resolved.activeIndicatorThickness);
      },
    );

    testWidgets(
      'a disabled selected pill fills with disabled-container — the '
      'container token, not the label ink and not the enabled fill',
      (tester) async {
        await tester.pumpWidget(
          _buildApp(
            Tabs(
              selectedIndex: 0,
              onChanged: (_) {},
              tabs: const [
                CoreTabItem<Widget>(label: 'Disabled', enabled: false),
                CoreTabItem<Widget>(label: 'Tab 2'),
              ],
            ),
          ),
        );

        final element = tester.element(find.byType(Tabs));
        final resolved = resolveTabs(
          element,
          variant: .pill,
          size: .defaultSize,
        );
        // The pill is an AREA, so its disabled indicator is the container
        // token — a different value from the label's ink, which is the
        // whole reason the field is per variant.
        expect(
          resolved.disabledIndicatorColor,
          isNot(resolved.activeIndicatorColor),
        );
        expect(
          resolved.disabledIndicatorColor,
          isNot(resolved.disabledContentColor),
        );

        // …and the box the disabled selected tab draws uses it. Read from
        // the decoration rather than trusted from the resolver: the fill
        // used to be `activeIndicatorColor` here while the resolver had
        // the right value sitting unused one field over.
        final box = tester.widget<DecoratedBox>(
          find
              .ancestor(
                of: find.text('Disabled'),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        final decoration = box.decoration as BoxDecoration;
        expect(decoration.color, resolved.disabledIndicatorColor);
      },
    );

    testWidgets(
      'the two variants take different disabled indicator tokens',
      (tester) async {
        await tester.pumpWidget(
          _buildApp(
            Tabs(selectedIndex: 0, onChanged: (_) {}, tabs: _kTabs),
          ),
        );

        final element = tester.element(find.byType(Tabs));
        // A rule is ink and a pill is an area. One shared value would put
        // a container colour on the underline's 2px rule or an ink colour
        // across the pill, depending on which way it was unified.
        expect(
          resolveTabs(
            element,
            variant: .pill,
            size: .defaultSize,
          ).disabledIndicatorColor,
          isNot(
            resolveTabs(
              element,
              variant: .underline,
              size: .defaultSize,
            ).disabledIndicatorColor,
          ),
        );
      },
    );

    testWidgets('CoreTabsSize.sm renders a shorter item than the lg rung', (
      tester,
    ) async {
      // `_hugging` gives loose height constraints — otherwise the row's
      // `crossAxisAlignment: .stretch` fills whatever height the parent
      // hands it, and the per-item `height:` request is invisible.
      await tester.pumpWidget(
        _buildApp(
          _hugging(
            Tabs(
              size: .sm,
              selectedIndex: 0,
              onChanged: (_) {},
              tabs: _kTabs,
            ),
          ),
        ),
      );

      final smResolved = resolveTabs(
        tester.element(find.byType(Tabs)),
        variant: .pill,
        size: .sm,
      );
      final lgResolved = resolveTabs(
        tester.element(find.byType(Tabs)),
        variant: .pill,
        size: .lg,
      );
      final box = tester.getSize(
        find
            .descendant(
              of: find.byType(Tabs),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      expect(box.height, smResolved.itemHeight);
      expect(smResolved.itemHeight, lessThan(lgResolved.itemHeight));
    });
  });

  group('Tabs variant rows', () {
    TextStyle labelStyle(WidgetTester tester, String label) => tester
        .widget<DefaultTextStyle>(
          find
              .ancestor(
                of: find.text(label),
                matching: find.byType(DefaultTextStyle),
              )
              .first,
        )
        .style;

    Future<void> pumpTabs(
      WidgetTester tester, {
      required CoreTabVariant variant,
      CoreTabsSize size = .md,
      CoreTabsStyle? tabsStyle,
    }) => tester.pumpWidget(
      _buildApp(
        _hugging(
          Tabs(
            variant: variant,
            size: size,
            selectedIndex: 0,
            onChanged: (_) {},
            tabs: _kTabs,
            tabsStyle: tabsStyle,
          ),
        ),
      ),
    );

    const rungSizes = {
      CoreTabsSize.sm: 13.0,
      CoreTabsSize.md: 14.0,
      CoreTabsSize.lg: 15.0,
    };
    for (final MapEntry(key: size, value: fontSize) in rungSizes.entries) {
      testWidgets('underline ${size.name}: the rung role $fontSize, selected '
          'w600 · idle w500', (tester) async {
        await pumpTabs(tester, variant: .underline, size: size);

        final selected = labelStyle(tester, 'Tab 1');
        final idle = labelStyle(tester, 'Tab 2');
        expect(selected.fontSize, fontSize);
        expect(idle.fontSize, fontSize);
        expect(selected.fontWeight, FontWeight.w600);
        expect(idle.fontWeight, FontWeight.w500);
      });
    }

    testWidgets('pill: the rung role, selected w600 · idle w500', (
      tester,
    ) async {
      await pumpTabs(tester, variant: .pill, size: .sm);
      expect(labelStyle(tester, 'Tab 1').fontSize, 13);
      expect(labelStyle(tester, 'Tab 1').fontWeight, FontWeight.w600);
      expect(labelStyle(tester, 'Tab 2').fontSize, 13);
      expect(labelStyle(tester, 'Tab 2').fontWeight, FontWeight.w500);

      await pumpTabs(tester, variant: .pill);
      expect(labelStyle(tester, 'Tab 1').fontSize, 14);
      expect(labelStyle(tester, 'Tab 2').fontWeight, FontWeight.w500);

      await pumpTabs(tester, variant: .pill, size: .lg);
      expect(labelStyle(tester, 'Tab 1').fontSize, 15);
    });

    testWidgets('underline tabs are as wide as their label — no tab inset', (
      tester,
    ) async {
      await pumpTabs(tester, variant: .underline);

      final box = tester.getSize(
        find
            .ancestor(
              of: find.text('Tab 1'),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      expect(box.width, tester.getSize(find.text('Tab 1')).width);
    });

    testWidgets('underline tabs sit 20 apart', (tester) async {
      await pumpTabs(tester, variant: .underline);

      final first = find
          .ancestor(
            of: find.text('Tab 1'),
            matching: find.byType(AnimatedContainer),
          )
          .first;
      final second = find
          .ancestor(
            of: find.text('Tab 2'),
            matching: find.byType(AnimatedContainer),
          )
          .first;
      expect(
        tester.getTopLeft(second).dx - tester.getTopRight(first).dx,
        closeTo(20, 0.01),
      );
    });

    testWidgets('pill tabs sit 2 apart inside a track inset 2 on every side', (
      tester,
    ) async {
      await pumpTabs(tester, variant: .pill);

      final first = find
          .ancestor(
            of: find.text('Tab 1'),
            matching: find.byType(AnimatedContainer),
          )
          .first;
      final second = find
          .ancestor(
            of: find.text('Tab 2'),
            matching: find.byType(AnimatedContainer),
          )
          .first;
      expect(
        tester.getTopLeft(second).dx - tester.getTopRight(first).dx,
        closeTo(2, 0.01),
      );
      final track = tester.widget<Padding>(
        find
            .ancestor(
              of: find.byType(IntrinsicHeight),
              matching: find.byType(Padding),
            )
            .first,
      );
      expect(track.padding, const EdgeInsets.all(2));
    });

    testWidgets('the selected pill chip is drawn at radius 6', (tester) async {
      await pumpTabs(tester, variant: .pill);

      final decoration =
          tester
                  .widget<AnimatedContainer>(
                    find
                        .ancestor(
                          of: find.text('Tab 1'),
                          matching: find.byType(AnimatedContainer),
                        )
                        .first,
                  )
                  .decoration!
              as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(6));
    });

    // The rung is the bar's outside height. Read back from layout, not from
    // the resolver: the track's height is never stated anywhere — it is
    // the tab plus the inset around it — so only the rendered box shows it
    // landed on the rung.
    const pillHeights = {
      CoreTabsSize.sm: (track: 32.0, tab: 28.0),
      CoreTabsSize.md: (track: 40.0, tab: 36.0),
      CoreTabsSize.lg: (track: 48.0, tab: 44.0),
    };
    for (final MapEntry(key: size, value: height) in pillHeights.entries) {
      testWidgets('pill ${size.name}: the track stands at the rung '
          '(${height.track}), each tab inside its inset (${height.tab})', (
        tester,
      ) async {
        await pumpTabs(tester, variant: .pill, size: size);

        final track = find
            .ancestor(
              of: find.byType(IntrinsicHeight),
              matching: find.byType(DecoratedBox),
            )
            .first;
        expect(tester.getSize(track).height, height.track);
        for (final label in ['Tab 1', 'Tab 2']) {
          final tab = find
              .ancestor(
                of: find.text(label),
                matching: find.byType(AnimatedContainer),
              )
              .first;
          expect(tester.getSize(tab).height, height.tab, reason: label);
        }
      });
    }

    for (final (size, rung) in [
      (CoreTabsSize.sm, 32.0),
      (CoreTabsSize.md, 40.0),
      (CoreTabsSize.lg, 48.0),
    ]) {
      testWidgets('underline ${size.name}: each tab stands at the rung '
          '($rung)', (tester) async {
        await pumpTabs(tester, variant: .underline, size: size);

        final tab = find
            .ancestor(
              of: find.text('Tab 1'),
              matching: find.byType(AnimatedContainer),
            )
            .first;
        expect(tester.getSize(tab).height, rung);
      });
    }

    testWidgets('a stated rung stands the pill track at it', (tester) async {
      await pumpTabs(
        tester,
        variant: .pill,
        tabsStyle: const CoreTabsStyle(
          itemHeight: 56,
          tabBarPadding: CoreEdgeInsets.all(CoreSpace.space4),
        ),
      );

      final track = find
          .ancestor(
            of: find.byType(IntrinsicHeight),
            matching: find.byType(DecoratedBox),
          )
          .first;
      final tab = find
          .ancestor(
            of: find.text('Tab 1'),
            matching: find.byType(AnimatedContainer),
          )
          .first;
      expect(tester.getSize(track).height, 56);
      expect(tester.getSize(tab).height, 48);
    });

    // The variant row says whether the rung is the track's. An `underline`
    // bar has no track around its tabs, so a track inset stated on the
    // instance neither pads the bar nor comes out of the tab: the tab stays
    // at the rung.
    testWidgets('an underline tab stays at the rung when a track inset is '
        'stated', (tester) async {
      await pumpTabs(
        tester,
        variant: .underline,
        tabsStyle: const CoreTabsStyle(
          tabBarPadding: CoreEdgeInsets.all(CoreSpace.space4),
        ),
      );

      final tab = find
          .ancestor(
            of: find.text('Tab 1'),
            matching: find.byType(AnimatedContainer),
          )
          .first;
      expect(tester.getSize(tab).height, 40);
    });

    // Tabs keep their own rung under every density, and the track's inset
    // (2) sits below the spacing ladder's density floor, so the pill track
    // stays at the rung too — the same reading the Web resolver emits.
    for (final density in CoreDensity.values) {
      testWidgets('pill md under ${density.name} density: track 40, tab 36', (
        tester,
      ) async {
        await tester.pumpWidget(
          CoUIApp(
            theme: const ThemeData(),
            density: density,
            // `pill` is the default variant.
            home: _hugging(
              Tabs(selectedIndex: 0, onChanged: (_) {}, tabs: _kTabs),
            ),
          ),
        );
        await tester.pump();

        final track = find
            .ancestor(
              of: find.byType(IntrinsicHeight),
              matching: find.byType(DecoratedBox),
            )
            .first;
        final tab = find
            .ancestor(
              of: find.text('Tab 1'),
              matching: find.byType(AnimatedContainer),
            )
            .first;
        expect(tester.getSize(track).height, 40);
        expect(tester.getSize(tab).height, 36);
      });
    }

    testWidgets('resolveTabs reads the variant row for spacing and weights', (
      tester,
    ) async {
      await pumpTabs(tester, variant: .underline);
      final element = tester.element(find.byType(Tabs));

      final underline = resolveTabs(
        element,
        variant: .underline,
        size: .defaultSize,
      );
      expect(underline.tabSpacing, 20);
      expect(underline.activeContentTextStyle.fontWeight, FontWeight.w600);
      expect(underline.inactiveContentTextStyle.fontWeight, FontWeight.w500);
      expect(underline.tabPadding, EdgeInsets.zero);

      final pill = resolveTabs(element, variant: .pill, size: .defaultSize);
      expect(pill.tabSpacing, 2);
      expect(pill.tabBarPadding, const EdgeInsets.all(2));
      expect(pill.activeContentTextStyle.fontWeight, FontWeight.w600);
      expect(pill.inactiveContentTextStyle.fontWeight, FontWeight.w500);
    });

    testWidgets('a tabsStyle override wins over the variant row', (
      tester,
    ) async {
      await pumpTabs(
        tester,
        variant: .underline,
        tabsStyle: const CoreTabsStyle(
          tabSpacing: 4,
          contentTextStyle: CoreTextStyle(fontWeight: CoreFontWeight.black),
        ),
      );

      // The instance's weight covers both selections; the row's per-
      // selection weights sit beneath it.
      expect(labelStyle(tester, 'Tab 1').fontWeight, FontWeight.w900);
      expect(labelStyle(tester, 'Tab 2').fontWeight, FontWeight.w900);
      // The role is still the rung's (md).
      expect(labelStyle(tester, 'Tab 1').fontSize, 14);
      final resolved = resolveTabs(
        tester.element(find.byType(Tabs)),
        variant: .underline,
        size: .defaultSize,
        tabsStyle: const CoreTabsStyle(tabSpacing: 4),
      );
      expect(resolved.tabSpacing, 4);
    });
  });

  group('TabPane widget', () {
    testWidgets('renders tab labels', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          TabPane(
            onChanged: (index) {},
            selectedIndex: 0,
            tabs: const [
              CoreTabItem<Widget>(label: 'Overview'),
              CoreTabItem<Widget>(label: 'Details'),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(TabPane), findsOneWidget);
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Details'), findsOneWidget);
    });

    testWidgets('renders with leading and trailing widgets', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          TabPane(
            onChanged: (index) {},
            selectedIndex: 0,
            tabs: const [CoreTabItem<Widget>(label: 'Tab')],
            leading: const [Text('Lead')],
            trailing: const [Text('Trail')],
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Lead'), findsOneWidget);
      expect(find.text('Trail'), findsOneWidget);
    });

    // The tab is an underline tab in a bordered card: the card owns the one
    // outline, the focused tab carries no face and no outline of its own,
    // and the bar sits flush on the card's top. Each fact is asserted on its
    // own, as a result rather than as tree shape.
    group('card and bar', () {
      // The chip box of each tab: the nearest box above its label that holds
      // the tab's padding. (A Clickable's focus ring is a box above it.)
      Iterable<DecoratedBox> tabBoxes(WidgetTester tester) => [
        for (final tab in _kTabs)
          tester.widget<DecoratedBox>(
            find
                .ancestor(
                  of: find.text(tab.label),
                  matching: find.byWidgetPredicate(
                    (widget) =>
                        widget is DecoratedBox && widget.child is Padding,
                  ),
                )
                .first,
          ),
      ];

      testWidgets('the focused tab carries no outline and no rounded face', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(
            TabPane(onChanged: (index) {}, selectedIndex: 0, tabs: _kTabs),
          ),
        );
        await tester.pump();

        for (final box in tabBoxes(tester)) {
          final decoration = box.decoration;
          if (decoration is! BoxDecoration) continue;
          final border = decoration.border;
          if (border is Border) {
            expect(border.top, BorderSide.none);
            expect(border.left, BorderSide.none);
            expect(border.right, BorderSide.none);
          }
          // Only the indicator bar (2) rounds; no tab face rounds at 12+.
          final radius = decoration.borderRadius;
          if (radius is BorderRadius) {
            expect(radius.topLeft.x, lessThan(CoreRadius.radius12));
          }
        }
      });

      testWidgets('a stated separator follows reading direction', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(
            TabPane(
              onChanged: (index) {},
              selectedIndex: 0,
              tabs: _kTabs,
              tabPaneStyle: const CoreTabPaneStyle(
                tabSeparatorColor: CoreColor.token(CoreColors.outline),
                tabSpacing: 0,
              ),
            ),
          ),
        );
        await tester.pump();

        // Directional, not physical: the rule must be declared on the
        // reading-direction end so an RTL locale flips it. A `Border`
        // (physical) would pin it to the right forever.
        final wrapper = find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration! as BoxDecoration).border is BorderDirectional,
          description: 'a tab wrapper carrying the directional rule',
        );
        expect(wrapper, findsWidgets);
        final border =
            (tester.widget<Container>(wrapper.first).decoration!
                        as BoxDecoration)
                    .border!
                as BorderDirectional;
        expect(border.end.width, CoreTabPaneStyle.defaultTabSeparatorWidth);
        // …and nowhere else: a rule on all four sides is a box, not a
        // divider.
        expect(border.start, BorderSide.none);
        expect(border.top, BorderSide.none);
        expect(border.bottom, BorderSide.none);
      });

      testWidgets('item slots render in reading order around the label', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(
            TabPane(
              onChanged: (index) {},
              selectedIndex: 0,
              tabs: const [
                CoreTabItem<Widget>(
                  label: 'Account',
                  leading: Text('L'),
                  trailing: Text('T'),
                ),
                CoreTabItem<Widget>(label: 'Password'),
              ],
            ),
          ),
        );
        await tester.pump();

        // The RESULT — geometry, not tree shape: leading sits before the
        // label and trailing after it. A slot appended to the wrong end
        // still "renders", which is why this reads x positions.
        final lx = tester.getRect(find.text('L')).left;
        final labelX = tester.getRect(find.text('Account')).left;
        final tx = tester.getRect(find.text('T')).left;
        expect(lx, lessThan(labelX));
        expect(tx, greaterThan(labelX));
        // …and the tab that states neither grows no slot.
        expect(find.text('Password'), findsOneWidget);
      });

      testWidgets('the focused label reads differently from the unfocused', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(
            TabPane(onChanged: (index) {}, selectedIndex: 0, tabs: _kTabs),
          ),
        );
        await tester.pump();

        Color? labelColour(String text) {
          final holder = find.ancestor(
            of: find.text(text),
            matching: find.byType(DefaultTextStyle),
          );
          return tester.widget<DefaultTextStyle>(holder.first).style.color;
        }

        // The RESULT, not the wiring: the two states must not resolve to the
        // same colour. A pane whose unfocused tabs read identically to the
        // focused one is the picture this pair exists to fix.
        final focused = labelColour(_kTabs.first.label);
        final unfocused = labelColour(_kTabs[1].label);
        expect(focused, isNotNull);
        expect(unfocused, isNotNull);
        expect(focused, isNot(unfocused));
      });

      testWidgets('the bar holds the default height and sits on the card top', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(
            TabPane(onChanged: (index) {}, selectedIndex: 0, tabs: _kTabs),
          ),
        );
        await tester.pump();

        final strip = tester.getRect(find.byType(FadeScroll));
        expect(strip.height, CoreTabPaneStyle.boxed.barHeight);
        // Inside the card's own rule: one rule from the top.
        expect(strip.top, CoreTabPaneStyle.defaultBorderWidth);
        // And nothing is translated onto the panel's rule any more.
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Transform &&
                widget.transform.getTranslation().y != 0 &&
                widget.transform.getTranslation().x == 0,
          ),
          findsNothing,
        );
      });

      testWidgets('the bar is padded by barPadding, 16 either side', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(
            TabPane(onChanged: (index) {}, selectedIndex: 0, tabs: _kTabs),
          ),
        );
        await tester.pump();

        final card = tester.getRect(
          find
              .ancestor(
                of: find.byType(FadeScroll),
                matching: find.byWidgetPredicate(
                  (widget) =>
                      widget is Container &&
                      widget.decoration is BoxDecoration &&
                      (widget.decoration! as BoxDecoration).border != null,
                ),
              )
              .first,
        );
        final strip = tester.getRect(find.byType(FadeScroll));
        expect(
          strip.left - card.left,
          CoreTabPaneStyle.defaultBorderWidth + CoreSpace.space16,
        );
        expect(
          card.right - strip.right,
          CoreTabPaneStyle.defaultBorderWidth + CoreSpace.space16,
        );
      });
    });

    testWidgets('editorStrip does not render content panel', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          TabPane(
            variant: .editorStrip,
            onChanged: (index) {},
            selectedIndex: 0,
            tabs: const [
              CoreTabItem<Widget>(
                label: 'main.dart',
                content: Text('SHOULD_NOT_RENDER'),
              ),
              CoreTabItem<Widget>(label: 'pubspec.yaml'),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.text('main.dart'), findsOneWidget);
      expect(find.text('SHOULD_NOT_RENDER'), findsNothing);
      // No T-junction translate — strip is the whole component.
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Transform &&
              widget.transform ==
                  Matrix4.translationValues(
                    0,
                    CoreTabPaneStyle.defaultBorderWidth,
                    0,
                  ),
        ),
        findsNothing,
      );
    });

    testWidgets('editorStrip chain getter sets variant', (tester) async {
      final pane = TabPane(
        onChanged: (index) {},
        selectedIndex: 0,
        tabs: const [CoreTabItem<Widget>(label: 'a')],
      ).editorStrip;
      expect(pane.variant, CoreTabPaneVariant.editorStrip);
    });

    group('tabPadding wraps the whole chip', () {
      // `tabPadding` is the chip's padding: it wraps leading through the
      // close ×, the box the Web chip `<span>` and the Figma tab frame pad.
      // A padding that wrapped only the select region would leave trailing
      // and the × flush to the chip's end edge, and the tab would draw
      // narrower on Flutter alone. Geometry, not tree shape.
      late EdgeInsets padding;

      Widget pane(CoreTabItem<Widget> first, {CoreTabPaneVariant? variant}) =>
          material.Builder(
            builder: (context) {
              // The editorStrip's padding is directional (start 14 / end 4),
              // so it is read against the ambient direction like the
              // `Padding` that paints it.
              padding = resolveTabPane(
                context,
                variant: variant ?? CoreTabPaneVariant.defaultVariant,
              ).tabPadding.resolve(Directionality.of(context));
              return TabPane(
                variant: variant ?? CoreTabPaneVariant.defaultVariant,
                selectedIndex: 0,
                onChanged: (index) {},
                tabs: [
                  first,
                  const CoreTabItem<Widget>(label: 'other'),
                ],
              );
            },
          );

      /// The focused tab's chip — the box that holds the padding, nearest
      /// above [inside]. Its face is not painted (an underline tab), but it
      /// is still the box `tabPadding` wraps.
      Rect chipOf(WidgetTester tester, Finder inside) => tester.getRect(
        find
            .ancestor(
              of: inside,
              matching: find.byWidgetPredicate(
                (w) => w is DecoratedBox && w.child is Padding,
              ),
            )
            .first,
      );

      testWidgets('leading and trailing sit inside the chip padding', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(
            pane(
              const CoreTabItem<Widget>(
                label: 'Account',
                leading: Text('L'),
                trailing: Text('T'),
              ),
            ),
          ),
        );
        await tester.pump();

        final chip = chipOf(tester, find.text('T'));
        expect(padding.left, greaterThan(0));
        expect(padding.right, greaterThan(0));
        expect(tester.getRect(find.text('L')).left - chip.left, padding.left);
        expect(
          chip.right - tester.getRect(find.text('T')).right,
          padding.right,
        );
      });

      testWidgets('the close × sits inside the chip padding', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            pane(
              CoreTabItem<Widget>(label: 'main.dart', onClose: () {}),
              variant: .editorStrip,
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        final chip = chipOf(tester, find.byType(Button));
        final close = tester.getRect(find.byType(Button));
        expect(chip.right - close.right, padding.right);
        expect(
          tester.getRect(find.text('main.dart')).left - chip.left,
          padding.left,
        );
        // Vertically the × keeps its own size and sits centred in the
        // chip's padded box — it is not stretched to the chip's height
        // (that paints a taller hover face than the Button is). Equal
        // clearance above and below, and less than the chip's height.
        expect(close.height, lessThan(chip.height - padding.vertical));
        expect(close.top - chip.top, greaterThanOrEqualTo(padding.top));
        expect(
          close.top - chip.top - padding.top,
          closeTo(chip.bottom - close.bottom - padding.bottom, 0.01),
        );
      });
    });

    testWidgets('onClose does not fire onChanged', (tester) async {
      var selected = 0;
      var closed = 0;
      await tester.pumpWidget(
        _buildApp(
          StatefulBuilder(
            builder: (context, setState) {
              return TabPane(
                variant: .editorStrip,
                selectedIndex: selected,
                onChanged: (index) => setState(() => selected = index),
                tabs: [
                  CoreTabItem<Widget>(
                    label: 'main.dart',
                    onClose: () => setState(() => closed++),
                  ),
                  const CoreTabItem<Widget>(label: 'other.dart'),
                ],
              );
            },
          ),
        ),
      );
      await tester.pump();

      // Tap the synthesised close × (ghost Button with LucideIcons.x).
      await tester.tap(find.byType(Button));
      await tester.pump();

      expect(closed, 1);
      expect(selected, 0);
    });

    testWidgets('trailing close does not fire onChanged', (tester) async {
      var selected = 0;
      var closed = 0;
      await tester.pumpWidget(
        _buildApp(
          StatefulBuilder(
            builder: (context, setState) {
              return TabPane(
                variant: .editorStrip,
                selectedIndex: selected,
                onChanged: (index) => setState(() => selected = index),
                tabs: [
                  CoreTabItem<Widget>(
                    label: 'main.dart',
                    trailing: Button(
                      onPressed: () => setState(() => closed++),
                      variant: .ghost,
                      size: .sm,
                      child: const Text('×'),
                    ),
                  ),
                  const CoreTabItem<Widget>(label: 'other.dart'),
                ],
              );
            },
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('×'));
      await tester.pump();

      expect(closed, 1);
      expect(selected, 0);
    });
  });

  // `CoreTabItem.badge` is a composition slot: the caller supplies the
  // styled widget, the tab composes it after the label behind a 1-off
  // `Gap` whose style is the resolver's `labelBadgeGapStyle` forward.
  // Both variants and `TabPane` render the same shape, and an item
  // without a badge composes no `Gap` at all.
  group('badge slot', () {
    Finder labelBadgeGap(CoreGapStyle style) => find.byWidgetPredicate(
      (widget) => widget is Gap && widget.gapStyle == style,
      description: 'the label↔badge Gap carrying $style',
    );

    for (final variant in CoreTabVariant.values) {
      testWidgets('$variant renders the badge after the label behind a Gap', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(
            Tabs(
              onChanged: (index) {},
              selectedIndex: 0,
              tabs: const [
                CoreTabItem<Widget>(
                  label: 'Inbox',
                  badge: Badge(child: Text('3')),
                ),
                CoreTabItem<Widget>(label: 'Sent'),
              ],
              variant: variant,
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(Badge), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
        // One Gap for the one badge — the plain tab composes none.
        final gap = labelBadgeGap(CoreTabsStyle.defaultLabelBadgeGapStyle);
        expect(gap, findsOneWidget);
        // Label → Gap → badge, left to right, with the stated step between.
        final labelRight = tester.getTopRight(find.text('Inbox')).dx;
        final badgeLeft = tester.getTopLeft(find.byType(Badge)).dx;
        expect(tester.getTopLeft(gap).dx, equals(labelRight));
        expect(badgeLeft - labelRight, closeTo(CoreSpace.space6, 0.01));
      });
    }

    testWidgets('a tabsStyle override reaches the Gap', (tester) async {
      const override = CoreGapStyle(size: CoreSpace.space12);
      await tester.pumpWidget(
        _buildApp(
          Tabs(
            onChanged: (index) {},
            selectedIndex: 0,
            tabs: const [
              CoreTabItem<Widget>(
                label: 'Inbox',
                badge: Badge(child: Text('3')),
              ),
            ],
            tabsStyle: const CoreTabsStyle(labelBadgeGapStyle: override),
          ),
        ),
      );
      await tester.pump();

      expect(
        labelBadgeGap(
          CoreTabsStyle.defaultLabelBadgeGapStyle.merge(override),
        ),
        findsOneWidget,
      );
      final labelRight = tester.getTopRight(find.text('Inbox')).dx;
      final badgeLeft = tester.getTopLeft(find.byType(Badge)).dx;
      expect(badgeLeft - labelRight, closeTo(CoreSpace.space12, 0.01));
    });

    testWidgets('an item without a badge composes no Gap', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Tabs(onChanged: (index) {}, selectedIndex: 0, tabs: _kTabs),
        ),
      );
      await tester.pump();

      expect(find.byType(Badge), findsNothing);
      expect(
        labelBadgeGap(CoreTabsStyle.defaultLabelBadgeGapStyle),
        findsNothing,
      );
    });

    testWidgets('TabPane renders the badge behind its own Gap slot', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          TabPane(
            onChanged: (index) {},
            selectedIndex: 0,
            tabs: const [
              CoreTabItem<Widget>(
                label: 'Inbox',
                badge: Badge(child: Text('3')),
              ),
              CoreTabItem<Widget>(label: 'Sent'),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Badge), findsOneWidget);
      expect(
        labelBadgeGap(CoreTabPaneStyle.defaultLabelBadgeGapStyle),
        findsOneWidget,
      );
      final labelRight = tester.getTopRight(find.text('Inbox')).dx;
      final badgeLeft = tester.getTopLeft(find.byType(Badge)).dx;
      expect(badgeLeft - labelRight, closeTo(CoreSpace.space6, 0.01));
    });
  });

  group('Tabs textScaler (#4626)', () {
    testWidgets(
      'labels are not clipped at theme.scaling 1.25 × OS textScaler',
      (tester) async {
        const labels = ['통계', '로그'];
        for (final scale in [1.0, 1.15, 1.3, 2.0]) {
          await tester.pumpWidget(
            _buildApp(
              Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(scale),
                  ),
                  child: Theme(
                    data: const ThemeData(scaling: 1.25),
                    child: Tabs(
                      onChanged: (index) {},
                      selectedIndex: 0,
                      tabs: [
                        for (final label in labels)
                          CoreTabItem<Widget>(label: label),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();

          for (final label in labels) {
            final box =
                tester.renderObject(find.text(label)) as material.RenderBox;
            final intrinsic = box.getMaxIntrinsicHeight(box.size.width);
            expect(
              box.size.height + 0.5,
              greaterThanOrEqualTo(intrinsic),
              reason:
                  'textScaler $scale clipped "$label" '
                  '(box ${box.size.height} < intrinsic $intrinsic)',
            );
          }
        }
      },
    );
  });

  group('Tabs pill chip and track, read back in each mode', () {
    const semantic = CouiSemanticColors.from(CouiColorPresets.source);
    final modes = <String, CoreColorScheme>{
      'light': semantic.light,
      'dark': semantic.dark,
      'high-contrast light': semantic.highContrastLight,
      'high-contrast dark': semantic.highContrastDark,
    };

    for (final MapEntry(key: name, value: scheme) in modes.entries) {
      final brightness = name.contains('dark')
          ? CoreBrightness.dark
          : CoreBrightness.light;

      testWidgets('$name: the selected chip is surfaceRaised on a '
          'surfaceContainer track', (tester) async {
        await tester.pumpWidget(
          CoUIApp(
            theme: ThemeData(colorScheme: scheme.resolved(brightness)),
            home: _hugging(
              Tabs(selectedIndex: 0, onChanged: (_) {}, tabs: _kTabs),
            ),
          ),
        );
        await tester.pump();

        final colors = Theme.of(tester.element(find.byType(Tabs))).colorScheme;
        final chip =
            tester
                    .widget<AnimatedContainer>(
                      find
                          .ancestor(
                            of: find.text('Tab 1'),
                            matching: find.byType(AnimatedContainer),
                          )
                          .first,
                    )
                    .decoration!
                as BoxDecoration;
        final track =
            tester
                    .widget<DecoratedBox>(
                      find
                          .ancestor(
                            of: find.byType(IntrinsicHeight),
                            matching: find.byType(DecoratedBox),
                          )
                          .first,
                    )
                    .decoration
                as BoxDecoration;
        expect(
          chip.color,
          colors
              .resolve(const CoreColor.token(CoreColors.surfaceRaised))
              .toValue(),
        );
        expect(
          track.color,
          colors
              .resolve(const CoreColor.token(CoreColors.surfaceContainer))
              .toValue(),
        );
        expect(chip.color, isNot(track.color));
      });
    }
  });

  group('Tabs underline rule, read back in each mode', () {
    const semantic = CouiSemanticColors.from(CouiColorPresets.source);
    final modes = <String, CoreColorScheme>{
      'light': semantic.light,
      'dark': semantic.dark,
      'high-contrast light': semantic.highContrastLight,
      'high-contrast dark': semantic.highContrastDark,
    };

    for (final MapEntry(key: name, value: scheme) in modes.entries) {
      final brightness = name.contains('dark')
          ? CoreBrightness.dark
          : CoreBrightness.light;

      testWidgets('$name: the rule is the outlineSubtle hairline', (
        tester,
      ) async {
        late ThemeData theme;
        late ResolvedTabs resolved;
        await tester.pumpWidget(
          CoUIApp(
            theme: ThemeData(colorScheme: scheme.resolved(brightness)),
            home: Builder(
              builder: (context) {
                theme = Theme.of(context);
                resolved = resolveTabs(
                  context,
                  variant: .underline,
                  size: .defaultSize,
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        await tester.pump();

        expect(
          resolved.borderColor,
          theme.colorScheme
              .resolve(const CoreColor.token(CoreColors.outlineSubtle))
              .toValue(),
        );
      });
    }
  });
}
