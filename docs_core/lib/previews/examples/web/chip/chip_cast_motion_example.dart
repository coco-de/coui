import 'package:coui_web/coui_web.dart';

class ChipCastMotionExample extends StatefulComponent {
  const ChipCastMotionExample({super.key});

  @override
  State<ChipCastMotionExample> createState() => _ChipCastMotionExampleState();
}

class _ChipCastMotionExampleState extends State<ChipCastMotionExample> {
  @override
  Component build(BuildContext context) {
    return div(
      [
        Chip(
          label: '기본',
          chipStyle: const CoreChipStyle(
            castMotion: CoreCastMotion.defaultMotion,
          ),
          onTap: () {},
        ),
        const Gap.space12(),
        Chip(
          label: '그림자 없음',
          chipStyle: const CoreChipStyle(castMotion: CoreCastMotion.noShadow),
          onTap: () {},
        ),
        const Gap.space12(),
        Chip(
          label: '반대로',
          chipStyle: const CoreChipStyle(castMotion: CoreCastMotion.reverse),
          onTap: () {},
        ),
      ],
      classes: 'flex flex-row items-center',
    );
  }
}
