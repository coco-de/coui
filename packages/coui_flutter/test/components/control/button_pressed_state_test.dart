import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

const ValueKey<String> _kButton = ValueKey('pressed-button');
const ValueKey<String> _kLabel = ValueKey('pressed-label');
const ValueKey<String> _kLeading = ValueKey('pressed-leading');
const ValueKey<String> _kTrailing = ValueKey('pressed-trailing');

Finder get _button => find.byKey(_kButton);

ResolvedButton _resolved(WidgetTester tester) {
  final button = tester.widget<Button>(_button);
  return resolveButton(
    tester.element(_button),
    variant: button.variant,
    size: button.size,
    shape: button.shape,
    role: button.role,
    buttonStyle: button.buttonStyle,
  );
}

Finder _chrome() {
  final chrome = find.descendant(
    of: _button,
    matching: find.byWidgetPredicate(
      (widget) => widget is AnimatedContainer && widget.decoration != null,
    ),
  );
  expect(chrome, findsOneWidget);
  return chrome;
}

void _expectChrome(
  WidgetTester tester,
  Set<WidgetState> states, {
  bool targetOnly = false,
}) {
  final resolved = _resolved(tester);
  final expected = resolved.decoration.resolve(states) as BoxDecoration;
  final chrome = _chrome();
  final BoxDecoration actual;
  if (targetOnly) {
    // Keyboard activation is a timed pulse. Check the live paint target before
    // its timer expires; settled pointer cases inspect the painted child below.
    actual =
        tester.widget<AnimatedContainer>(chrome).decoration! as BoxDecoration;
  } else {
    final painted = find.descendant(
      of: chrome,
      matching: find.byType(DecoratedBox),
    );
    expect(painted, findsOneWidget);
    actual = tester.widget<DecoratedBox>(painted).decoration as BoxDecoration;
  }
  expect(actual.color, expected.color, reason: 'actual fill for $states');
  expect(actual.border, expected.border, reason: 'actual edge for $states');
  expect(
    DefaultTextStyle.of(tester.element(find.byKey(_kLabel))).style.color,
    resolved.textStyle.resolve(states).color,
    reason: 'inherited label for $states',
  );
  expect(
    IconTheme.of(tester.element(find.byKey(_kLeading))).color,
    resolved.leadingIconTheme.resolve(states).color,
    reason: 'inherited leading icon for $states',
  );
  expect(
    IconTheme.of(tester.element(find.byKey(_kTrailing))).color,
    resolved.trailingIconTheme.resolve(states).color,
    reason: 'inherited trailing icon for $states',
  );
}

Future<void> _mount(
  WidgetTester tester, {
  CoreButtonVariant variant = .primary,
  bool dark = false,
  bool enabled = true,
  VoidCallback? onPressed,
  CoreButtonStyle? style,
  WidgetStatesController? states,
  FocusNode? focus,
}) async {
  await pumpTestApp(
    tester,
    Button(
      key: _kButton,
      variant: variant,
      enabled: enabled,
      onPressed: onPressed ?? () {},
      buttonStyle: style,
      statesController: states,
      focusNode: focus,
      leading: const SizedBox(key: _kLeading, width: 8, height: 8),
      trailing: const SizedBox(key: _kTrailing, width: 8, height: 8),
      child: const Text('Action', key: _kLabel),
    ),
    theme: ThemeData.fromCore(
      dark ? CoreThemePresets.dark : CoreThemePresets.light,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final variant in [
    CoreButtonVariant.primary,
    CoreButtonVariant.destructive,
  ]) {
    for (final dark in [false, true]) {
      testWidgets('${variant.name}/$dark paints held press and returns on up', (
        tester,
      ) async {
        var calls = 0;
        await _mount(
          tester,
          variant: variant,
          dark: dark,
          onPressed: () => calls++,
        );
        final resolved = _resolved(tester);
        expect(
          resolved.decoration.resolve({WidgetState.pressed}),
          isNot(resolved.decoration.resolve({})),
          reason: 'the authored pressed treatment must differ from rest',
        );
        _expectChrome(tester, {});
        final gesture = await tester.startGesture(tester.getCenter(_button));
        var finished = false;
        try {
          await tester.pumpAndSettle();
          expect(calls, 0);
          _expectChrome(tester, {WidgetState.pressed});
          await gesture.up();
          finished = true;
          await tester.pumpAndSettle();
          _expectChrome(tester, {});
          expect(calls, 1);
        } finally {
          if (!finished) await gesture.cancel();
        }
      });
    }
  }

  testWidgets('cancel clears the actual held treatment without activation', (
    tester,
  ) async {
    var calls = 0;
    await _mount(tester, onPressed: () => calls++);
    final gesture = await tester.startGesture(tester.getCenter(_button));
    var finished = false;
    try {
      await tester.pumpAndSettle();
      _expectChrome(tester, {WidgetState.pressed});
      await gesture.cancel();
      finished = true;
      await tester.pumpAndSettle();
      _expectChrome(tester, {});
      expect(calls, 0);
    } finally {
      if (!finished) await gesture.cancel();
    }
  });

  testWidgets('held mouse press takes precedence over hover', (tester) async {
    final mouse = await tester.createGesture(kind: .mouse);
    await mouse.addPointer(location: .zero);
    addTearDown(mouse.removePointer);
    await _mount(tester);
    await mouse.moveTo(tester.getCenter(_button));
    await tester.pumpAndSettle();
    _expectChrome(tester, {WidgetState.hovered});
    final resolved = _resolved(tester);
    expect(
      resolved.decoration.resolve({WidgetState.hovered, WidgetState.pressed}),
      isNot(resolved.decoration.resolve({WidgetState.hovered})),
    );
    await mouse.down(tester.getCenter(_button));
    var finished = false;
    try {
      await tester.pumpAndSettle();
      _expectChrome(tester, {WidgetState.hovered, WidgetState.pressed});
      await mouse.up();
      finished = true;
      await tester.pumpAndSettle();
      _expectChrome(tester, {WidgetState.hovered});
      await mouse.moveTo(.zero);
      await tester.pumpAndSettle();
      _expectChrome(tester, {});
    } finally {
      if (!finished) await mouse.cancel();
    }
  });

  testWidgets('disabled treatment still wins and ignores the pointer', (
    tester,
  ) async {
    var calls = 0;
    await _mount(tester, enabled: false, onPressed: () => calls++);
    final gesture = await tester.startGesture(tester.getCenter(_button));
    try {
      await tester.pumpAndSettle();
      _expectChrome(tester, {WidgetState.disabled, WidgetState.pressed});
    } finally {
      await gesture.cancel();
    }
    await tester.pumpAndSettle();
    _expectChrome(tester, {WidgetState.disabled});
    expect(calls, 0);
  });

  testWidgets('selected menu treatment keeps its existing precedence', (
    tester,
  ) async {
    final states = WidgetStatesController({WidgetState.selected});
    addTearDown(states.dispose);
    await _mount(tester, variant: .menu, states: states);
    _expectChrome(tester, {WidgetState.selected});
    final gesture = await tester.startGesture(tester.getCenter(_button));
    try {
      await tester.pumpAndSettle();
      _expectChrome(tester, {WidgetState.selected, WidgetState.pressed});
    } finally {
      await gesture.cancel();
    }
    await tester.pumpAndSettle();
    _expectChrome(tester, {WidgetState.selected});
  });

  testWidgets('plain instance ramp reaches the actual pressed fill', (
    tester,
  ) async {
    await _mount(
      tester,
      variant: .plain,
      style: const CoreButtonStyle(
        foregroundColor: CoreColor.token(CoreColors.onInfo),
        hoverForegroundColor: CoreColor.token(CoreColors.onInfo),
        stateLayer: CoreStateLayer.subtle,
      ),
    );
    _expectChrome(tester, {});
    final gesture = await tester.startGesture(tester.getCenter(_button));
    try {
      await tester.pumpAndSettle();
      _expectChrome(tester, {WidgetState.pressed});
    } finally {
      await gesture.cancel();
    }
    await tester.pumpAndSettle();
    _expectChrome(tester, {});
  });

  testWidgets('keyboard activation exposes the same authored press pulse', (
    tester,
  ) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    var calls = 0;
    await _mount(tester, focus: focus, onPressed: () => calls++);
    focus.requestFocus();
    await tester.pumpAndSettle();
    expect(focus.hasFocus, isTrue);
    expect(await tester.sendKeyEvent(.enter), isTrue);
    await tester.pump();
    try {
      _expectChrome(tester, {
        WidgetState.focused,
        WidgetState.pressed,
      }, targetOnly: true);
    } finally {
      await tester.pump(_resolved(tester).castHideDuration);
      await tester.pumpAndSettle();
    }
    _expectChrome(tester, {WidgetState.focused});
    expect(calls, 1);
  });
}
