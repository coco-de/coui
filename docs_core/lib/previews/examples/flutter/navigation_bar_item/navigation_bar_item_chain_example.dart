import 'package:coui_flutter/coui_flutter.dart';

class NavigationBarItemChainExample extends StatelessWidget {
  const NavigationBarItemChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: CoreLayout.layout240),
      child:
          NavigationBarItem(
            icon: const Icon(LucideIcons.inbox),
            label: '받은편지함',
            selected: true,
            onPressed: () {},
          ).withStyle(
            const CoreNavigationBarStyle(
              selectedBackgroundColor: CoreColor.token(CoreColors.primaryContainer),
              itemRadius: CoreBorderRadius.all(CoreRadiusRole.panel),
            ),
          ),
    );
  }
}
