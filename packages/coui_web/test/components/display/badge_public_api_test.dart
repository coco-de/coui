import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

class _Capture extends StatelessComponent {
  const _Capture(this.onBuild);

  final void Function(BuildContext) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

void main() {
  testComponents('public Badge resolvers expose chrome and interactive rules', (
    tester,
  ) async {
    late BuildContext context;
    pumpWithTheme(tester, _Capture((value) => context = value));

    final badge = resolveBadge(
      context,
      tone: CoreBadgeTone.defaultTone,
      variant: CoreBadgeVariant.defaultVariant,
      form: CoreBadgeForm.defaultForm,
      size: CoreBadgeContract.defaultSize,
      interactive: true,
    );
    final rules = resolveBadgeRules(
      context,
      scopeId: 'public-badge',
      tone: CoreBadgeTone.defaultTone,
      variant: CoreBadgeVariant.defaultVariant,
      form: CoreBadgeForm.defaultForm,
      size: CoreBadgeContract.defaultSize,
      interactive: true,
    );

    expect(badge, isA<ResolvedBadge>());
    expect(rules, isA<ResolvedBadgeRules>());
    expect(badge.root.className, isNotEmpty);
    expect(rules.css, contains('public-badge'));
  });
}
