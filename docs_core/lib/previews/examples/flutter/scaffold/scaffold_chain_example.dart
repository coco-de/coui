import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreScaffoldStyle] slot without constructing the widget
/// from scratch — chained with the primitive-token `.surfaceContainer`
/// getter (a direct 1:1 alias for `CoreColors.surfaceContainer`), which
/// is shorter than a second `.withStyle(const CoreScaffoldStyle(backgroundColor:
/// CoreColor.token(CoreColors.surfaceContainer)))` call.
class ScaffoldChainExample extends StatelessWidget {
  const ScaffoldChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
          headers: [
            AppBar(
              title: const Text('대시보드').titleMedium,
              trailing: const [Icon(LucideIcons.settings)],
            ),
          ],
          footers: [
            AppBar(
              title: const Text('준비됨').bodySmall.onSurfaceVariant,
            ),
          ],
          child: const Center(child: Text('본문 영역')),
        )
        .withStyle(
          const CoreScaffoldStyle(
            headerBorderColor: CoreColor.token(CoreColors.outline),
            headerBorderWidth: CoreStrokeWidth.stroke2,
          ),
        )
        .surfaceContainer;
  }
}
