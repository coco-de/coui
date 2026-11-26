import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// `CoreButtonStyle.castHideDuration` / `CoreChipStyle.castHideDuration`
/// (#4407) is a per-instance Core Style field, so it has to reach Web the
/// same way every other override does — `check_web_resolver.sh` RULE E
/// enforces this generically, and this file pins the specific mechanism:
/// the resolver publishes [kControlEngageDurationVar] inline, and
/// `ThemeConfig._controlShadowPressRule` reads it back with the token
/// default as fallback (`control_press_reduced_motion_test.dart` pins
/// that half). Neither half alone proves the override reaches the
/// rendered pixel — this file is the resolver-publishing half.
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

void main() {
  group('Button publishes the engage-duration override (#4407)', () {
    testComponents(
      'the default (no override) resolves to the 50ms token',
      (tester) async {
        final resolved = resolveButton(
          _themedContext(tester),
          variant: CoreButtonVariant.primary,
          size: CoreComponentSize.md,
          shape: CoreButtonShape.rectangle,
          expanded: false,
        );
        final raw = resolved.root.inlineStyles?.properties ?? const {};

        expect(
          raw[kControlEngageDurationVar],
          equals(durationMsCss(CoreDuration.ms50)),
          reason:
              'no per-instance override means the published clock should '
              'be exactly CoreButtonStyle.defaultCastHideDuration, '
              'token-routed',
        );
      },
    );

    testComponents(
      'a per-instance castHideDuration override changes the published '
      'clock',
      (tester) async {
        final resolved = resolveButton(
          _themedContext(tester),
          variant: CoreButtonVariant.primary,
          size: CoreComponentSize.md,
          shape: CoreButtonShape.rectangle,
          expanded: false,
          buttonStyle: const CoreButtonStyle(
            castHideDuration: Duration(milliseconds: CoreDuration.ms200),
          ),
        );
        final raw = resolved.root.inlineStyles?.properties ?? const {};

        expect(
          raw[kControlEngageDurationVar],
          equals(durationMsCss(CoreDuration.ms200)),
          reason:
              'CoreButtonStyle.castHideDuration must reach the inline '
              'bundle — this is the Web half of the field '
              '`check_web_resolver.sh` RULE E requires (Flutter already '
              "reflects it via resolveButton's castHideDuration)",
        );
      },
    );

    testComponents(
      'an arbitrary transition override follows the reduced-motion factor',
      (tester) async {
        final resolved = resolveButton(
          _themedContext(tester),
          variant: CoreButtonVariant.primary,
          size: CoreComponentSize.md,
          shape: CoreButtonShape.rectangle,
          expanded: false,
          buttonStyle: const CoreButtonStyle(
            castHideDuration: Duration(milliseconds: 37),
          ),
        );
        final raw = resolved.root.inlineStyles?.properties ?? const {};

        expect(raw[kControlEngageDurationVar], equals(durationMsCss(37)));
      },
    );
  });

  group('Chip publishes the engage-duration override (#4407)', () {
    testComponents(
      'the default (no override) resolves to the 50ms token',
      (tester) async {
        final resolved = resolveChip(
          _themedContext(tester),
          variant: CoreChipVariant.outlined,
          chipColor: CoreChipColor.defaultColor,
          size: CoreChipSize.md,
          selected: false,
          emphasis: .defaultEmphasis,
          enabled: true,
        );
        final raw = resolved.root.inlineStyles?.properties ?? const {};

        expect(
          raw[kControlEngageDurationVar],
          equals(durationMsCss(CoreDuration.ms50)),
        );
      },
    );

    testComponents(
      'a per-instance castHideDuration override changes the published '
      'clock',
      (tester) async {
        final resolved = resolveChip(
          _themedContext(tester),
          variant: CoreChipVariant.outlined,
          chipColor: CoreChipColor.defaultColor,
          size: CoreChipSize.md,
          selected: false,
          emphasis: .defaultEmphasis,
          enabled: true,
          chipStyle: const CoreChipStyle(
            castHideDuration: Duration(milliseconds: CoreDuration.ms200),
          ),
        );
        final raw = resolved.root.inlineStyles?.properties ?? const {};

        expect(
          raw[kControlEngageDurationVar],
          equals(durationMsCss(CoreDuration.ms200)),
        );
      },
    );

    testComponents(
      'a disabled chip publishes neither the chrome nor the engage clock '
      'variable — it states its own literal transition instead',
      (tester) async {
        final resolved = resolveChip(
          _themedContext(tester),
          variant: CoreChipVariant.outlined,
          chipColor: CoreChipColor.defaultColor,
          size: CoreChipSize.md,
          selected: false,
          emphasis: .defaultEmphasis,
          enabled: false,
        );
        final raw = resolved.root.inlineStyles?.properties ?? const {};

        expect(raw.keys, isNot(contains(kControlEngageDurationVar)));
      },
    );
  });
}
