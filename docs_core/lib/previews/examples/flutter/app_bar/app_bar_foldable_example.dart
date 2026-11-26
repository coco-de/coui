import 'package:coui_flutter/coui_flutter.dart';

/// Toggle the preview variant between a phone bar and a Duo control rail.
class AppBarFoldableExample extends StatelessWidget {
  const AppBarFoldableExample({this.controlRail = true, super.key});
  final bool controlRail;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 384,
    child: Scaffold(
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
            Semantics(
              label: '이전',
              child: Button(
                variant: .ghost,
                shape: .square,
                onPressed: () {},
                child: const Icon(LucideIcons.chevronLeft),
              ),
            ),
          ],
          trailing: [
            Semantics(
              label: '공유',
              child: Button(variant: .ghost, shape: .square, onPressed: () {}, child: const Icon(LucideIcons.share)),
            ),
            BarAction(
              axisBehavior: .horizontalOnly,
              child: Button(variant: .ghost, onPressed: () {}, child: const Text('편집')),
            ),
          ],
        ),
      ],
      child: const Center(child: Text('본문 · 아이콘은 우측 레일')),
    ),
  );
}
