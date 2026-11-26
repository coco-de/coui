import 'package:coui_web/coui_web.dart';

/// Toggle the preview variant between a phone bar and a Duo control rail.
class AppBarFoldableExample extends StatelessComponent {
  const AppBarFoldableExample({this.controlRail = true, super.key});
  final bool controlRail;

  @override
  Component build(BuildContext context) => div(styles: const Styles(raw: {'height': '384px'}), [
    Scaffold(
      adaptiveAppBarActions: true,
      // A device preview supplies physical safe-area geometry. Apps omit it.
      appBarControlInsets: controlRail ? const CoreEdgeInsets.only(right: 84, bottom: 34) : CoreEdgeInsets.zero,
      scaffoldStyle: const CoreScaffoldStyle(headerBorderWidth: 0),
      headers: [
        AppBar(
          centerTitle: true,
          showDivider: false,
          appBarStyle: const CoreAppBarStyle(surfaceStyle: .liquidGlass),
          title: const Text('보관함'),
          leading: [
            Button(
              variant: .ghost,
              shape: .square,
              attributes: const {'aria-label': '이전'},
              onPressed: () {},
              child: const Icon(LucideIcons.chevronLeft),
            ),
          ],
          trailing: [
            Button(
              variant: .ghost,
              shape: .square,
              attributes: const {'aria-label': '공유'},
              onPressed: () {},
              child: const Icon(LucideIcons.share),
            ),
            BarAction(
              axisBehavior: .horizontalOnly,
              child: Button(variant: .ghost, onPressed: () {}, child: const Text('편집')),
            ),
          ],
        ),
      ],
      child: const Text('본문 · 아이콘은 우측 레일'),
    ),
  ]);
}
