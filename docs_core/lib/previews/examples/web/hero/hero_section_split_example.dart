import 'package:coui_web/coui_web.dart';

/// Split hero: copy leading, media trailing on a wide viewport.
class HeroSectionSplitExample extends StatelessComponent {
  /// Creates the split hero example.
  const HeroSectionSplitExample({super.key});

  @override
  Component build(BuildContext context) {
    final cs = context.theme.colorScheme;
    return div(
      [
        Hero(
          layout: CoreHeroLayout.split,
          heroStyle: const CoreHeroStyle(minHeight: 280),
          media: div(
            [Text('미디어')],
            classes:
                'flex items-center justify-center h-44 bg-${cs.surfaceContainerHigh} text-${CoreTextStyles.titleMedium.name} text-${cs.onSurface}',
          ),
          child: div(
            [
              div(
                [Text('제품을 출시해 보세요')],
                classes: 'text-${CoreTextStyles.headlineSmall.name} text-${cs.onSurface}',
              ),
              const Gap.space12(),
              div(
                [
                  Text(
                    '글은 앞쪽에 놓여요. 미디어는 넓은 화면에서는 뒤에, 좁은 화면에서는 아래에 쌓여요.',
                  ),
                ],
                classes: 'text-${CoreTextStyles.bodyMedium.name} text-${cs.onSurfaceVariant}',
              ),
            ],
            classes: 'flex flex-col items-start',
          ),
        ),
      ],
      classes: 'w-full',
      styles: const Styles(raw: {'height': '280px'}),
    );
  }
}
