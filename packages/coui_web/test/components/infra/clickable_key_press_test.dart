// Regression for #4421: `Clickable` gave press feedback (scale-shrink /
// neo-brutalism cast shift) to a mouse press but not to a Space/Enter
// keyboard activation — the browser attaches `:active` on keyboard
// activation only to a native `<button>`, never to the `<div
// role="button">` `Clickable` renders (it wraps arbitrary content, and a
// native `<button>` around another interactive element is invalid HTML).
//
// `clickable.dart`'s keydown/keyup/blur handlers toggle
// `kClickableKeyPressedMarker` directly on the DOM node instead — this
// file covers what that fix needs to be *reachable*: the resolved press
// duration the Enter-key pulse rides (`resolveClickableTiming`), and that
// the global press rule (`coui_web.dart`'s `CoUIWeb`) actually matches the
// marker with the identical transform/shadow the `:active` rules use.
//
// The live keydown/keyup dispatch itself is not covered here — `dart
// test` runs this suite on the VM (no `dart_test.yaml` chrome platform is
// configured in this package), and `universal_web`'s `KeyboardEvent.key`
// getter throws `Unsupported operation` outside a real browser/JS
// environment. `Resizable`'s `resizable_test.dart` and `Slider`'s
// `slider_test.dart` document the same limitation for the same reason.
library;

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/server_test.dart';

import '../../helpers/pump_with_theme.dart';

/// An override value distinct from [CoreClickableStyle.defaultPressDuration]
/// — proves the pulse duration actually follows the merge chain rather
/// than being hardcoded to the default.
const _kOverridePressDuration = Duration(milliseconds: 250);

ResolvedClickableTiming? _seenTiming;

class _CaptureTiming extends StatelessComponent {
  const _CaptureTiming({required this.style});

  final CoreClickableStyle? style;

  @override
  Component build(BuildContext context) {
    _seenTiming = resolveClickableTiming(context, clickableStyle: style);
    return const Component.text('x');
  }
}

void main() {
  group('resolveClickableTiming (#4421)', () {
    testComponents(
      'defaults to CoreClickableStyle.defaultPressDuration',
      (tester) async {
        pumpWithTheme(tester, const _CaptureTiming(style: null));
        await tester.pump();

        expect(
          _seenTiming!.pressDurationMs,
          CoreClickableStyle.defaultPressDuration.inMilliseconds,
        );
      },
    );

    testComponents(
      'a pressDuration override reaches the pulse duration — the Enter '
      'pulse cannot drift from the pointer/Space press pair it rides the '
      'same token as',
      (tester) async {
        pumpWithTheme(
          tester,
          const _CaptureTiming(
            style: CoreClickableStyle(pressDuration: _kOverridePressDuration),
          ),
        );
        await tester.pump();

        expect(
          _seenTiming!.pressDurationMs,
          _kOverridePressDuration.inMilliseconds,
        );
      },
    );
  });

  group('global keyboard-press rule (#4421)', () {
    testServer(
      'the keyboard marker rule states the identical transform/shadow the '
      ':active rules do — same custom properties, different trigger',
      (tester) async {
        tester.pumpComponent(
          CoUIWeb(
            theme: .coui,
            child: const Clickable(id: 'c', child: Text('press me')),
          ),
        );
        final response = await tester.request('/');
        final styleTags = response.document!.querySelectorAll('style');
        final css = styleTags.map((s) => s.text).join();

        // Whole-declaration strings, not a bare substring of the marker
        // class name — `web/pseudo-state-emit.md` warns this is exactly
        // the trap that lets a rule exist under the right selector but
        // with the wrong (or no) declaration survive a substring check.
        const transform =
            'transform:translate(var(--coui-press-x,0),'
            'var(--coui-press-y,0)) scale(var(--coui-press-scale,1));';
        const shadow = 'box-shadow:var(--coui-press-shadow);';

        expect(
          css,
          contains(
            '.coui-clickable-press.coui-clickable-key-pressed'
            '{$transform}',
          ),
        );
        expect(
          css,
          contains(
            '.coui-clickable-press-shadow.coui-clickable-key-pressed'
            '{$shadow}',
          ),
        );

        // The pointer-driven `:active` rules still carry the same
        // declarations — this fix adds a second trigger, it does not
        // replace the first.
        expect(css, contains('.coui-clickable-press:active{$transform}'));
        expect(
          css,
          contains('.coui-clickable-press-shadow:active{$shadow}'),
        );
      },
    );

    testServer(
      'the marker class is never baked into a default render — it is '
      'toggled by the keydown/keyup/blur handlers, not stated per-instance',
      (tester) async {
        tester.pumpComponent(
          CoUIWeb(
            theme: .coui,
            child: const Clickable(id: 'c', child: Text('press me')),
          ),
        );
        final response = await tester.request('/');
        final node = response.document!.querySelector('#c');

        expect(node, isNotNull);
        expect(
          node!.attributes['class'],
          isNot(contains('coui-clickable-key-pressed')),
        );
      },
    );
  });
}
