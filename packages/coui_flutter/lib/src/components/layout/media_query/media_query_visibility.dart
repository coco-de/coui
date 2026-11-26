import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/src/components/layout/media_query/media_query_style.dart';
import 'package:flutter/widgets.dart';

/// Unified responsive visibility wrapper for CoUI Flutter.
///
/// Measures its containing box via [LayoutBuilder] — mirrors Web
/// `MediaQueryVisibility` which uses a CSS `@container` query on the
/// wrapping element. When the parent constraints are unbounded the widget
/// falls back to the ambient `MediaQuery` width.
class MediaQueryVisibility extends StatelessWidget
    implements CoreMediaQueryVisibilityContract<Widget> {
  /// Creates a [MediaQueryVisibility].
  const MediaQueryVisibility({
    required this.child,
    super.key,
    this.alternateChild,
    this.minWidth,
    this.maxWidth,
    this.minBreakpoint,
    this.maxBreakpoint,
  });

  @override
  final Widget child;

  @override
  final Widget? alternateChild;

  @override
  final double? minWidth;

  @override
  final double? maxWidth;

  @override
  final CoreBreakpoint? minBreakpoint;

  @override
  final CoreBreakpoint? maxBreakpoint;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveMediaQueryVisibility(
      context,
      minWidth: minWidth,
      maxWidth: maxWidth,
      minBreakpoint: minBreakpoint,
      maxBreakpoint: maxBreakpoint,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final containerWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.widthOf(context);
        final belowMin =
            resolved.minWidth != null && containerWidth < resolved.minWidth!;
        final aboveMax =
            resolved.maxWidth != null && containerWidth > resolved.maxWidth!;
        if (belowMin || aboveMax) {
          return SizedBox(child: alternateChild);
        }
        return SizedBox(child: child);
      },
    );
  }
}
