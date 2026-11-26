import 'package:coui_flutter/coui_flutter.dart';

/// Primitive chains — font size, line height, letter spacing, family.
class TextTypographyPrimitiveExample extends StatelessWidget {
  const TextTypographyPrimitiveExample({super.key});

  @override
  Widget build(BuildContext context) {
    final dts = DefaultTextStyle.of(context).style;
    // ignore: avoid_print
    print(
      '[primitive-base] fontSize=${dts.fontSize} '
      'height=${dts.height} fontFamily=${dts.fontFamily} '
      'mqSize=${MediaQuery.of(context).size}',
    );
    return Padding(
      padding: const CoreEdgeInsets.all(CoreSpace.space16).toValue(geometry: Theme.of(context).geometry),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Theme.of(context).geometry.space(CoreSpace.space8),
        children: [
          const Text('s10 (10px)').s10,
          const Text('s14 (14px)').s14,
          const Text('s20 (20px)').s20,
          const Text('s32 (32px)').s32,
          const Text('h160 (line-height 1.6)').h160,
          const Text('tighter (-0.05em)').tighter,
          const Text('sans (Pretendard)').sans,
        ],
      ),
    );
  }
}
