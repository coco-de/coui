import 'package:coui_flutter/coui_flutter.dart';

class FocusOutlineTheme {
  const FocusOutlineTheme({this.align, this.border, this.borderRadius});

  final double? align;
  final BorderRadiusGeometry? borderRadius;

  final Border? border;

  FocusOutlineTheme copyWith({
    ValueGetter<double?>? align,
    ValueGetter<Border?>? border,
    ValueGetter<BorderRadiusGeometry?>? borderRadius,
  }) {
    return FocusOutlineTheme(
      align: align == null ? this.align : align(),
      border: border == null ? this.border : border(),
      borderRadius: borderRadius == null ? this.borderRadius : borderRadius(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FocusOutlineTheme &&
        other.align == align &&
        other.border == border &&
        other.borderRadius == borderRadius;
  }

  @override
  int get hashCode => Object.hash(border, align, borderRadius);
}

class FocusOutline extends StatelessWidget {
  const FocusOutline({
    this.align,
    this.border,
    this.borderRadius,
    required this.child,
    required this.focused,
    super.key,
    this.shape,
  });

  static BorderRadius _getAdjustedBorderRadius(
    double align,
    BorderRadiusGeometry? borderRadius,
    TextDirection textDirection,
  ) {
    final rawRadius = borderRadius;
    if (rawRadius == null) return BorderRadius.zero;
    final resolved = rawRadius.resolve(textDirection);

    return BorderRadius.only(
      bottomLeft: resolved.bottomLeft + Radius.circular(align),
      bottomRight: resolved.bottomRight + Radius.circular(align),
      topLeft: resolved.topLeft + Radius.circular(align),
      topRight: resolved.topRight + Radius.circular(align),
    );
  }

  final Widget child;
  final bool focused;
  final BorderRadiusGeometry? borderRadius;
  final double? align;
  final Border? border;

  final BoxShape? shape;

  @override
  Widget build(BuildContext context) {
    final compTheme = ComponentTheme.maybeOf<FocusOutlineTheme>(context);
    final double align = styleValue(
      defaultValue: 3,
      themeValue: compTheme?.align,
      widgetValue: this.align,
    );
    final BorderRadiusGeometry? borderRadius = styleValue(
      defaultValue: null,
      themeValue: compTheme?.borderRadius,
      widgetValue: this.borderRadius,
    );
    final offset = -align;
    final textDirection = Directionality.of(context);

    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.passthrough,
      children: [
        child,
        AnimatedValueBuilder(
          builder: (context, value, child) {
            return Positioned(
              bottom: offset * value,
              left: offset * value,
              right: offset * value,
              top: offset * value,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    border: styleValue(
                      defaultValue: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.ring.scaleAlpha(0.5),
                        width: 3,
                      ),
                      themeValue: compTheme?.border,
                      widgetValue: border,
                    ).scale(value),
                    borderRadius: shape == BoxShape.circle
                        ? null
                        : _getAdjustedBorderRadius(
                            textDirection,
                            align,
                            borderRadius,
                          ),
                    shape: shape ?? BoxShape.rectangle,
                  ),
                ),
              ),
            );
          },
          duration: kDefaultDuration,
          value: focused ? 1.0 : 0.0,
        ),
      ],
    );
  }
}
