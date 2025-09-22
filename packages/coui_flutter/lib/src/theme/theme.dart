import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:coui_flutter/coui_flutter.dart';

class AdaptiveScaling {
  const AdaptiveScaling([double scaling = 1])
      : this.only(
          radiusScaling: scaling,
          sizeScaling: scaling,
          textScaling: scaling,
        );

  const AdaptiveScaling.only({
    this.radiusScaling = 1,
    this.sizeScaling = 1,
    this.textScaling = 1,
  });

  static const desktop = AdaptiveScaling();
  static const mobile = AdaptiveScaling(1.25);
  final double radiusScaling;

  final double sizeScaling;

  final double textScaling;

  ThemeData scale(ThemeData theme) {
    return theme.copyWith(
      iconTheme:
          textScaling == 1 ? null : () => theme.iconTheme.scale(textScaling),
      radius: radiusScaling == 1 ? null : () => theme.radius * radiusScaling,
      scaling: sizeScaling == 1 ? null : () => theme.scaling * sizeScaling,
      typography:
          textScaling == 1 ? null : () => theme.typography.scale(textScaling),
    );
  }

  static AdaptiveScaling lerp(
    AdaptiveScaling a,
    AdaptiveScaling b,
    double t,
  ) {
    return AdaptiveScaling.only(
      radiusScaling: lerpDouble(a.radiusScaling, b.radiusScaling, t)!,
      sizeScaling: lerpDouble(a.sizeScaling, b.sizeScaling, t)!,
      textScaling: lerpDouble(a.textScaling, b.textScaling, t)!,
    );
  }
}

class AdaptiveScaler extends StatelessWidget {
  const AdaptiveScaler({
    required this.child,
    super.key,
    required this.scaling,
  });

  static AdaptiveScaling defaultScalingOf(BuildContext context) {
    final theme = Theme.of(context);

    return defaultScaling(theme);
  }

  static AdaptiveScaling defaultScaling(ThemeData theme) {
    switch (theme.platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.android:
        return AdaptiveScaling.mobile;

      default:
        return AdaptiveScaling.desktop;
    }
  }

  final AdaptiveScaling scaling;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Theme(data: scaling.scale(theme), child: child);
  }
}

class ThemeData {
  const ThemeData({
    this.colorScheme = ColorSchemes.lightDefaultColor,
    this.iconTheme = const IconThemeProperties(),
    TargetPlatform? platform,
    this.radius = 0.5,
    this.scaling = 1,
    this.surfaceBlur,
    this.surfaceOpacity,
    this.typography = const Typography.geist(),
  }) : _platform = platform;

  const ThemeData.dark({
    this.colorScheme = ColorSchemes.darkDefaultColor,
    this.iconTheme = const IconThemeProperties(),
    TargetPlatform? platform,
    this.radius = 0.5,
    this.scaling = 1,
    this.surfaceBlur,
    this.surfaceOpacity,
    this.typography = const Typography.geist(),
  }) : _platform = platform;

  final ColorScheme colorScheme;
  final Typography typography;
  final double radius;
  final double scaling;
  final IconThemeProperties iconTheme;
  final double? surfaceOpacity;

  final double? surfaceBlur;

  final TargetPlatform? _platform;

  /// The current platform.
  TargetPlatform get platform => _platform ?? defaultTargetPlatform;

  /// At normal radius, the scaled radius is 24.
  double get radiusXxl => radius * 24;

  /// At normal radius, the scaled radius is 20.
  double get radiusXl => radius * 20;

  /// At normal radius, the scaled radius is 16.
  double get radiusLg => radius * 16;

  /// At normal radius, the scaled radius is 12.
  double get radiusMd => radius * 12;

  /// At normal radius, the scaled radius is 8.
  double get radiusSm => radius * 8;

  /// At normal radius, the scaled radius is 4.
  double get radiusXs => radius * 4;

  BorderRadius get borderRadiusXxl => BorderRadius.circular(radiusXxl);
  BorderRadius get borderRadiusXl => BorderRadius.circular(radiusXl);
  BorderRadius get borderRadiusLg => BorderRadius.circular(radiusLg);
  BorderRadius get borderRadiusMd => BorderRadius.circular(radiusMd);
  BorderRadius get borderRadiusSm => BorderRadius.circular(radiusSm);
  BorderRadius get borderRadiusXs => BorderRadius.circular(radiusXs);

  Radius get radiusXxlRadius => Radius.circular(radiusXxl);
  Radius get radiusXlRadius => Radius.circular(radiusXl);
  Radius get radiusLgRadius => Radius.circular(radiusLg);
  Radius get radiusMdRadius => Radius.circular(radiusMd);
  Radius get radiusSmRadius => Radius.circular(radiusSm);
  Radius get radiusXsRadius => Radius.circular(radiusXs);

  Brightness get brightness => colorScheme.brightness;

  ThemeData copyWith({
    ValueGetter<ColorScheme>? colorScheme,
    ValueGetter<IconThemeProperties>? iconTheme,
    ValueGetter<TargetPlatform>? platform,
    ValueGetter<double>? radius,
    ValueGetter<double>? scaling,
    ValueGetter<double>? surfaceBlur,
    ValueGetter<double>? surfaceOpacity,
    ValueGetter<Typography>? typography,
  }) {
    return ThemeData(
      colorScheme: colorScheme == null ? this.colorScheme : colorScheme(),
      iconTheme: iconTheme == null ? this.iconTheme : iconTheme(),
      platform: platform == null ? _platform : platform(),
      radius: radius == null ? this.radius : radius(),
      scaling: scaling == null ? this.scaling : scaling(),
      surfaceBlur: surfaceBlur == null ? this.surfaceBlur : surfaceBlur(),
      surfaceOpacity:
          surfaceOpacity == null ? this.surfaceOpacity : surfaceOpacity(),
      typography: typography == null ? this.typography : typography(),
    );
  }

  static ThemeData lerp(ThemeData a, ThemeData b, double t) {
    return ThemeData(
      colorScheme: ColorScheme.lerp(a.colorScheme, b.colorScheme, t),
      iconTheme: IconThemeProperties.lerp(a.iconTheme, b.iconTheme, t),
      platform: t < 0.5 ? a.platform : b.platform,
      radius: lerpDouble(a.radius, b.radius, t)!,
      scaling: lerpDouble(a.scaling, b.scaling, t)!,
      surfaceBlur: lerpDouble(a.surfaceBlur, b.surfaceBlur, t),
      surfaceOpacity: lerpDouble(a.surfaceOpacity, b.surfaceOpacity, t),
      typography: Typography.lerp(a.typography, b.typography, t),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ThemeData &&
        other.colorScheme == colorScheme &&
        other.typography == typography &&
        other.radius == radius &&
        other.scaling == scaling &&
        other.iconTheme == iconTheme &&
        other.surfaceOpacity == surfaceOpacity &&
        other.surfaceBlur == surfaceBlur;
  }

  @override
  String toString() {
    return 'ThemeData(colorScheme: $colorScheme, typography: $typography, radius: $radius, scaling: $scaling, iconTheme: $iconTheme, surfaceOpacity: $surfaceOpacity, surfaceBlur: $surfaceBlur)';
  }

  @override
  int get hashCode {
    return Object.hash(
      colorScheme,
      typography,
      radius,
      scaling,
      iconTheme,
      surfaceOpacity,
      surfaceBlur,
    );
  }
}

class Theme extends InheritedTheme {
  const Theme({required super.child, required this.data, super.key});

  static ThemeData of(BuildContext context) {
    final theme = context.dependOnInheritedWidgetOfExactType<Theme>();
    assert(theme != null, 'No Theme found in context');

    return theme!.data;
  }

  final ThemeData data;

  @override
  bool updateShouldNotify(covariant Theme oldWidget) {
    return oldWidget.data != data;
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    final ancestorTheme = context.findAncestorWidgetOfExactType<Theme>();

    return identical(this, ancestorTheme)
        ? child
        : Theme(data: data, child: child);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ThemeData>('data', data));
  }
}

class ThemeDataTween extends Tween<ThemeData> {
  ThemeDataTween({required ThemeData super.begin, required super.end});

  @override
  ThemeData lerp(double t) {
    return end == null ? begin! : ThemeData.lerp(begin!, end!, t);
  }
}

class AnimatedTheme extends ImplicitlyAnimatedWidget {
  const AnimatedTheme({
    required this.child,
    super.curve,
    required this.data,
    required super.duration,
    super.key,
  });

  final ThemeData data;

  final Widget child;

  @override
  _AnimatedThemeState createState() => _AnimatedThemeState();
}

class _AnimatedThemeState extends AnimatedWidgetBaseState<AnimatedTheme> {
  ThemeDataTween? _data;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _data = visitor(
      _data,
      widget.data,
      (dynamic value) => ThemeDataTween(begin: value as ThemeData, end: null),
    ) as ThemeDataTween?;
  }

  @override
  Widget build(BuildContext context) {
    final theme = _data!.evaluate(animation);

    return Theme(data: theme, child: widget.child);
  }
}

class IconThemeProperties {
  const IconThemeProperties({
    this.large = const IconThemeData(size: 24),
    this.medium = const IconThemeData(size: 20),
    this.small = const IconThemeData(size: 16),
    this.x2Large = const IconThemeData(size: 40),
    this.x2Small = const IconThemeData(size: 10),
    this.x3Large = const IconThemeData(size: 48),
    this.x3Small = const IconThemeData(size: 8),
    this.x4Large = const IconThemeData(size: 56),
    this.x4Small = const IconThemeData(size: 6),
    this.xLarge = const IconThemeData(size: 32),
    this.xSmall = const IconThemeData(size: 12),
  });

  final IconThemeData x4Small;
  final IconThemeData x3Small;
  final IconThemeData x2Small;
  final IconThemeData xSmall;
  final IconThemeData small;
  final IconThemeData medium;
  final IconThemeData large;
  final IconThemeData xLarge;
  final IconThemeData x2Large;
  final IconThemeData x3Large;

  final IconThemeData x4Large;

  IconThemeProperties copyWith({
    ValueGetter<IconThemeData>? large,
    ValueGetter<IconThemeData>? medium,
    ValueGetter<IconThemeData>? small,
    ValueGetter<IconThemeData>? x2Large,
    ValueGetter<IconThemeData>? x2Small,
    ValueGetter<IconThemeData>? x3Large,
    ValueGetter<IconThemeData>? x3Small,
    ValueGetter<IconThemeData>? x4Large,
    ValueGetter<IconThemeData>? x4Small,
    ValueGetter<IconThemeData>? xLarge,
    ValueGetter<IconThemeData>? xSmall,
  }) {
    return IconThemeProperties(
      large: large == null ? this.large : large(),
      medium: medium == null ? this.medium : medium(),
      small: small == null ? this.small : small(),
      x2Large: x2Large == null ? this.x2Large : x2Large(),
      x2Small: x2Small == null ? this.x2Small : x2Small(),
      x3Large: x3Large == null ? this.x3Large : x3Large(),
      x3Small: x3Small == null ? this.x3Small : x3Small(),
      x4Large: x4Large == null ? this.x4Large : x4Large(),
      x4Small: x4Small == null ? this.x4Small : x4Small(),
      xLarge: xLarge == null ? this.xLarge : xLarge(),
      xSmall: xSmall == null ? this.xSmall : xSmall(),
    );
  }

  IconThemeProperties scale(double factor) {
    return IconThemeProperties(
      large: large.size == null
          ? large
          : large.copyWith(size: large.size! * factor),
      medium: medium.size == null
          ? medium
          : medium.copyWith(size: medium.size! * factor),
      small: small.size == null
          ? small
          : small.copyWith(size: small.size! * factor),
      x2Large: x2Large.size == null
          ? x2Large
          : x2Large.copyWith(size: x2Large.size! * factor),
      x2Small: x2Small.size == null
          ? x2Small
          : x2Small.copyWith(size: x2Small.size! * factor),
      x3Large: x3Large.size == null
          ? x3Large
          : x3Large.copyWith(size: x3Large.size! * factor),
      x3Small: x3Small.size == null
          ? x3Small
          : x3Small.copyWith(size: x3Small.size! * factor),
      x4Large: x4Large.size == null
          ? x4Large
          : x4Large.copyWith(size: x4Large.size! * factor),
      x4Small: x4Small.size == null
          ? x4Small
          : x4Small.copyWith(size: x4Small.size! * factor),
      xLarge: xLarge.size == null
          ? xLarge
          : xLarge.copyWith(size: xLarge.size! * factor),
      xSmall: xSmall.size == null
          ? xSmall
          : xSmall.copyWith(size: xSmall.size! * factor),
    );
  }

  static IconThemeProperties lerp(
    IconThemeProperties a,
    IconThemeProperties b,
    double t,
  ) {
    return IconThemeProperties(
      large: IconThemeData.lerp(a.large, b.large, t),
      medium: IconThemeData.lerp(a.medium, b.medium, t),
      small: IconThemeData.lerp(a.small, b.small, t),
      x2Large: IconThemeData.lerp(a.x2Large, b.x2Large, t),
      x2Small: IconThemeData.lerp(a.x2Small, b.x2Small, t),
      x3Large: IconThemeData.lerp(a.x3Large, b.x3Large, t),
      x3Small: IconThemeData.lerp(a.x3Small, b.x3Small, t),
      x4Large: IconThemeData.lerp(a.x4Large, b.x4Large, t),
      x4Small: IconThemeData.lerp(a.x4Small, b.x4Small, t),
      xLarge: IconThemeData.lerp(a.xLarge, b.xLarge, t),
      xSmall: IconThemeData.lerp(a.xSmall, b.xSmall, t),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is IconThemeProperties &&
        other.x4Small == x4Small &&
        other.x3Small == x3Small &&
        other.x2Small == x2Small &&
        other.xSmall == xSmall &&
        other.small == small &&
        other.medium == medium &&
        other.large == large &&
        other.xLarge == xLarge &&
        other.x2Large == x2Large &&
        other.x3Large == x3Large &&
        other.x4Large == x4Large;
  }

  @override
  String toString() {
    return 'IconThemeProperties(x4Small: $x4Small, x3Small: $x3Small, x2Small: $x2Small, xSmall: $xSmall, small: $small, medium: $medium, large: $large, xLarge: $xLarge, x2Large: $x2Large, x3Large: $x3Large, x4Large: $x4Large)';
  }

  @override
  int get hashCode {
    return Object.hash(
      x4Small,
      x3Small,
      x2Small,
      xSmall,
      small,
      medium,
      large,
      xLarge,
      x2Large,
      x3Large,
      x4Large,
    );
  }
}

class ComponentTheme<T> extends InheritedTheme {
  const ComponentTheme({
    required super.child,
    required this.data,
    super.key,
  });

  static T of<T>(BuildContext context) {
    final data = maybeOf<T>(context);
    assert(data != null, 'No ComponentTheme<$T> found in context');

    return data!;
  }

  static T? maybeOf<T>(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<ComponentTheme<T>>();

    return widget == null ? null : widget.data;
  }

  final T data;

  @override
  Widget wrap(BuildContext context, Widget child) {
    final ancestorTheme =
        context.findAncestorWidgetOfExactType<ComponentTheme<T>>();

    return identical(this, ancestorTheme)
        ? child
        : ComponentTheme<T>(data: data, child: child);
  }

  @override
  bool updateShouldNotify(covariant ComponentTheme<T> oldWidget) {
    return oldWidget.data != data;
  }
}

enum ThemeMode {
  dark,
  light,
  system,
}
