import 'package:coui_flutter/coui_flutter.dart';

/// Theme configuration for loading widgets.
class LoadingTheme {
  const LoadingTheme({this.color, this.size});

  /// Color of the loading elements.
  final Color? color;

  /// Size of the loading widget.
  final double? size;

  LoadingTheme copyWith({
    ValueGetter<Color?>? color,
    ValueGetter<double?>? size,
  }) {
    return LoadingTheme(
      color: color == null ? this.color : color(),
      size: size == null ? this.size : size(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LoadingTheme && other.color == color && other.size == size;
  }

  @override
  int get hashCode => Object.hash(color, size);
}

abstract class LoadingTransform {}

abstract class LoadingElement {
  void paint(Canvas canvas, Size size, Matrix4 transform);
}

abstract class Loading extends StatelessWidget {
  const Loading({this.color, super.key, this.size});

  final Color? color;
  final double? size;

  /// Resolve loading color considering theme overrides.
  Color? resolveColor(BuildContext context) {
    final compTheme = ComponentTheme.maybeOf<LoadingTheme>(context);

    return styleValue(
      widgetValue: color,
      themeValue: compTheme?.color,
      defaultValue: null,
    );
  }

  /// Resolve loading size considering theme overrides and a default value.
  double resolveSize(BuildContext context, double defaultValue) {
    final compTheme = ComponentTheme.maybeOf<LoadingTheme>(context);

    return styleValue(
      widgetValue: size,
      themeValue: compTheme?.size,
      defaultValue: defaultValue,
    );
  }
}
