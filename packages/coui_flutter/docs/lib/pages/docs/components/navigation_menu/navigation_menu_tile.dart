import 'package:docs/pages/docs/components_page.dart';
import 'package:coui_flutter/coui_flutter.dart';

class NavigationMenuTile extends StatelessWidget implements IComponentPage {
  const NavigationMenuTile({super.key});

  @override
  String get title => 'Navigation Menu';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ComponentCard(
      name: 'navigation_menu',
      title: 'Navigation Menu',
      example: Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NavigationMenu(
              children: [
                Button(
                  style: const ButtonStyle.ghost().copyWith(
                    decoration: (context, states, value) {
                      return (value as BoxDecoration).copyWith(
                        color: theme.colorScheme.muted.scaleAlpha(0.8),
                        borderRadius: BorderRadius.circular(theme.radiusMd),
                      );
                    },
                  ),
                  trailing: const Icon(RadixIcons.chevronUp, size: 12),
                  onPressed: () {
                    // TODOS: will be implemented later.
                  },
                  child: const Text('Getting Started'),
                ),
                const NavigationMenuItem(
                  content: SizedBox(),
                  child: Text('Components'),
                ),
              ],
            ),
            const Gap(8),
            OutlinedContainer(
              borderRadius: theme.borderRadiusMd,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: NavigationMenuContentList(
                  children: [
                    Button(
                      style: ButtonVariance.ghost.copyWith(
                        decoration: (context, states, value) {
                          return (value as BoxDecoration).copyWith(
                            color: theme.colorScheme.muted.scaleAlpha(0.8),
                            borderRadius: BorderRadius.circular(theme.radiusMd),
                          );
                        },
                        padding: (context, states, value) {
                          return const EdgeInsets.all(12);
                        },
                      ),
                      onPressed: () {
                        // TODOS: will be implemented later.
                      },
                      alignment: Alignment.topLeft,
                      child: Basic(
                        content: const Text(
                          'How to install Coui/UI for Flutter',
                        ).muted(),
                        mainAxisAlignment: MainAxisAlignment.start,
                        title: const Text('Installation').medium(),
                      ),
                    ).constrained(maxWidth: 16 * 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      scale: 1,
    );
  }
}
