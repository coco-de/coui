import 'package:coui_web/coui_web.dart';

class NavigationBarItemChainExample extends StatelessComponent {
  const NavigationBarItemChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        NavigationBarItem(
          icon: const Icon(LucideIcons.inbox),
          label: '받은편지함',
          selected: true,
          onPressed: () {},
        ).withStyle(
          const CoreNavigationBarStyle(
            selectedBackgroundColor: CoreColor.token(
              CoreColors.primaryContainer,
            ),
            itemRadius: CoreBorderRadius.all(CoreRadiusRole.panel),
          ),
        ),
      ],
      classes: 'w-full max-w-${CoreLayout.scale.layout240}',
    );
  }
}
