import 'package:coui_flutter/coui_flutter.dart';

class SidebarChainExample extends StatelessWidget {
  const SidebarChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    // withStyle full-control — a narrower panel on the page's own face.
    return SizedBox(
      height: CoreLayout.layout400,
      child:
          Sidebar(
            children: [
              SidebarItem(
                leading: const Icon(LucideIcons.house),
                label: const Text('홈'),
                selected: true,
                onPressed: () {},
              ),
              SidebarItem(
                leading: const Icon(LucideIcons.inbox),
                label: const Text('받은 편지함'),
                onPressed: () {},
              ),
            ],
          ).withStyle(
            const CoreSidebarStyle(
              panelWidth: CoreLayout.layout240,
              backgroundColor: CoreColor.token(CoreColors.surface),
            ),
          ),
    );
  }
}
