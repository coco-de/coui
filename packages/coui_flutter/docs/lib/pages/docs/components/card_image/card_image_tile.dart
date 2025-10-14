import 'package:docs/pages/docs/components_page.dart';
import 'package:coui_flutter/coui_flutter.dart';

class CardImageTile extends StatelessWidget implements IComponentPage {
  const CardImageTile({super.key});

  @override
  String get title => 'Card Image';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ComponentCard(
      name: 'card_image',
      title: 'Card Image',
      example: Card(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.border),
            borderRadius: BorderRadius.circular(8),
          ),
          width: 280,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.muted,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                height: 160,
                child: Center(
                  child: Icon(
                    Icons.image,
                    size: 48,
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Card Title').bold().large(),
                    const Gap(8),
                    const Text(
                      'This is a description of the card content. It provides additional information about the image above.',
                    ).muted(),
                    const Gap(16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlineButton(
                            child: const Text('Cancel'),
                            onPressed: () {
                              // TODOS: will be implemented later.
                            },
                          ),
                        ),
                        const Gap(8),
                        Expanded(
                          child: PrimaryButton(
                            child: const Text('Action'),
                            onPressed: () {
                              // TODOS: will be implemented later.
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
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
