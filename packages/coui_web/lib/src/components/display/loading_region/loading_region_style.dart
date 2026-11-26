import 'package:coui_web/src/base/web_layout.dart';

/// Class for the element that carries the announcement.
///
/// Visually hidden but read: the region draws nothing, so its text exists
/// only for assistive technology. It is out of flow and out of the page's
/// scrollable overflow, so it takes no part in the layout of whatever the
/// region sits in — including a horizontal scroller, where a plain `sr-only`
/// box would widen the page.
String buildLoadingRegionAnnouncerClassName() => WebLayout.srOnlyFixed;

/// Class for the element that holds the loading content.
///
/// `display: contents` — the wrapper exists only to carry `aria-hidden`, and
/// as a box it would add a level of layout the Flutter twin (a semantics
/// node) does not have. Box layout (flex, grid, flow) treats the content as the
/// region's parent's own child. Selectors that count siblings do not: a
/// parent's `space-y-*` / `divide-*` / `:first-child` reach the wrapper, which
/// has no box, and the announcer beside it, not the content inside.
String buildLoadingRegionContentClassName() => WebLayout.contents;
