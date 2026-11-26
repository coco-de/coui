import 'package:coui_core/coui_core.dart';

typedef LoadingBarMotionCase = ({
  String name,
  CoreLoadingTheme? theme,
  CoreLoadingStyle? style,
  CoreComponentSize? componentSize,
  int durationMs,
  double length,
  double height,
});

const kLoadingBarMotionCases = <LoadingBarMotionCase>[
  (
    name: 'default',
    theme: null,
    style: null,
    componentSize: null,
    durationMs: CoreDuration.indeterminate,
    length:
        CoreLoadingStyle.defaultSize * CoreLoadingStyle.defaultBarLengthRatio,
    height: CoreLoadingStyle.defaultBarHeight,
  ),
  (
    name: 'theme',
    theme: CoreLoadingTheme(
      style: CoreLoadingStyle(
        duration: Duration(milliseconds: 2000),
        size: 100,
        barHeight: 4,
      ),
    ),
    style: null,
    componentSize: null,
    durationMs: 2000,
    length: 200,
    height: 4,
  ),
  (
    name: 'variant',
    theme: CoreLoadingTheme(
      style: CoreLoadingStyle(
        duration: Duration(milliseconds: 2000),
        size: 100,
        barHeight: 4,
      ),
      variantStyles: {
        CoreLoadingVariant.bar: CoreLoadingStyle(
          duration: Duration(milliseconds: 1600),
          size: 80,
        ),
      },
    ),
    style: null,
    componentSize: null,
    durationMs: 1600,
    length: 160,
    height: 4,
  ),
  (
    name: 'instance',
    theme: CoreLoadingTheme(
      style: CoreLoadingStyle(
        duration: Duration(milliseconds: 2000),
        size: 100,
        barHeight: 4,
      ),
      variantStyles: {
        CoreLoadingVariant.bar: CoreLoadingStyle(
          duration: Duration(milliseconds: 1600),
          size: 80,
        ),
      },
    ),
    style: CoreLoadingStyle(
      duration: Duration(milliseconds: 1237),
      size: 200,
      barHeight: 7,
    ),
    componentSize: null,
    durationMs: 1237,
    length: 400,
    height: 7,
  ),
  (
    name: 'size-step',
    theme: null,
    style: null,
    componentSize: CoreComponentSize.lg,
    durationMs: CoreDuration.indeterminate,
    length: 64,
    height: 4,
  ),
];

const kLoadingBarMotionPhases = [
  0.0,
  0.125,
  0.25,
  0.5,
  0.75,
  0.875,
  1.0,
  1.125,
];
