import 'dart:ui' show Tristate;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

/// `NavigationBarItem` is the destination the bar composes, placed on its
/// own. Each test reads the rendered value — the face the box paints, the
/// height it lays out to, the node assistive technology reads — so an item
/// that merely builds without behaving like the bar's destination fails.

const _badge = Badge(
  form: CoreBadgeForm.count,
  tone: CoreBadgeTone.info,
  variant: CoreBadgeVariant.filled,
  size: CoreComponentSize.xs,
  child: Text('3'),
);

/// The test shell's `Overlay` keeps the entries it was first built with, so a
/// second pump of the same shell would keep showing the first child.
Future<void> _reset(WidgetTester tester) =>
    tester.pumpWidget(const SizedBox.shrink());

Future<ResolvedNavigationBar> _resolved(
  WidgetTester tester, {
  CoreNavigationBarMode mode = CoreNavigationBarMode.sidebar,
}) async {
  late ResolvedNavigationBar resolved;
  await _reset(tester);
  await tester.pumpWidget(
    buildTestApp(
      Builder(
        builder: (context) {
          resolved = resolveNavigationBar(
            context,
            mode: mode,
            variant: CoreNavigationBarVariant.defaultVariant,
          );
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return resolved;
}

Future<void> _pumpItem(WidgetTester tester, Widget item) async {
  await _reset(tester);
  await tester.pumpWidget(
    buildTestApp(
      Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: 240, child: item),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The item's face — the box that paints the per-state fill.
BoxDecoration _face(WidgetTester tester, [Finder? within]) {
  final box = tester.widget<AnimatedContainer>(
    find
        .descendant(
          of: within ?? find.byType(NavigationBarItem),
          matching: find.byType(AnimatedContainer),
        )
        .first,
  );
  return box.decoration! as BoxDecoration;
}

Finder _clickable([Finder? within]) => find.descendant(
  of: within ?? find.byType(NavigationBarItem),
  matching: find.byType(Clickable),
);

void main() {
  late FocusHighlightStrategy previousStrategy;
  setUp(() {
    // Hover and focus faces are highlight-driven; the default touch strategy
    // of the test platform never shows either.
    previousStrategy = FocusManager.instance.highlightStrategy;
    FocusManager.instance.highlightStrategy = .alwaysTraditional;
  });
  tearDown(() => FocusManager.instance.highlightStrategy = previousStrategy);

  group('a standalone item draws a sidebar row', () {
    testWidgets('the sidebar density by default', (tester) async {
      final resolved = await _resolved(tester);
      await _pumpItem(
        tester,
        NavigationBarItem(
          icon: const Icon(LucideIcons.inbox),
          label: 'Inbox',
          onPressed: () {},
        ),
      );

      expect(
        CoreNavigationBarItemContract.defaultMode,
        CoreNavigationBarMode.sidebar,
      );
      expect(
        tester.getSize(find.byType(NavigationBarItem)).height,
        resolved.itemMinHeight,
      );
      expect(resolved.itemMinHeight, 40);
      expect(find.text('Inbox'), findsOneWidget);
    });

    testWidgets('the selected face and the resting face', (tester) async {
      final resolved = await _resolved(tester);
      await _pumpItem(
        tester,
        NavigationBarItem(
          label: 'Inbox',
          selected: true,
          onPressed: () {},
        ),
      );
      // A row — the label beside the icon — takes the row face, the
      // icon-only pill's `primaryContainer` pair (#5740).
      expect(_face(tester).color, resolved.selectedBackgroundColor);
      expect(
        tester.widget<Text>(find.text('Inbox')).style,
        resolved.selectedRowLabelTextStyle,
      );

      await _pumpItem(
        tester,
        NavigationBarItem(label: 'Inbox', onPressed: () {}),
      );
      expect(_face(tester).color, resolved.idleBackgroundColor);
      expect(
        tester.widget<Text>(find.text('Inbox')).style,
        resolved.labelTextStyle,
      );
    });

    testWidgets('the count sits at the far end of the row', (tester) async {
      await _pumpItem(
        tester,
        NavigationBarItem(
          icon: const Icon(LucideIcons.inbox),
          label: 'Inbox',
          badge: const KeyedSubtree(key: ValueKey('badge'), child: _badge),
          onPressed: () {},
        ),
      );
      final row = tester.getRect(find.byType(NavigationBarItem));
      final badge = tester.getRect(find.byKey(const ValueKey('badge')));
      final label = tester.getRect(find.text('Inbox'));
      final resolved = await _resolvedPadding(tester);

      // The far end, less the row's own end padding — not after the label.
      expect(badge.right, closeTo(row.right - resolved, 0.01));
      expect(badge.left, greaterThan(label.right));
      expect(find.byType(Indicator), findsNothing);
    });

    // The designer's answer (#5740): a disabled item that is the current one
    // keeps its selection mark, dimmed — the row's face in the disabled area
    // tone, the label in the disabled tone at the selected weight — and still
    // states no selection to assistive technology.
    testWidgets('a disabled selected item keeps its mark, dimmed', (
      tester,
    ) async {
      final resolved = await _resolved(tester);
      final handle = tester.ensureSemantics();
      await _pumpItem(
        tester,
        NavigationBarItem(
          label: 'Inbox',
          selected: true,
          enabled: false,
          onPressed: () {},
        ),
      );

      expect(_face(tester).color, resolved.disabledSelectedBackgroundColor);
      expect(
        tester.widget<Text>(find.text('Inbox')).style,
        resolved.disabledSelectedLabelTextStyle,
      );
      final data = tester.getSemantics(_clickable()).getSemanticsData();
      expect(data.flagsCollection.isSelected, Tristate.isFalse);
      expect(data.flagsCollection.isEnabled, Tristate.isFalse);
      handle.dispose();
    });
  });

  group('enabled follows the callback', () {
    testWidgets('no onPressed → disabled', (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpItem(tester, const NavigationBarItem(label: 'Inbox'));
      final data = tester.getSemantics(_clickable()).getSemanticsData();
      expect(data.flagsCollection.isEnabled, isNot(Tristate.none));
      expect(data.flagsCollection.isEnabled, Tristate.isFalse);
      handle.dispose();
    });

    testWidgets('an onPressed → enabled, and a tap reaches it', (
      tester,
    ) async {
      var presses = 0;
      final handle = tester.ensureSemantics();
      await _pumpItem(
        tester,
        NavigationBarItem(label: 'Inbox', onPressed: () => presses++),
      );
      final data = tester.getSemantics(_clickable()).getSemanticsData();
      expect(data.flagsCollection.isEnabled, Tristate.isTrue);
      await tester.tap(find.byType(NavigationBarItem));
      expect(presses, 1);
      handle.dispose();
    });

    testWidgets('enabled: false wins over a callback', (tester) async {
      var presses = 0;
      await _pumpItem(
        tester,
        NavigationBarItem(
          label: 'Inbox',
          enabled: false,
          onPressed: () => presses++,
        ),
      );
      await tester.tap(find.byType(NavigationBarItem), warnIfMissed: false);
      expect(presses, 0);
    });
  });

  group('semantics — one node, the current place, the count heard', () {
    testWidgets('selected states the current place', (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpItem(
        tester,
        NavigationBarItem(label: 'Inbox', selected: true, onPressed: () {}),
      );
      final data = tester.getSemantics(_clickable()).getSemanticsData();
      expect(data.flagsCollection.isSelected, Tristate.isTrue);
      expect(data.flagsCollection.isButton, isTrue);
      handle.dispose();
    });

    testWidgets('the badge is heard after the name', (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpItem(
        tester,
        NavigationBarItem(
          icon: const Icon(LucideIcons.inbox),
          label: 'Inbox',
          badge: _badge,
          onPressed: () {},
        ),
      );
      expect(
        tester.getSemantics(_clickable()).getSemanticsData().label,
        'Inbox\n3',
      );
      handle.dispose();
    });

    testWidgets('a hidden label is still the name, and the tooltip', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pumpItem(
        tester,
        NavigationBarItem(
          icon: const Icon(LucideIcons.inbox),
          label: 'Inbox',
          labelMode: CoreNavigationLabelMode.none,
          onPressed: () {},
        ),
      );
      expect(find.text('Inbox'), findsNothing);
      expect(
        tester.getSemantics(_clickable()).getSemanticsData().label,
        'Inbox',
      );
      expect(
        tester.widget<Tooltip>(find.byType(Tooltip)).message,
        'Inbox',
      );
      handle.dispose();
    });
  });

  group('interaction faces', () {
    testWidgets('hover · focus · press each paint their own face', (
      tester,
    ) async {
      final resolved = await _resolved(tester);
      await _pumpItem(
        tester,
        NavigationBarItem(label: 'Inbox', onPressed: () {}),
      );

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.byType(NavigationBarItem)));
      await tester.pumpAndSettle();
      expect(_face(tester).color, resolved.hoverBackgroundColor);
      await mouse.moveTo(const Offset(700, 500));
      await tester.pumpAndSettle();
      expect(_face(tester).color, resolved.idleBackgroundColor);

      final inner = find.descendant(
        of: _clickable(),
        matching: find.byType(AnimatedContainer),
      );
      Focus.of(tester.element(inner.first)).requestFocus();
      await tester.pumpAndSettle();
      expect(_face(tester).color, resolved.focusBackgroundColor);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();

      final press = await tester.startGesture(
        tester.getCenter(find.byType(NavigationBarItem)),
      );
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(_face(tester).color, resolved.pressedBackgroundColor);
      await press.up();
      await tester.pumpAndSettle();
      expect(_face(tester).color, resolved.idleBackgroundColor);
    });

    testWidgets('a selected item lays the layer over its face', (
      tester,
    ) async {
      // #5740 — the state layer is laid over the selection, not swapped for
      // it: a focused selected row is its face under the 8 % layer.
      final resolved = await _resolved(tester);
      await _pumpItem(
        tester,
        NavigationBarItem(label: 'Inbox', selected: true, onPressed: () {}),
      );
      expect(_face(tester).color, resolved.selectedBackgroundColor);

      final inner = find.descendant(
        of: _clickable(),
        matching: find.byType(AnimatedContainer),
      );
      Focus.of(tester.element(inner.first)).requestFocus();
      await tester.pumpAndSettle();
      expect(_face(tester).color, resolved.selectedFocusBackgroundColor);
      expect(
        resolved.selectedFocusBackgroundColor,
        isNot(resolved.selectedBackgroundColor),
      );
      final ink =
          Theme.of(
                tester.element(find.byType(NavigationBarItem)),
              ).colorScheme
              .resolve(const CoreColor.token(CoreColors.onSurface))
              .toValue();
      expect(
        resolved.selectedFocusBackgroundColor,
        Color.alphaBlend(
          ink.withValues(alpha: 0.08),
          Color.alphaBlend(
            resolved.selectedBackgroundColor,
            resolved.backgroundColor,
          ),
        ),
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
    });

    testWidgets('Enter and Space activate the focused item', (tester) async {
      var presses = 0;
      await _pumpItem(
        tester,
        NavigationBarItem(label: 'Inbox', onPressed: () => presses++),
      );
      final inner = find.descendant(
        of: _clickable(),
        matching: find.byType(AnimatedContainer),
      );
      Focus.of(tester.element(inner.first)).requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(presses, 2);
    });
  });

  group('the bar and the rail densities', () {
    for (final mode in [
      CoreNavigationBarMode.bar,
      CoreNavigationBarMode.rail,
    ]) {
      testWidgets(
        '${mode.name} stacks the label and hangs the badge on the icon',
        (
          tester,
        ) async {
          final resolved = await _resolved(tester, mode: mode);
          await _pumpItem(
            tester,
            NavigationBarItem(
              mode: mode,
              icon: const Icon(LucideIcons.inbox, key: ValueKey('icon')),
              label: 'Inbox',
              labelMode: CoreNavigationLabelMode.all,
              badge: _badge,
              onPressed: () {},
            ),
          );
          expect(
            tester.getSize(find.byType(NavigationBarItem)).height,
            greaterThanOrEqualTo(resolved.itemMinHeight),
          );
          expect(find.byType(Indicator), findsOneWidget);
          final icon = tester.getRect(find.byKey(const ValueKey('icon')));
          final label = tester.getRect(find.text('Inbox'));
          expect(label.top, greaterThan(icon.bottom));
        },
      );
    }
  });

  testWidgets('a standalone item is the destination the bar composes', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    Widget host(Widget child, {double width = 240}) => buildTestApp(
      Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: width, child: child),
      ),
    );
    await tester.pumpWidget(
      host(
        NavigationBar(
          mode: CoreNavigationBarMode.sidebar,
          selectedIndex: 0,
          onSelected: (_) {},
          navigationBarStyle: const CoreNavigationBarStyle(
            padding: CoreEdgeInsets.zero,
          ),
          items: const [
            CoreNavigationBarItem.destination(
              icon: Icon(LucideIcons.inbox),
              label: 'Inbox',
              badge: _badge,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    final composedSize = tester.getSize(find.byType(NavigationBarItem));
    final composedFace = _face(tester);
    final composedNode = tester.getSemantics(_clickable()).getSemanticsData();

    await _reset(tester);
    // The bar's own hairline takes a pixel off its width; the standalone
    // item gets the width the bar's item got.
    await tester.pumpWidget(
      host(
        width: composedSize.width,
        NavigationBarItem(
          icon: const Icon(LucideIcons.inbox),
          label: 'Inbox',
          badge: _badge,
          selected: true,
          onPressed: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(NavigationBarItem)), composedSize);
    expect(_face(tester), composedFace);
    final standaloneNode = tester.getSemantics(_clickable()).getSemanticsData();
    expect(standaloneNode.label, composedNode.label);
    expect(standaloneNode.flagsCollection, composedNode.flagsCollection);
    handle.dispose();
  });

  testWidgets('an unbounded row keeps the badge after the label', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestApp(
        Align(
          alignment: Alignment.topLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              NavigationBarItem(
                icon: const Icon(LucideIcons.inbox),
                label: 'Inbox',
                badge: const KeyedSubtree(
                  key: ValueKey('badge'),
                  child: _badge,
                ),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final badge = tester.getRect(find.byKey(const ValueKey('badge')));
    final label = tester.getRect(find.text('Inbox'));
    expect(badge.left, greaterThan(label.right));
  });

  testWidgets('withStyle merges into the bar style the item draws', (
    tester,
  ) async {
    await _pumpItem(
      tester,
      NavigationBarItem(label: 'Inbox', onPressed: () {}).withStyle(
        const CoreNavigationBarStyle(
          itemRadius: CoreBorderRadius.all(CoreRadius.radius2),
        ),
      ),
    );
    expect(_face(tester).borderRadius, BorderRadius.circular(2));
  });
}

/// The sidebar row's end inset, read from the same resolver the item uses.
Future<double> _resolvedPadding(WidgetTester tester) async {
  late double end;
  await _reset(tester);
  await tester.pumpWidget(
    buildTestApp(
      Builder(
        builder: (context) {
          end = resolveNavigationBar(
            context,
            mode: CoreNavigationBarMode.sidebar,
            variant: CoreNavigationBarVariant.defaultVariant,
          ).itemPadding.right;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return end;
}
