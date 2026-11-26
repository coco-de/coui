// The bar's compact form (`NavigationBar.compact`): when it is drawn, what it
// is, and that it follows the content the scaffold scrolls. The rule that
// reads the scrolling is Core's (`CoreNavigationScrollCompaction`) and the
// table in `coui_core/test/fixtures/navigation_scroll_compaction_vectors.json`
// pins it for every package; this file dispatches that table's steps as
// scroll notifications and reads the scale the bar is drawn at, and holds
// what only the widget can show — that it shrinks without being laid out
// again, and what it does not follow.
import 'dart:convert';
import 'dart:io';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

const String _kVectorsPath =
    '../coui_core/test/fixtures/navigation_scroll_compaction_vectors.json';

const _glass = CoreNavigationBarStyle(surfaceStyle: .liquidGlass);
const double _compactScale = CoreNavigationBarStyle.glassCompactScale;

const _items = [
  CoreNavigationBarItem<Widget>.destination(
    icon: Icon(LucideIcons.house),
    label: 'Home',
  ),
  CoreNavigationBarItem<Widget>.destination(
    icon: Icon(LucideIcons.search),
    label: 'Search',
  ),
  CoreNavigationBarItem<Widget>.destination(
    icon: Icon(LucideIcons.user),
    label: 'Profile',
  ),
];

const _contentKey = ValueKey<String>('content');
const _stripKey = ValueKey<String>('strip');

/// The transform the bar's compact form is drawn through: the outermost one
/// under the bar (a destination's press-shrink is one further in).
Finder get _compaction => find
    .descendant(
      of: find.byType(NavigationBar),
      matching: find.byType(AnimatedScale),
    )
    .first;

/// The scale the bar is asked to be drawn at.
double _target(WidgetTester tester) =>
    tester.widget<AnimatedScale>(_compaction).scale;

/// The scale the bar is drawn at on this frame.
double _drawn(WidgetTester tester) => tester
    .widget<ScaleTransition>(
      find
          .descendant(
            of: _compaction,
            matching: find.byType(ScaleTransition),
          )
          .first,
    )
    .scale
    .value;

/// What a test changes on the bar after it is pumped. The test app keeps the
/// first child it is given, so a bar that changes is rebuilt from this.
typedef _BarState = ({CoreNavigationCompact compact, int selectedIndex});

ValueNotifier<_BarState> _state([
  CoreNavigationCompact compact = .onScroll,
]) {
  final notifier = ValueNotifier<_BarState>((
    compact: compact,
    selectedIndex: 0,
  ));
  addTearDown(notifier.dispose);

  return notifier;
}

extension on ValueNotifier<_BarState> {
  set compact(CoreNavigationCompact compact) =>
      value = (compact: compact, selectedIndex: value.selectedIndex);

  set selectedIndex(int index) =>
      value = (compact: value.compact, selectedIndex: index);
}

/// A bar on its own, as wide as a phone.
Widget _bar(
  ValueNotifier<_BarState> state, {
  CoreNavigationBarMode mode = .bar,
  CoreNavigationBarStyle style = _glass,
  ValueChanged<int>? onSelected,
}) => ValueListenableBuilder<_BarState>(
  valueListenable: state,
  builder: (context, value, _) => SizedBox(
    width: mode == .bar ? 360 : null,
    child: NavigationBar(
      mode: mode,
      items: _items,
      selectedIndex: value.selectedIndex,
      onSelected: onSelected,
      compact: value.compact,
      navigationBarStyle: style,
    ),
  ),
);

/// A scaffold whose body scrolls under a floating bar — the shell the compact
/// form is for.
Widget _shell(ValueNotifier<_BarState> state, {Widget? child}) =>
    ValueListenableBuilder<_BarState>(
      valueListenable: state,
      builder: (context, value, _) => SizedBox(
        width: 360,
        height: 640,
        child: Scaffold(
          floatingFooter: true,
          footers: [
            NavigationBar(
              items: _items,
              selectedIndex: value.selectedIndex,
              onSelected: (_) {},
              compact: value.compact,
              navigationBarStyle: _glass,
            ),
          ],
          child:
              child ??
              ListView(
                key: _contentKey,
                children: [
                  SizedBox(
                    height: 80,
                    child: ListView(
                      key: _stripKey,
                      scrollDirection: .horizontal,
                      children: [
                        for (var i = 0; i < 20; i++) const SizedBox(width: 120),
                      ],
                    ),
                  ),
                  for (var i = 0; i < 60; i++) const SizedBox(height: 80),
                ],
              ),
        ),
      ),
    );

/// Dispatches one scroll step of the content, as the scrollable would.
void _scrollStep(
  WidgetTester tester, {
  required double offset,
  required double delta,
  required double maxExtent,
}) {
  final context = tester.element(find.byKey(_contentKey));
  ScrollUpdateNotification(
    metrics: FixedScrollMetrics(
      minScrollExtent: 0,
      maxScrollExtent: maxExtent,
      pixels: offset,
      viewportDimension: 640,
      axisDirection: AxisDirection.down,
      devicePixelRatio: 1,
    ),
    context: context,
    scrollDelta: delta,
  ).dispatch(context);
}

List<Map<String, Object?>> _list(Object? value) =>
    (value! as List).cast<Map<String, Object?>>();

/// The bar's material pass — the box its capsule is drawn in.
Finder get _face => find.descendant(
  of: find.byType(NavigationBar),
  matching: find.byType(BackdropFilter),
);

void main() {
  group('when the compact form is drawn', () {
    testWidgets('never, by default', (tester) async {
      await pumpTestApp(
        tester,
        const SizedBox(
          width: 360,
          child: NavigationBar(items: _items, navigationBarStyle: _glass),
        ),
      );
      expect(_target(tester), 1);
    });

    testWidgets('always draws the floating glass bar at its compact size', (
      tester,
    ) async {
      await pumpTestApp(tester, _bar(_state(.always)));
      expect(_target(tester), _compactScale);
      expect(_drawn(tester), _compactScale);
    });

    testWidgets('a docked bar has no compact form', (tester) async {
      await pumpTestApp(
        tester,
        _bar(_state(.always), style: const CoreNavigationBarStyle()),
      );
      expect(_target(tester), 1);
    });

    testWidgets('a style states the compact size', (tester) async {
      await pumpTestApp(
        tester,
        _bar(
          _state(.always),
          style: const CoreNavigationBarStyle(compactScale: .5),
        ),
      );
      expect(_target(tester), .5);
    });
  });

  group('the compact form', () {
    testWidgets('drops the captions and draws the glyphs smaller, toward the '
        'bottom edge', (tester) async {
      // Beside a bar that never shows a caption: the compact bar is that bar,
      // drawn at the compact size.
      final state = _state(.never);
      await pumpTestApp(
        tester,
        // Stacked from the bottom, as a shell holds its bar: a bar that
        // gets shorter keeps its bottom edge.
        Column(
          mainAxisAlignment: .end,
          children: [
            const SizedBox(
              key: ValueKey<String>('glyphs'),
              width: 360,
              child: NavigationBar(
                items: _items,
                labelMode: .none,
                navigationBarStyle: _glass,
              ),
            ),
            KeyedSubtree(
              key: const ValueKey<String>('bar'),
              child: _bar(state),
            ),
          ],
        ),
      );
      Finder face(String key) => find.descendant(
        of: find.byKey(ValueKey<String>(key)),
        matching: find.byType(BackdropFilter),
      );
      final glyphs = tester.getRect(face('glyphs'));
      final resting = tester.getRect(face('bar'));
      expect(resting.height, greaterThan(glyphs.height));

      state.compact = .always;
      await tester.pumpAndSettle();
      final drawn = tester.getRect(face('bar'));
      expect(drawn.width, closeTo(glyphs.width * _compactScale, 1e-6));
      expect(drawn.height, closeTo(glyphs.height * _compactScale, 1e-6));
      // About the middle of the bottom edge.
      expect(drawn.bottom, closeTo(resting.bottom, 1e-6));
      expect(drawn.center.dx, closeTo(resting.center.dx, 1e-6));
    });

    testWidgets('folds each caption away and keeps the destination', (
      tester,
    ) async {
      final state = _state(.never);
      await pumpTestApp(tester, _bar(state, onSelected: (_) {}));
      // The caption's fold: the clip nearest it.
      Finder fold(String caption) => find
          .ancestor(of: find.text(caption), matching: find.byType(ClipRect))
          .first;
      final destination = tester.element(find.byKey(const ValueKey<int>(0)));
      final clickable = tester.state(
        find.descendant(
          of: find.byKey(const ValueKey<int>(0)),
          matching: find.byType(Clickable),
        ),
      );
      final unfolded = tester.getSize(fold('Home')).height;
      expect(
        unfolded,
        tester.getSize(find.text('Home')).height +
            CoreNavigationBarStyle.defaultLabelSpacing,
        reason: 'the gap to the icon is inside the fold',
      );

      state.compact = .always;
      await tester.pump();
      await tester.pump(CoreNavigationBarStyle.defaultCompactDuration ~/ 2);
      expect(
        tester.getSize(fold('Home')).height,
        allOf(greaterThan(0), lessThan(unfolded)),
      );
      await tester.pumpAndSettle();
      for (final caption in ['Home', 'Search', 'Profile']) {
        expect(tester.getSize(fold(caption)).height, 0, reason: caption);
      }
      // The destination is the one it was: no tooltip came to stand in for
      // the caption, and what held its hover and focus is still there.
      expect(tester.element(find.byKey(const ValueKey<int>(0))), destination);
      expect(
        tester.state(
          find.descendant(
            of: find.byKey(const ValueKey<int>(0)),
            matching: find.byType(Clickable),
          ),
        ),
        same(clickable),
      );
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.byType(Tooltip),
        ),
        findsNothing,
      );
      // And it still says its name.
      expect(find.bySemanticsLabel('Home'), findsOneWidget);

      state.compact = .never;
      await tester.pumpAndSettle();
      expect(tester.getSize(fold('Home')).height, unfolded);
    });

    testWidgets('a bar that can turn compact rests exactly as one that '
        'cannot', (tester) async {
      // The fold is in the tree from the start; at rest it has to be the
      // caption's own box and the stack's own gap.
      Map<String, Rect> rects() => {
        for (final caption in ['Home', 'Search', 'Profile'])
          caption: tester.getRect(find.text(caption)),
        for (final (index, _) in _items.indexed)
          'icon $index': tester.getRect(
            find.descendant(
              of: find.byKey(ValueKey<int>(index)),
              matching: find.byType(Icon),
            ),
          ),
        'bar': tester.getRect(_face),
      };
      // Stating a compact size of 1 is having no compact form: the same
      // glass bar, without the fold.
      await pumpTestApp(
        tester,
        _bar(_state(.never), style: _glass.copyWith(compactScale: 1)),
      );
      expect(
        find.ancestor(of: find.text('Home'), matching: find.byType(ClipRect)),
        findsNothing,
      );
      final plain = rects();
      await tester.pumpWidget(const SizedBox());
      await pumpTestApp(tester, _bar(_state(.never)));
      expect(
        find.ancestor(of: find.text('Home'), matching: find.byType(ClipRect)),
        findsWidgets,
      );
      expect(rects(), plain);
    });

    testWidgets('a bar with no compact form keeps its captions', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        _bar(_state(.always), style: const CoreNavigationBarStyle()),
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(find.text('Home')).height, greaterThan(0));
      expect(
        find.ancestor(of: find.text('Home'), matching: find.byType(ClipRect)),
        findsNothing,
        reason: 'no fold where there is nothing to fold for',
      );
    });

    testWidgets('a column shrinks about its centre', (tester) async {
      final state = _state(.never);
      await pumpTestApp(
        tester,
        _bar(state, mode: .rail, style: _glass.copyWith(compactScale: .8)),
      );
      final resting = tester.getRect(_face);

      state.compact = .always;
      await tester.pumpAndSettle();
      final drawn = tester.getRect(_face);
      expect(drawn.height, closeTo(resting.height * .8, 1e-6));
      expect(drawn.center.dx, closeTo(resting.center.dx, 1e-6));
      expect(drawn.center.dy, closeTo(resting.center.dy, 1e-6));
    });

    testWidgets("is reached over the style's duration, on the move curve", (
      tester,
    ) async {
      final state = _state(.never);
      await pumpTestApp(tester, _bar(state));
      state.compact = .always;
      await tester.pump();
      final animated = tester.widget<AnimatedScale>(_compaction);
      expect(animated.duration, CoreNavigationBarStyle.defaultCompactDuration);
      expect(animated.curve.toString(), CoreEasing.move.toValue().toString());

      await tester.pump(CoreNavigationBarStyle.defaultCompactDuration ~/ 2);
      expect(_drawn(tester), allOf(lessThan(1), greaterThan(_compactScale)));
      await tester.pumpAndSettle();
      expect(_drawn(tester), _compactScale);
    });

    testWidgets('is reached at once under reduced motion', (tester) async {
      final state = _state(.never);
      await pumpTestApp(tester, _bar(state), disableAnimations: true);
      state.compact = .always;
      await tester.pump();
      expect(
        tester.widget<AnimatedScale>(_compaction).duration,
        Duration.zero,
      );
      await tester.pump();
      expect(_drawn(tester), _compactScale);
    });

    testWidgets("keeps the bar's subtree when it turns compact", (
      tester,
    ) async {
      // An app that drives the form itself switches between `never` and
      // `always`; a wrapper that came and went would rebuild the bar from
      // nothing each time and cut the motion.
      final state = _state(.never);
      await pumpTestApp(tester, _bar(state));
      final before = tester.element(find.byKey(const ValueKey<int>(0)));
      state.compact = .always;
      await tester.pump();
      expect(_target(tester), _compactScale);
      expect(tester.element(find.byKey(const ValueKey<int>(0))), same(before));
    });

    testWidgets('a compact bar takes a tap where it is drawn', (tester) async {
      int? selected;
      await pumpTestApp(
        tester,
        _bar(_state(.always), onSelected: (index) => selected = index),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<int>(2)));
      await tester.pumpAndSettle();
      expect(selected, 2);
    });

    testWidgets('a drag along a compact bar selects where the finger goes', (
      tester,
    ) async {
      // The lens is placed in the bar as it is laid out and the finger is on
      // the bar as it is drawn; the compact form is one more transform
      // between the two.
      int? selected;
      await pumpTestApp(
        tester,
        _bar(_state(.always), onSelected: (index) => selected = index),
      );
      await tester.pumpAndSettle();
      final from = tester.getCenter(find.byKey(const ValueKey<int>(0)));
      final to = tester.getCenter(find.byKey(const ValueKey<int>(2)));
      final gesture = await tester.startGesture(from);
      await tester.pump();
      for (var step = 1; step <= 10; step++) {
        await gesture.moveTo(Offset.lerp(from, to, step / 10)!);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();
      expect(selected, 2);
    });
  });

  group('following the content', () {
    final vectors =
        jsonDecode(File(_kVectorsPath).readAsStringSync())
            as Map<String, Object?>;

    for (final trace in _list(vectors['traces'])) {
      testWidgets('the shared table: ${trace['name']}', (tester) async {
        final state = _state();
        await pumpTestApp(tester, _shell(state));
        final maxExtent = (trace['maxExtent']! as num).toDouble();
        for (final step in _list(trace['steps'])) {
          if (step['event'] == 'reset') {
            state.selectedIndex = state.value.selectedIndex == 0 ? 1 : 0;
          } else {
            _scrollStep(
              tester,
              offset: (step['offset']! as num).toDouble(),
              delta: (step['delta']! as num).toDouble(),
              maxExtent: maxExtent,
            );
          }
          await tester.pump();
          expect(
            _target(tester),
            step['compact']! as bool ? _compactScale : 1,
            reason: '$step',
          );
        }
      });
    }

    testWidgets('a drag on the content moves the bar and a drag back '
        'returns it', (tester) async {
      await pumpTestApp(tester, _shell(_state()));
      expect(_target(tester), 1);

      await tester.drag(find.byKey(_contentKey), const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(_target(tester), _compactScale);
      expect(_drawn(tester), _compactScale);

      await tester.drag(find.byKey(_contentKey), const Offset(0, 80));
      await tester.pumpAndSettle();
      expect(_target(tester), 1);
      expect(_drawn(tester), 1);
    });

    testWidgets('the content is not laid out again when the bar moves', (
      tester,
    ) async {
      await pumpTestApp(tester, _shell(_state()));
      final before = tester.getRect(find.byKey(_contentKey));
      await tester.drag(find.byKey(_contentKey), const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(_target(tester), _compactScale);
      expect(tester.getRect(find.byKey(_contentKey)), before);
    });

    testWidgets('a sideways scroll in the content does not move the bar', (
      tester,
    ) async {
      await pumpTestApp(tester, _shell(_state()));
      await tester.drag(find.byKey(_stripKey), const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(
        tester
            .state<ScrollableState>(
              find.descendant(
                of: find.byKey(_stripKey),
                matching: find.byType(Scrollable),
              ),
            )
            .position
            .pixels,
        greaterThan(0),
        reason: 'the strip did scroll',
      );
      expect(_target(tester), 1);
    });

    testWidgets('a nested vertical list cannot compact or restore the bar', (
      tester,
    ) async {
      final outer = ScrollController();
      final inner = ScrollController();
      final rows = ValueNotifier(10);
      addTearDown(outer.dispose);
      addTearDown(inner.dispose);
      addTearDown(rows.dispose);
      await pumpTestApp(
        tester,
        _shell(
          _state(),
          child: SingleChildScrollView(
            controller: outer,
            child: Column(
              children: [
                SizedBox(
                  height: 120,
                  child: ValueListenableBuilder<int>(
                    valueListenable: rows,
                    builder: (_, count, _) => ListView(
                      controller: inner,
                      children: [
                        for (var i = 0; i < count; i++)
                          const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 2000),
              ],
            ),
          ),
        ),
      );
      inner.jumpTo(60);
      await tester.pumpAndSettle();
      expect(inner.offset, 60);
      expect(_target(tester), 1);

      inner.jumpTo(0);
      outer.jumpTo(200);
      await tester.pumpAndSettle();
      expect(_target(tester), _compactScale);
      // A layout notification at offset zero is forwarded by the observer
      // as a scroll update; it must not look like the content reached its top.
      rows.value = 20;
      await tester.pumpAndSettle();
      expect(_target(tester), _compactScale);

      outer.jumpTo(160);
      await tester.pumpAndSettle();
      expect(_target(tester), 1);
    });

    for (final muteTickers in [false, true]) {
      testWidgets('an offstage tab cannot restore the bar '
          '(muted tickers: $muteTickers)', (tester) async {
        final active = ScrollController();
        final hidden = ScrollController();
        final rows = ValueNotifier(30);
        addTearDown(active.dispose);
        addTearDown(hidden.dispose);
        addTearDown(rows.dispose);
        await pumpTestApp(
          tester,
          _shell(
            _state(),
            child: Stack(
              children: [
                ListView(
                  controller: active,
                  children: const [SizedBox(height: 2000)],
                ),
                Offstage(
                  child: TickerMode(
                    enabled: !muteTickers,
                    child: ValueListenableBuilder<int>(
                      valueListenable: rows,
                      builder: (_, count, _) => ListView(
                        controller: hidden,
                        children: [
                          for (var i = 0; i < count; i++)
                            const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        active.jumpTo(200);
        await tester.pumpAndSettle();
        expect(_target(tester), _compactScale);
        rows.value = 60;
        await tester.pumpAndSettle();
        expect(_target(tester), _compactScale);
        hidden
          ..jumpTo(60)
          ..jumpTo(0);
        await tester.pumpAndSettle();
        expect(_target(tester), _compactScale);
      });
    }

    testWidgets('a vertical list inside a horizontal page is content', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await pumpTestApp(
        tester,
        _shell(
          _state(),
          child: PageView(
            children: [
              ListView(
                controller: controller,
                children: const [SizedBox(height: 2000)],
              ),
            ],
          ),
        ),
      );
      controller.jumpTo(200);
      await tester.pumpAndSettle();
      expect(_target(tester), _compactScale);
      controller.jumpTo(0);
      await tester.pumpAndSettle();
      expect(_target(tester), 1);
    });

    testWidgets("the bar's own column scrolling is not the content", (
      tester,
    ) async {
      // A rail too tall for its room scrolls its own column, vertically.
      await pumpTestApp(
        tester,
        SizedBox(
          width: 360,
          height: 200,
          child: ScrollNotificationObserver(
            child: Align(
              alignment: .centerLeft,
              child: NavigationBar(
                mode: .rail,
                items: const [..._items, ..._items],
                selectedIndex: 0,
                onSelected: (_) {},
                compact: .onScroll,
                navigationBarStyle: _glass.copyWith(compactScale: .8),
              ),
            ),
          ),
        ),
      );
      final column = find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byType(Scrollable),
      );
      final position = tester.state<ScrollableState>(column).position;
      expect(position.maxScrollExtent, greaterThan(40));
      position.jumpTo(40);
      await tester.pump();
      expect(position.pixels, 40, reason: 'the column did scroll');
      expect(_target(tester), 1);
    });

    testWidgets('`never` and `always` do not follow the content', (
      tester,
    ) async {
      final state = _state(.never);
      await pumpTestApp(tester, _shell(state));
      await tester.drag(find.byKey(_contentKey), const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(_target(tester), 1);

      state.compact = .always;
      await tester.pumpAndSettle();
      await tester.drag(find.byKey(_contentKey), const Offset(0, 150));
      await tester.pumpAndSettle();
      expect(_target(tester), _compactScale);
    });

    testWidgets('a bar that stops following returns in full, and starts '
        'again from there', (tester) async {
      final state = _state();
      await pumpTestApp(tester, _shell(state));
      await tester.drag(find.byKey(_contentKey), const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(_target(tester), _compactScale);

      state.compact = .never;
      await tester.pump();
      expect(_target(tester), 1);
      state.compact = .onScroll;
      await tester.pump();
      expect(_target(tester), 1);
      await tester.drag(find.byKey(_contentKey), const Offset(0, -100));
      await tester.pumpAndSettle();
      expect(_target(tester), _compactScale);
    });

    testWidgets('without an observer above it the bar keeps its size', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        SizedBox(
          width: 360,
          height: 640,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  key: _contentKey,
                  children: [
                    for (var i = 0; i < 60; i++) const SizedBox(height: 80),
                  ],
                ),
              ),
              const NavigationBar(
                items: _items,
                compact: .onScroll,
                navigationBarStyle: _glass,
              ),
            ],
          ),
        ),
      );
      await tester.drag(find.byKey(_contentKey), const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(_target(tester), 1);
    });
  });
}
