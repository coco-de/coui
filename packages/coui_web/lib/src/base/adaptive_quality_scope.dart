import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_dom_utils.dart';
import 'package:jaspr/jaspr.dart';

/// The quality tier the surfaces under it are drawn at, and the way to ask the
/// governor behind it to stop measuring.
///
/// Named and shaped like the Flutter scope so an app reads the same call on
/// both platforms. Only the transport differs, and it is the one each
/// framework already has: Flutter rebuilds with a theme whose material has
/// gone without what the tier gives up, and here the document gains the
/// attribute (`kQualityAttribute`) the stylesheet's rules and the refraction
/// host key off — which is how a tier reaches markup the server already
/// rendered, and why a step costs no rebuild of the page.
///
/// It is an ambient scope rather than a module-level variable for the reason
/// `SurfaceStyleScope` is: a Jaspr app can be server-rendered, and a server
/// handles requests concurrently — a global "current tier" would let one
/// request overwrite another's.
///
/// Components do not read this.
class AdaptiveQualityScope extends InheritedComponent {
  /// Creates a scope publishing [tier] to [child]. Mounted by `CoUIWeb`.
  const AdaptiveQualityScope({
    required this.tier,
    required this.opensHold,
    required super.child,
    super.key,
  });

  /// The tier the surfaces are drawn at, with a reduce-transparency preference
  /// already taken into it.
  final CoreQualityTier tier;

  /// Opens a hold on the governor behind the scope, or null when none runs.
  final CoreQualityHold Function()? opensHold;

  /// The tier at [context], or the default when no scope is above it.
  static CoreQualityTier of(BuildContext context) =>
      context
          .dependOnInheritedComponentOfExactType<AdaptiveQualityScope>()
          ?.tier ??
      CoreQualityTier.defaultTier;

  /// Stops frame measurement until the returned hold is released.
  ///
  /// Wrap heavy work of the app's own that competes with the glass for the
  /// device, so the slowdown is not mistaken for a device that cannot draw it.
  /// Returns a hold that holds nothing where no governor runs, so the call
  /// needs no guard.
  static CoreQualityHold holdMeasurement(BuildContext context) {
    final scope =
        context
                .getElementForInheritedComponentOfExactType<
                  AdaptiveQualityScope
                >()
                ?.component
            as AdaptiveQualityScope?;

    return scope?.opensHold?.call() ?? CoreQualityHold.none();
  }

  /// The tier the document carries, as the stylesheet sees it.
  static CoreQualityTier currentTier() {
    final value = documentAttribute(kQualityAttribute);

    for (final tier in CoreQualityTier.values) {
      if (tier.name == value) return tier;
    }

    return CoreQualityTier.defaultTier;
  }

  @override
  bool updateShouldNotify(AdaptiveQualityScope oldComponent) =>
      tier != oldComponent.tier;
}
