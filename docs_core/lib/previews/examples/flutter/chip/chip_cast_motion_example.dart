import 'package:coui_flutter/coui_flutter.dart';

class ChipCastMotionExample extends StatefulWidget {
  const ChipCastMotionExample({super.key});

  @override
  State<ChipCastMotionExample> createState() => _ChipCastMotionExampleState();
}

class _ChipCastMotionExampleState extends State<ChipCastMotionExample> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
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
    );
  }
}
