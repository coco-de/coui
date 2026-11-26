import 'package:jaspr/jaspr.dart';

/// Ambient scope for where `coui_web` components fetch their static assets
/// from.
///
/// A shipped component that pulls an asset from a CDN hands that request
/// to every consumer — a CSP that allows no third-party origin, an offline
/// build, or a policy against third-party requests has no way out unless
/// the origin can be changed. This scope is that way out: mirror the asset
/// set on your own origin and point the scope at it. With no scope, or a
/// scope that leaves a source null, components keep the public CDN default.
///
/// A scope rather than a constructor parameter because the capability is
/// Web-only — Flutter bundles the same assets locally and needs no source —
/// so a per-widget parameter would break the two platforms' shared
/// signature. A scope rather than a global because a server renders many
/// requests at once and a global would let one request's choice leak into
/// another's; the tree is rebuilt per request, so a scope is isolated for
/// free (the same reasoning as `CouiLocalizationsScope`).
///
/// ```dart
/// CouiAssetSourceScope(
///   flagIconsBaseUrl: '/assets/flags/4x3',
///   child: MyPage(),
/// )
/// ```
class CouiAssetSourceScope extends InheritedComponent {
  /// Creates a scope exposing asset sources to [child].
  const CouiAssetSourceScope({
    required super.child,
    this.flagIconsBaseUrl,
    super.key,
  });

  /// The public CDN directory `PhoneInput` loads its flag SVGs from — the
  /// `flag-icons` 4:3 set, the same set the Flutter `PhoneInput` bundles,
  /// so both platforms draw identical flags.
  static const String defaultFlagIconsBaseUrl =
      'https://cdn.jsdelivr.net/gh/lipis/flag-icons@7.2.3/flags/4x3';

  /// Directory holding the `flag-icons` 4:3 SVGs, one `<code>.svg` per
  /// lower-case ISO country code, without a trailing slash. Null keeps
  /// [defaultFlagIconsBaseUrl].
  final String? flagIconsBaseUrl;

  /// The flag directory in effect for [context] — the nearest scope's
  /// [flagIconsBaseUrl], or [defaultFlagIconsBaseUrl].
  static String flagIconsBaseUrlOf(BuildContext context) =>
      context
          .dependOnInheritedComponentOfExactType<CouiAssetSourceScope>()
          ?.flagIconsBaseUrl ??
      defaultFlagIconsBaseUrl;

  @override
  bool updateShouldNotify(covariant CouiAssetSourceScope oldComponent) =>
      flagIconsBaseUrl != oldComponent.flagIconsBaseUrl;
}
