import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);
  final void Function(BuildContext) onBuild;
  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

void main() {
  for (final preserve in [false, true]) {
    testComponents(
      'zero token alpha preserves only when requested: $preserve',
      (tester) async {
        late BuildContext context;
        pumpWithTheme(tester, _ContextCapture((value) => context = value));
        final result = resolveOutlinedContainer(
          context: context,
          containerStyle: CoreOutlinedContainerStyle(
            borderColor: const CoreColor.token(CoreColors.primary, opacity: 0),
            borderWidth: 2,
            preserveTransparentBorder: preserve,
          ),
        );
        expect(
          result.root.inlineStyles!.properties['border-width'],
          'var(--coui-stroke-width-${preserve ? 2 : 0})',
        );
      },
    );
  }
  for (final (opacity, expectedWidth) in [(0.0, 0), (0.5, 2), (1.0, 2)]) {
    testComponents('token opacity $opacity resolves width $expectedWidth', (
      tester,
    ) async {
      late BuildContext context;
      pumpWithTheme(tester, _ContextCapture((value) => context = value));
      final result = resolveOutlinedContainer(
        context: context,
        containerStyle: CoreOutlinedContainerStyle(
          borderColor: CoreColor.token(CoreColors.primary, opacity: opacity),
          borderWidth: 2,
        ),
      );
      expect(
        result.root.inlineStyles!.properties['border-width'],
        'var(--coui-stroke-width-$expectedWidth)',
      );
    });
  }
}
