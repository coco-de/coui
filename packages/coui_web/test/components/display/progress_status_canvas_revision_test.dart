// The values the designer changed after checking the canvas, read back from
// the Web resolvers: the `xl` ring's figure role and the round ends of the
// bar across a `busy` Status dot. (The `dots` wave and gap are read back in
// `loading_test.dart`.)
import 'package:coui_web/coui_web.dart';
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

void main() {
  testComponents('RadialProgress xl figure is the headlineLarge role', (
    tester,
  ) async {
    final context = _themedContext(tester);
    final resolved = resolveRadialProgress(
      context: context,
      size: CoreProgressSize.xl,
    );
    final classes = resolved.label!.className.split(' ');
    // A role class, so the typography tier variables step it down on a
    // phone — no size is written inline.
    expect(classes, contains('text-${CoreTextStyles.headlineLarge.name}'));
    expect(
      classes,
      isNot(contains('text-${CoreTextStyles.headlineSmall.name}')),
    );
    expect(
      resolved.label!.inlineStyles?.properties['font-size'],
      isNull,
    );
  });

  testComponents('Status busy bar has round ends', (tester) async {
    final context = _themedContext(tester);
    final resolved = resolveStatus(
      context,
      color: CoreStatusColor.neutral,
      size: CoreStatusSize.md,
      variant: CoreStatusVariant.busy,
    );
    expect(
      resolved.bar.inlineStyles?.properties['border-radius'],
      equals(CoreStatusStyle.defaultBarBorderRadius.toValue()),
    );
    expect(
      CoreStatusStyle.defaultBarBorderRadius,
      equals(const CoreBorderRadius.all(CoreRadius.radius9999)),
    );
  });

  testComponents('a stated bar radius reaches the bar', (tester) async {
    final context = _themedContext(tester);
    const stated = CoreBorderRadius.zero;
    final resolved = resolveStatus(
      context,
      color: CoreStatusColor.neutral,
      size: CoreStatusSize.md,
      variant: CoreStatusVariant.busy,
      statusStyle: const CoreStatusStyle(barBorderRadius: stated),
    );
    expect(
      resolved.bar.inlineStyles?.properties['border-radius'],
      equals(stated.toValue()),
    );
  });
}
