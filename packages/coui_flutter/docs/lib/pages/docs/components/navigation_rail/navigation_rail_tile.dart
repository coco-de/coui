import 'package:docs/pages/docs/components_page.dart';
import 'package:coui_flutter/coui_flutter.dart';

class NavigationRailTile extends StatelessWidget implements IComponentPage {
  const NavigationRailTile({super.key});

  @override
  String get title => 'Navigation Rail';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ComponentCard(
      name: 'navigation_rail',
      title: 'Navigation Rail',
      example: Card(
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.muted,
            borderRadius: BorderRadius.circular(8),
          ),
          width: 80,
          height: 300,
          child: Column(
            children: [
              const Gap(16),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                width: 40,
                height: 40,
                child: Icon(
                  Icons.home,
                  color: theme.colorScheme.primaryForeground,
                ),
              ),
              const Gap(16),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                width: 40,
                height: 40,
                child: const Icon(Icons.search),
              ),
              const Gap(16),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                width: 40,
                height: 40,
                child: const Icon(Icons.favorite),
              ),
              const Gap(16),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                width: 40,
                height: 40,
                child: const Icon(Icons.settings),
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                ),
                width: 40,
                height: 40,
                child: const Icon(Icons.person),
              ),
              const Gap(16),
            ],
          ),
        ),
      ),
      scale: 1.2,
    );
  }
}
