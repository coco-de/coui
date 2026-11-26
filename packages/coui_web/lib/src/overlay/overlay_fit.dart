/// Shared chrome for a portal-mounted overlay panel that is held to the room
/// the viewport leaves it (`DropdownMenu` / `ContextMenu` / `Menubar`).
///
/// The positioner measures the panel and reports the height it is capped to
/// (`OverlayPositioner.onFit`); a host keeps that beside the panel's origin
/// and tells the `Menu` it composes through a `MenuFitScope`, and the `Menu`
/// asks for the chrome here. The panel's own box is held to the cap and the
/// list *inside* it scrolls. The box carries the border, the rounded corners,
/// the shadow and — under a glass surface — a rim drawn by pseudo-elements
/// that are positioned inside it; anything positioned inside a scroller moves
/// with the scrolled content, so a scrolling box would carry its rim off the
/// screen. Only the rows move, as on Flutter.
library;

import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/overlay/positioning/fit.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' show Styles;

/// Inline styles that hold a panel's own box to [maxHeight].
///
/// Laid over the panel's own chrome, which already clips the box
/// (`overflow-hidden`), so the border, corners and shadow stay with it.
/// [maxHeight] is a height the browser measured (the viewport's), so it goes
/// back in as CSS pixels.
///
/// `box-sizing: border-box` makes the cap the height of the whole box —
/// border and padding included — the way the positioner measures it.
/// coui_web ships without Tailwind's preflight, so a consumer's page may size
/// boxes by their content, and a cap that left the border and padding on top
/// would put the panel past the edge it was held to.
Styles resolveOverlayFitBox({required double maxHeight}) {
  return Styles(
    raw: {'box-sizing': 'border-box', 'max-height': measuredPxCss(maxHeight)},
  );
}

/// The chrome of the list that scrolls inside a held panel's box.
///
/// - `display: flex` in a column with `gap: inherit` keeps the rows in the
///   column and at the spacing the box laid them out in — the spacing stays
///   the box's own decision.
/// - `flex: 1 1 auto` with `min-height: 0` makes the list take the height the
///   box leaves it and shrink to it; a flex item will not shrink below its
///   content unless its minimum is lifted, which would defeat the cap.
/// - `overflow-y: auto` scrolls the rows; the other axis stays hidden.
/// - `scrollbar-gutter: stable` reserves the scrollbar's width in the box the
///   panel is sized from; without it a classic scrollbar appears after the
///   panel was sized to its widest row and takes that width from the rows.
/// - `overscroll-behavior-y: contain` keeps a wheel or swipe at the end of
///   the list from scrolling the page behind the panel.
///
/// The class is the marker the overlay positioner looks for to learn how much
/// the panel holds beyond what it shows.
WebElementChrome resolveOverlayFitScroller() {
  return const WebElementChrome(
    className: kOverlayFitScrollerClass,
    inlineStyles: Styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'gap': 'inherit',
        'flex': '1 1 auto',
        'min-height': '0',
        'overflow-x': 'hidden',
        'overflow-y': 'auto',
        'overscroll-behavior-y': 'contain',
        'scrollbar-gutter': 'stable',
      },
    ),
  );
}
