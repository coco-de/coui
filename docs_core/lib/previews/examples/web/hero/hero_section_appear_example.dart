import 'package:coui_web/coui_web.dart';

class HeroSectionAppearExample extends StatelessComponent {
  const HeroSectionAppearExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        Hero(
          appear: true,
          semanticLabel: 'CoUI 소개',
          heroStyle: const CoreHeroStyle(minHeight: 280),
          child: div(
            [
              Text('CoUI에 오신 것을 환영해요').titleLarge.semiBold.onSurface,
              const Gap.space12(),
              Text(
                'Flutter와 Jaspr를 위한 크로스 플랫폼 디자인 시스템이에요.',
                textAlign: .center,
              ).bodyMedium.onSurfaceVariant,
            ],
            classes: 'flex flex-col items-center',
          ),
        ),
      ],
      classes: 'w-full',
      styles: const Styles(raw: {'height': '280px'}),
    );
  }
}
