import 'dart:ui' show Tristate;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

/// The designer's answer for a destination that is selected AND disabled
/// (#5740, #6358): it keeps its selection mark, dimmed. Read from what the
/// widget paints, not from the resolver:
///
/// - the whole tile — stacked or a row, under either indicator — takes
///   [CoreNavigationBarStyle.defaultDisabledSelectedFaceColor], with the
///   glyph in `disabledContent`; no pill wraps the icon;
/// - the label takes `disabledContent` at the selected weight (bold);
/// - assistive technology still hears no selection.

Future<void> _reset(WidgetTester tester) =>
    tester.pumpWidget(const SizedBox.shrink());

Color _color(BuildContext context, CoreColor color) =>
    Theme.of(context).colorScheme.resolve(color).toValue();

Color _token(BuildContext context, CoreColorToken token) =>
    _color(context, CoreColor.token(token));

/// The dimmed selected face Core states for every indicator.
Color _dimmedFace(BuildContext context) =>
    _color(context, CoreNavigationBarStyle.defaultDisabledSelectedFaceColor);

final FontWeight? _bold = fontWeightFromInt(CoreFontWeight.bold);

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

/// The destination's painted boxes. The tile is the only one: no pill wraps
/// the icon (#6358).
List<BoxDecoration> _boxes(WidgetTester tester, [Finder? within]) => tester
    .widgetList<AnimatedContainer>(
      find.descendant(
        of: within ?? find.byType(NavigationBarItem),
        matching: find.byType(AnimatedContainer),
      ),
    )
    .map((box) => box.decoration! as BoxDecoration)
    .toList();

TextStyle _label(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style!;

Color? _iconColor(WidgetTester tester, Key key) =>
    IconTheme.of(tester.element(find.byKey(key))).color;

NavigationBarItem _item({
  required CoreNavigationBarMode mode,
  required bool selected,
  CoreNavigationLabelPosition? labelPosition,
  CoreNavigationLabelMode? labelMode,
  CoreNavigationSelectionIndicator? indicator,
}) => NavigationBarItem(
  mode: mode,
  labelPosition: labelPosition,
  labelMode: labelMode,
  indicator: indicator,
  icon: const Icon(LucideIcons.inbox, key: ValueKey('icon')),
  label: 'Inbox',
  selected: selected,
  enabled: false,
);

void main() {
  group('a selected, disabled stacked destination', () {
    for (final indicator in CoreNavigationSelectionIndicator.values) {
      for (final labelMode in [
        CoreNavigationLabelMode.all,
        CoreNavigationLabelMode.none,
      ]) {
        testWidgets('${indicator.name}, label ${labelMode.name}', (
          tester,
        ) async {
          final context = await _pump(
            tester,
            _item(
              mode: CoreNavigationBarMode.rail,
              labelMode: labelMode,
              indicator: indicator,
              selected: true,
            ),
          );
          final boxes = _boxes(tester);
          // Under `fill` the tile carries the dimmed selection; under `color`
          // it paints no face (#6393). Nothing paints round the icon.
          expect(boxes, hasLength(1));
          if (indicator == CoreNavigationSelectionIndicator.fill) {
            expect(boxes.single.color, _dimmedFace(context));
          } else {
            expect(boxes.single.color?.a ?? 0, 0);
          }
          expect(
            _iconColor(tester, const ValueKey('icon')),
            _token(context, CoreColors.disabledContent),
          );
          if (labelMode == CoreNavigationLabelMode.all) {
            final label = _label(tester, 'Inbox');
            expect(label.color, _token(context, CoreColors.disabledContent));
            expect(label.fontWeight, _bold);
          }
        });
      }
    }

    testWidgets('an unselected disabled destination paints no face', (
      tester,
    ) async {
      final context = await _pump(
        tester,
        _item(mode: CoreNavigationBarMode.rail, selected: false),
      );
      expect(_boxes(tester).single.color!.a, 0);
      final label = _label(tester, 'Inbox');
      expect(label.color, _token(context, CoreColors.disabledContent));
      // The resting weight — only the selected one is heavier.
      expect(label.fontWeight, fontWeightFromInt(CoreFontWeight.medium));
    });
  });

  testWidgets('a row dims its face', (tester) async {
    final context = await _pump(
      tester,
      SizedBox(
        width: 240,
        child: _item(
          mode: CoreNavigationBarMode.rail,
          labelPosition: CoreNavigationLabelPosition.end,
          selected: true,
        ),
      ),
    );
    expect(_boxes(tester).first.color, _dimmedFace(context));
    final label = _label(tester, 'Inbox');
    expect(label.color, _token(context, CoreColors.disabledContent));
    expect(label.fontWeight, _bold);
  });

  testWidgets('the color indicator paints no face, keeps the weight', (
    tester,
  ) async {
    final context = await _pump(
      tester,
      _item(
        mode: CoreNavigationBarMode.bar,
        indicator: CoreNavigationSelectionIndicator.color,
        selected: true,
      ),
    );
    // No face (#6393) — the bold weight tells it from the other disabled
    // destinations.
    expect(_boxes(tester).single.color?.a ?? 0, 0);
    final label = _label(tester, 'Inbox');
    expect(label.color, _token(context, CoreColors.disabledContent));
    expect(label.fontWeight, _bold);
  });
  testWidgets('the selection dot stays, dimmed', (tester) async {
    final context = await _pump(
      tester,
      const NavigationBarItem(
        mode: CoreNavigationBarMode.rail,
        selectionMark: CoreNavigationSelectionMark.dot,
        icon: Icon(LucideIcons.inbox),
        label: 'Inbox',
        selected: true,
        enabled: false,
      ),
    );
    final mark = tester.widget<AnimatedOpacity>(
      find.ancestor(
        of: find.byType(Badge),
        matching: find.byType(AnimatedOpacity),
      ),
    );
    expect(mark.opacity, 1);
    final dot = tester.widget<Badge>(find.byType(Badge));
    final color = dot.badgeStyle!.backgroundColor!;
    expect(
      Theme.of(context).colorScheme.resolve(color).toValue(),
      _token(context, CoreColors.disabledContent),
    );
  });

  testWidgets('an unselected disabled destination shows no dot', (
    tester,
  ) async {
    await _pump(
      tester,
      const NavigationBarItem(
        mode: CoreNavigationBarMode.rail,
        selectionMark: CoreNavigationSelectionMark.dot,
        icon: Icon(LucideIcons.inbox),
        label: 'Inbox',
        enabled: false,
      ),
    );
    final mark = tester.widget<AnimatedOpacity>(
      find.ancestor(
        of: find.byType(Badge),
        matching: find.byType(AnimatedOpacity),
      ),
    );
    expect(mark.opacity, 0);
  });

  testWidgets('a caller face still wins', (tester) async {
    await _pump(
      tester,
      const NavigationBarItem(
        mode: CoreNavigationBarMode.rail,
        navigationBarStyle: CoreNavigationBarStyle(
          disabledSelectedBackgroundColor: CoreColor(0xFFFF0000),
        ),
        icon: Icon(LucideIcons.inbox),
        label: 'Inbox',
        selected: true,
        enabled: false,
      ),
    );
    expect(_boxes(tester).single.color, const Color(0xFFFF0000));
  });

  testWidgets('the deprecated pill colour paints nothing', (tester) async {
    final context = await _pump(
      tester,
      const NavigationBarItem(
        mode: CoreNavigationBarMode.rail,
        navigationBarStyle: CoreNavigationBarStyle(
          // The no-op is what is under test.
          // ignore: deprecated_member_use
          disabledSelectedIconAnchorColor: CoreColor(0xFFFF0000),
        ),
        icon: Icon(LucideIcons.inbox),
        label: 'Inbox',
        selected: true,
        enabled: false,
      ),
    );
    final boxes = _boxes(tester);
    expect(boxes, hasLength(1));
    expect(boxes.single.color, _dimmedFace(context));
  });

  testWidgets('inside the bar, the current disabled destination keeps it', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final context = await _pump(
      tester,
      SizedBox(
        width: 320,
        child: NavigationBar(
          mode: CoreNavigationBarMode.rail,
          selectedIndex: 0,
          onSelected: (_) {},
          items: const [
            CoreNavigationBarItem.destination(
              icon: Icon(LucideIcons.house),
              label: 'Home',
              enabled: false,
            ),
            CoreNavigationBarItem.destination(
              icon: Icon(LucideIcons.search),
              label: 'Search',
            ),
          ],
        ),
      ),
    );
    final first = find.byType(NavigationBarItem).first;
    expect(_boxes(tester, first).single.color, _dimmedFace(context));
    final label = _label(tester, 'Home');
    expect(label.color, _token(context, CoreColors.disabledContent));
    expect(label.fontWeight, _bold);
    final clickable = find.descendant(
      of: first,
      matching: find.byType(Clickable),
    );
    final data = tester.getSemantics(clickable).getSemanticsData();
    expect(data.flagsCollection.isSelected, Tristate.isFalse);
    handle.dispose();
  });
}
