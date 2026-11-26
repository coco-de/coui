import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';
import '../../helpers/surface_fold.dart';

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
  testComponents('omitted and uniform padding retain existing output', (
    tester,
  ) async {
    late BuildContext context;
    pumpWithTheme(tester, _ContextCapture((value) => context = value));
    final normal = resolveOutlinedContainer(context: context);
    final uniform = resolveOutlinedContainer(
      context: context,
      containerStyle: const CoreOutlinedContainerStyle(
        padding: CoreEdgeInsets.all(8),
      ),
    );
    expect(
      normal.root.inlineStyles!.properties.containsKey('padding'),
      isFalse,
    );
    expect(
      unfoldSurfaceEdge(uniform.root.inlineStyles!.properties['padding']!),
      'var(--coui-space-8)',
    );
  });

  testComponents('physical padding preserves every side', (tester) async {
    late BuildContext context;
    pumpWithTheme(tester, _ContextCapture((value) => context = value));
    final result = resolveOutlinedContainer(
      context: context,
      containerStyle: const CoreOutlinedContainerStyle(
        padding: CoreEdgeInsets.fromLTRB(4, 8, 16, 24),
      ),
    );
    expect(
      unfoldSurfaceEdge(result.root.inlineStyles!.properties['padding']!),
      'var(--coui-space-8) var(--coui-space-16) '
      'var(--coui-space-24) var(--coui-space-4)',
    );
  });

  testComponents('directional padding uses logical CSS sides', (tester) async {
    late BuildContext context;
    pumpWithTheme(tester, _ContextCapture((value) => context = value));
    final result = resolveOutlinedContainer(
      context: context,
      containerStyle: const CoreOutlinedContainerStyle(
        padding: CoreEdgeInsets.directional(
          start: 4,
          top: 8,
          end: 16,
          bottom: 24,
        ),
      ),
    );
    final props = result.root.inlineStyles!.properties;
    expect(
      unfoldSurfaceEdge(props['padding-inline-start']!),
      'var(--coui-space-4)',
    );
    expect(
      unfoldSurfaceEdge(props['padding-inline-end']!),
      'var(--coui-space-16)',
    );
    expect(
      unfoldSurfaceEdge(props['padding-block-start']!),
      'var(--coui-space-8)',
    );
    expect(
      unfoldSurfaceEdge(props['padding-block-end']!),
      'var(--coui-space-24)',
    );
    expect(props.containsKey('padding'), isFalse);
  });
}
