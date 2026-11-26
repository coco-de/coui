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
  for (final color in [
    const CoreColor(0xFFFF0000),
    const CoreColor(0xFF00FF00),
    const CoreColor(0xFF000000),
    const CoreColor(0xFF0000FF),
    const CoreColor(0x80123400),
    const CoreColor(0x00123456),
  ]) {
    for (final style in CoreOutlinedContainerBorderStyle.values) {
      testComponents('ARGB ${color.argb} $style preserves opaque width', (
        tester,
      ) async {
        final resolved = resolveOutlinedContainer(
          context: _themedContext(tester),
          containerStyle: CoreOutlinedContainerStyle(
            borderColor: color,
            borderWidth: 2,
            borderStyle: style,
          ),
        );
        final patterned =
            style == CoreOutlinedContainerBorderStyle.dashed ||
            style == CoreOutlinedContainerBorderStyle.dotted;
        final properties = patterned
            ? resolved.dashRect!.inlineStyles!.properties
            : resolved.root.inlineStyles!.properties;
        final width =
            color.argb >>> 24 == 0 ||
                style == CoreOutlinedContainerBorderStyle.none
            ? 0
            : 2;
        expect(
          properties[patterned ? 'stroke-width' : 'border-width'],
          'var(--coui-stroke-width-$width)',
        );
      });
    }
  }
}
