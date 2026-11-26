import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/infra/clickable/clickable_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

const _shift = CoreOffset(4, 4);
const _hard = [
  (
    offsetX: 0.0,
    offsetY: 2.0,
    blurRadius: 0.0,
    spreadRadius: 0.0,
    opacity: 1.0,
    inset: false,
  ),
];

ResolvedClickable? _seen;

class _Capture extends StatelessComponent {
  const _Capture({required this.style});

  final CoreClickableStyle? style;

  @override
  Component build(BuildContext context) {
    _seen = resolveClickable(
      context,
      enabled: true,
      focusOutline: true,
      enableFeedback: true,
      clickableStyle: style,
    );

    return const Component.text('x');
  }
}

Future<ResolvedClickable> _resolve(
  ComponentTester tester,
  CoreClickableStyle? style,
) async {
  pumpWithTheme(tester, _Capture(style: style));
  await tester.pump();

  return _seen!;
}

void main() {
  group('a style that says nothing about pressing changes nothing', () {
    testComponents('no press custom properties, no shadow class', (
      tester,
    ) async {
      // The whole point of the opt-in: a control with a resting shadow and
      // no press shadow must keep that shadow when pressed. The rule that
      // would take it away is only turned on by the class.
      final resolved = await _resolve(tester, null);
      final props = resolved.root.inlineStyles?.properties ?? const {};

      expect(props, isNot(contains('--coui-press-x')));
      expect(props, isNot(contains('--coui-press-shadow')));
      expect(
        resolved.root.className,
        isNot(contains('coui-clickable-press-shadow')),
      );
    });
  });

  group('a stated press reaches the page', () {
    testComponents('the shift is emitted in both axes', (tester) async {
      // Written together on purpose — a half-set pair would leave the
      // other axis on whatever an ancestor last set.
      final resolved = await _resolve(
        tester,
        const CoreClickableStyle(pressedTranslate: _shift),
      );
      final props = resolved.root.inlineStyles!.properties;

      expect(props['--coui-press-x'], isNotNull);
      expect(props['--coui-press-y'], isNotNull);
    });

    testComponents('the shadow rides a property, not a class', (tester) async {
      // A surface style states this shadow, and nothing makes its tint a
      // palette token. A custom property carries any colour; a Tailwind
      // colour class would need a token name and throw without one.
      final resolved = await _resolve(
        tester,
        const CoreClickableStyle(pressedBoxShadow: _hard),
      );

      expect(
        resolved.root.inlineStyles!.properties['--coui-press-shadow'],
        isNotNull,
      );
      expect(
        resolved.root.className,
        contains('coui-clickable-press-shadow'),
      );
    });

    testComponents('a shift survives the shrink being turned off', (
      tester,
    ) async {
      // A style built on a hard cast shadow says "pressed" by moving the
      // control into that shadow, and turns the shrink off because the
      // two read as different gestures. Gating the press chrome on the
      // scale alone would drop that style's entire effect.
      final resolved = await _resolve(
        tester,
        const CoreClickableStyle(pressedScale: 1, pressedTranslate: _shift),
      );
      final props = resolved.root.inlineStyles?.properties ?? const {};

      expect(props['--coui-press-x'], isNotNull);
      expect(resolved.root.className, contains('coui-clickable-press'));
    });

    testComponents('a raw tint does not throw', (tester) async {
      // The failure this replaces: a pseudo-state colour emitted as a
      // Tailwind class crashes at render when the value carries no token.
      final resolved = await _resolve(
        tester,
        const CoreClickableStyle(
          pressedBoxShadow: [
            (
              offsetX: 0.0,
              offsetY: 1.0,
              blurRadius: 0.0,
              spreadRadius: 0.0,
              opacity: 0.5,
              inset: false,
            ),
          ],
        ),
      );

      expect(
        resolved.root.inlineStyles!.properties['--coui-press-shadow'],
        isNotEmpty,
      );
    });
  });
}
