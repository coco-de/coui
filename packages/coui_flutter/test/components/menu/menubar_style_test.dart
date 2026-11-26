import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

/// Default menu offset used in [CoreMenubarStyle] merge assertions.
const double _kBaseOffset = 4;

/// Overriding menu offset used in [CoreMenubarStyle] merge assertions.
const double _kOverrideOffset = 12;

/// Panel minimum width used in [CoreMenubarStyle.copyWith] assertions.
const double _kPanelMinWidth = 200;

/// Menu offset used in equality assertions.
const double _kEqualityOffset = 8;

material.Widget _buildApp(material.Widget child) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: material.Scaffold(body: child),
  ),
);

/// Settles pending animations, discarding the frame count so call
/// sites stay free of `avoid-ignoring-return-values` noise.
Future<void> _settle(WidgetTester tester) async {
  final frames = await tester.pumpAndSettle();
  expect(frames, greaterThanOrEqualTo(0));
}

/// Attaches a **mouse** pointer parked off-widget, so a later `moveTo`
/// reads as a genuine hover.
///
/// Two things are load-bearing here, and both fail silently:
///
/// * The device kind. `Menubar`'s hover-switch rides on
///   `Clickable.onHover`, which a `MouseRegion` feeds and which
///   therefore never fires for touch. A gesture created with the
///   default kind would exercise nothing and still pass any test whose
///   assertion is "nothing happened".
/// * The focus highlight mode. `Clickable` routes hover through
///   `FocusableActionDetector.onShowHoverHighlight`, which is suppressed
///   entirely while `FocusManager.highlightMode` is `touch` — the
///   default in a widget test. Production never sees this: hovering
///   requires a mouse, and a real mouse flips the automatic strategy to
///   `traditional` on its first event.
Future<TestGesture> _mousePointer(WidgetTester tester) async {
  final previousStrategy = material.FocusManager.instance.highlightStrategy;
  material.FocusManager.instance.highlightStrategy =
      material.FocusHighlightStrategy.alwaysTraditional;
  addTearDown(
    () => material.FocusManager.instance.highlightStrategy = previousStrategy,
  );

  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: Offset.zero);
  addTearDown(gesture.removePointer);
  await tester.pump();
  return gesture;
}

const _kMenus = [
  CoreMenubarMenu(
    label: 'File',
    entries: [
      CoreMenubarEntry.action(label: 'New', shortcut: 'Ctrl+N'),
      CoreMenubarEntry.action(label: 'Open'),
      CoreMenubarEntry.divider(),
      CoreMenubarEntry.action(label: 'Exit', enabled: false),
    ],
  ),
  CoreMenubarMenu(
    label: 'Edit',
    entries: [
      CoreMenubarEntry.action(label: 'Cut'),
      CoreMenubarEntry.action(label: 'Copy'),
    ],
  ),
];

void main() {
  group('CoreMenubarEntry', () {
    test('action constructor sets fields', () {
      const entry = CoreMenubarEntry.action(
        label: 'Save',
        shortcut: 'Ctrl+S',
      );

      expect(entry.kind, CoreMenubarEntryKind.action);
      expect(entry.label, 'Save');
      expect(entry.shortcut, 'Ctrl+S');
      expect(entry.enabled, isTrue);
    });

    test('divider constructor sets divider kind', () {
      const entry = CoreMenubarEntry.divider();

      expect(entry.kind, CoreMenubarEntryKind.divider);
      expect(entry.enabled, isFalse);
    });

    test('equality with same values', () {
      const a = CoreMenubarEntry.action(label: 'X');
      const b = CoreMenubarEntry.action(label: 'X');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality with different labels', () {
      const a = CoreMenubarEntry.action(label: 'X');
      const b = CoreMenubarEntry.action(label: 'Y');

      expect(a, isNot(equals(b)));
    });
  });

  group('CoreMenubarMenu', () {
    test('equality compares label and entries', () {
      const a = CoreMenubarMenu(
        label: 'File',
        entries: [CoreMenubarEntry.action(label: 'New')],
      );
      const b = CoreMenubarMenu(
        label: 'File',
        entries: [CoreMenubarEntry.action(label: 'New')],
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality with different entry lists', () {
      const a = CoreMenubarMenu(
        label: 'File',
        entries: [CoreMenubarEntry.action(label: 'New')],
      );
      const b = CoreMenubarMenu(
        label: 'File',
        entries: [CoreMenubarEntry.action(label: 'Open')],
      );

      expect(a, isNot(equals(b)));
    });
  });

  group('CoreMenubarStyle', () {
    test('merge overrides non-null fields', () {
      const base = CoreMenubarStyle(menuOffset: _kBaseOffset);
      const override = CoreMenubarStyle(menuOffset: _kOverrideOffset);

      expect(base.merge(override).menuOffset, _kOverrideOffset);
      expect(base.merge(null).menuOffset, _kBaseOffset);
    });

    test('copyWith replaces only supplied fields', () {
      const style = CoreMenubarStyle(menuOffset: _kBaseOffset);
      final copy = style.copyWith(
        menuPanelStyle: const CorePopupStyle(minWidth: _kPanelMinWidth),
      );

      expect(copy.menuOffset, _kBaseOffset);
      expect(copy.menuPanelStyle?.minWidth, _kPanelMinWidth);
    });

    test('equality and hashCode', () {
      const a = CoreMenubarStyle(menuOffset: _kEqualityOffset);
      const b = CoreMenubarStyle(menuOffset: _kEqualityOffset);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('defaultsByVariant covers the standard variant', () {
      expect(
        CoreMenubarStyle.defaultsByVariant[CoreMenubarVariant.standard],
        isNotNull,
      );
    });
  });

  group('Menubar', () {
    testWidgets('renders top-level menu labels', (tester) async {
      await tester.pumpWidget(
        _buildApp(const Menubar(menus: _kMenus)),
      );

      expect(find.byType(Menubar), findsOneWidget);
      expect(find.text('File'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
    });

    testWidgets('opens dropdown on trigger tap', (tester) async {
      await tester.pumpWidget(
        _buildApp(const Menubar(menus: _kMenus)),
      );

      await tester.tap(find.text('File'));
      await _settle(tester);

      expect(find.text('New'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Ctrl+N'), findsOneWidget);
    });

    testWidgets(
      're-tapping the open trigger closes (no double-toggle reopen)',
      (
        tester,
      ) async {
        // Guard the close-then-reopen double-toggle: re-tapping the open
        // trigger must close the panel, not have the engine outside-tap
        // dismissal close it while `_handleMenuToggle` reopens it. The
        // `_openIndex == index` / `target == _shownIndex` guards keep the
        // toggle idempotent after the trigger migrated to a `Button`.
        await tester.pumpWidget(_buildApp(const Menubar(menus: _kMenus)));

        await tester.tap(find.text('File'));
        await _settle(tester);
        expect(find.text('New'), findsOneWidget);

        await tester.tap(find.text('File'));
        await _settle(tester);
        expect(find.text('New'), findsNothing);
      },
    );

    testWidgets(
      'switching to a sibling trigger opens it in a single tap',
      (tester) async {
        // Cross-platform parity: on Web, tapping `Edit` while `File` is
        // open switches the dropdown to `Edit` directly. The Flutter
        // dropdown must do the same in ONE tap — its tap-consuming modal
        // barrier must NOT absorb the sibling-trigger tap (which would
        // only dismiss `File`, leaving `Edit` closed until a second tap).
        await tester.pumpWidget(_buildApp(const Menubar(menus: _kMenus)));

        await tester.tap(find.text('File'));
        await _settle(tester);
        expect(find.text('New'), findsOneWidget);

        await tester.tap(find.text('Edit'));
        await _settle(tester);
        expect(
          find.text('New'),
          findsNothing,
          reason: 'File panel should close on switch',
        );
        expect(
          find.text('Cut'),
          findsOneWidget,
          reason: 'Edit panel should open in the same tap',
        );
      },
    );

    testWidgets(
      'hovering a sibling trigger switches the open menu without a click',
      (tester) async {
        // The behaviour this whole change exists for: once a menu is
        // open the bar tracks the pointer, as desktop menubars do.
        // Before, only a click switched menus.
        await tester.pumpWidget(_buildApp(const Menubar(menus: _kMenus)));

        await tester.tap(find.text('File'));
        await _settle(tester);
        expect(find.text('New'), findsOneWidget);

        final gesture = await _mousePointer(tester);
        await gesture.moveTo(tester.getCenter(find.text('Edit')));
        await _settle(tester);

        expect(
          find.text('New'),
          findsNothing,
          reason: 'File panel should close when the pointer reaches Edit',
        );
        expect(
          find.text('Cut'),
          findsOneWidget,
          reason: 'Edit panel should open on hover alone — no tap',
        );
      },
    );

    testWidgets('hovering a trigger while closed opens nothing', (
      tester,
    ) async {
      // A menubar arms on click, not on hover. Without this guard the
      // bar would fire every time the pointer merely crossed it on the
      // way somewhere else — the reason `Menubar` and `NavigationMenu`
      // differ despite sharing a trigger widget.
      await tester.pumpWidget(_buildApp(const Menubar(menus: _kMenus)));

      final gesture = await _mousePointer(tester);
      await gesture.moveTo(tester.getCenter(find.text('File')));
      await _settle(tester);

      expect(find.text('New'), findsNothing);

      await gesture.moveTo(tester.getCenter(find.text('Edit')));
      await _settle(tester);

      expect(find.text('Cut'), findsNothing);
    });

    testWidgets('moving the pointer off a trigger leaves the menu open', (
      tester,
    ) async {
      // Hover-OUT must not close: the pointer has to leave the trigger
      // to reach the panel hanging beneath it, so treating un-hover as
      // a close would make every menu unreachable. Closing stays with
      // outside-tap / Escape / entry selection.
      await tester.pumpWidget(_buildApp(const Menubar(menus: _kMenus)));

      await tester.tap(find.text('File'));
      await _settle(tester);
      expect(find.text('New'), findsOneWidget);

      final gesture = await _mousePointer(tester);
      await gesture.moveTo(tester.getCenter(find.text('File')));
      await _settle(tester);
      await gesture.moveTo(Offset.zero);
      await _settle(tester);

      expect(
        find.text('New'),
        findsOneWidget,
        reason: 'panel must survive the pointer leaving the trigger',
      );
    });

    testWidgets('re-hovering the open trigger keeps it open', (tester) async {
      // `_setActiveIndex` returns early on an unchanged index, so the
      // open panel is never torn down and rebuilt while the pointer
      // rests on its own trigger.
      await tester.pumpWidget(_buildApp(const Menubar(menus: _kMenus)));

      await tester.tap(find.text('File'));
      await _settle(tester);

      final gesture = await _mousePointer(tester);
      await gesture.moveTo(tester.getCenter(find.text('File')));
      await _settle(tester);

      expect(find.text('New'), findsOneWidget);
    });

    testWidgets('hover switch reports through onActiveIndexChanged', (
      tester,
    ) async {
      // Controlled mode must see hover switches, not just clicks —
      // otherwise a parent owning `activeIndex` would drift out of sync
      // with what the bar is showing.
      final reported = <int?>[];
      await tester.pumpWidget(
        _buildApp(
          Menubar(menus: _kMenus, onActiveIndexChanged: reported.add),
        ),
      );

      await tester.tap(find.text('File'));
      await _settle(tester);

      final gesture = await _mousePointer(tester);
      await gesture.moveTo(tester.getCenter(find.text('Edit')));
      await _settle(tester);

      expect(reported, [0, 1]);
    });

    testWidgets('selecting an entry invokes onSelect and closes', (
      tester,
    ) async {
      var selected = false;
      final menus = [
        CoreMenubarMenu(
          label: 'File',
          entries: [
            CoreMenubarEntry.action(
              label: 'New',
              onSelect: () => selected = true,
            ),
          ],
        ),
      ];

      await tester.pumpWidget(_buildApp(Menubar(menus: menus)));

      await tester.tap(find.text('File'));
      await _settle(tester);

      await tester.tap(find.text('New'));
      await _settle(tester);

      expect(selected, isTrue);
      expect(find.text('New'), findsNothing);
    });

    testWidgets('disabled entry does not invoke onSelect', (tester) async {
      var selected = false;
      final menus = [
        CoreMenubarMenu(
          label: 'File',
          entries: [
            CoreMenubarEntry.action(
              label: 'Exit',
              enabled: false,
              onSelect: () => selected = true,
            ),
          ],
        ),
      ];

      await tester.pumpWidget(_buildApp(Menubar(menus: menus)));

      await tester.tap(find.text('File'));
      await _settle(tester);

      await tester.tap(find.text('Exit'));
      await _settle(tester);

      expect(selected, isFalse);
    });

    testWidgets('renders without border', (tester) async {
      await tester.pumpWidget(
        _buildApp(const Menubar(menus: _kMenus, border: false)),
      );

      expect(find.byType(Menubar), findsOneWidget);
    });
  });
}
