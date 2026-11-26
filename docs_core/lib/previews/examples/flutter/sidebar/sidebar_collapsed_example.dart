import 'package:coui_flutter/coui_flutter.dart';

class SidebarCollapsedExample extends StatelessWidget {
  const SidebarCollapsedExample({super.key});

  @override
  Widget build(BuildContext context) {
    // The rail alone — each destination named by its tooltip.
    return SizedBox(
      height: CoreLayout.layout400,
      child: Sidebar(
        type: CoreSidebarType.collapsed,
        railHeader: const Avatar(initials: 'C'),
        railItems: [
          SidebarRailItem(
            icon: const Icon(LucideIcons.house),
            label: '홈',
            selected: true,
            onPressed: () {},
          ),
          SidebarRailItem(
            icon: const Icon(LucideIcons.inbox),
            label: '받은 편지함',
            dot: true,
            onPressed: () {},
          ),
          SidebarRailItem(
            icon: const Icon(LucideIcons.calendar),
            label: '일정',
            onPressed: () {},
          ),
        ],
        railFooter: SidebarRailItem(
          icon: const Icon(LucideIcons.settings),
          label: '설정',
          onPressed: () {},
        ),
      ),
    );
  }
}
