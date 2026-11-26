import 'package:coui_core/src/component/contracts/semantics/core_semantic_role.dart';
import 'package:meta/meta.dart';

/// Optional accessibility / DOM metadata for `CoreFrameContract`.
///
/// Kept as a single object so the common 99 % of frames carry no
/// extra noise on their constructor — only the special cases that
/// need ARIA roles, page-anchor IDs, or test hooks pass an `a11y`
/// value.
///
/// Maps to:
/// - Web: HTML `role` / `id` attributes plus arbitrary `aria-*` /
///   `data-*` keys via [attributes].
/// - Flutter: the corresponding `Semantics` properties (Web-only
///   fields like [id] and `data-*` are ignored).
///
/// Visual styling is **not** part of this object — `tag` is on the
/// frame itself (it's a SEO / semantic-structure decision, not
/// metadata) and any `class` / `style` keys in [attributes] are
/// rejected by lint to keep the design contract closed.
@immutable
class CoreFrameA11y {
  /// Creates a [CoreFrameA11y].
  const CoreFrameA11y({
    this.role,
    this.label,
    this.id,
    this.attributes,
  });

  /// What this frame announces itself to be.
  ///
  /// Platform-neutral: each adapter turns it into an ARIA `role`
  /// attribute (Web) or a `SemanticsRole` / semantics flag (Flutter).
  /// It was a raw ARIA `String` until the two platforms diverged into
  /// 94 Web role sites and zero Flutter ones — a platform-neutral
  /// package holding one platform's vocabulary, which
  /// `core/layer-mapping.md` forbids.
  ///
  /// Several roles carry structural obligations that Flutter enforces
  /// with a debug assert — see [CoreSemanticRole]. A frame that does
  /// not own the subtree those obligations describe should not state
  /// the role.
  final CoreSemanticRole? role;

  /// Accessible label / `aria-label`. Mirrors `Semantics.label` on
  /// Flutter.
  final String? label;

  /// DOM `id` — Web-only. Used for in-page anchors, JS DOM lookup,
  /// or test hooks (`getElementById`). Ignored on Flutter.
  final String? id;

  /// Arbitrary HTML attributes — `aria-*` and `data-*` keys only.
  /// Web-only; ignored on Flutter. Lint enforces that `class` and
  /// `style` keys never appear here, so visual styling cannot leak
  /// in via the attributes map.
  final Map<String, String>? attributes;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CoreFrameA11y &&
        other.role == role &&
        other.label == label &&
        other.id == id &&
        _mapEquals(other.attributes, attributes);
  }

  @override
  int get hashCode => Object.hash(
    role,
    label,
    id,
    attributes == null ? null : _hashMap(attributes!),
  );

  static bool _mapEquals(Map<String, String>? a, Map<String, String>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      if (a[key] != b[key]) return false;
    }
    return true;
  }

  static int _hashMap(Map<String, String> m) {
    var h = 0;
    for (final entry in m.entries) {
      h ^= entry.key.hashCode ^ entry.value.hashCode;
    }
    return h;
  }
}
