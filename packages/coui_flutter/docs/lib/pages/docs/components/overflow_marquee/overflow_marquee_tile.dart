import 'package:docs/pages/docs/components_page.dart';
import 'package:coui_flutter/coui_flutter.dart';

class OverflowMarqueeTile extends StatelessWidget implements IComponentPage {
  const OverflowMarqueeTile({super.key});

  @override
  String get title => 'Overflow Marquee';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ComponentCard(
      name: 'overflow_marquee',
      title: 'Overflow Marquee',
      example: Card(
        child: Container(
          padding: const EdgeInsets.all(16),
          width: 250,
          height: 120,
          child: Column(
            children: [
              const Text('Scrolling Text:').bold(),
              const Gap(16),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.muted,
                  borderRadius: BorderRadius.circular(8),
                ),
                width: 200,
                height: 40,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        width: double.infinity,
                        child: const Center(
                          child: Text(
                            'This is a very long text that will scroll horizontally when it overflows the container width',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      // Simulate scrolling effect with positioned text
                      const Positioned(
                        left: -100,
                        top: 12,
                        child: Text(
                          'This is a very long text that will scroll...',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(8),
              const Text('Auto-scrolling overflow text').muted(),
            ],
          ),
        ),
      ),
      scale: 1.2,
    );
  }
}
