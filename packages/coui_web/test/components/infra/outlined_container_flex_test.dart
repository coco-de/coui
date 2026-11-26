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
  testComponents('visible overflow retains flex shrink safety', (tester) async {
    late BuildContext context;
    pumpWithTheme(tester, _ContextCapture((value) => context = value));
    for (final behavior in CoreClipBehavior.values) {
      final result = resolveOutlinedContainer(
        context: context,
        containerStyle: CoreOutlinedContainerStyle(clipBehavior: behavior),
      );
      expect(result.root.inlineStyles!.properties['min-width'], '0');
      expect(
        result.root.inlineStyles!.properties['overflow'],
        behavior == CoreClipBehavior.none ? 'visible' : 'hidden',
      );
    }
  });

  testComponents('caller may still override the minimum', (tester) async {
    pumpWithTheme(
      tester,
      const OutlinedContainer(
        id: 'explicit-minimum',
        css: Styles(raw: {'min-width': '96px'}),
      ),
    );
    await tester.pump();
    final box = find
        .tag('div')
        .evaluate()
        .map((node) => node.component)
        .whereType<DomComponent>()
        .singleWhere((node) => node.id == 'explicit-minimum');
    expect(box.styles!.properties['min-width'], '96px');
  });
}
