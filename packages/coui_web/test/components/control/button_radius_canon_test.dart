import 'package:coui_web/coui_web.dart';
// Resolver-level assertion — the focus outline style is not on the barrel.
import 'package:coui_web/src/components/infra/focus_outline/focus_outline_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

/// The control corner per size — the control height × 0.25 (디자이너 결정
/// 2026-10-08), stated from the contract heights rather than read off the
/// style row, so the test checks the emit against the rule.
final Map<CoreComponentSize, int> _kCorner = {
  for (final (size, height) in [
    (CoreComponentSize.xs, CoreControlSize.heightXs),
    (CoreComponentSize.sm, CoreControlSize.heightSm),
    (CoreComponentSize.md, CoreControlSize.heightMd),
    (CoreComponentSize.lg, CoreControlSize.heightLg),
    (CoreComponentSize.xl, CoreControlSize.heightXl),
    (CoreComponentSize.xl2, CoreControlSize.heightXl2),
  ])
    size: (height * 0.25).toInt(),
};

/// The four-corner shorthand `CoreBorderRadius.toValue()` emits.
String _all(int n) => List.filled(4, 'var(--coui-radius-$n)').join(' ');

BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return context;
}

ResolvedButton _button(
  BuildContext context, {
  required CoreComponentSize size,
  CoreButtonShape shape = CoreButtonShape.rectangle,
  CoreButtonStyle? style,
}) => resolveButton(
  context,
  variant: CoreButtonVariant.primary,
  size: size,
  shape: shape,
  expanded: false,
  buttonStyle: style,
);

String? _buttonRadius(
  BuildContext context, {
  required CoreComponentSize size,
  CoreButtonShape shape = CoreButtonShape.rectangle,
  CoreButtonStyle? style,
}) => _button(
  context,
  size: size,
  shape: shape,
  style: style,
).root.inlineStyles?.properties['border-radius'];

void main() {
  group('control corner — Button (Web)', () {
    testComponents('every size emits its height × 0.25', (tester) async {
      final context = _themedContext(tester);
      for (final size in CoreComponentSize.values) {
        expect(
          _buttonRadius(context, size: size),
          _all(_kCorner[size]!),
          reason: '$size — the corner is one ratio of the control height.',
        );
      }
    });

    testComponents('square takes the same corner as the rectangle', (
      tester,
    ) async {
      final context = _themedContext(tester);
      for (final size in CoreComponentSize.values) {
        expect(
          _buttonRadius(context, size: size, shape: CoreButtonShape.square),
          _all(_kCorner[size]!),
          reason: '$size',
        );
      }
    });

    testComponents('the dashed-border overlay follows the size corner', (
      tester,
    ) async {
      final context = _themedContext(tester);
      for (final size in CoreComponentSize.values) {
        final rect = _button(
          context,
          size: size,
          style: const CoreButtonStyle(dashedBorder: true),
        ).dashRect!;
        expect(
          rect.inlineStyles!.properties['rx'],
          'max(0px, calc(var(--coui-radius-${_kCorner[size]!}) - '
          '${rect.inlineStyles!.properties['stroke-width']} / 2))',
          reason: '$size',
        );
      }
    });

    testComponents('circle keeps the pill, an override still wins', (
      tester,
    ) async {
      final context = _themedContext(tester);
      expect(
        _buttonRadius(
          context,
          size: CoreComponentSize.md,
          shape: CoreButtonShape.circle,
        ),
        contains('var(--coui-radius-9999)'),
      );
      expect(
        _buttonRadius(
          context,
          size: CoreComponentSize.lg,
          style: const CoreButtonStyle(
            borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
          ),
        ),
        _all(4),
      );
    });

    testComponents('the focus ring rides the root corner on every size', (
      tester,
    ) async {
      final context = _themedContext(tester);
      for (final size in CoreComponentSize.values) {
        final root = _button(context, size: size).root;
        // The ring is an outline on the button element itself, so it
        // curves around the element's own `border-radius` (grown by the
        // offset) — the size corner — with no radius of its own to fall
        // out of step.
        expect(root.className, contains('focus-visible:outline-'));
        expect(
          root.inlineStyles!.properties['border-radius'],
          _all(_kCorner[size]!),
          reason: '$size',
        );
      }
    });
  });

  group('FocusOutline derives band / ring (Web)', () {
    testComponents('the ring rides the host radius; +2 / +4 are the offset '
        'and width', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final props = resolveFocusOutline(
        context,
        focused: true,
        shape: CoreFocusOutlineShape.rectangle,
        focusOutlineStyle: const CoreFocusOutlineStyle(
          borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
        ),
      ).root.inlineStyles!.properties;
      // The outline grows concentrically around the element's own
      // `border-radius` — the browser computes R+2 / R+4 from the offset
      // and width; nothing states 12 or 14.
      expect(props['border-radius'], _all(10));
      final ring = [
        props['outline-offset']!,
        props['outline-width']!,
      ].join(' ');
      expect(props['outline-offset'], startsWith('calc(4.0px - '));
      expect(ring, isNot(contains('12px')));
      expect(ring, isNot(contains('14px')));
    });
  });

  group('Fieldset (Web)', () {
    testComponents('stays 16 (the surface role) whatever the fields inside', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final props = resolveFieldset(
        context,
        enabled: true,
        size: CoreComponentSize.md,
      ).root.inlineStyles!.properties;
      expect(props['border-radius'], _all(16));
    });
  });
}
