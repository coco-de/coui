// Guards the Web slider's pointer wiring.
//
// The component declared `onChangeStart` / `onChangeEnd`, threaded both
// through `copyWith`, and fired neither: its drag registration passed a
// literal `onUp: (_) {}`, so a press-release produced no end signal and
// no cancel path existed at all. A consumer writing one slider for both
// platforms got a commit signal on Flutter and silence here.
//
// What this file can and cannot reach:
//
//   Dispatching the callbacks needs a real `web.PointerEvent` and real
//   element geometry — `getMouseRatio` measures the track. These tests
//   run on the VM, where `package:web` is a stub and no layout exists, so
//   the gesture itself cannot be driven here. The order-and-values
//   assertions live in the Flutter twin's
//   `slider_change_lifecycle_test.dart`, which can drive a real drag.
//
//   What is reachable is whether the handler is *attached*, which is the
//   shape the bug actually took — the wiring was absent, not wrong. A
//   build that drops the pointerdown registration fails here.

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

const _kPointerDownEvent = 'pointerdown';

/// The event names bound on the slider's root element.
Set<String> _boundEvents() {
  for (final element in find.tag('div').evaluate()) {
    final dom = element.component as DomComponent;
    if (dom.attributes?['role'] == 'slider') {
      return (dom.events ?? const {}).keys.toSet();
    }
  }

  return const {};
}

void main() {
  group('Slider pointer wiring', () {
    testComponents('an interactive slider binds pointerdown', (tester) async {
      pumpWithTheme(tester, Slider(value: 50, onChanged: (_) {}));

      expect(
        _boundEvents(),
        contains(_kPointerDownEvent),
        reason: 'the drag lifecycle hangs off this registration',
      );
    });

    testComponents('a disabled slider binds no pointerdown', (tester) async {
      pumpWithTheme(
        tester,
        Slider(value: 50, enabled: false, onChanged: (_) {}),
      );

      expect(_boundEvents(), isNot(contains(_kPointerDownEvent)));
    });

    testComponents('a read-only slider binds no pointerdown', (tester) async {
      pumpWithTheme(tester, Slider(value: 50));

      expect(
        _boundEvents(),
        isNot(contains(_kPointerDownEvent)),
        reason: 'no onChanged means nothing to report',
      );
    });

    testComponents('the lifecycle callbacks survive copyWith', (tester) async {
      var started = false;
      var ended = false;

      final slider = Slider(
        value: 50,
        onChanged: (_) {},
        onChangeStart: (_) => started = true,
        onChangeEnd: (_) => ended = true,
      ).copyWith(value: 60);

      pumpWithTheme(tester, slider);

      expect(slider.value, equals(60));
      expect(slider.onChangeStart, isNotNull);
      expect(slider.onChangeEnd, isNotNull);

      // Proves the copies are the caller's closures rather than fresh
      // no-ops threaded into their place.
      slider.onChangeStart!(0);
      slider.onChangeEnd!(0);
      expect(started, isTrue);
      expect(ended, isTrue);
    });
  });
}
