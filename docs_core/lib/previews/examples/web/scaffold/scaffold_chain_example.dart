import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreScaffoldStyle] slot without constructing the widget
/// from scratch — chained with the primitive-token `.surfaceContainer`
/// getter (a direct 1:1 alias for `CoreColors.surfaceContainer`), which
/// is shorter than a second `.withStyle(const CoreScaffoldStyle(backgroundColor:
/// CoreColor.token(CoreColors.surfaceContainer)))` call.
class ScaffoldChainExample extends StatelessComponent {
  const ScaffoldChainExample({super.key});

  @override
  Component build(BuildContext context) {
    // Fixed-height frame (matches the Flutter preview canvas height)
    // so the scaffold's `min-h-full` has a definite parent to fill —
    // the Flutter twin fills its canvas constraints the same way.
    return div(
      [
        Scaffold(
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
              // `flex-1` fills the scaffold's body column (Flutter
              // `Center` fills the available body the same way).
              child: div(
                [const Text('본문 영역')],
                classes: 'flex items-center justify-center flex-1',
              ),
            )
            .withStyle(
              const CoreScaffoldStyle(
                headerBorderColor: CoreColor.token(CoreColors.outline),
                headerBorderWidth: CoreStrokeWidth.stroke2,
              ),
            )
            .surfaceContainer,
      ],
      classes: 'w-full',
      styles: Styles(raw: const {'height': '${400 / 16}rem'}),
    );
  }
}
