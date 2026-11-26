import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_dom_utils.dart';
import 'package:jaspr/jaspr.dart';

/// Makes the active surface style available to a subtree, and switches it.
///
/// Named and shaped identically to the Flutter scope so an app reads the
/// same call on both platforms. What differs is only the transport, which
/// is what each framework already offers: Flutter rebuilds with a new
/// theme, and here the document gains an attribute that the stylesheet's
/// `[data-coui-style="…"]` rules key off.
///
/// It is an ambient scope rather than a module-level variable because a
/// Jaspr app can be server-rendered, and a server handles requests
/// concurrently — a global "current style" would let one request overwrite
/// another's. A scope travels down a tree that is rebuilt per request, so
/// the isolation is automatic.
class SurfaceStyleScope extends InheritedComponent {
  /// Creates a scope publishing [surfaceStyle] to [child].
  const SurfaceStyleScope({
    required this.surfaceStyle,
    required super.child,
    super.key,
  });

  /// The style in effect for this subtree.
  final CoreSurfaceStyleId surfaceStyle;

  /// The style in effect at [context], or the default when none is set.
  static CoreSurfaceStyleId of(BuildContext context) =>
      context
          .dependOnInheritedComponentOfExactType<SurfaceStyleScope>()
          ?.surfaceStyle ??
      .defaultId;

  /// Switches the whole document to [style].
  ///
  /// The default style clears the attribute instead of writing its name:
  /// the base rules already describe it, so leaving an attribute behind
  /// would mean the "no style" state is spelled two ways.
  static void setSurfaceStyle(CoreSurfaceStyleId style) {
    if (style == .defaultId) {
      removeDocumentAttribute(kSurfaceStyleAttribute);
      return;
    }

    setDocumentAttribute(kSurfaceStyleAttribute, style.name);
  }

  /// The style the document currently carries.
  static CoreSurfaceStyleId currentSurfaceStyle() {
    final value = documentAttribute(kSurfaceStyleAttribute);

    for (final id in CoreSurfaceStyleId.values) {
      if (id.name == value) return id;
    }

    return .defaultId;
  }

  @override
  bool updateShouldNotify(SurfaceStyleScope oldComponent) =>
      surfaceStyle != oldComponent.surfaceStyle;
}
