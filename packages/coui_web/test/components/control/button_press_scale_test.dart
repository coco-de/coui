import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// Web `Button` shrinks while pressed, the way the Flutter twin does
/// through `Clickable.pressedScale` (#4427).
///
/// Three halves, each pinned separately because none of them proves the
/// others:
///
///  * the **resolver** opts the control in (marker class) and states the
///    factor (`kControlPressScaleVar`) from `CoreButtonStyle.pressedScale`
///    — and stays out when feedback is off or the factor is the identity;
///  * the **shared rule** writes `scale` on `:active` only, so the rest
///    render is untouched, and runs it on the engage clock;
///  * the **style gate** (`kControlPressShrinkVar`) stands the shrink
///    down where the style's travel carries the press, and a control that
///    casts nothing restores it — the Flutter resolver's pin, term for
///    term.
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

ResolvedButton _resolve(
  ComponentTester tester, {
  CoreButtonVariant variant = CoreButtonVariant.primary,
  bool enableFeedback = CoreButtonContract.defaultEnableFeedback,
  CoreButtonStyle? buttonStyle,
}) => resolveButton(
  _themedContext(tester),
  variant: variant,
  size: CoreComponentSize.md,
  shape: CoreButtonShape.rectangle,
  expanded: false,
  enableFeedback: enableFeedback,
  buttonStyle: buttonStyle,
);

Set<String> _classes(ResolvedButton resolved) =>
    resolved.root.className.split(' ').toSet();

Map<String, String> _raw(ResolvedButton resolved) =>
    resolved.root.inlineStyles?.properties ?? const {};

/// The one-layer cast neo-brutalism authors — enough for the geometry
/// block to publish a travel.
const List<CoreShadowLayer> _kCast = [
  (
    offsetX: 4.0,
    offsetY: 4.0,
    blurRadius: 0.0,
    spreadRadius: 0.0,
    opacity: 1.0,
    inset: false,
  ),
];

void main() {
  group('the resolver opts a button into the press shrink', () {
    testComponents('a default button carries the marker and the factor', (
      tester,
    ) async {
      final resolved = _resolve(tester);

      expect(_classes(resolved), contains(kControlPressScaleMarker));
      expect(
        _raw(resolved)[kControlPressScaleVar],
        '${CoreButtonStyle.defaultPressedScale}',
        reason:
            'the factor is the Core default the Flutter twin hands '
            '`Clickable.pressedScale` — one value, both platforms',
      );
    });

    testComponents('a per-instance pressedScale reaches the inline bundle', (
      tester,
    ) async {
      const scale = 0.9;
      final resolved = _resolve(
        tester,
        buttonStyle: const CoreButtonStyle(pressedScale: scale),
      );

      expect(_raw(resolved)[kControlPressScaleVar], '$scale');
    });

    testComponents('enableFeedback: false withholds the shrink entirely', (
      tester,
    ) async {
      final resolved = _resolve(tester, enableFeedback: false);

      expect(_classes(resolved), isNot(contains(kControlPressScaleMarker)));
      expect(_raw(resolved), isNot(contains(kControlPressScaleVar)));
    });

    testComponents('a pressedScale of 1.0 gains no rule at all', (
      tester,
    ) async {
      final resolved = _resolve(
        tester,
        buttonStyle: const CoreButtonStyle(pressedScale: 1),
      );

      expect(_classes(resolved), isNot(contains(kControlPressScaleMarker)));
      expect(_raw(resolved), isNot(contains(kControlPressScaleVar)));
    });

    testComponents(
      'a button that casts nothing restores the style gate — it has no '
      'shadow to travel into',
      (tester) async {
        // Ghost has no fill, so no injected cast and a zeroed travel.
        final resolved = _resolve(tester, variant: CoreButtonVariant.ghost);

        expect(_raw(resolved)['--coui-control-shadow-offset-x'], '0px');
        expect(_raw(resolved)[kControlPressShrinkVar], '1');
      },
    );

    testComponents(
      'a filled button leaves the style gate to the style — it casts',
      (tester) async {
        final resolved = _resolve(tester);

        expect(_raw(resolved), isNot(contains(kControlPressShrinkVar)));
      },
    );

    testComponents('an anchor-rendered button carries it too', (tester) async {
      // `href` changes the tag, never the resolver's input — the class
      // list is the same object a `<button>` gets.
      pumpWithTheme(
        tester,
        Button(href: '/contact', child: const Text('Contact')),
      );

      final anchor = find.tag('a');
      expect(anchor, findsOneComponent);
      final element = anchor.evaluate().single.component as DomComponent;
      expect(
        (element.classes ?? '').split(' '),
        contains(kControlPressScaleMarker),
      );
    });
  });

  group('the shared rule shrinks on press only', () {
    final css = ThemeConfig.defaults().cssVariables;

    test('scale is written under :active — never on the bare marker', () {
      expect(
        css,
        contains(
          '@media (hover:hover){.$kControlPressScaleMarker'
          ':active:hover:not(:disabled) ',
        ),
      );
      expect(
        css,
        contains(
          '@media (hover:none){.$kControlPressScaleMarker'
          ':active:not(:disabled) ',
        ),
      );
      expect(
        RegExp(
          '\\.${RegExp.escape(kControlPressScaleMarker)}\\s*\\{',
        ).hasMatch(css),
        isFalse,
        reason:
            'a rule on the bare marker would apply at rest — the rest '
            'render must not change',
      );
    });

    test('the factor is gated by the style', () {
      expect(
        css,
        contains(
          'scale:calc(1 - (1 - var($kControlPressScaleVar,1)) * '
          'var($kControlPressShrinkVar,1));',
        ),
      );
    });

    test('scale eases on the engage clock, inside the one transition', () {
      final block = RegExp(
        '\\.${RegExp.escape(kControlShadowPressMarker)}\\{transition:([^}]*)\\}',
      ).firstMatch(css)!.group(1)!;

      expect(
        block,
        contains(
          'scale var($kControlEngageDurationVar,'
          '${durationMsCss(CoreDuration.ms50)})',
        ),
        reason:
            'the Flutter twin animates the shrink over castHideDuration — '
            'the clock this variable carries',
      );
    });
  });

  group('the style gate', () {
    final config = ThemeConfig.defaults();

    test('a style that travels stands the shrink down', () {
      final block = config.surfaceStyleGeometryBlock(
        .neoBrutalism,
        const CoreSurfaceGeometryConstraint(
          shadowOffsetAdd: (dx: 4, dy: 4),
          controlShadow: _kCast,
        ),
      );

      expect(block, contains('$kControlPressShrinkVar:0;'));
    });

    test('a zero travel leaves it alone — nothing carries the press '
        'instead', () {
      final block = config.surfaceStyleGeometryBlock(
        .neoBrutalism,
        const CoreSurfaceGeometryConstraint(
          shadowOffsetAdd: (dx: 0, dy: 0),
          controlShadow: _kCast,
        ),
      );

      expect(block, isNot(contains(kControlPressShrinkVar)));
    });
  });
}
