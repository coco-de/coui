/// Per-instance style for `ScrollArea`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/scrollbar/scrollbar_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/opacity_scale.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `ScrollArea` should render.
///
/// `CoreScrollAreaStyle` carries the viewport size constraints plus a
/// nested [scrollbarStyle] slot for the composed `Scrollbar` (child
/// component composition — the scrollbar surface is drawn by the
/// unified `Scrollbar` on both platforms, so its chrome flows through
/// that component's own Style rather than flat duplicate fields here).
/// Behavioural fields (`child`, `controller`, `showScrollbar`) and the
/// semantic enum (`direction`) remain flat on the widget — they are
/// not chrome.
///
/// ```text
/// CoreScrollAreaStyle.defaultX             ← static const default
///   → CoreComponentTheme.scrollArea.style  ← project-level override
///   → widget.scrollAreaStyle               ← per-instance override
/// ```
@immutable
class CoreScrollAreaStyle implements CoreStyle<CoreScrollAreaStyle> {
  /// Creates a [CoreScrollAreaStyle].
  const CoreScrollAreaStyle({
    this.height,
    this.maxHeight,
    this.scrollbarStyle,
  });

  // ─── Design-system defaults ────────────────────────────────────────

  /// Default nested scrollbar chrome — a *partial* `CoreScrollbarStyle`
  /// carrying only the fields where `ScrollArea` diverges from the
  /// `Scrollbar` defaults; the rest stay null so the composed
  /// `Scrollbar`'s own resolver fills them.
  ///
  /// * thumb colour — `onSurface` faded to 25 % (the legacy
  ///   `rgb(var(--bc) / 0.25)` translucency) instead of the 50 %
  ///   `Scrollbar` default.
  static const CoreScrollbarStyle defaultScrollbarStyle = CoreScrollbarStyle(
    thumbColor: CoreColor.token(
      CoreColors.onSurface,
      opacity: CoreOpacity.opacity25,
      fallbacks: [CoreColors.outline],
    ),
  );

  // ─── Fields ────────────────────────────────────────────────────────

  /// Fixed viewport height in logical pixels. When null the scroll area
  /// takes its parent's height (or its child's natural height when the
  /// parent sets no limit).
  ///
  /// **No default, and must not have one.** Both fields together are a
  /// switch, not a measurement: Flutter builds a `ConstrainedBox` only
  /// under `if (resolved.height != null || resolved.maxHeight != null)`
  /// and returns the unwrapped scroll view otherwise, and Web writes the
  /// `height` declaration only inside `if (height != null)`. A constant
  /// would make that branch permanently taken, so every scroll area in
  /// the tree would be clamped to one height regardless of the space its
  /// parent gave it — and a scroll area that ignores its parent is the
  /// one thing this component must not do.
  final double? height;

  /// Maximum viewport height in logical pixels. When set, the scroll
  /// area takes the child's natural height up to this maximum and scrolls
  /// when the child is taller. Combines with [height]: when both are set,
  /// each platform applies both.
  ///
  /// **No default, and must not have one** — it is the other half of the
  /// switch described on [height], and a constant would additionally
  /// introduce a scroll boundary where the caller asked for none.
  final double? maxHeight;

  /// Style of the `Scrollbar` inside — thumb colour, thickness, corner
  /// radius, minimum length, track colour. When null falls back to
  /// [defaultScrollbarStyle]; partial overrides merge on top of it.
  final CoreScrollbarStyle? scrollbarStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreScrollAreaStyle merge(CoreScrollAreaStyle? other) {
    if (other == null) return this;
    return CoreScrollAreaStyle(
      height: other.height ?? height,
      maxHeight: other.maxHeight ?? maxHeight,
      scrollbarStyle:
          scrollbarStyle?.merge(other.scrollbarStyle) ?? other.scrollbarStyle,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreScrollAreaStyle copyWith({
    double? height,
    double? maxHeight,
    CoreScrollbarStyle? scrollbarStyle,
  }) {
    return CoreScrollAreaStyle(
      height: height ?? this.height,
      maxHeight: maxHeight ?? this.maxHeight,
      scrollbarStyle: scrollbarStyle ?? this.scrollbarStyle,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CoreScrollAreaStyle) return false;
    return other.height == height &&
        other.maxHeight == maxHeight &&
        other.scrollbarStyle == scrollbarStyle;
  }

  @override
  int get hashCode => Object.hash(height, maxHeight, scrollbarStyle);
}
