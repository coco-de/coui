import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/layout/media_query/media_query_style.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

/// Unified responsive visibility wrapper for CoUI Web.
///
/// Wraps the two slots in a CSS container (`container-type: inline-size`)
/// and injects a scoped `@container` rule that toggles `display` based on
/// the configured range. Mirrors Flutter `MediaQueryVisibility` which
/// measures its `LayoutBuilder` parent constraints.
///
/// The wrapper explicitly takes `width: 100%` so its measured inline size
/// follows the parent slot rather than shrinking to intrinsic content width.
/// That keeps the `@container` query evaluating the same axis Flutter does.
class MediaQueryVisibility extends StatelessComponent
    implements CoreMediaQueryVisibilityContract<Component> {
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
  final Component child;

  @override
  final Component? alternateChild;

  @override
  final double? minWidth;

  @override
  final double? maxWidth;

  @override
  final CoreBreakpoint? minBreakpoint;

  @override
  final CoreBreakpoint? maxBreakpoint;

  @override
  Component build(BuildContext context) {
    // Behavioural / composed-CSS resolution — scope id, scoped
    // `@container` rule CSS text, and the unbounded branch flag. Kept
    // off the chrome resolver (pure `WebElementChrome` slots) per the
    // number_ticker separate-resolver pattern.
    final css = resolveMediaQueryVisibilityCss(
      context,
      minWidth: minWidth,
      maxWidth: maxWidth,
      minBreakpoint: minBreakpoint,
      maxBreakpoint: maxBreakpoint,
    );

    final resolved = resolveMediaQueryVisibility(scopeId: css.scopeId);

    final alt = alternateChild;

    // No bounds → just render child, skip the wrapper overhead entirely.
    if (css.isUnbounded) {
      if (alt == null) return child;
      return div(
        [child],
        classes: resolved.primary.className,
        styles: resolved.primary.inlineStyles,
      );
    }

    final rule = css.containerRuleCss;

    return div(
      [
        if (rule != null)
          Component.element(tag: 'style', children: [RawText(rule)]),
        div(
          [child],
          classes: resolved.primary.className,
          styles: resolved.primary.inlineStyles,
        ),
        if (alt != null)
          div(
            [alt],
            classes: resolved.alternate.className,
            styles: resolved.alternate.inlineStyles,
          ),
      ],
      id: css.scopeId,
      classes: resolved.root.className,
      styles: resolved.root.inlineStyles,
    );
  }
}
