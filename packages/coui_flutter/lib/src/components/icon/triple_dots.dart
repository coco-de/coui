import 'package:coui_flutter/coui_flutter.dart';

class MoreDots extends StatelessWidget {
  const MoreDots({
    this.color,
    this.count = 3,
    this.direction = Axis.horizontal,
    super.key,
    this.padding,
    this.size,
    this.spacing = 2,
  });

  final Axis direction;
  final int count;
  final double? size;
  final Color? color;
  final double spacing;

  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style;
    final color = this.color ?? style.color!;
    final size = this.size ?? (style.fontSize ?? 12) * 0.2;
    final children = <Widget>[];
    for (int i = 0; i < count; i += 1) {
      children.add(
        Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(size / 2),
          ),
          width: size,
          height: size,
        ),
      );
      if (i < count - 1) {
        children.add(
          SizedBox(
            width: direction == Axis.horizontal ? spacing : null,
            height: direction == Axis.vertical ? spacing : null,
          ),
        );
      }
    }

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: direction == Axis.horizontal
          ? Row(mainAxisSize: MainAxisSize.min, children: children)
          : Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}
