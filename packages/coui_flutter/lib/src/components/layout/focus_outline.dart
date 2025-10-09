import 'package:coui_flutter/coui_flutter.dart';

class FocusOutlineTheme {
  const FocusOutlineTheme({this.align, this.border, this.borderRadius});

  final double? align;
  final BorderRadiusGeometry? borderRadius;

  final Border? border;

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
    TextDirection textDirection,
    double align,
    BorderRadiusGeometry? borderRadius,
  ) {
    final rawRadius = borderRadius;
    if (rawRadius == null) return BorderRadius.zero;
    final resolved = rawRadius.resolve(textDirection);

    return BorderRadius.only(
      topLeft: resolved.topLeft + Radius.circular(align),
      topRight: resolved.topRight + Radius.circular(align),
      bottomLeft: resolved.bottomLeft + Radius.circular(align),
      bottomRight: resolved.bottomRight + Radius.circular(align),
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
      widgetValue: this.align,
      themeValue: compTheme?.align,
      defaultValue: 3,
    );
    final BorderRadiusGeometry? borderRadius = styleValue(
      widgetValue: this.borderRadius,
      themeValue: compTheme?.borderRadius,
      defaultValue: null,
    );
    final offset = -align;
    final textDirection = Directionality.of(context);

    return Stack(
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [
        child,
        AnimatedValueBuilder(
          value: focused ? 1.0 : 0.0,
          duration: kDefaultDuration,
          builder: (context, value, child) {
            return Positioned(
              left: offset * value,
              top: offset * value,
              right: offset * value,
              bottom: offset * value,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    border: styleValue(
                      widgetValue: border,
                      themeValue: compTheme?.border,
                      defaultValue: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.ring.scaleAlpha(0.5),
                        width: 3,
                      ),
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
        ),
      ],
    );
  }
}
