import 'package:jaspr/jaspr.dart';

import 'coui_localizations.dart';

/// Ambient scope for [CouiLocalizations].
///
/// Mirrors `Theme` / `FormControllerScope` / `RecentColorsScope` 1:1: pure
/// metadata, no DOM of its own — descendants read the value via
/// [CouiLocalizations.of] / [CouiLocalizations.maybeOf].
///
/// `CoUIWeb` installs one of these automatically (seeded from
/// `CoUIWeb.locale` or browser negotiation). A consuming SSR backend that
/// needs per-request locale isolation (distinct from `CoUIWeb`'s own
/// client-only negotiation) wraps its own instance *inside* `CoUIWeb.child`
/// so it shadows the app-root default for that subtree:
///
/// ```dart
/// CoUIWeb(
///   theme: ThemeData.coui,
///   child: CouiLocalizationsScope(
///     localizations: localizationsForRequest(request), // per-request, pure function
///     child: MyPage(),
///   ),
/// )
/// ```
class CouiLocalizationsScope extends InheritedComponent {
  /// Creates a scope exposing [localizations] to [child].
  const CouiLocalizationsScope({
    required this.localizations,
    required super.child,
    super.key,
  });

  /// The localizations instance shared with descendants.
  final CouiLocalizations localizations;

  @override
  bool updateShouldNotify(covariant CouiLocalizationsScope oldComponent) {
    return localizations != oldComponent.localizations;
  }
}
