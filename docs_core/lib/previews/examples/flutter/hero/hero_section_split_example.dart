import 'package:coui_flutter/coui_flutter.dart';

/// Split hero: copy leading, media trailing on a wide viewport.
class HeroSectionSplitExample extends StatelessWidget {
  /// Creates the split hero example.
  const HeroSectionSplitExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 280,
      child: Hero(
        layout: CoreHeroLayout.split,
        heroStyle: CoreHeroStyle(minHeight: 280),
        media: _HeroExampleMedia(),
        child: _HeroExampleCopy(),
      ),
    );
  }
}

class _HeroExampleCopy extends StatelessWidget {
  const _HeroExampleCopy();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('제품을 출시해 보세요').headlineSmall.onSurface,
        const Gap(gapStyle: CoreGapStyle(size: CoreSpace.space12)),
        Text(
          '글은 앞쪽에 놓여요. 미디어는 넓은 화면에서는 뒤에, 좁은 화면에서는 아래에 쌓여요.',
        ).bodyMedium.onSurfaceVariant,
      ],
    );
  }
}

class _HeroExampleMedia extends StatelessWidget {
  const _HeroExampleMedia();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 180,
      child: ColoredBox(
        color: theme.colorScheme.surfaceContainerHigh.toValue(),
        child: Center(child: Text('미디어').titleMedium.onSurface),
      ),
    );
  }
}
