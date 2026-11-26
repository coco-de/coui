import 'package:coui_flutter/coui_flutter.dart';

class HeroSectionAppearExample extends StatelessWidget {
  const HeroSectionAppearExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: Hero(
        appear: true,
        semanticLabel: 'CoUI 소개',
        heroStyle: const CoreHeroStyle(minHeight: 280),
        child: Column(
          mainAxisSize: .min,
          children: [
            Text('CoUI에 오신 것을 환영해요').titleLarge.semiBold.onSurface,
            const Gap.space12(),
            Text(
              'Flutter와 Jaspr를 위한 크로스 플랫폼 디자인 시스템이에요.',
              textAlign: .center,
            ).bodyMedium.onSurfaceVariant,
          ],
        ),
      ),
    );
  }
}
