import 'package:coui_web/coui_web.dart';

/// Demonstrates the `withStyle` chain — a quick way to override a
/// component's [CoreAppBarStyle] slot without constructing the component
/// from scratch — chained with the primitive-token `.surfaceContainer`
/// getter (a direct 1:1 alias for `CoreColors.surfaceContainer`), which
/// is shorter than a second `.withStyle(const CoreAppBarStyle(backgroundColor:
/// CoreColor.token(CoreColors.surfaceContainer)))` call.
class AppBarChainExample extends StatelessComponent {
  const AppBarChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return AppBar(
          leading: [
            Button(
              variant: CoreButtonVariant.plain,
              onPressed: () {},
              child: const Icon(LucideIcons.arrowLeft),
            ),
          ],
          title: const Text('대시보드'),
          trailing: [
            Button(
              variant: CoreButtonVariant.plain,
              onPressed: () {},
              child: const Icon(LucideIcons.settings),
            ),
          ],
        )
        .withStyle(
          const CoreAppBarStyle(
            dividerColor: CoreColor.token(CoreColors.outline),
            dividerWidth: CoreStrokeWidth.stroke2,
          ),
        )
        .surfaceContainer;
  }
}
