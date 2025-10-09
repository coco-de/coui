import 'package:coui_flutter/coui_flutter.dart';

/// Theme configuration for [MediaQueryVisibility].
class MediaQueryVisibilityTheme {
  /// Creates a [MediaQueryVisibilityTheme].
  const MediaQueryVisibilityTheme({this.maxWidth, this.minWidth});

  /// Minimum width at which the child is shown.
  final double? minWidth;

  /// Maximum width at which the child is shown.
  final double? maxWidth;

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
    final compTheme = ComponentTheme.maybeOf<MediaQueryVisibilityTheme>(
      context,
    );
    final size = mediaQuery.size.width;
    final minWidth = styleValue(
      widgetValue: this.minWidth,
      themeValue: compTheme?.minWidth,
      defaultValue: null,
    );
    final maxWidth = styleValue(
      widgetValue: this.maxWidth,
      themeValue: compTheme?.maxWidth,
      defaultValue: null,
    );
    if (minWidth != null && size < minWidth) {
      return SizedBox(child: alternateChild);
    }

    /// To prevent widget tree from changing.
    return maxWidth != null && size > maxWidth
        ? SizedBox(child: alternateChild)
        : SizedBox(child: child);
  }
}
