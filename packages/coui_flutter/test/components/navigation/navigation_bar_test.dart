import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart' show debugCheckIntrinsicSizes;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  group('NavigationBar widget', () {
    // NOTE: rendering visible labels (labelMode != none) currently trips a
    // pre-existing lib layout defect (a Flexible placed inside an Align), so
    // these tests exercise the data-driven API surface with the default
    // (label-less) layout rather than asserting label text.
    testWidgets('accepts destination items', (tester) async {
      const bar = NavigationBar(
        items: [
          CoreNavigationBarItem.destination(label: 'Home'),
          CoreNavigationBarItem.destination(label: 'Search'),
        ],
      );

      await pumpTestApp(tester, bar);
      await tester.pump();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(bar.items, hasLength(2));
      expect(bar.items.first.label, equals('Home'));
    });

    testWidgets('renders with empty items', (tester) async {
      await pumpTestApp(
        tester,
        const NavigationBar(items: []),
      );
      await tester.pump();

      expect(find.byType(NavigationBar), findsOneWidget);
    });

    // An empty bar renders without complaint, but it used to report an
    // illegal *negative* intrinsic size: `RenderFlex` bills spacing as
    // `spacing * (childCount - 1)`, and the bar spaces its items by
    // default, so zero children billed one gap backwards. Nothing shows
    // that until something measures the bar — an `IntrinsicWidth`
    // ancestor, or this flag, which is why the plain empty-items test
    // above passes on both sides of the fix.
    for (final mode in CoreNavigationBarMode.values) {
      testWidgets('an empty ${mode.name} reports a legal intrinsic size', (
        tester,
      ) async {
        debugCheckIntrinsicSizes = true;
        try {
          await pumpTestApp(tester, NavigationBar(items: const [], mode: mode));
          await tester.pump();

          expect(tester.takeException(), isNull);
        } finally {
          debugCheckIntrinsicSizes = false;
        }
      });
    }

    testWidgets('renders with custom alignment', (tester) async {
      await pumpTestApp(
        tester,
        const NavigationBar(
          alignment: CoreNavigationAlignment.start,
          items: [
            CoreNavigationBarItem.destination(label: 'A'),
            CoreNavigationBarItem.destination(label: 'B'),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('renders divider and gap items', (tester) async {
      await pumpTestApp(
        tester,
        NavigationBar(
          items: [
            const CoreNavigationBarItem.destination(label: 'A'),
            const CoreNavigationBarItem.divider(),
            CoreNavigationBarItem.gap(8),
            const CoreNavigationBarItem.destination(label: 'B'),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('renders in rail mode (vertical)', (tester) async {
      await pumpTestApp(
        tester,
        const NavigationBar(
          mode: CoreNavigationBarMode.rail,
          items: [
            CoreNavigationBarItem.destination(label: 'Item 1'),
            CoreNavigationBarItem.destination(label: 'Item 2'),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('onSelected callback is wired up', (tester) async {
      int? selectedIndex;

      await pumpTestApp(
        tester,
        NavigationBar(
          selectedIndex: 0,
          onSelected: (index) {
            selectedIndex = index;
          },
          items: const [
            CoreNavigationBarItem.destination(label: 'Home'),
            CoreNavigationBarItem.destination(label: 'Search'),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(selectedIndex, isNull);
    });
  });

  group('NavigationBar bar-mode width fill', () {
    // The design system states every bar-mode destination FILLs — equal
    // shares, edge to edge, no leftover gap — once the row's natural
    // content fits the available width. That leaves `alignment` nothing
    // to distribute for a pure-destination bar (below); it survives only
    // for a bar that mixes in a non-destination item (further below),
    // where a fixed-width entry keeps a real leftover to position.
    //
    // Keyed icons so each destination's laid-out position can be measured.
    const items = [
      CoreNavigationBarItem<Widget>.destination(
        icon: SizedBox.square(key: Key('nav0'), dimension: _kIconDimension),
        label: 'A',
      ),
      CoreNavigationBarItem<Widget>.destination(
        icon: SizedBox.square(key: Key('nav1'), dimension: _kIconDimension),
        label: 'B',
      ),
      CoreNavigationBarItem<Widget>.destination(
        icon: SizedBox.square(key: Key('nav2'), dimension: _kIconDimension),
        label: 'C',
      ),
    ];

    testWidgets(
      'destinations fill the bar in equal shares, edge to edge',
      (tester) async {
        await pumpTestApp(
          tester,
          const SizedBox(
            width: _kBarWidth,
            child: NavigationBar(
              selectedIndex: 0,
              items: items,
              // Uncapped: the bar's own 96 cap would stop these shares
              // short of the edges (see navigation_bar_item_max_width_test).
              navigationBarStyle: CoreNavigationBarStyle(
                itemMaxWidth: double.infinity,
              ),
            ),
          ),
        );
        await tester.pump();

        final first = tester.getCenter(find.byKey(const Key('nav0')));
        final middle = tester.getCenter(find.byKey(const Key('nav1')));
        final last = tester.getCenter(find.byKey(const Key('nav2')));
        final bar = tester.getRect(find.byType(NavigationBar));

        // Equal shares → equal spacing between consecutive centres,
        // regardless of what each item's own (fixed) icon size is.
        expect(middle.dx - first.dx, closeTo(last.dx - middle.dx, 1.0));
        expect(last.dx - first.dx, greaterThan(bar.width * 0.5));
        expect(last.dx, greaterThan(bar.center.dx));
      },
    );

    testWidgets(
      'alignment does not cluster destinations once they fill equally',
      (tester) async {
        await pumpTestApp(
          tester,
          const SizedBox(
            width: _kBarWidth,
            child: NavigationBar(
              alignment: CoreNavigationAlignment.start,
              selectedIndex: 0,
              items: items,
              // Uncapped, so every destination does take an equal share.
              navigationBarStyle: CoreNavigationBarStyle(
                itemMaxWidth: double.infinity,
              ),
            ),
          ),
        );
        await tester.pump();

        final first = tester.getCenter(find.byKey(const Key('nav0')));
        final middle = tester.getCenter(find.byKey(const Key('nav1')));
        final last = tester.getCenter(find.byKey(const Key('nav2')));

        // `alignment: start` used to cluster natural-width items near the
        // leading edge — there is no leftover space left for it to act on
        // once every destination grows to an equal share, so the layout
        // is identical to the no-alignment-override case above.
        expect(middle.dx - first.dx, closeTo(last.dx - middle.dx, 1.0));
        expect(
          last.dx,
          greaterThan(tester.getRect(find.byType(NavigationBar)).center.dx),
        );
      },
    );

    testWidgets(
      'a fixed-size gap keeps its own width while destinations divide '
      'the rest',
      (tester) async {
        final mixedItems = [
          const CoreNavigationBarItem<Widget>.destination(
            icon: SizedBox.square(
              key: Key('mixedA'),
              dimension: _kIconDimension,
            ),
          ),
          CoreNavigationBarItem<Widget>.gap(CoreSpace.space8),
          const CoreNavigationBarItem<Widget>.destination(
            icon: SizedBox.square(
              key: Key('mixedB'),
              dimension: _kIconDimension,
            ),
          ),
        ];

        await pumpTestApp(
          tester,
          SizedBox(
            width: _kBarWidth,
            child: NavigationBar(selectedIndex: 0, items: mixedItems),
          ),
        );
        await tester.pump();

        final a = tester.getCenter(find.byKey(const Key('mixedA')));
        final b = tester.getCenter(find.byKey(const Key('mixedB')));
        final bar = tester.getRect(find.byType(NavigationBar));

        // The gap is fixed and small next to the bar's width — only the
        // two destinations are growable, so they still land on either
        // side of the midline, each claiming roughly half of what the
        // gap does not.
        expect(a.dx, lessThan(bar.center.dx));
        expect(b.dx, greaterThan(bar.center.dx));
      },
    );

    testWidgets(
      'alignment still positions a bar with no growable destination',
      (tester) async {
        const labelsOnly = [
          CoreNavigationBarItem<Widget>.label('A'),
          CoreNavigationBarItem<Widget>.label('B'),
        ];

        await pumpTestApp(
          tester,
          const SizedBox(
            width: _kBarWidth,
            child: NavigationBar(
              alignment: CoreNavigationAlignment.start,
              selectedIndex: 0,
              items: labelsOnly,
            ),
          ),
        );
        await tester.pump();

        final first = tester.getTopLeft(find.text('A'));
        final bar = tester.getRect(find.byType(NavigationBar));

        // Nothing here is a destination, so nothing is growable — the
        // natural-width row plus `alignment: start` is the entire
        // remaining scope of the parameter, and it still clusters
        // content near the leading edge.
        expect(first.dx, lessThan(bar.left + bar.width * 0.25));
      },
    );

    testWidgets('renders without overflow when items exceed the width', (
      tester,
    ) async {
      final manyItems = List.generate(
        20,
        (index) => CoreNavigationBarItem<Widget>.destination(
          icon: const SizedBox.square(dimension: _kIconDimension),
          label: 'Item $index',
        ),
      );

      await pumpTestApp(
        tester,
        SizedBox(
          width: _kBarWidth,
          child: NavigationBar(selectedIndex: 0, items: manyItems),
        ),
      );
      await tester.pump();

      // The horizontal scroll fallback absorbs the overflow.
      expect(tester.takeException(), isNull);
      expect(find.byType(NavigationBar), findsOneWidget);
    });
  });

  group('NavigationBar selection foreground via IconTheme', () {
    // The selected destination's icon takes the indicator's colour (#5740):
    // the bar marks selection with colour alone, so its selected glyph is
    // `primary` while the others rest at `onSurfaceSubtle`. A caller's
    // `iconStyle` colour still reaches both.
    testWidgets('the selected icon takes the indicator colour', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        const SizedBox(
          width: _kBarWidth,
          child: NavigationBar(
            selectedIndex: 0,
            items: [
              CoreNavigationBarItem<Widget>.destination(
                icon: _IconThemeColorProbe(),
                label: 'A',
              ),
              CoreNavigationBarItem<Widget>.destination(
                icon: _IconThemeColorProbe(),
                label: 'B',
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      final context = tester.element(find.byType(NavigationBar));
      final scheme = Theme.of(context).colorScheme;
      final primary = scheme
          .resolve(const CoreColor.token(CoreColors.primary))
          .toValue();
      final subtle = scheme
          .resolve(const CoreColor.token(CoreColors.onSurfaceSubtle))
          .toValue();
      expect(find.text('color:${primary.toARGB32()}'), findsOneWidget);
      expect(find.text('color:${subtle.toARGB32()}'), findsOneWidget);
    });

    testWidgets(
      'iconStyle.color override reaches both selected and unselected icons',
      (tester) async {
        const overrideArgb = 0xFFFFFFFF; // white

        await pumpTestApp(
          tester,
          const SizedBox(
            width: _kBarWidth,
            child: NavigationBar(
              selectedIndex: 0,
              navigationBarStyle: CoreNavigationBarStyle(
                iconStyle: CoreIconStyle(color: CoreColor(overrideArgb)),
              ),
              items: [
                CoreNavigationBarItem<Widget>.destination(
                  icon: _IconThemeColorProbe(),
                  label: 'A',
                ),
                CoreNavigationBarItem<Widget>.destination(
                  icon: _IconThemeColorProbe(),
                  label: 'B',
                ),
              ],
            ),
          ),
        );
        await tester.pump();

        expect(find.text('color:$overrideArgb'), findsNWidgets(2));
      },
    );
  });
}

// Layout fixture constants.
const _kBarWidth = 400.0;
const _kIconDimension = 24.0;

/// Renders the ambient `IconTheme` colour as text so a test can assert the
/// foreground colour NavigationBar hands to a destination's icon.
class _IconThemeColorProbe extends StatelessWidget {
  const _IconThemeColorProbe();

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color;
    return Text('color:${color?.toARGB32()}');
  }
}
