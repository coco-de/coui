// A menu with more rows than the viewport has room for takes the room and
// scrolls, instead of running off the screen with its last rows out of reach.
//
// The three hosts that open a menu — DropdownMenu, ContextMenu, Menubar —
// share the overlay engine's `fitViewportHeight`, and the room it gives is
// the one Core states (`CoreOverlayFit`) for the Web as well. The vector
// table both read is `overlay_fit_vectors.json`.
import 'dart:convert';
import 'dart:io';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/gestures.dart' show kSecondaryButton;
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

/// The vector table shared with the Core test and the Web panel probe.
const String _kVectorsPath =
    '../coui_core/test/fixtures/overlay_fit_vectors.json';

/// A phone-sized viewport, at one device pixel per logical pixel so the
/// numbers below are the ones the layout uses.
const Size _kPhone = Size(360, 480);

/// The viewport margin a panel keeps (`ResolvedPopover.viewportMargin`'s
/// default) — the engine's own fallback when a caller passes none.
const double _kMargin = 8;

const int _kRows = 30;

material.Widget _app(material.Widget child) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: material.Scaffold(body: material.Center(child: child)),
  ),
);

/// Sizes the test view and restores it afterwards.
void _useView(
  WidgetTester tester,
  Size size, {
  FakeViewPadding padding = FakeViewPadding.zero,
  FakeViewPadding viewInsets = FakeViewPadding.zero,
}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.view.padding = padding;
  tester.view.viewPadding = padding;
  tester.view.viewInsets = viewInsets;
  addTearDown(tester.view.reset);
}

/// Thirty action rows, `Row 1` … `Row 30`; each reports its own name.
List<CoreMenuItem<Widget>> _rows(void Function(String) onSelect) => [
  for (var i = 1; i <= _kRows; i++)
    CoreMenuItem.action('Row $i', onPressed: () => onSelect('Row $i')),
];

/// Whether the centre of [label] lies inside the visible panel.
bool _visibleInPanel(WidgetTester tester, String label) {
  final panel = tester.getRect(find.byType(Popup).first);
  final center = tester.getCenter(find.text(label));

  return panel.contains(center);
}

/// The behaviour every menu host owes a menu that does not fit.
Future<void> _expectScrollableToTheLastRow(
  WidgetTester tester,
  List<String> selections,
) async {
  expect(
    tester.takeException(),
    isNull,
    reason: 'a menu taller than the viewport must not overflow',
  );

  final panel = tester.getRect(find.byType(Popup).first);
  final viewport = Offset.zero & _kPhone;
  expect(
    viewport.deflate(_kMargin).inflate(0.01).contains(panel.topLeft) &&
        viewport.deflate(_kMargin).inflate(0.01).contains(panel.bottomRight),
    isTrue,
    reason: 'the panel $panel must lie inside the viewport less its margin',
  );
  expect(
    _visibleInPanel(tester, 'Row 1'),
    isTrue,
    reason: 'the first row is where the menu starts',
  );
  expect(
    _visibleInPanel(tester, 'Row $_kRows'),
    isFalse,
    reason: 'thirty rows do not fit — the last one is below the fold',
  );

  await tester.drag(find.text('Row 1'), const Offset(0, -3000));
  await tester.pumpAndSettle();

  expect(
    _visibleInPanel(tester, 'Row $_kRows'),
    isTrue,
    reason: 'scrolling to the end reveals the last row',
  );
  expect(tester.takeException(), isNull);

  await tester.tap(find.text('Row $_kRows'));
  await tester.pumpAndSettle();

  expect(selections, ['Row $_kRows']);
}

void main() {
  group('a long menu fits the viewport and scrolls', () {
    // Every platform: the scroll physics and the desktop scrollbar behaviour
    // differ per platform, and the menu must reach its last row on each.
    testWidgets('DropdownMenu', (tester) async {
      _useView(tester, _kPhone);
      final selections = <String>[];

      await tester.pumpWidget(
        _app(
          DropdownMenu(
            trigger: const Text('Open'),
            items: _rows(selections.add),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await _expectScrollableToTheLastRow(tester, selections);
    }, variant: TargetPlatformVariant.all());

    testWidgets('ContextMenu', (tester) async {
      _useView(tester, _kPhone);
      final selections = <String>[];

      await tester.pumpWidget(
        _app(
          ContextMenu(
            items: _rows(selections.add),
            child: const Text('Right-click me'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Right-click me')),
        buttons: kSecondaryButton,
      );
      await gesture.up();
      // The panel follows its trigger with a ticker, so `pumpAndSettle` never
      // settles: pump the open transition instead.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Row 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final panel = tester.getRect(find.byType(Popup).first);
      expect(panel.top, greaterThanOrEqualTo(_kMargin - 0.01));
      expect(panel.bottom, lessThanOrEqualTo(_kPhone.height - _kMargin + 0.01));
      expect(_visibleInPanel(tester, 'Row 1'), isTrue);
      expect(_visibleInPanel(tester, 'Row $_kRows'), isFalse);

      await tester.drag(find.text('Row 1'), const Offset(0, -3000));
      await tester.pump(const Duration(milliseconds: 400));

      expect(_visibleInPanel(tester, 'Row $_kRows'), isTrue);

      await tester.tap(find.text('Row $_kRows'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(selections, ['Row $_kRows']);
    });

    testWidgets('Menubar', (tester) async {
      _useView(tester, _kPhone);
      final selections = <String>[];

      await tester.pumpWidget(
        _app(
          Menubar(
            menus: [
              CoreMenubarMenu(
                label: 'File',
                entries: [
                  for (var i = 1; i <= _kRows; i++)
                    CoreMenubarEntry.action(
                      label: 'Row $i',
                      onSelect: () => selections.add('Row $i'),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('File'));
      await tester.pumpAndSettle();

      await _expectScrollableToTheLastRow(tester, selections);
    });

    testWidgets('a menu that fits is not scrollable and keeps its size', (
      tester,
    ) async {
      _useView(tester, _kPhone);

      await tester.pumpWidget(
        _app(
          DropdownMenu(
            trigger: const Text('Open'),
            items: [
              CoreMenuItem.action('One', onPressed: () {}),
              CoreMenuItem.action('Two', onPressed: () {}),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final panel = tester.getRect(find.byType(Popup).first);
      expect(
        panel.height,
        lessThan(_kPhone.height / 2),
        reason: 'two rows are far from filling the viewport',
      );
      final scrollable = tester.state<ScrollableState>(
        find.descendant(
          of: find.byType(Popup).first,
          matching: find.byType(Scrollable),
        ),
      );
      expect(
        scrollable.position.maxScrollExtent,
        0,
        reason: 'nothing to scroll when everything fits',
      );
    });

    // A panel that fits must draw what it drew before it could scroll. The
    // app's scroll behaviour would add an overscroll painter (a glow, a
    // stretch) to every menu, including the ones that never scroll — and to
    // the ones that do, where the panel's rounded box is the edge, not a page.
    testWidgets('the scroller adds no overscroll chrome to the panel', (
      tester,
    ) async {
      _useView(tester, _kPhone);

      await tester.pumpWidget(
        _app(
          DropdownMenu(
            trigger: const Text('Open'),
            items: [
              CoreMenuItem.action('One', onPressed: () {}),
              CoreMenuItem.action('Two', onPressed: () {}),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final panel = find.byType(Popup).first;
      expect(
        find.descendant(
          of: panel,
          matching: find.byType(GlowingOverscrollIndicator),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: panel,
          matching: find.byType(StretchingOverscrollIndicator),
        ),
        findsNothing,
      );
    }, variant: TargetPlatformVariant.all());

    testWidgets('an inline submenu scrolls with its parent panel, not in a '
        'scroller of its own', (tester) async {
      _useView(tester, _kPhone);

      await tester.pumpWidget(
        _app(
          DropdownMenu(
            trigger: const Text('Open'),
            items: [
              CoreMenuItem.action(
                'More',
                submenu: [
                  CoreMenuItem.action('Settings', onPressed: () {}),
                  CoreMenuItem.action('Account', onPressed: () {}),
                ],
              ),
              ..._rows((_) {}),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Settings'), findsOneWidget, reason: 'it is drawn');
      expect(
        find.descendant(
          of: find.byType(Popup).first,
          matching: find.byType(Scrollable),
        ),
        findsOneWidget,
        reason: 'one scroller for the whole panel; the submenu rides in it',
      );
    });
  });
  group('the popover engine against the shared vectors', () {
    // The engine holds a panel with a constraint before it lays the panel
    // out, so what it can promise is the outcome the table states: an
    // over-tall panel takes exactly the room and starts at the near padding;
    // one that fits keeps its natural height.
    final doc =
        jsonDecode(File(_kVectorsPath).readAsStringSync())
            as Map<String, Object?>;
    final cases = (doc['cases']! as List).cast<Map<String, Object?>>();

    double n(Map<String, Object?> map, String key) =>
        (map[key]! as num).toDouble();

    for (final c in cases) {
      testWidgets(c['name']! as String, (tester) async {
        final viewport = n(c, 'viewport');
        final before = n(c, 'paddingBefore');
        final after = n(c, 'paddingAfter');
        final extent = n(c, 'extent');
        final fit = c['fit']! as Map<String, Object?>;
        _useView(tester, Size(360, viewport));

        final anchorKey = GlobalKey();
        final panelKey = GlobalKey();
        await tester.pumpWidget(
          _app(material.SizedBox(key: anchorKey, width: 40, height: 20)),
        );
        // `follow: false`: the follow ticker would keep the frame scheduled.
        const PopoverOverlayHandler().show<void>(
          context: anchorKey.currentContext!,
          alignment: Alignment.topCenter,
          builder: (_) =>
              material.SizedBox(key: panelKey, width: 120, height: extent),
          fitViewportHeight: true,
          follow: false,
          margin: EdgeInsets.fromLTRB(_kMargin, before, _kMargin, after),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        final panel = tester.getRect(find.byKey(panelKey));
        expect(panel.height, closeTo(n(fit, 'extent'), 0.01), reason: 'extent');
        if (fit['capped']! as bool) {
          expect(panel.top, closeTo(n(fit, 'start'), 0.01), reason: 'start');
        }
      });
    }

    testWidgets('the system bars are kept clear by a panel that takes all '
        'the room, and by no other', (tester) async {
      // A phone with a status bar over the top 47 and a home indicator over
      // the bottom 34. The room is the one the table states for 8 + those.
      const padding = FakeViewPadding(top: 47, bottom: 34);
      _useView(tester, const Size(360, 844), padding: padding);

      final anchorKey = GlobalKey();
      final tallKey = GlobalKey();
      final shortKey = GlobalKey();
      await tester.pumpWidget(
        _app(material.SizedBox(key: anchorKey, width: 40, height: 20)),
      );
      const handler = PopoverOverlayHandler();
      final tall = handler.show<void>(
        context: anchorKey.currentContext!,
        alignment: Alignment.topCenter,
        builder: (_) =>
            material.SizedBox(key: tallKey, width: 120, height: 5000),
        fitViewportHeight: true,
        follow: false,
      );
      await tester.pumpAndSettle();

      final tallPanel = tester.getRect(find.byKey(tallKey));
      expect(tallPanel.top, closeTo(_kMargin + 47, 0.01));
      expect(tallPanel.bottom, closeTo(844 - _kMargin - 34, 0.01));
      expect(tallPanel.height, closeTo(747, 0.01), reason: 'the table: 747');

      tall.dismissImmediately();
      await tester.pumpAndSettle();

      // A panel with room to spare is placed by the collision alone — the
      // same place it takes without the flag.
      Future<double> topOf({required bool fit}) async {
        final handle = handler.show<void>(
          context: anchorKey.currentContext!,
          alignment: Alignment.topCenter,
          anchorAlignment: Alignment.bottomCenter,
          builder: (_) =>
              material.SizedBox(key: shortKey, width: 120, height: 100),
          fitViewportHeight: fit,
          follow: false,
        );
        await tester.pumpAndSettle();
        final top = tester.getRect(find.byKey(shortKey)).top;
        handle.dismissImmediately();
        await tester.pumpAndSettle();

        return top;
      }

      expect(await topOf(fit: true), await topOf(fit: false));
    });

    testWidgets('the on-screen keyboard is room the panel does not get', (
      tester,
    ) async {
      _useView(
        tester,
        _kPhone,
        viewInsets: const FakeViewPadding(bottom: 216),
      );

      final anchorKey = GlobalKey();
      final panelKey = GlobalKey();
      await tester.pumpWidget(
        _app(material.SizedBox(key: anchorKey, width: 40, height: 20)),
      );
      const PopoverOverlayHandler().show<void>(
        context: anchorKey.currentContext!,
        alignment: Alignment.topCenter,
        builder: (_) =>
            material.SizedBox(key: panelKey, width: 120, height: 5000),
        fitViewportHeight: true,
        follow: false,
      );
      await tester.pumpAndSettle();

      final panel = tester.getRect(find.byKey(panelKey));
      expect(panel.top, closeTo(_kMargin, 0.01));
      expect(
        panel.bottom,
        closeTo(_kPhone.height - 216 - _kMargin, 0.01),
        reason: 'the panel ends above the keyboard, a margin clear of it',
      );
    });
  });
}
