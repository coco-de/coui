/// A docs preview takes the framework's focus only while its own view holds
/// the page's.
///
/// **What went wrong.** A Flutter app focuses its first route as it starts,
/// and the `View` above it answers a focused scope by asking the page for the
/// view's DOM focus. On a docs page that moved the reader's focus into the
/// preview the moment it appeared, and from then on the app's default
/// shortcuts kept the arrow keys and Tab — the page did not scroll and did
/// not move its own focus until the reader clicked somewhere else.
///
/// **What is measured.** The same app the embed mounts (`docs_site`'s
/// `PreviewApp`), under the `View` every widget test is pumped into — the
/// widget whose focus handling is the other half of this. The page's side is
/// the test platform dispatcher: it records each request the framework makes
/// for a view's focus, and the tests hand it the focus events an engine
/// would report. What a browser then does with the DOM focus is not in
/// reach here; that is measured on a built site.
library;

import 'dart:ui' show SemanticsAction, ViewFocusDirection, ViewFocusEvent, ViewFocusState;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_core/previews/preview_focus_gate.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';

/// docs_site's `PreviewApp` around [home] — the same app, with the gate
/// where the embed puts it, or without it to show what the gate changes.
///
/// [stopAfter] puts one more focus stop in the view, after the app in
/// reading order and outside its navigator. The built site has one: with the
/// browser's context menu left on, the kit's web text selection mounts the
/// framework's context-menu platform view, and that view's node is a stop of
/// the view's own traversal. A VM test has no platform view, so the stop is
/// stood in for here.
Widget _embed(Widget home, {bool gated = true, FocusNode? stopAfter}) {
  Widget app = CoUIApp(
    theme: ThemeData.fromCore(CoreThemePresets.previewLight),
    scaling: const AdaptiveScaling(),
    debugShowCheckedModeBanner: false,
    disableBrowserContextMenu: false,
    enableThemeAnimation: false,
    home: home,
  );
  if (stopAfter != null) {
    app = Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        children: [
          Expanded(child: app),
          Focus(focusNode: stopAfter, child: const SizedBox(width: 8, height: 8)),
        ],
      ),
    );
  }

  return gated ? PreviewFocusGate(child: app) : app;
}

/// Three focusable boxes in reading order.
class _Controls extends StatelessWidget {
  const _Controls(this.nodes);

  final List<FocusNode> nodes;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final node in nodes)
        Focus(key: ValueKey(node.debugLabel), focusNode: node, child: const SizedBox(width: 80, height: 24)),
    ],
  );
}

/// A widget test with the accessibility tree off.
///
/// `testWidgets` turns the tree on unless told otherwise, and the gate stays
/// open while it is on. The tests that are about the tree turn it on
/// themselves, at the moment they mean to.
void _test(String description, WidgetTesterCallback body) => testWidgets(description, body, semanticsEnabled: false);

void main() {
  late List<FocusNode> nodes;

  setUp(() {
    nodes = [
      for (final label in const ['first', 'second', 'third']) FocusNode(debugLabel: label),
    ];
  });

  tearDown(() {
    for (final node in nodes) {
      node.dispose();
    }
  });

  /// The requests the framework has made for a view's focus.
  List<ViewFocusEvent> requests(WidgetTester tester) => tester.binding.platformDispatcher.testFocusEvents;

  /// What an engine reports when the page's focus enters or leaves a view.
  void report(
    WidgetTester tester,
    ViewFocusState state, {
    ViewFocusDirection direction = ViewFocusDirection.undefined,
    int? viewId,
  }) {
    tester.binding.platformDispatcher.onViewFocusChange?.call(
      ViewFocusEvent(viewId: viewId ?? tester.view.viewId, state: state, direction: direction),
    );
  }

  /// Tab moving the page's focus into the view: the engine reports the view
  /// focused while the key that caused it is still down.
  Future<void> tabIn(WidgetTester tester, {bool backward = false}) async {
    if (backward) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.tab);
    report(
      tester,
      ViewFocusState.focused,
      direction: backward ? ViewFocusDirection.backward : ViewFocusDirection.forward,
    );
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.tab);
    if (backward) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
  }

  /// Has the gate hear of a view's focus before the `View` does.
  ///
  /// Observers are told in the order they registered, and a `View` registers
  /// before anything it builds. Registering it again puts it last.
  void tellTheGateFirst(WidgetTester tester) {
    final view = tester.state(find.byType(View)) as WidgetsBindingObserver;
    tester.binding
      ..removeObserver(view)
      ..addObserver(view);
  }

  FocusNode? primary() => FocusManager.instance.primaryFocus;

  /// The box of the control whose node is labelled [label].
  Finder control(String label) => find.byKey(ValueKey<String?>(label));

  bool focusIsInTheApp(WidgetTester tester) =>
      primary()!.ancestors.contains(Focus.of(tester.element(find.byType(CoUIApp)), scopeOk: true));

  setUp(() => addTearDown(TestWidgetsFlutterBinding.instance.platformDispatcher.resetFocusedViewTestValues));

  group('as it starts', () {
    _test('an app with no gate asks the page for its view\'s focus', (tester) async {
      // The framework behaviour the gate exists for. When this stops being
      // true the gate has nothing left to stop.
      await tester.pumpWidget(_embed(_Controls(nodes), gated: false));
      await tester.pump();

      expect(requests(tester), hasLength(1));
      expect(requests(tester).single.state, ViewFocusState.focused);
      expect(focusIsInTheApp(tester), isTrue);
    });

    _test('a gated app asks for none and holds none', (tester) async {
      await tester.pumpWidget(_embed(_Controls(nodes)));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(requests(tester), isEmpty);
      expect(primary(), FocusManager.instance.rootScope);
    });

    _test('a request made while the view is not the reader\'s is dropped', (tester) async {
      await tester.pumpWidget(_embed(_Controls(nodes)));
      await tester.pump();

      nodes.first.requestFocus();
      await tester.pump();

      expect(nodes.first.hasFocus, isFalse);
      expect(requests(tester), isEmpty);
      expect(primary(), FocusManager.instance.rootScope);
    });

    _test('the gate lays out and paints nothing of its own', (tester) async {
      await tester.pumpWidget(_embed(_Controls(nodes), gated: false));
      final bare = [for (final node in nodes) node.rect];

      await tester.pumpWidget(_embed(_Controls(nodes)));

      expect([for (final node in nodes) node.rect], bare);
      expect(tester.getSize(find.byType(PreviewFocusGate)), tester.getSize(find.byType(CoUIApp)));
      expect(tester.getTopLeft(find.byType(CoUIApp)), tester.getTopLeft(find.byType(PreviewFocusGate)));
    });
  });

  group('coming in by keyboard', () {
    for (final gateFirst in const [false, true]) {
      final order = gateFirst ? 'the gate is told first' : 'the View is told first';

      _test('Tab lands on the first control — $order', (tester) async {
        await tester.pumpWidget(_embed(_Controls(nodes)));
        await tester.pump();
        if (gateFirst) tellTheGateFirst(tester);

        await tabIn(tester);

        expect(primary(), nodes.first);
        // The view already holds the page's focus; nothing is left to ask.
        expect(requests(tester), isEmpty);
      });

      _test('Shift+Tab lands on the last control — $order', (tester) async {
        await tester.pumpWidget(_embed(_Controls(nodes)));
        await tester.pump();
        if (gateFirst) tellTheGateFirst(tester);

        await tabIn(tester, backward: true);

        expect(primary(), nodes.last);
        expect(requests(tester), isEmpty);
      });
    }

    for (final gateFirst in const [false, true]) {
      final order = gateFirst ? 'the gate is told first' : 'the View is told first';

      _test('Tab lands on the first control of a view with a stop after the app — $order', (tester) async {
        final after = FocusNode(debugLabel: 'after the app');
        addTearDown(after.dispose);
        await tester.pumpWidget(_embed(_Controls(nodes), stopAfter: after));
        await tester.pump();
        if (gateFirst) tellTheGateFirst(tester);

        await tabIn(tester);

        expect(primary(), nodes.first);
      });
    }

    _test('Shift+Tab lands on the last stop of the view, wherever the app put it', (tester) async {
      // The view's traversal ends on the stop after the app, so that is
      // where a `View` sends a focus that comes in backwards — the gate
      // does not choose a different stop than the traversal does.
      final after = FocusNode(debugLabel: 'after the app');
      addTearDown(after.dispose);
      await tester.pumpWidget(_embed(_Controls(nodes), stopAfter: after));
      await tester.pump();

      await tabIn(tester, backward: true);

      expect(primary(), after);
    });

    _test('Tab lands in a scope the app nests its controls in', (tester) async {
      await tester.pumpWidget(_embed(FocusScope(child: _Controls(nodes))));
      await tester.pump();

      await tabIn(tester);
      expect(primary(), nodes.first);

      report(tester, ViewFocusState.unfocused);
      await tester.pump();
      // Leaving by Tab clears what a scope remembers; a script that parks
      // the focus does the same here.
      await tabIn(tester, backward: true);
      expect(primary(), anyOf(nodes.first, nodes.last));
    });

    _test('Tab comes back to the control the reader left by pressing elsewhere', (tester) async {
      // A Tab that reaches a scope goes on to the child the scope last had
      // focused — the traversal's own rule, not the gate's.
      await tester.pumpWidget(_embed(_Controls(nodes)));
      await tester.pump();
      report(tester, ViewFocusState.focused, direction: ViewFocusDirection.forward);
      await tester.pump();
      nodes[1].requestFocus();
      await tester.pump();
      report(tester, ViewFocusState.unfocused);
      await tester.pump();

      await tabIn(tester);

      expect(primary(), nodes[1]);
    });

    _test('Tab then walks the controls in order', (tester) async {
      await tester.pumpWidget(_embed(_Controls(nodes)));
      await tester.pump();
      await tabIn(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(primary(), nodes[1]);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(primary(), nodes[2]);
    });

    _test('a view with nothing to focus keeps the focus on no control', (tester) async {
      await tester.pumpWidget(_embed(const SizedBox(width: 80, height: 24)));
      await tester.pump();

      await tabIn(tester);

      expect(focusIsInTheApp(tester), isTrue);
      expect(primary(), isA<FocusScopeNode>());
      expect(requests(tester), isEmpty);
    });
  });

  group('coming in any other way', () {
    for (final gateFirst in const [false, true]) {
      final order = gateFirst ? 'the gate is told first' : 'the View is told first';

      _test('the focus goes to the app and to no control — $order', (tester) async {
        // A press, a script, the window coming back: the engine reports the
        // view focused with no Tab held. The `View` gives that a scope, not
        // a control, and so does the gate.
        await tester.pumpWidget(_embed(_Controls(nodes)));
        await tester.pump();
        if (gateFirst) tellTheGateFirst(tester);

        report(tester, ViewFocusState.focused, direction: ViewFocusDirection.forward);
        await tester.pump();

        expect(focusIsInTheApp(tester), isTrue);
        expect(primary(), isA<FocusScopeNode>());
        expect(requests(tester), isEmpty);
      });
    }

    _test('the focus rests on the scope it rests on with no gate', (tester) async {
      // An app asks for the focus as it starts, and behind a closed gate
      // that request makes the navigator's scope forget the route it had
      // named to focus first. The focus must still come to rest on the
      // route's scope, not one above it.
      await tester.pumpWidget(_embed(_Controls(nodes), gated: false));
      await tester.pump();
      report(tester, ViewFocusState.focused, direction: ViewFocusDirection.forward);
      await tester.pump();
      final bare = primary()!.debugLabel;
      expect(bare, contains('_ModalScopeState'));

      await tester.pumpWidget(const SizedBox());
      report(tester, ViewFocusState.unfocused);
      await tester.pumpWidget(_embed(_Controls(nodes)));
      await tester.pump();
      report(tester, ViewFocusState.focused, direction: ViewFocusDirection.forward);
      await tester.pump();

      expect(primary()!.debugLabel, bare);
    });

    for (final gated in const [false, true]) {
      _test('keys the route answers reach it after a press on nothing — ${gated ? 'gated' : 'no gate'}', (
        tester,
      ) async {
        // A scroll shortcut looks for a scroll view from where the focus
        // rests. The route provides the primary one; the scope above the
        // route does not.
        await tester.pumpWidget(
          _embed(
            ListView(
              primary: true,
              children: [for (var i = 0; i < 60; i++) SizedBox(height: 40, child: Text('row $i'))],
            ),
            gated: gated,
          ),
        );
        await tester.pump();

        await tester.tap(find.text('row 2'));
        report(tester, ViewFocusState.focused, direction: ViewFocusDirection.forward);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
        await tester.pumpAndSettle();

        expect(tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels, greaterThan(0));
      });
    }

    _test('the control focused before is focused again', (tester) async {
      await tester.pumpWidget(_embed(_Controls(nodes)));
      await tester.pump();
      report(tester, ViewFocusState.focused, direction: ViewFocusDirection.forward);
      await tester.pump();
      nodes[1].requestFocus();
      await tester.pump();
      expect(primary(), nodes[1]);

      // The window loses the focus and gets it back.
      report(tester, ViewFocusState.unfocused);
      await tester.pump();
      expect(primary(), FocusManager.instance.rootScope);
      report(tester, ViewFocusState.focused, direction: ViewFocusDirection.forward);
      await tester.pump();

      expect(primary(), nodes[1]);
    });

    _test('a control takes the focus once the view has it', (tester) async {
      await tester.pumpWidget(_embed(_Controls(nodes)));
      await tester.pump();
      report(tester, ViewFocusState.focused, direction: ViewFocusDirection.forward);
      await tester.pump();

      nodes[2].requestFocus();
      await tester.pump();

      expect(primary(), nodes[2]);
    });
  });

  group('a press inside the view', () {
    _test('focuses a text field on the first press', (tester) async {
      await tester.pumpWidget(_embed(SizedBox(width: 240, child: TextField(placeholder: const Text('email')))));
      await tester.pump();
      expect(tester.testTextInput.hasAnyClients, isFalse);

      await tester.tap(find.byType(TextField));
      await tester.pump();

      expect(tester.testTextInput.hasAnyClients, isTrue);
      await tester.enterText(find.byType(EditableText), 'abc');
      expect(find.text('abc'), findsOneWidget);
    });

    _test('lets a control that takes the focus as it is pressed have it', (tester) async {
      // A scrollable viewport focuses itself from its pointer-down listener
      // — during the press, before the engine has focused the view.
      final pressed = FocusNode(debugLabel: 'pressed');
      addTearDown(pressed.dispose);
      await tester.pumpWidget(
        _embed(
          Listener(
            key: const ValueKey<String?>('pressed'),
            behavior: HitTestBehavior.opaque,
            onPointerDown: (_) => pressed.requestFocus(),
            child: Focus(focusNode: pressed, child: const SizedBox(width: 80, height: 24)),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(control('pressed'));
      await tester.pump();

      expect(primary(), pressed);
    });

    _test('is a press even with Tab held', (tester) async {
      // Tab moving the focus in lands on the first control; a press does not
      // choose a control for the reader, whatever the keyboard is doing.
      await tester.pumpWidget(_embed(_Controls(nodes)));
      await tester.pump();

      final gesture = await tester.startGesture(tester.getCenter(control('third')));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.tab);
      report(tester, ViewFocusState.focused, direction: ViewFocusDirection.forward);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.tab);
      await gesture.up();
      await tester.pump();

      expect(primary(), isA<FocusScopeNode>());
    });

    _test('keeps that focus when the engine then reports the view focused', (tester) async {
      await tester.pumpWidget(_embed(_Controls(nodes)));
      await tester.pump();

      final gesture = await tester.startGesture(tester.getCenter(control('third')));
      nodes[2].requestFocus();
      await tester.pump();
      // The engine focuses a pressed view a task after the press.
      report(tester, ViewFocusState.focused, direction: ViewFocusDirection.forward);
      await gesture.up();
      await tester.pump();

      expect(primary(), nodes[2]);
    });
  });

  group('when the focus leaves', () {
    _test('the app holds none and takes none', (tester) async {
      await tester.pumpWidget(_embed(_Controls(nodes)));
      await tester.pump();
      await tabIn(tester);
      expect(primary(), nodes.first);

      report(tester, ViewFocusState.unfocused);
      await tester.pump();
      expect(primary(), FocusManager.instance.rootScope);

      nodes[1].requestFocus();
      await tester.pump();

      expect(nodes[1].hasFocus, isFalse);
      expect(primary(), FocusManager.instance.rootScope);
      expect(requests(tester), isEmpty);
    });

    for (final otherFirst in const [true, false]) {
      final order = otherFirst ? 'the other view moved the focus first' : 'the other view moves the focus after';

      _test('to another view, it is not pulled back — $order', (tester) async {
        // Another view's scope sits beside this one, under the root scope.
        final other = FocusScopeNode(debugLabel: 'another view');
        addTearDown(other.dispose);
        await tester.pumpWidget(_embed(_Controls(nodes)));
        await tester.pump();
        await tabIn(tester);
        expect(primary(), nodes.first);

        void otherViewTakesTheFocus() => FocusManager.instance.rootScope.requestFocus(other);
        if (otherFirst) otherViewTakesTheFocus();
        report(tester, ViewFocusState.focused, direction: ViewFocusDirection.forward, viewId: tester.view.viewId + 1);
        if (!otherFirst) otherViewTakesTheFocus();
        await tester.pump();
        await tester.pump();

        expect(primary(), other);
        // Had the gate closed on a focus it still held, that focus would have
        // gone to this view's scope and the view would have asked for the
        // page's again.
        expect(requests(tester), isEmpty);

        nodes[1].requestFocus();
        await tester.pump();
        expect(primary(), other);
        expect(requests(tester), isEmpty);
      });
    }
  });

  group('with the accessibility tree on', () {
    _test('an app that starts takes the focus, as it does with no gate', (tester) async {
      // The reach of the gate, not a wish: in this mode the engine focuses
      // the first node of a route that appears, by itself, so a gate closed
      // while the app starts would not keep the page's focus where it was —
      // and would drop the focus assistive technology gives next.
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_embed(_Controls(nodes)));
      await tester.pump();

      expect(focusIsInTheApp(tester), isTrue);
      expect(requests(tester).map((request) => request.state), [ViewFocusState.focused]);
      semantics.dispose();
    });

    _test('a focus action from the tree focuses the control it names', (tester) async {
      // Assistive technology focuses a node of the tree, and that action
      // reaches the framework before any report of the view's focus.
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_embed(_Controls(nodes)));
      await tester.pump();

      final node = tester.getSemantics(control('third'));
      node.owner!.performAction(node.id, SemanticsAction.focus);
      await tester.pump();

      expect(primary(), nodes[2]);
      semantics.dispose();
    });

    _test('turning it on opens a gate that was closed', (tester) async {
      await tester.pumpWidget(_embed(_Controls(nodes)));
      await tester.pump();
      nodes[1].requestFocus();
      await tester.pump();
      expect(nodes[1].hasFocus, isFalse);

      final semantics = tester.ensureSemantics();
      await tester.pump();
      nodes[1].requestFocus();
      await tester.pump();

      expect(primary(), nodes[1]);
      semantics.dispose();
    });

    _test('Tab lands on the first control of a view with a stop after the app', (tester) async {
      // The gate is open, so the `View` has already given the focus to the
      // navigator's scope when the gate hears of it. The gate goes on from
      // that stop, not from the one after it.
      final after = FocusNode(debugLabel: 'after the app');
      addTearDown(after.dispose);
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_embed(_Controls(nodes), stopAfter: after));
      await tester.pump();

      await tabIn(tester);

      expect(primary(), nodes.first);
      semantics.dispose();
    });
  });

  _test('a gate that is gone ignores what the engine reports', (tester) async {
    await tester.pumpWidget(_embed(_Controls(nodes)));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());

    report(tester, ViewFocusState.focused, direction: ViewFocusDirection.forward);
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
