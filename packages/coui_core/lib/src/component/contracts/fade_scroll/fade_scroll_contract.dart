/// Platform-independent contract for the unified fade-scroll component.
library;

import 'package:coui_core/src/component/contracts/fade_scroll/fade_scroll_direction.dart';
import 'package:coui_core/src/component/contracts/fade_scroll/fade_scroll_style.dart';

/// Contract for a unified `FadeScroll`.
///
/// Wraps a scrollable [child] and overlays a soft fade gradient at the
/// scroll edges to indicate that more content exists past the visible
/// viewport. Both edges fade dynamically based on scroll position — the
/// start fade is hidden when scrolled to the very top/left, and the end
/// fade is hidden when scrolled to the very bottom/right.
///
/// All chrome / dimensional overrides flow through the single
/// [fadeScrollStyle] field (Phase 6f). Behavioural fields
/// (`child`, `showScrollbar`) and the semantic enum (`direction`)
/// stay flat on the widget. The Flutter-only `ScrollController` is
/// exposed as a widget-level field rather than a contract member —
/// Web has no equivalent.
///
/// Type parameter:
/// - [W] — platform widget type (Flutter `Widget`, Web `Component`).
abstract interface class CoreFadeScrollContract<W> {
  /// Scrollable content the fade is applied to.
  W get child;

  /// Scroll axis. Defaults to [CoreFadeScrollDirection.defaultDirection].
  CoreFadeScrollDirection get direction;

  /// Whether to show the native scrollbar inside the scroll viewport. When
  /// `false` (default) the viewport hides its scrollbar but stays scrollable;
  /// the fade gradient itself communicates the overflow.
  bool get showScrollbar;

  /// Per-instance chrome / dimensional style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// CoreFadeScrollStyle.defaultX               ← static const default
  ///   → CoreComponentTheme.fadeScroll.style    ← project-level override
  ///   → widget.fadeScrollStyle                 ← per-instance override
  /// ```
  CoreFadeScrollStyle? get fadeScrollStyle;
}
