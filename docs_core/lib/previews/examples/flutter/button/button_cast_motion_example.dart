import 'package:coui_flutter/coui_flutter.dart';

class ButtonCastMotionExample extends StatefulWidget {
  const ButtonCastMotionExample({super.key});

  @override
  State<ButtonCastMotionExample> createState() => _ButtonCastMotionExampleState();
}

class _ButtonCastMotionExampleState extends State<ButtonCastMotionExample> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Button(
          variant: CoreButtonVariant.primary,
          buttonStyle: const CoreButtonStyle(
            castMotion: CoreCastMotion.defaultMotion,
          ),
          onPressed: () {},
          child: Text('기본').lineLimit(1).ellipsis,
        ),
        const Gap.space12(),
        Button(
          variant: CoreButtonVariant.primary,
          buttonStyle: const CoreButtonStyle(
            castMotion: CoreCastMotion.noShadow,
          ),
          onPressed: () {},
          child: Text('그림자 없음').lineLimit(1).ellipsis,
        ),
        const Gap.space12(),
        Button(
          variant: CoreButtonVariant.primary,
          buttonStyle: const CoreButtonStyle(castMotion: CoreCastMotion.reverse),
          onPressed: () {},
          child: Text('반대로').lineLimit(1).ellipsis,
        ),
      ],
    );
  }
}
