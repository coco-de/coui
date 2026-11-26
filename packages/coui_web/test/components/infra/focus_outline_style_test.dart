import 'package:coui_web/coui_web.dart';
// focus_outline_style.dart is not re-exported by the barrel — import it
// directly for resolver-level assertions.
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

BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return context;
}

const CoreFocusOutlineStyle _kCircleRadius4 = CoreFocusOutlineStyle(
  circleBorderRadius: CoreBorderRadius.all(CoreRadius.radius4),
);

const CoreFocusOutlineStyle _kRectRadius4 = CoreFocusOutlineStyle(
  borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
);

String? _radius(
  BuildContext context, {
  required CoreFocusOutlineShape shape,
  CoreFocusOutlineStyle? style,
}) => resolveFocusOutline(
  context,
  focused: true,
  shape: shape,
  focusOutlineStyle: style,
).root.inlineStyles?.properties['border-radius'];

void main() {
  testComponents('zero-width ring emits a zero CSS outline', (tester) async {
    final context = _themedContext(tester);
    for (final shape in CoreFocusOutlineShape.values) {
      final resolved = resolveFocusOutline(
        context,
        focused: true,
        shape: shape,
        focusOutlineStyle: const CoreFocusOutlineStyle(
          align: 0,
          borderWidth: 0,
        ),
      );
      expect(
        resolved.root.inlineStyles?.properties['outline-width'],
        'var(--coui-stroke-width-0)',
      );
    }
  });

  group('FocusOutline circle radius (Web)', () {
    // Web already honoured `circleBorderRadius` when #4091 was filed —
    // that asymmetry is what made the Flutter side a gap rather than a
    // shared design decision. Pinning it here means a later "the field
    // reaches nothing, delete it" reads as a failure on both platforms
    // instead of only the one that was already broken.
    testComponents('the circle shape emits the design-system pill default', (
      tester,
    ) async {
      final context = _themedContext(tester);

      expect(
        _radius(context, shape: .circle),
        contains('var(--coui-radius-9999)'),
      );
    });

    testComponents('an override replaces the pill default', (tester) async {
      final context = _themedContext(tester);

      final radius = _radius(
        context,
        shape: .circle,
        style: _kCircleRadius4,
      );

      expect(radius, contains('var(--coui-radius-4)'));
      expect(
        radius,
        isNot(contains('var(--coui-radius-9999)')),
        reason:
            'the override has to replace the default, not sit alongside '
            'it',
      );
    });

    testComponents('the rectangle shape ignores the circle radius field', (
      tester,
    ) async {
      final context = _themedContext(tester);

      expect(
        _radius(
          context,
          shape: .rectangle,
          style: _kCircleRadius4,
        ),
        isNull,
        reason:
            'the two radius fields are mutually exclusive by shape — a '
            'rectangle ring stays square unless `borderRadius` says '
            'otherwise',
      );
      expect(
        _radius(
          context,
          shape: .rectangle,
          style: _kRectRadius4,
        ),
        contains('var(--coui-radius-4)'),
      );
    });

    testComponents('the circle shape ignores the rectangle radius field', (
      tester,
    ) async {
      final context = _themedContext(tester);

      expect(
        _radius(
          context,
          shape: .circle,
          style: _kRectRadius4,
        ),
        contains('var(--coui-radius-9999)'),
      );
    });
  });

  group('FocusOutline ring is an outline; the band only when stated (Web)', () {
    ResolvedFocusOutline resolve(
      BuildContext context, {
      required bool focused,
      CoreFocusOutlineStyle? style,
    }) => resolveFocusOutline(
      context,
      focused: focused,
      shape: .rectangle,
      focusOutlineStyle: style,
    );

    testComponents('the default band is transparent — no box-shadow layer', (
      tester,
    ) async {
      final context = _themedContext(tester);
      for (final focused in [true, false]) {
        final props = resolve(
          context,
          focused: focused,
        ).root.inlineStyles!.properties;
        expect(props, isNot(contains('box-shadow')), reason: '$focused');
        expect(props['outline-width'], 'var(--coui-stroke-width-2)');
        expect(
          props['outline-offset'],
          'calc(4.0px - var(--coui-stroke-width-2))',
        );
        expect(
          props['transition'],
          'outline-color var(--coui-duration-150) var(--easing-ease-in-out)',
        );
      }
    });

    testComponents('the outline stays on in both states and only its colour '
        'moves — the ring colour when focused, the same triplet at zero '
        'alpha at rest', (tester) async {
      final context = _themedContext(tester);
      final focused = resolve(context, focused: true).root;
      final resting = resolve(context, focused: false).root;

      // Switched on by a class (not inline) so the forced-colours root rule
      // can still switch it off on this non-focused wrapper — and in BOTH
      // states, so blurring fades the colour out instead of dropping
      // `outline-style` to `none` and snapping the ring off.
      expect(focused.className, 'outline');
      expect(resting.className, 'outline');
      expect(
        focused.inlineStyles!.properties['outline-color'],
        'rgb(var(--coui-focus-ring) / 1.0)',
      );
      expect(
        resting.inlineStyles!.properties['outline-color'],
        'rgb(var(--coui-focus-ring) / 0)',
      );
    });

    testComponents('a stated band paints one box-shadow layer of the gap', (
      tester,
    ) async {
      final context = _themedContext(tester);
      const style = CoreFocusOutlineStyle(
        offsetColor: CoreFocusRing.opaqueOffsetColor,
      );
      final focused = resolve(
        context,
        focused: true,
        style: style,
      ).root.inlineStyles!.properties;
      final resting = resolve(
        context,
        focused: false,
        style: style,
      ).root.inlineStyles!.properties;

      expect(
        focused['box-shadow'],
        '0 0 0 calc(4.0px - var(--coui-stroke-width-2)) '
        'rgb(var(--coui-surface) / 1.0)',
      );
      // Same single layer at rest, alpha 0 — the fade interpolates the
      // channel instead of padding a missing layer from black.
      expect(
        resting['box-shadow'],
        '0 0 0 calc(4.0px - var(--coui-stroke-width-2)) '
        'rgb(var(--coui-surface) / 0)',
      );
      expect(focused['transition'], contains('box-shadow '));
    });
  });
}
