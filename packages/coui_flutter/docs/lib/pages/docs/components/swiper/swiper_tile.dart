import 'package:docs/pages/docs/components_page.dart';
// ignore_for_file: deprecated_member_use
import 'package:coui_flutter/coui_flutter.dart';

class SwiperTile extends StatelessWidget implements IComponentPage {
  const SwiperTile({super.key});

  @override
  String get title => 'Swiper';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ComponentCard(
      name: 'swiper',
      title: 'Swiper',
      example: Card(
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
          width: 300,
          height: 200,
          child: Stack(
            children: [
              // Swiper content
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'Slide 1',
                    style: TextStyle(
                      color: theme.colorScheme.primaryForeground,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Navigation arrows
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.background.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    width: 32,
                    height: 32,
                    child: const Icon(Icons.chevron_left, size: 20),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 8,
                bottom: 0,
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.background.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    width: 32,
                    height: 32,
                    child: const Icon(Icons.chevron_right, size: 20),
                  ),
                ),
              ),
              // Dots indicator
              Positioned(
                left: 0,
                right: 0,
                bottom: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryForeground,
                        shape: BoxShape.circle,
                      ),
                      width: 8,
                      height: 8,
                    ),
                    const Gap(4),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryForeground.withOpacity(
                          0.5,
                        ),
                        shape: BoxShape.circle,
                      ),
                      width: 8,
                      height: 8,
                    ),
                    const Gap(4),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryForeground.withOpacity(
                          0.5,
                        ),
                        shape: BoxShape.circle,
                      ),
                      width: 8,
                      height: 8,
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
