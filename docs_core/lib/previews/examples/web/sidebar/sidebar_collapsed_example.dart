import 'package:coui_web/coui_web.dart';

class SidebarCollapsedExample extends StatelessComponent {
  const SidebarCollapsedExample({super.key});

  @override
  Component build(BuildContext context) {
    // The rail alone — each destination named by its tooltip.
    return div(classes: 'h-${CoreLayout.scale.layout400}', [
      Sidebar(
        type: CoreSidebarType.collapsed,
        railHeader: Avatar(initials: 'C'),
        railItems: [
          SidebarRailItem(
            icon: Icon(LucideIcons.house),
            label: '홈',
            selected: true,
            onPressed: () {},
          ),
          SidebarRailItem(
            icon: Icon(LucideIcons.inbox),
            label: '받은 편지함',
            dot: true,
            onPressed: () {},
          ),
          SidebarRailItem(
            icon: Icon(LucideIcons.calendar),
            label: '일정',
            onPressed: () {},
          ),
        ],
        railFooter: SidebarRailItem(
          icon: Icon(LucideIcons.settings),
          label: '설정',
          onPressed: () {},
        ),
      ),
    ]);
  }
}
