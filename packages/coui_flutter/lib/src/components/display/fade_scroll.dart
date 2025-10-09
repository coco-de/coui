import 'package:flutter/foundation.dart';

import 'package:coui_flutter/coui_flutter.dart';

/// Theme configuration for [FadeScroll].
class FadeScrollTheme {
  /// Creates a [FadeScrollTheme].
  const FadeScrollTheme({this.endOffset, this.gradient, this.startOffset});

  /// The distance from the start before fading begins.
  final double? startOffset;

  /// The distance from the end before fading begins.
  final double? endOffset;

  /// The gradient colors used for the fade.
  final List<Color>? gradient;

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
    this.endOffset,
    this.gradient,
    super.key,
    this.startOffset,
  });

  final double? startOffset;
  final double? endOffset;
  final Widget child;
  final ScrollController controller;

  final List<Color>? gradient;

  @override
  Widget build(BuildContext context) {
    final compTheme = ComponentTheme.maybeOf<FadeScrollTheme>(context);
    final startOffset = styleValue(
      widgetValue: this.startOffset,
      themeValue: compTheme?.startOffset,
      defaultValue: 0,
    );
    final endOffset = styleValue(
      widgetValue: this.endOffset,
      themeValue: compTheme?.endOffset,
      defaultValue: 0,
    );
    final gradient = styleValue(
      widgetValue: this.gradient,
      themeValue: compTheme?.gradient,
      defaultValue: const [Colors.white, Colors.transparent],
    );

    return ListenableBuilder(
      listenable: controller,
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
                  final stops = <double>[
                    if (shouldFadeStart && shouldFadeEnd) ...[
                      for (int i = 0; i < gradient.length; i += 1)
                        ((i / gradient.length) * relativeStart),
                      relativeStart,
                      relativeEnd,
                      for (int i = 1; i < gradient.length + 1; i += 1)
                        (relativeEnd +
                            (i / gradient.length) * (1 - relativeEnd)),
                    ] else if (shouldFadeStart) ...[
                      for (int i = 0; i < gradient.length; i += 1)
                        ((i / gradient.length) * relativeStart),
                      relativeStart,
                      1.0,
                    ] else ...[
                      0.0,
                      relativeEnd,
                      for (int i = 1; i < gradient.length + 1; i += 1)
                        (relativeEnd +
                            (i / gradient.length) * (1 - relativeEnd)),
                    ]
                  ];

                  return LinearGradient(
                    begin: start,
                    end: end,
                    colors: [
                      if (shouldFadeStart) ...gradient,
                      Colors.white,
                      Colors.white,
                      if (shouldFadeEnd) ...gradient.reversed,
                    ],
                    stops: stops,
                    transform: const _ScaleGradient(Offset(1, 1.5)),
                  ).createShader(bounds);
                },
                child: child,
              );
      },
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
