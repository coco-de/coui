import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/display/loading_region/loading_region_style.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/jaspr.dart' hide Text;

/// Announces "loading" once for an area whose content has not arrived.
///
/// Wrap the skeletons standing in for one area. The region emits one
/// `role="status"` element whose text is [semanticLabel] (or the locale's
/// loading label), visually hidden; the area itself sits under
/// `aria-hidden` while the region speaks for it, and the skeletons inside
/// read [LoadingRegionScope] and drop their own announcement.
///
/// Draws nothing. Box layout (flex, grid, flow) sees the content as the
/// region's parent's own child; a parent's sibling-based spacing
/// (`space-y-*`, `divide-*`) does not reach it, so give the region's parent a
/// `gap` instead.
///
/// Example:
/// ```dart
/// LoadingRegion(
///   semanticLabel: 'Loading orders',
///   child: div([for (var i = 0; i < 5; i++) Skeleton(height: '20px')]),
/// )
/// ```
class LoadingRegion extends StatelessComponent
    implements CoreLoadingRegionContract<Component> {
  /// Creates a [LoadingRegion].
  const LoadingRegion({required this.child, super.key, this.semanticLabel});

  @override
  final String? semanticLabel;

  @override
  final Component child;

  static const _kDiv = 'div';
  static const _kRoleAttr = 'role';
  static const _kAriaHiddenAttr = 'aria-hidden';

  @override
  Component build(BuildContext context) {
    // An enclosing region already speaks for this area and already hides
    // it, so a nested one adds nothing but a second announcement.
    if (LoadingRegionScope.existsAbove(context)) return child;

    return Component.fragment([
      Component.element(
        tag: _kDiv,
        classes: buildLoadingRegionAnnouncerClassName(),
        attributes: {_kRoleAttr: CoreSemanticRole.status.ariaRole},
        children: [
          // Read at render time: a default parameter value cannot reach
          // the active locale.
          Text(semanticLabel ?? CouiLocalizations.of(context).loadingLabel),
        ],
      ),
      Component.element(
        tag: _kDiv,
        classes: buildLoadingRegionContentClassName(),
        attributes: const {_kAriaHiddenAttr: 'true'},
        children: [LoadingRegionScope(child: child)],
      ),
    ]);
  }
}

/// Tells the skeletons below that an enclosing [LoadingRegion] announces
/// for them.
///
/// Named and shaped like the Flutter counterpart so the two platforms read
/// the same; the transport is whatever each framework already offers.
///
/// Not exported from the package — wrapping a subtree in the scope alone
/// would silence its skeletons with nothing announcing in their place.
class LoadingRegionScope extends InheritedComponent {
  /// Creates a scope declaring a region announces for [child].
  const LoadingRegionScope({required super.child, super.key});

  /// Whether an enclosing [LoadingRegion] already announces this area.
  static bool existsAbove(BuildContext context) =>
      context.dependOnInheritedComponentOfExactType<LoadingRegionScope>() !=
      null;

  @override
  bool updateShouldNotify(LoadingRegionScope oldComponent) => false;
}
