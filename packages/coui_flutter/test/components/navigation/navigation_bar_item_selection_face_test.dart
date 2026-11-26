import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

/// The designer's answers for `NavigationBarItem` (#5740, #6358), read from
/// what the widget paints and lays out:
///
/// - a selected destination — a row (the label beside the icon) or stacked,
///   label shown or hidden — takes a `primary` glyph and a bold `primary`
///   label; under `fill` its whole tile paints
///   [CoreNavigationBarStyle.defaultSelectedFaceColor], under `color` it
///   paints no face (#6393); no pill wraps the icon;
/// - an icon-only destination paints 64 × 40 and still takes a tap within 48.

Future<void> _reset(WidgetTester tester) =>
    tester.pumpWidget(const SizedBox.shrink());

Color _color(BuildContext context, CoreColor color) =>
    Theme.of(context).colorScheme.resolve(color).toValue();

Color _token(BuildContext context, CoreColorToken token) =>
    _color(context, CoreColor.token(token));

Color _selectedFace(BuildContext context) =>
    _color(context, CoreNavigationBarStyle.defaultSelectedFaceColor);

Future<BuildContext> _pump(WidgetTester tester, Widget child) async {
  late BuildContext captured;
  await _reset(tester);
  await tester.pumpWidget(
    buildTestApp(
      Builder(
        builder: (context) {
          captured = context;
          return Align(alignment: Alignment.topLeft, child: child);
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return captured;
}

/// The destination's own painted box — the outermost `AnimatedContainer`.
Finder _box([Finder? within]) => find
    .descendant(
      of: within ?? find.byType(NavigationBarItem),
      matching: find.byType(AnimatedContainer),
    )
    .first;

BoxDecoration _face(WidgetTester tester, [Finder? within]) =>
    tester.widget<AnimatedContainer>(_box(within)).decoration! as BoxDecoration;

Color? _iconColor(WidgetTester tester, Key key) =>
    IconTheme.of(tester.element(find.byKey(key))).color;

/// Every painted box under the destination — the tile alone (#6358).
List<BoxDecoration> _boxes(WidgetTester tester) => tester
    .widgetList<AnimatedContainer>(
      find.descendant(
        of: find.byType(NavigationBarItem),
        matching: find.byType(AnimatedContainer),
      ),
    )
    .map((box) => box.decoration! as BoxDecoration)
    .toList();

/// The selection every placement states: one painted box — the tile face
/// under `fill`, no face under `color` — a `primary` glyph and, when shown,
/// a bold `primary` label.
void _expectSelected(
  WidgetTester tester,
  BuildContext context,
  CoreNavigationSelectionIndicator indicator, {
  bool labelShown = true,
}) {
  final boxes = _boxes(tester);
  expect(boxes, hasLength(1));
  expect(
    boxes.single.color,
    indicator == CoreNavigationSelectionIndicator.fill
        ? _selectedFace(context)
        : _color(context, CoreColor.transparent),
  );
  final primary = _token(context, CoreColors.primary);
  expect(_iconColor(tester, const ValueKey('icon')), primary);
  if (labelShown) {
    final label = tester.widget<Text>(find.text('Inbox')).style!;
    expect(label.color, primary);
    expect(label.fontWeight, fontWeightFromInt(CoreFontWeight.bold));
  }
}

void main() {
  group('every placement marks the selection', () {
    for (final indicator in CoreNavigationSelectionIndicator.values) {
      testWidgets('${indicator.name}, label at the end', (tester) async {
        final context = await _pump(
          tester,
          SizedBox(
            width: 240,
            child: NavigationBarItem(
              mode: CoreNavigationBarMode.rail,
              indicator: indicator,
              labelPosition: CoreNavigationLabelPosition.end,
              icon: const Icon(LucideIcons.inbox, key: ValueKey('icon')),
              label: 'Inbox',
              selected: true,
              onPressed: () {},
            ),
          ),
        );
        _expectSelected(tester, context, indicator);
      });

      testWidgets('${indicator.name}, stacked with its label shown', (
        tester,
      ) async {
        final context = await _pump(
          tester,
          NavigationBarItem(
            mode: CoreNavigationBarMode.rail,
            indicator: indicator,
            icon: const Icon(LucideIcons.inbox, key: ValueKey('icon')),
            label: 'Inbox',
            selected: true,
            onPressed: () {},
          ),
        );
        _expectSelected(tester, context, indicator);
      });

      testWidgets('${indicator.name}, icon only', (tester) async {
        final context = await _pump(
          tester,
          NavigationBarItem(
            mode: CoreNavigationBarMode.rail,
            indicator: indicator,
            labelMode: CoreNavigationLabelMode.none,
            icon: const Icon(LucideIcons.inbox, key: ValueKey('icon')),
            label: 'Inbox',
            selected: true,
            onPressed: () {},
          ),
        );
        _expectSelected(tester, context, indicator, labelShown: false);
      });
    }

    testWidgets('a row and a stacked destination share one face', (
      tester,
    ) async {
      // A rail that expands into rows keeps the face it had.
      final context = await _pump(
        tester,
        SizedBox(
          width: 240,
          child: NavigationBarItem(
            mode: CoreNavigationBarMode.rail,
            labelPosition: CoreNavigationLabelPosition.end,
            icon: const Icon(LucideIcons.inbox, key: ValueKey('icon')),
            label: 'Inbox',
            selected: true,
            onPressed: () {},
          ),
        ),
      );
      final row = _face(tester).color;
      expect(row, _selectedFace(context));
      await _pump(
        tester,
        NavigationBarItem(
          mode: CoreNavigationBarMode.rail,
          icon: const Icon(LucideIcons.inbox, key: ValueKey('icon')),
          label: 'Inbox',
          selected: true,
          onPressed: () {},
        ),
      );
      expect(_face(tester).color, row);
    });

    testWidgets('a focused selected stacked destination lays the layer', (
      tester,
    ) async {
      late ResolvedNavigationBar resolved;
      await _pump(
        tester,
        Builder(
          builder: (context) {
            resolved = resolveNavigationBar(
              context,
              mode: CoreNavigationBarMode.rail,
              variant: CoreNavigationBarVariant.defaultVariant,
            );
            return NavigationBarItem(
              mode: CoreNavigationBarMode.rail,
              icon: const Icon(LucideIcons.inbox),
              label: 'Inbox',
              selected: true,
              onPressed: () {},
            );
          },
        ),
      );
      final previous = FocusManager.instance.highlightStrategy;
      FocusManager.instance.highlightStrategy = .alwaysTraditional;
      addTearDown(() => FocusManager.instance.highlightStrategy = previous);
      final inner = find.descendant(
        of: find.byType(Clickable),
        matching: find.byType(AnimatedContainer),
      );
      Focus.of(tester.element(inner.first)).requestFocus();
      await tester.pumpAndSettle();
      // The selected face stays; the 8 % layer is laid over it.
      expect(_face(tester).color, resolved.selectedFocusBackgroundColor);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
    });

    for (final labelPosition in [
      CoreNavigationLabelPosition.end,
      CoreNavigationLabelPosition.bottom,
    ]) {
      testWidgets('a caller face still outranks the default '
          '(${labelPosition.name})', (tester) async {
        await _pump(
          tester,
          SizedBox(
            width: 240,
            child: NavigationBarItem(
              mode: CoreNavigationBarMode.rail,
              labelPosition: labelPosition,
              navigationBarStyle: const CoreNavigationBarStyle(
                selectedBackgroundColor: CoreColor(0xFFFF0000),
              ),
              icon: const Icon(LucideIcons.inbox),
              label: 'Inbox',
              selected: true,
              onPressed: () {},
            ),
          ),
        );
        expect(_face(tester).color, const Color(0xFFFF0000));
      });
    }

    testWidgets('the deprecated pill fields paint nothing', (tester) async {
      final context = await _pump(
        tester,
        NavigationBarItem(
          mode: CoreNavigationBarMode.rail,
          navigationBarStyle: const CoreNavigationBarStyle(
            // The no-op is what is under test.
            // ignore: deprecated_member_use
            selectedIconAnchorColor: CoreColor(0xFFFF0000),
            // The no-op is what is under test.
            // ignore: deprecated_member_use
            selectedIconAnchorIconStyle: CoreIconStyle(
              color: CoreColor(0xFF00FF00),
            ),
          ),
          icon: const Icon(LucideIcons.inbox, key: ValueKey('icon')),
          label: 'Inbox',
          selected: true,
          onPressed: () {},
        ),
      );
      _expectSelected(tester, context, CoreNavigationSelectionIndicator.fill);
    });
  });

  group('an icon-only destination paints 64 × 40', () {
    testWidgets('standalone, hugging its content', (tester) async {
      // Unconstrained across, the destination hugs: the 48 pill and the
      // item padding come to 56, the floor lifts it to 64.
      await _pump(
        tester,
        UnconstrainedBox(
          child: NavigationBarItem(
            mode: CoreNavigationBarMode.rail,
            labelMode: CoreNavigationLabelMode.none,
            icon: const Icon(LucideIcons.inbox),
            label: 'Inbox',
            onPressed: () {},
          ),
        ),
      );
      expect(tester.getSize(_box()), const Size(64, 40));
    });

    testWidgets('a narrower share wins over the width floor', (tester) async {
      await _pump(
        tester,
        SizedBox(
          width: 58,
          child: NavigationBarItem(
            mode: CoreNavigationBarMode.rail,
            labelMode: CoreNavigationLabelMode.none,
            icon: const Icon(LucideIcons.inbox),
            label: 'Inbox',
            onPressed: () {},
          ),
        ),
      );
      expect(tester.getSize(_box()), const Size(58, 40));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a labelled destination keeps the 64 floor', (tester) async {
      await _pump(
        tester,
        NavigationBarItem(
          mode: CoreNavigationBarMode.rail,
          icon: const Icon(LucideIcons.inbox),
          label: 'Inbox',
          onPressed: () {},
        ),
      );
      expect(tester.getSize(_box()).height, 64);
    });

    testWidgets('a stated itemMinHeight still reaches it', (tester) async {
      await _pump(
        tester,
        NavigationBarItem(
          mode: CoreNavigationBarMode.rail,
          labelMode: CoreNavigationLabelMode.none,
          navigationBarStyle: const CoreNavigationBarStyle(itemMinHeight: 56),
          icon: const Icon(LucideIcons.inbox),
          label: 'Inbox',
          onPressed: () {},
        ),
      );
      expect(tester.getSize(_box()).height, 56);
    });
  });

  group('a tap within 48 reaches the icon-only destination', () {
    testWidgets('standalone, 3 above the painted box', (tester) async {
      var taps = 0;
      await _pump(
        tester,
        Padding(
          padding: const EdgeInsets.all(20),
          child: NavigationBarItem(
            mode: CoreNavigationBarMode.rail,
            labelMode: CoreNavigationLabelMode.none,
            icon: const Icon(LucideIcons.inbox),
            label: 'Inbox',
            onPressed: () => taps += 1,
          ),
        ),
      );
      final box = tester.getRect(_box());
      await tester.tapAt(Offset(box.center.dx, box.top - 3));
      expect(taps, 1);
      // Outside the 48 region the pointer is not the destination's.
      await tester.tapAt(Offset(box.center.dx, box.top - 6));
      expect(taps, 1);
    });

    testWidgets('in the bar, 3 below the painted row', (tester) async {
      final taps = <int>[];
      await _pump(
        tester,
        SizedBox(
          width: 360,
          child: NavigationBar(
            labelMode: CoreNavigationLabelMode.none,
            selectedIndex: 0,
            onSelected: taps.add,
            items: const [
              CoreNavigationBarItem.destination(
                icon: Icon(LucideIcons.house),
                label: 'Home',
              ),
              CoreNavigationBarItem.destination(
                icon: Icon(LucideIcons.search),
                label: 'Search',
              ),
            ],
          ),
        ),
      );
      final second = tester.getRect(_box(find.byType(NavigationBarItem).last));
      expect(second.height, 40);
      await tester.tapAt(Offset(second.center.dx, second.bottom + 3));
      expect(taps, [1]);
    });
  });
}
