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

void main() {
  for (final (ms, duration) in [
    (137, 'calc(137ms * var(--coui-transition-motion-factor, 1))'),
    (150, 'var(--coui-duration-150)'),
    (730, '730ms'),
  ]) {
    testComponents('duration $ms uses the shared motion policy', (
      tester,
    ) async {
      late BuildContext context;
      pumpWithTheme(tester, _ContextCapture((value) => context = value));
      final result = resolveOutlinedContainer(
        context: context,
        containerStyle: CoreOutlinedContainerStyle(
          duration: Duration(milliseconds: ms),
        ),
      );
      final transition = result.root.inlineStyles!.properties['transition'];
      expect(transition, contains('background-color $duration '));
      expect(transition, contains('border-width $duration '));
    });
  }
}
