import 'package:coui_web/coui_web.dart';
// The resolvers are internal chrome — not re-exported by the barrel.
import 'package:coui_web/src/components/control/button/button_style.dart';
import 'package:coui_web/src/components/display/banner/banner_style.dart';
import 'package:coui_web/src/components/overlay/toast/toast_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// The hover and pressed wash a `plain` button wears when the surface it
/// sits on pins its label colour — a banner or toast action.
///
/// Web paints the wash from the scoped `color-mix()` rule
/// `resolveButtonRules` emits, so that rule is what these tests read.
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

const _kScope = 'co-button-test';

String _rules(BuildContext context, CoreButtonStyle? style) =>
    resolveButtonRules(
      context,
      scopeId: _kScope,
      variant: .plain,
      buttonStyle: style,
    ).css;

/// The two rules the wash is made of, for [ink] over `plain`'s
/// transparent resting fill.
List<String> _wash(CoreColor ink) {
  final tint = ink.withOpacity(1).toValue();
  final base = CoreColor.transparent.toValue();
  String rule(String pseudo, double weight) =>
      '#$_kScope:$pseudo{background-color:color-mix(in srgb, $tint '
      '${(weight * 100).round()}%, $base) !important;}';

  return [
    rule('hover', CoreOpacity.hover),
    rule('active', CoreOpacity.pressed),
  ];
}

void main() {
  group('Button instance stateLayer', () {
    testComponents('plain without a ramp emits no wash', (tester) async {
      final context = _themedContext(tester);

      expect(_rules(context, null), isNot(contains('color-mix')));
    });

    testComponents('the ramp washes the instance label colour', (
      tester,
    ) async {
      final context = _themedContext(tester);
      const ink = CoreColor.token(CoreColors.onInfo);
      final css = _rules(
        context,
        const CoreButtonStyle(
          foregroundColor: ink,
          hoverForegroundColor: ink,
          stateLayer: CoreStateLayer.subtle,
        ),
      );

      expect(css, contains('rgb(var(--coui-on-info)) 3%'));
      for (final rule in _wash(ink)) {
        expect(css, contains(rule));
      }
      // Pressed is written after hover — the cascade is what makes it win.
      expect(
        css.indexOf(':active{'),
        greaterThan(css.indexOf(':hover{background-color:color-mix')),
      );
    });

    testComponents('a fill override skips the wash', (tester) async {
      final context = _themedContext(tester);
      final css = _rules(
        context,
        const CoreButtonStyle(
          backgroundColor: CoreColor.token(CoreColors.surface),
          stateLayer: CoreStateLayer.subtle,
        ),
      );

      expect(css, isNot(contains('color-mix')));
    });
  });

  group('Banner and Toast actions show hover', () {
    for (final emphasis in CoreBannerEmphasis.values) {
      for (final variant in CoreBannerVariant.values) {
        testComponents('banner ${emphasis.name} ${variant.name}', (
          tester,
        ) async {
          final context = _themedContext(tester);
          final banner = resolveBanner(
            context,
            variant: variant,
            emphasis: emphasis,
          );

          for (final style in [
            banner.actionButtonStyle,
            banner.closeButtonStyle,
          ]) {
            expect(style.stateLayer, CoreStateLayer.subtle);
            final css = _rules(context, style);
            for (final rule in _wash(style.foregroundColor!)) {
              expect(css, contains(rule));
            }
          }
        });
      }
    }

    for (final variant in CoreToastVariant.values) {
      testComponents('toast ${variant.name} action', (tester) async {
        final context = _themedContext(tester);
        final style = resolveToast(
          context,
          variant: variant,
          dismissible: true,
        ).actionButtonStyle;

        expect(style.stateLayer, CoreStateLayer.subtle);
        final css = _rules(context, style);
        for (final rule in _wash(style.foregroundColor!)) {
          expect(css, contains(rule));
        }
      });
    }
  });
}
