/// Names the navigation bar's resolver, its component and its DOM runtimes
/// agree on — kept apart from the resolver so a runtime can name a variable
/// without importing the chrome that reads it.
library;

/// The compact size the bar's style states, as a factor of its resting size
/// — set on the bar's root by the resolver.
const kNavigationCompactScaleVar = '--coui-navigation-compact-scale';

/// The factor the bar is drawn at now: [kNavigationCompactScaleVar] while
/// the bar is compact, unset — read as `1` — otherwise.
const kNavigationCompactVar = '--coui-navigation-compact';

/// Marks a bar that is compact. The component sets it; what compact looks
/// like is the resolver's ([kNavigationCompactScaleVar]).
const kNavigationCompactAttribute = 'data-coui-navigation-compact';

/// The scale the glass runtime draws the whole bar at while its lens is up
/// (`CoreGlassNavigationMotion.barSwell`), and the point along the bar that
/// swell grows from — published by the runtime beside the `scale` and
/// `transform-origin` it writes, so the compact transform can be stated
/// about its own point whatever the origin is.
const kNavigationSwellVar = '--coui-navigation-swell';

/// See [kNavigationSwellVar].
const kNavigationSwellOriginVar = '--coui-navigation-swell-origin';
