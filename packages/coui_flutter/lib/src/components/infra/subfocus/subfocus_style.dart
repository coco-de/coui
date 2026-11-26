import 'package:coui_flutter/coui_flutter.dart';

/// Default focus-ring corner radius for [Subfocus] — promoted from
/// [CoreSubfocusStyle.defaultFocusRingRadius] so the resolver owns its
/// fallback (Epic #1603 C4).
const _kDefaultFocusRingRadius = CoreSubfocusStyle.defaultFocusRingRadius;

/// Resolved focus-ring chrome for [Subfocus].
///
/// Output of [resolveSubfocus] — the merge chain has been applied
/// plus the `CoreSubfocusStyle.defaultX` fallbacks:
///
/// ```text
/// CoreSubfocusStyle.defaultX
///   → CoreSubfocusScopeTheme.style
///   → widget.subfocusStyle
/// ```
///
/// Widget tree (`co_subfocus` renders the resolved value):
///
/// ```text
/// MouseRegion
///   └─ GestureDetector
///        └─ FocusOutline (focusOutlineStyle)   // child unified widget
///             └─ child
/// ```
///
/// [focusOutlineStyle] is a nested [CoreFocusOutlineStyle] slot forwarded
/// straight to `FocusOutline.focusOutlineStyle` — the ring colour /
/// width / animation are owned by the already-unified `FocusOutline`,
/// so the resolver only fills the corner-radius axis it controls.
class ResolvedSubfocus {
  /// Creates a [ResolvedSubfocus].
  const ResolvedSubfocus({required this.focusOutlineStyle});

  /// Paint-ready focus-outline slot — fed straight to
  /// `FocusOutline.focusOutlineStyle` so the focus ring's corner
  /// radius matches the resolved subfocus chrome.
  final CoreFocusOutlineStyle focusOutlineStyle;
}

/// Resolves [ResolvedSubfocus] for the given [context].
///
/// Single entry point for the subfocus item Style slot — applies the
/// merge chain (`CoreSubfocusScopeTheme.style` → `subfocusStyle`) and
/// the static-const default fallbacks.
ResolvedSubfocus resolveSubfocus(
  BuildContext context, {
  CoreSubfocusStyle? subfocusStyle,
}) {
  final coreTheme = Theme.of(context).coreComponentTheme?.subfocusScope;

  // Merge chain: theme.style → subfocusStyle.
  final merged = resolveStyleChain(const CoreSubfocusStyle(), [
    coreTheme?.style,
    subfocusStyle,
  ]);

  final focusRingRadius = merged.focusRingRadius ?? _kDefaultFocusRingRadius;

  return ResolvedSubfocus(
    focusOutlineStyle: CoreFocusOutlineStyle(borderRadius: focusRingRadius),
  );
}
