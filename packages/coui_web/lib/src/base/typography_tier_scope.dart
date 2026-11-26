import 'package:coui_core/coui_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// Renders [child]'s display and headline roles at [tier], whatever the
/// viewport.
///
/// The page steps those roles down with its width; this holds a part of it
/// to one tier. A box sized independently of the viewport whose text was
/// picked to fill it — an avatar's initials, a time picker's digits — states
/// its own tier with this, and a preview that shows components at their
/// authored size states desktop around them.
///
/// Named and shaped identically to the Flutter scope so an app reads the
/// same call on both platforms. Only the transport differs: Flutter gives
/// the subtree a theme with that tier's typography, and here a wrapper
/// carries `data-coui-typography-tier`, whose rule
/// (`ThemeConfig.typographyTierBlocks`) restates the role variables the tier
/// moves for everything inside it.
///
/// The wrapper draws no box (`display: contents`): it neither lays out nor
/// paints, so wrapping a positioned element keeps that element's containing
/// block. Custom properties still inherit through it — that is what carries
/// the tier.
///
/// A panel the subtree opens is portalled to the overlay host, outside the
/// wrapper. The popovers, menus, tooltips, hover cards and dialogs that
/// portal it state the scope again around the panel
/// (`OverlayPortal.capture`), so the panel renders at this tier too — as
/// on Flutter, where those panels capture the theme of the place they
/// opened from.
///
/// A drawer (`openDrawer`, and the swiper that opens one) does not: it
/// renders at the tier around the host it mounts on, as the Flutter drawer
/// renders at the tier around the navigator it is pushed on and captures
/// no theme from the place it was opened. By default that host is the
/// app's, so a drawer opened in here renders at the app's tier.
///
/// ```dart
/// // Components at their authored size inside a responsive page.
/// TypographyTierScope(tier: CoreBreakpointTier.desktop, child: preview)
/// ```
class TypographyTierScope extends StatelessComponent {
  /// Creates a scope rendering [child]'s headings at [tier].
  const TypographyTierScope({
    required this.tier,
    required this.child,
    super.key,
  });

  /// The tier [child]'s display and headline roles render at.
  final CoreBreakpointTier tier;

  /// The subtree that renders at [tier].
  final Component child;

  @override
  Component build(BuildContext context) => _TypographyTierPin(
    tier: tier,
    child: div(
      [child],
      styles: const Styles(raw: {'display': 'contents'}),
      attributes: {kTypographyTierAttribute: tier.name},
    ),
  );
}

/// The tier of the nearest [TypographyTierScope] above [context] when that
/// scope sits below [boundary] — `null` when no scope is above [context],
/// or when the nearest one is above [boundary] too.
///
/// The DOM carries the tier to the elements inside the wrapper; this
/// carries it to what the subtree renders under [boundary] instead — a
/// panel it portals to the overlay host (`OverlayPortal.capture`). A scope
/// above [boundary] still reaches what renders there, so only a scope
/// between the two is left behind.
///
/// The answer turns on where the scope sits, never on its tier: a caller
/// that wraps on it keeps its wrapper while the tier changes, and only the
/// tree's shape adds or drops it.
CoreBreakpointTier? typographyTierBetween(
  BuildContext context,
  Element boundary,
) {
  final scope = context
      .getElementForInheritedComponentOfExactType<_TypographyTierPin>();
  // Both are ancestors of [context], so the deeper one is the nearer.
  if (scope == null || scope.depth <= boundary.depth) return null;

  return (context.dependOnInheritedElement(scope) as _TypographyTierPin).tier;
}

/// A [TypographyTierScope]'s tier, for the components below it.
class _TypographyTierPin extends InheritedComponent {
  const _TypographyTierPin({required this.tier, required super.child});

  final CoreBreakpointTier tier;

  @override
  bool updateShouldNotify(covariant _TypographyTierPin oldComponent) =>
      tier != oldComponent.tier;
}
