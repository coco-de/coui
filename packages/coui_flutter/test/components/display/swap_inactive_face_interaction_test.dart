import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart' as widgets;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

const _kSwapKey = widgets.ValueKey<String>('inactive-face-swap');

widgets.Widget _host(widgets.Widget child) => widgets.WidgetsApp(
  // Required app-shell metadata; it does not style either Swap face.
  color: const widgets.Color(0xff000000),
  builder: (_, _) => buildTestApp(
    child,
    theme: coui.ThemeData.fromCore(coui.CoreThemePresets.light),
  ),
);

widgets.Widget _pointerFace(widgets.VoidCallback onTap) =>
    widgets.GestureDetector(
      behavior: widgets.HitTestBehavior.opaque,
      onTap: onTap,
      child: const widgets.SizedBox(width: 48, height: 48),
    );

widgets.Widget _focusFace({
  required widgets.FocusNode focusNode,
  required widgets.VoidCallback onPressed,
  required double order,
  required String label,
}) => widgets.FocusTraversalOrder(
  order: widgets.NumericFocusOrder(order),
  child: widgets.SizedBox(
    width: 96,
    height: 48,
    child: widgets.FocusableActionDetector(
      focusNode: focusNode,
      shortcuts: const {
        widgets.SingleActivator(LogicalKeyboardKey.enter):
            widgets.ActivateIntent(),
        widgets.SingleActivator(LogicalKeyboardKey.space):
            widgets.ActivateIntent(),
      },
      actions: {
        widgets.ActivateIntent: widgets.CallbackAction<widgets.ActivateIntent>(
          onInvoke: (_) {
            onPressed();
            return null;
          },
        ),
      },
      child: widgets.GestureDetector(
        behavior: widgets.HitTestBehavior.opaque,
        onTap: onPressed,
        child: widgets.Text(label),
      ),
    ),
  ),
);

Future<void> _expectVisiblePointer(
  WidgetTester tester, {
  required coui.CoreSwapAnimation animation,
  required bool checked,
}) async {
  var offTaps = 0;
  var onTaps = 0;
  await tester.pumpWidget(
    _host(
      coui.Swap(
        key: _kSwapKey,
        checked: checked,
        animation: animation,
        offContent: _pointerFace(() {
          offTaps++;
        }),
        onContent: _pointerFace(() {
          onTaps++;
        }),
      ),
    ),
  );
  await tester.pumpAndSettle();

  // Equal face sizes isolate participation from the existing size policy.
  // No outer onToggle is supplied: these are ordinary caller-owned inputs.
  await tester.tapAt(tester.getCenter(find.byKey(_kSwapKey)));
  await tester.pump();

  expect(
    {'off': offTaps, 'on': onTaps},
    {'off': checked ? 0 : 1, 'on': checked ? 1 : 0},
  );
  expect(tester.takeException(), isNull);
}

Future<void> _expectVisibleFocus(
  WidgetTester tester, {
  required coui.CoreSwapAnimation animation,
  required bool checked,
}) async {
  final offFocus = widgets.FocusNode(debugLabel: 'off-face');
  final onFocus = widgets.FocusNode(debugLabel: 'on-face');
  addTearDown(offFocus.dispose);
  addTearDown(onFocus.dispose);
  var offActivations = 0;
  var onActivations = 0;
  await tester.pumpWidget(
    _host(
      widgets.FocusTraversalGroup(
        policy: widgets.OrderedTraversalPolicy(),
        child: coui.Swap(
          key: _kSwapKey,
          checked: checked,
          animation: animation,
          offContent: _focusFace(
            focusNode: offFocus,
            order: 0,
            label: 'Off',
            onPressed: () {
              offActivations++;
            },
          ),
          onContent: _focusFace(
            focusNode: onFocus,
            order: 1,
            label: 'On',
            onPressed: () {
              onActivations++;
            },
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  final visibleFocus = checked ? onFocus : offFocus;
  final hiddenFocus = checked ? offFocus : onFocus;
  visibleFocus.requestFocus();
  await tester.pump();
  expect(visibleFocus.hasFocus, isTrue);
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await tester.pumpAndSettle();
  expect(
    {'off': offActivations, 'on': onActivations},
    {'off': checked ? 0 : 1, 'on': checked ? 1 : 0},
  );

  // Explicit numeric orders avoid overlap/paint-order traversal ties.
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.pump();
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await tester.pumpAndSettle();
  expect(hiddenFocus.hasFocus, isFalse);
  expect(checked ? offActivations : onActivations, 0);

  // An inactive face also cannot acquire focus through the public API.
  hiddenFocus.requestFocus();
  await tester.pump();
  expect(hiddenFocus.hasFocus, isFalse);
  expect(tester.takeException(), isNull);
}

class _RetainedFace extends widgets.StatefulWidget {
  const _RetainedFace({
    required this.label,
    required this.width,
    super.key,
  });

  final String label;
  final double width;

  @override
  widgets.State<_RetainedFace> createState() => _RetainedFaceState();
}

class _RetainedFaceState extends widgets.State<_RetainedFace> {
  int taps = 0;

  @override
  widgets.Widget build(widgets.BuildContext context) => widgets.GestureDetector(
    behavior: widgets.HitTestBehavior.opaque,
    onTap: () {
      setState(() {
        taps++;
      });
    },
    child: widgets.SizedBox(
      width: widget.width,
      height: 32,
      child: widgets.Text('${widget.label}: $taps'),
    ),
  );
}

void main() {
  testWidgets('host Tab moves focus and Enter activates the second input', (
    tester,
  ) async {
    final first = widgets.FocusNode(debugLabel: 'host-first');
    final second = widgets.FocusNode(debugLabel: 'host-second');
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    var firstCalls = 0;
    var secondCalls = 0;
    await tester.pumpWidget(
      _host(
        widgets.FocusTraversalGroup(
          policy: widgets.OrderedTraversalPolicy(),
          child: widgets.Row(
            mainAxisSize: widgets.MainAxisSize.min,
            children: [
              _focusFace(
                focusNode: first,
                order: 0,
                label: 'First',
                onPressed: () {
                  firstCalls++;
                },
              ),
              _focusFace(
                focusNode: second,
                order: 1,
                label: 'Second',
                onPressed: () {
                  secondCalls++;
                },
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    first.requestFocus();
    await tester.pump();
    expect(first.hasFocus, isTrue);
    expect(second.hasFocus, isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(first.hasFocus, isFalse);
    expect(second.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(
      {'first': firstCalls, 'second': secondCalls},
      {'first': 0, 'second': 1},
    );
    expect(tester.takeException(), isNull);
  });

  for (final animation in [
    coui.CoreSwapAnimation.none,
    coui.CoreSwapAnimation.rotate,
  ]) {
    for (final checked in [false, true]) {
      final pointerName = animation == coui.CoreSwapAnimation.none && !checked
          ? 'inactive on face cannot intercept a visible off tap'
          : '${animation.name} checked=$checked routes taps to the active face';
      final focusName = animation == coui.CoreSwapAnimation.none && !checked
          ? 'inactive on face cannot receive Tab activation'
          : '${animation.name} checked=$checked excludes inactive focus';
      testWidgets(pointerName, (tester) async {
        await _expectVisiblePointer(
          tester,
          animation: animation,
          checked: checked,
        );
      });
      testWidgets(focusName, (tester) async {
        await _expectVisibleFocus(
          tester,
          animation: animation,
          checked: checked,
        );
      });
    }

    testWidgets('${animation.name} preserves both face states and layout', (
      tester,
    ) async {
      final checked = widgets.ValueNotifier<bool>(false);
      addTearDown(checked.dispose);
      final offKey = widgets.GlobalKey<_RetainedFaceState>();
      final onKey = widgets.GlobalKey<_RetainedFaceState>();
      final off = _RetainedFace(key: offKey, label: 'Off', width: 48);
      final on = _RetainedFace(key: onKey, label: 'On', width: 80);
      await tester.pumpWidget(
        _host(
          widgets.ValueListenableBuilder<bool>(
            valueListenable: checked,
            builder: (_, value, _) => coui.Swap(
              key: _kSwapKey,
              checked: value,
              animation: animation,
              offContent: off,
              onContent: on,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final offState = offKey.currentState;
      final onState = onKey.currentState;
      final offElement = offKey.currentContext;
      final onElement = onKey.currentContext;
      final initialSize = tester.getSize(find.byKey(_kSwapKey));
      expect(offState, isNotNull);
      expect(onState, isNotNull);

      for (final value in [false, true, false]) {
        checked.value = value;
        await tester.pumpAndSettle();
        expect(offKey.currentState, same(offState));
        expect(onKey.currentState, same(onState));
        expect(offKey.currentContext, same(offElement));
        expect(onKey.currentContext, same(onElement));
        expect(tester.getSize(find.byKey(_kSwapKey)), initialSize);
        await tester.tapAt(tester.getCenter(find.byKey(_kSwapKey)));
        await tester.pumpAndSettle();
      }
      expect(offState!.taps, 2);
      expect(onState!.taps, 1);
      expect(tester.takeException(), isNull);
    });
  }
}
