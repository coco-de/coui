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
  for (final style in CoreOutlinedContainerBorderStyle.values) {
    for (final width in [0.0, 2.0]) {
      testComponents('$style preserves CSS/SVG width $width', (tester) async {
        final resolved = resolveOutlinedContainer(
          context: _themedContext(tester),
          containerStyle: CoreOutlinedContainerStyle(
            borderColor: const CoreColor(0xFF123456),
            borderWidth: width,
            borderStyle: style,
          ),
        );
        final patterned =
            style == CoreOutlinedContainerBorderStyle.dashed ||
            style == CoreOutlinedContainerBorderStyle.dotted;
        final properties = patterned
            ? resolved.dashRect!.inlineStyles!.properties
            : resolved.root.inlineStyles!.properties;
        final effectiveWidth = style == CoreOutlinedContainerBorderStyle.none
            ? 0
            : width.toInt();
        expect(
          properties[patterned ? 'stroke-width' : 'border-width'],
          'var(--coui-stroke-width-$effectiveWidth)',
        );
      });
    }
  }
}
