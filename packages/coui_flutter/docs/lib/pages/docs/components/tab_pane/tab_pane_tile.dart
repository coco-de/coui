import 'package:docs/pages/docs/components_page.dart';
import 'package:coui_flutter/coui_flutter.dart';

class TabPaneTile extends StatelessWidget implements IComponentPage {
  const TabPaneTile({super.key});

  @override
  String get title => 'Tab Pane';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ComponentCard(
      name: 'tab_pane',
      title: 'Tab Pane',
      example: Card(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.border),
            borderRadius: BorderRadius.circular(8),
          ),
          width: 300,
          height: 200,
          child: Column(
            children: [
              // Tab headers
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.muted,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                height: 40,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Tab 1',
                        style: TextStyle(
                          color: theme.colorScheme.primaryForeground,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Gap(4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      child: const Text(
                        'Tab 2',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    const Gap(4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      child: const Text(
                        'Tab 3',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              // Tab content
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: const Center(child: Text('Tab 1 Content')),
                ),
              ),
            ],
          ),
        ),
      ),
      scale: 1.2,
    );
  }
}
