import 'package:coui_web/coui_web.dart';

/// Primitive chains — font size, line height, letter spacing, family.
class TextTypographyPrimitiveExample extends StatelessComponent {
  const TextTypographyPrimitiveExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      classes: 'flex flex-col gap-${CoreSpace.scale.space8} p-${CoreSpace.scale.space16}',
      [
        Text('s10 (10px)').s10,
        Text('s14 (14px)').s14,
        Text('s20 (20px)').s20,
        Text('s32 (32px)').s32,
        Text('h160 (line-height 1.6)').h160,
        Text('tighter (-0.05em)').tighter,
        Text('sans (Pretendard)').sans,
      ],
    );
  }
}
