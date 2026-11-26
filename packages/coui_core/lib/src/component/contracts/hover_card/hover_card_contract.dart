/// Cross-platform contract for unified hover card components.
library;

import 'package:coui_core/coui_core.dart';

/// Contract for a unified hover card component.
///
/// Per Epic #1302 chrome / dimensional / timing overrides flow through
/// the single [hoverCardStyle] field — see [CoreHoverCardStyle] for
/// the merge chain. Behavioural fields (`trigger`, `content`,
/// `onClose`, `openDelay`, `closeDelay`) and the semantic enum
/// (`placement`) stay flat on the widget.
///
/// Type parameters:
/// - [W]: Widget type (Flutter: `Widget`, Web: `Component`).
/// - [Cb]: Callback type (Flutter: `VoidCallback`, Web: `CoreVoidCallback`).
///
/// Implementations render a floating card that appears on hover
/// over the [trigger] element.
abstract interface class CoreHoverCardContract<W, Cb> {
  /// The trigger element that activates the hover card.
  W get trigger;

  /// The content displayed inside the hover card.
  W get content;

  /// The preferred placement relative to the trigger.
  CorePopoverPlacement get placement;

  /// Delay before showing the hover card after mouse enters the trigger.
  ///
  /// When `null`, implementations fall back to
  /// [CoreHoverCardStyle.openDelay] (via the theme/widget style merge
  /// chain) or the platform default.
  Duration? get openDelay;

  /// Delay before hiding the hover card after the mouse exits.
  ///
  /// When `null`, implementations fall back to
  /// [CoreHoverCardStyle.closeDelay] (via the theme/widget style merge
  /// chain) or the platform default.
  Duration? get closeDelay;

  /// Callback invoked when the hover card is closed.
  Cb? get onClose;

  /// Per-instance chrome / dimensional / timing style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreHoverCardTheme.style
  ///   → parent component slot override
  ///   → widget.hoverCardStyle
  /// ```
  CoreHoverCardStyle? get hoverCardStyle;
}
