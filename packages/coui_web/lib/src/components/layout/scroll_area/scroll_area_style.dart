library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `ScrollArea`.
///
/// DOM shape (the composed `Scrollbar` owns the scroll container and
/// its scoped scrollbar skin — `ScrollArea` contributes only the size
/// constraints and the `relative` positioning context):
///
/// ```text
/// Scrollbar root (<div>)                // composed unified Scrollbar —
///   │                                   //   owns overflow classes +
///   │                                   //   scoped scrollbar skin.
///   │                                   //   ScrollArea forwards
///   │                                   //   `root.className` (relative)
///   │                                   //   + `root.inlineStyles`
///   │                                   //   (height / max-height) into
///   │                                   //   its caller-chrome params.
///   └─ widget.child                     // user-supplied scrollable
///                                       //   content (no chrome —
///                                       //   caller owns).
/// ```
class ResolvedScrollArea implements WebResolvedChrome {
  /// Creates a [ResolvedScrollArea].
  const ResolvedScrollArea({required this.root, required this.scrollbarStyle});

  /// ScrollArea's own contribution to the composed `Scrollbar` root —
  /// `relative` (positioning context for descendant overlays) plus the
  /// inline size constraints (`height` / `max-height`).
  @override
  final WebElementChrome root;

  /// Nested chrome for the composed `Scrollbar` — the ScrollArea
  /// defaults merged with the caller's partial overrides, raw-forwarded
  /// so `Scrollbar`'s own resolver emits the thumb / track skin.
  final CoreScrollbarStyle scrollbarStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedScrollArea] for `ScrollArea` (Web).
///
/// Merge chain:
///
/// ```text
/// design-system default (CoreScrollAreaStyle.defaultX)
///   → theme.coreComponentTheme.scrollArea.style
///   → widget.scrollAreaStyle
/// ```
///
/// The widget MUST NOT touch
/// `context.theme.coreComponentTheme.scrollArea` directly — this
/// resolver is the single encapsulation point.
ResolvedScrollArea resolveScrollArea(
  BuildContext context, {
  CoreScrollAreaStyle? scrollAreaStyle,
}) {
  final scrollAreaTheme = context.theme.coreComponentTheme?.scrollArea;

  // ─── Merge chain ──────────────────────────────────────
  // 2-stage merge chain — variant 가 없는 컴포넌트.
  final merged = resolveStyleChain(const CoreScrollAreaStyle(), [
    scrollAreaTheme?.style,
    scrollAreaStyle,
  ]);

  // ─── Resolved chrome values ───────────────────────────
  final height = merged.height;
  final maxHeight = merged.maxHeight;

  // Composite nested slot — the ScrollArea-divergent defaults merged
  // with the caller's partial overrides, then raw-forwarded (the
  // composed scrollbar's own resolver emits the thumb / track skin).
  final scrollbarStyle = CoreScrollAreaStyle.defaultScrollbarStyle.merge(
    merged.scrollbarStyle,
  );

  // ─── Local builders ───────────────────────────────────

  /// Composes ScrollArea's className contribution — `relative` so any
  /// descendant overlay can be positioned against the scroll area. The
  /// overflow primitives come from the composed `Scrollbar`.
  String buildRootClassName() => WebLayout.relative;

  /// Composes ScrollArea's inline-CSS contribution — the size
  /// constraints only. All scrollbar styling flows through the nested
  /// [CoreScrollbarStyle] slot into the composed `Scrollbar`.
  Styles buildRootInlineStyles() {
    final raw = <String, String>{};
    if (height != null) {
      raw['height'] = '${height / kRemDivisor}rem';
    }
    if (maxHeight != null) {
      raw['max-height'] = '${maxHeight / kRemDivisor}rem';
    }
    return Styles(raw: raw);
  }

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedScrollArea(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: buildRootInlineStyles(),
    ),
    scrollbarStyle: scrollbarStyle,
  );
}
