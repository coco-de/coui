import 'package:flutter/foundation.dart';

import 'package:coui_flutter/coui_flutter.dart';

/// Theme configuration for [FadeScroll].
class FadeScrollTheme {
  /// Creates a [FadeScrollTheme].
  const FadeScrollTheme({
    this.endOffset,
    this.gradient,
    this.startOffset,
  });

  /// The distance from the start before fading begins.
  final double? startOffset;

  /// The distance from the end before fading begins.
  final double? endOffset;

  /// The gradient colors used for the fade.
  final List<Color>? gradient;

  /// Creates a copy of this theme but with the given fields replaced.
  FadeScrollTheme copyWith({
    ValueGetter<double?>? endOffset,
    ValueGetter<List<Color>?>? gradient,
    ValueGetter<double?>? startOffset,
  }) {
    return FadeScrollTheme(
      endOffset: endOffset == null ? this.endOffset : endOffset(),
      gradient: gradient == null ? this.gradient : gradient(),
      startOffset: startOffset == null ? this.startOffset : startOffset(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FadeScrollTheme &&
        other.startOffset == startOffset &&
        other.endOffset == endOffset &&
        listEquals(other.gradient, gradient);
  }

  @override
  int get hashCode => Object.hash(startOffset, endOffset, gradient);
}

class FadeScroll extends StatelessWidget {
  const FadeScroll({
    required this.child,
    required this.controller,
    this.endCrossOffset = 0,
    this.endOffset,
    this.gradient,
    super.key,
    this.startCrossOffset = 0,
    this.startOffset,
  });

  final double? startOffset;
  final double? endOffset;
  final double startCrossOffset;
  final double endCrossOffset;
  final Widget child;
  final ScrollController controller;

  final List<Color>? gradient;

  @override
  Widget build(BuildContext context) {
    final compTheme = ComponentTheme.maybeOf<FadeScrollTheme>(context);
    final startOffset = styleValue(
      defaultValue: 0,
      themeValue: compTheme?.startOffset,
      widgetValue: this.startOffset,
    );
    final endOffset = styleValue(
      defaultValue: 0,
      themeValue: compTheme?.endOffset,
      widgetValue: this.endOffset,
    );
    final gradient = styleValue(
      defaultValue: const [Colors.white, Colors.transparent],
      themeValue: compTheme?.gradient,
      widgetValue: this.gradient,
    );

    return ListenableBuilder(
      builder: (context, child) {
        if (!controller.hasClients) {
          return child!;
        }
        final position = controller.position.pixels;
        final max = controller.position.maxScrollExtent;
        final min = controller.position.minScrollExtent;
        final direction = controller.position.axis;
        final size = controller.position.viewportDimension;
        final shouldFadeStart = position > min;
        final shouldFadeEnd = position < max;

        return !shouldFadeStart && !shouldFadeEnd
            ? child!
            : ShaderMask(
                shaderCallback: (bounds) {
                  final start = direction == Axis.horizontal
                      ? Alignment.centerLeft
                      : Alignment.topCenter;
                  final end = direction == Axis.horizontal
                      ? Alignment.centerRight
                      : Alignment.bottomCenter;
                  final relativeStart = startOffset / size;
                  final relativeEnd = 1 - endOffset / size;
                  final stops = shouldFadeStart && shouldFadeEnd
                      ? [
                          for (int i = 0; i < gradient.length; i += 1)
                            (i / gradient.length) * relativeStart,
                          relativeStart,
                          relativeEnd,
                          for (int i = 1; i < gradient.length + 1; i += 1)
                            relativeEnd +
                                (i / gradient.length) * (1 - relativeEnd),
                        ]
                      : shouldFadeStart
                          ? [
                              for (int i = 0; i < gradient.length; i += 1)
                                (i / gradient.length) * relativeStart,
                              relativeStart,
                              1,
                            ]
                          : [
                              0,
                              relativeEnd,
                              for (int i = 1; i < gradient.length + 1; i += 1)
                                relativeEnd +
                                    (i / gradient.length) * (1 - relativeEnd),
                            ];

                  return LinearGradient(
                    begin: start,
                    colors: [
                      if (shouldFadeStart) ...gradient,
                      Colors.white,
                      Colors.white,
                      if (shouldFadeEnd) ...gradient.reversed,
                    ],
                    end: end,
                    stops: stops,
                    transform: const _ScaleGradient(Offset(1, 1.5)),
                  ).createShader(bounds);
                },
                child: child,
              );
      },
      listenable: controller,
      child: child,
    );
  }
}

class _ScaleGradient extends GradientTransform {
  const _ScaleGradient(this.scale);

  final Offset scale;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    final center = bounds.center;
    final dx = center.dx * (1 - scale.dx);
    final dy = center.dy * (1 - scale.dy);

    return Matrix4.identity()
      ..multiply(Matrix4.translationValues(dx, dy, 0))
      ..multiply(Matrix4.diagonal3Values(scale.dx, scale.dy, 1.0))
      ..multiply(Matrix4.translationValues(-dx, -dy, 0));
  }
}
