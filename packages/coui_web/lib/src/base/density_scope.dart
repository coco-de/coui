import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_dom_utils.dart';
import 'package:jaspr/jaspr.dart';

/// Makes the active density available to a subtree, and switches it.
///
/// Named and shaped identically to the Flutter scope so an app reads the
/// same call on both platforms. What differs is only the transport, which
/// is what each framework already offers: Flutter rebuilds with a new
/// theme, and here the document gains an attribute that the stylesheet's
/// `[data-coui-density="…"]` rules key off — the rules that re-point the
/// spacing, control-row and corner variables.
///
/// It is an ambient scope rather than a module-level variable for the
/// reason `SurfaceStyleScope` is: a Jaspr app can be server-rendered, and
/// a server handles requests concurrently — a global "current density"
/// would let one request overwrite another's.
class DensityScope extends InheritedComponent {
  /// Creates a scope publishing [density] to [child].
  const DensityScope({required this.density, required super.child, super.key});

  /// The density in effect for this subtree.
  final CoreDensity density;

  /// The density in effect at [context], or the default when none is set.
  static CoreDensity of(BuildContext context) =>
      context.dependOnInheritedComponentOfExactType<DensityScope>()?.density ??
      .defaultDensity;

  /// Switches the whole document to [density].
  ///
  /// The default density clears the attribute instead of writing its name:
  /// the base rules already describe it, so leaving an attribute behind
  /// would mean the "authored values" state is spelled two ways.
  static void setDensity(CoreDensity density) {
    if (density == .defaultDensity) {
      removeDocumentAttribute(kDensityAttribute);
      return;
    }

    setDocumentAttribute(kDensityAttribute, density.name);
  }

  /// The density the document currently carries.
  static CoreDensity currentDensity() {
    final value = documentAttribute(kDensityAttribute);

    for (final density in CoreDensity.values) {
      if (density.name == value) return density;
    }

    return .defaultDensity;
  }

  @override
  bool updateShouldNotify(DensityScope oldComponent) =>
      density != oldComponent.density;
}
