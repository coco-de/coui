part of 'navigation_bar.dart';

// Private structural chrome over an already-resolved destination. Core
// dimensions stay in the main resolver, carried by the destination's CSS
// variable; neither the public Resolved interface nor its constructor grows.
({
  WebElementChrome inner,
  WebElementChrome? sizer,
  WebElementChrome tooltip,
})
_resolveNavigationBarItemLayout(
  ResolvedNavigationBar resolved, {
  required CoreNavigationBarMode mode,
  required bool iconOnly,
}) {
  final needsSizer = mode == CoreNavigationBarMode.rail && iconOnly;
  return (
    inner: needsSizer
        ? WebElementChrome(
            className: '${WebLayout.grid} ${WebLayout.justifyItemsCenter}',
            inlineStyles: Styles(
              raw: {
                'grid-template-columns': 'minmax(0,1fr)',
                'gap': spaceCss(CoreSpace.space0),
                'min-width': '0',
              },
            ),
          )
        : resolved.inner,
    sizer: needsSizer
        ? const WebElementChrome(
            className: '',
            inlineStyles: Styles(
              raw: {
                'width': 'var(--co-navbar-icon-only-content-width, 0px)',
                'max-width': '100%',
                'height': '0',
              },
            ),
          )
        : null,
    // The trigger wrapper is then the row's flex item, so it takes the
    // destination's cell — its share and the cap on it.
    tooltip: WebElementChrome(
      className: '${resolved.destinationCell.className} ${WebLayout.grid}',
      inlineStyles: mode == CoreNavigationBarMode.rail
          ? const Styles(raw: {'grid-template-columns': 'minmax(0,1fr)'})
          : resolved.destinationCell.inlineStyles,
    ),
  );
}
