import 'package:coui_flutter/coui_flutter.dart';

class HeroSectionDefaultExample extends StatelessWidget {
  const HeroSectionDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 280,
      child: Hero(
        heroStyle: const CoreHeroStyle(minHeight: 280),
        child: Column(
          mainAxisSize: .min,
          children: [
            Text(
              'CoUI에 오신 것을 환영해요',
              style: theme.typography.titleLarge
                  .toValue(theme: theme)
                  .copyWith(
                    color: theme.colorScheme.onSurface.toValue(),
                    fontWeight: FontWeight.values.firstWhere(
                      (w) => w.value == CoreFontWeight.semiBold,
                      orElse: () => .w600,
                    ),
                  ),
            ),
            const Gap.space12(),
            Text(
              'Flutter와 Jaspr를 위한 크로스 플랫폼 디자인 시스템이에요.',
              textAlign: .center,
              style: theme.typography.bodyMedium
                  .toValue(theme: theme)
                  .copyWith(
                    color: theme.colorScheme.onSurfaceVariant.toValue(),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
