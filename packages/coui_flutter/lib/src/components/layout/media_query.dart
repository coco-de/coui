import 'package:coui_flutter/coui_flutter.dart';

/// Theme configuration for [MediaQueryVisibility].
class MediaQueryVisibilityTheme {
  /// Creates a [MediaQueryVisibilityTheme].
  const MediaQueryVisibilityTheme({this.maxWidth, this.minWidth});

  /// Minimum width at which the child is shown.
  final double? minWidth;

  /// Maximum width at which the child is shown.
  final double? maxWidth;

  /// Creates a copy of this theme but with the given fields replaced.
  MediaQueryVisibilityTheme copyWith({
    ValueGetter<double?>? maxWidth,
    ValueGetter<double?>? minWidth,
  }) {
    return MediaQueryVisibilityTheme(
      maxWidth: maxWidth == null ? this.maxWidth : maxWidth(),
      minWidth: minWidth == null ? this.minWidth : minWidth(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MediaQueryVisibilityTheme &&
        other.minWidth == minWidth &&
        other.maxWidth == maxWidth;
  }

  @override
  int get hashCode => Object.hash(minWidth, maxWidth);
}

class MediaQueryVisibility extends StatelessWidget {
  const MediaQueryVisibility({
    this.alternateChild,
    required this.child,
    super.key,
    this.maxWidth,
    this.minWidth,
  });

  final double? minWidth;
  final double? maxWidth;
  final Widget child;

  final Widget? alternateChild;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final compTheme =
        ComponentTheme.maybeOf<MediaQueryVisibilityTheme>(context);
    final size = mediaQuery.size.width;
    final minWidth = styleValue(
      defaultValue: null,
      themeValue: compTheme?.minWidth,
      widgetValue: this.minWidth,
    );
    final maxWidth = styleValue(
      defaultValue: null,
      themeValue: compTheme?.maxWidth,
      widgetValue: this.maxWidth,
    );
    if (minWidth != null && size < minWidth) {
      return SizedBox(child: alternateChild);
    }

    // to prevent widget tree from changing
    return maxWidth != null && size > maxWidth
        ? SizedBox(child: alternateChild)
        : SizedBox(child: child);
  }
}
