import 'package:docs/pages/docs/components_page.dart';
import 'package:coui_flutter/coui_flutter.dart';

class WindowTile extends StatelessWidget implements IComponentPage {
  const WindowTile({super.key});

  @override
  String get title => 'Window';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ComponentCard(
      name: 'window',
      title: 'Window',
      example: Card(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.border),
            borderRadius: BorderRadius.circular(8),
          ),
          width: 320,
          height: 240,
          child: Column(
            children: [
              // Window title bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
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
                    // Window controls
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      width: 12,
                      height: 12,
                    ),
                    const Gap(6),
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.yellow,
                        shape: BoxShape.circle,
                      ),
                      width: 12,
                      height: 12,
                    ),
                    const Gap(6),
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      width: 12,
                      height: 12,
                    ),
                    const Gap(16),
                    const Text('Window Title').medium(),
                    const Spacer(),
                    const Icon(Icons.minimize, size: 16),
                    const Gap(8),
                    const Icon(Icons.crop_square, size: 16),
                    const Gap(8),
                    const Icon(Icons.close, size: 16),
                  ],
                ),
              ),
              // Window content
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: const Center(child: Text('Window Content Area')),
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
