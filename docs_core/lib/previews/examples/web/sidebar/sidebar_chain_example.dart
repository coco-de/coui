import 'package:coui_web/coui_web.dart';

class SidebarChainExample extends StatelessComponent {
  const SidebarChainExample({super.key});

  @override
  Component build(BuildContext context) {
    // withStyle full-control — a narrower panel on the page's own face.
    return div(classes: 'h-${CoreLayout.scale.layout400}', [
      Sidebar(
        children: [
          SidebarItem(
            leading: Icon(LucideIcons.house),
            label: Text('홈'),
            selected: true,
            onPressed: () {},
          ),
          SidebarItem(
            leading: Icon(LucideIcons.inbox),
            label: Text('받은 편지함'),
            onPressed: () {},
          ),
        ],
      ).withStyle(
        const CoreSidebarStyle(
          panelWidth: CoreLayout.layout240,
          backgroundColor: CoreColor.token(CoreColors.surface),
        ),
      ),
    ]);
  }
}
