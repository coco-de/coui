/// Style-slot single entry point for the Web `Swiper` — the gesture
/// wrapper's chrome and the nested style forwarded to the composed
/// `Drawer`, which draws the panel and its grab handle.
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:jaspr/dom.dart' show Styles;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `Swiper`.
///
/// DOM shape (the composed unified `Drawer` — via `openDrawer` — owns
/// the panel surface, barrier, slide animation, drag-to-dismiss and the
/// grab handle; `Swiper` renders only the swipe-gesture wrapper):
///
/// ```text
/// root (<div>)                          // swipe-gesture wrapper
///   └─ child wrapper (<div contents>)   // gesture listeners host
///        └─ widget.child
/// Drawer(showDragHandle:, drawerStyle:) (portalled by openDrawer)
///   └─ widget.overlayContent
/// ```
class ResolvedSwiper implements WebResolvedChrome {
  /// Creates a [ResolvedSwiper].
  const ResolvedSwiper({
    required this.root,
    required this.child,
    required this.drawerStyle,
  });

  /// Paint-ready chrome for the gesture-wrapper root `<div>`.
  @override
  final WebElementChrome root;

  /// Paint-ready chrome for the inline child wrapper `<div>` —
  /// `contents` so the wrapper yields layout to the user child while
  /// hosting the swipe listeners.
  final WebElementChrome child;

  /// Nested chrome for the composed `Drawer` — the variant partial
  /// (`CoreSwiperStyle.defaultsByVariant`), the handle values still
  /// stated through the deprecated flat `dragHandle*` fields, and the
  /// caller's `drawerStyle` slot (which wins), raw-forwarded so the
  /// drawer's own resolver emits the panel chrome and the handle.
  final CoreDrawerStyle drawerStyle;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedSwiper] for the given [context].
///
/// Merge chain:
///
/// ```text
/// CoreSwiperStyle.defaultsByVariant[variant] (drawer partial)
///   → theme.coreComponentTheme.swiper.style
///   → theme.coreComponentTheme.swiper.variantStyles[variant]
///   → widget.swiperStyle
/// ```
ResolvedSwiper resolveSwiper(
  BuildContext context, {
  required CoreSwiperVariant variant,
  required CoreSwiperPosition position,
  CoreSwiperStyle? swiperStyle,
}) {
  final swiperTheme = context.theme.coreComponentTheme?.swiper;

  // ─── Stage 1 RESOLVE — merge chain ────────────────────
  final merged = resolveStyleChain(const CoreSwiperStyle(), [
    swiperTheme?.style,
    swiperTheme?.variantStyles?[variant],
    swiperStyle,
  ]);

  // Composite nested slot — the variant's divergent drawer chrome, the
  // handle values a caller still states the deprecated way, then the
  // caller's own `drawerStyle` (which wins), raw-forwarded: the composed
  // drawer's resolver emits the panel chrome and the handle.
  final drawerStyle = CoreSwiperStyle.defaultsByVariant[variant]!
      // The deprecated spelling is still honoured until it is removed.
      // ignore: deprecated_member_use
      .merge(merged.legacyDragHandleStyle)
      .merge(merged.drawerStyle);

  // ─── Local builders ───────────────────────────────────

  /// Composes the gesture-wrapper root `<div>` Tailwind className.
  String buildRootClassName() => WebLayout.relative;

  /// Composes the inline child wrapper `<div>` Tailwind className —
  /// `contents` so the wrapper yields layout to the user child and the
  /// swipe-gesture event listeners stay attached to a single subtree
  /// host.
  String buildChildClassName() => WebLayout.contents;

  // ─── Compose paint-ready chrome ───────────────────────
  return ResolvedSwiper(
    root: WebElementChrome(
      className: buildRootClassName(),
      inlineStyles: Styles(
        raw: {
          'touch-action': position.isHorizontal
              ? 'pan-y pinch-zoom'
              : 'pan-x pinch-zoom',
        },
      ),
    ),
    drawerStyle: drawerStyle,
    child: WebElementChrome(className: buildChildClassName()),
  );
}
