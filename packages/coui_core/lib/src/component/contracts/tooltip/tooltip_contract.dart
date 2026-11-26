/// Platform-independent contract for unified tooltip components.
library;

import 'package:coui_core/src/component/contracts/tooltip/core_tooltip_position.dart';
import 'package:coui_core/src/component/contracts/tooltip/tooltip_style.dart';
import 'package:coui_core/src/motion/duration_token.dart';

/// Contract for a unified tooltip component.
///
/// Per Epic #1302, every chrome / dimensional / surface-effect
/// override flows through the single [tooltipStyle] field — see
/// [CoreTooltipStyle] for the merge chain. Behaviour fields
/// (position / message / child / tooltipChild) stay flat.
///
/// Type parameters:
/// - [W] — platform widget type (Flutter `Widget`, Web `Component`).
abstract interface class CoreTooltipContract<W> {
  /// Hover wait before the tooltip opens — the cursor must rest on the
  /// trigger for this long. Single source for both platforms (Flutter
  /// `Tooltip.waitDuration` default / Web hover-wait timer), so the
  /// timing can never silently diverge.
  static const Duration defaultWaitDuration = Duration(
    milliseconds: CoreDuration.fast,
  );

  /// Linger after the cursor leaves before the close starts — the
  /// bubble stays fully visible for this window (Flutter
  /// `Tooltip.showDuration` default, consumed by `Hover` as the exit
  /// delay / Web linger timer).
  static const Duration defaultShowDuration = Duration(
    milliseconds: CoreDuration.fast,
  );

  /// Floor on the open window — leaving the trigger before this much
  /// wall-clock has passed since the cursor arrived holds the bubble for
  /// the remainder instead of starting the close. Zero means no floor,
  /// so the close always begins after [defaultShowDuration].
  static const Duration defaultMinDuration = .zero;

  /// Enter animation duration (fade / scale in).
  static const Duration defaultOpenAnimationDuration = Duration(
    milliseconds: CoreDuration.fast,
  );

  /// Close window — wall-clock the panel stays mounted after the close
  /// starts. The visible motion runs over the first 2/3 of it
  /// (`Interval(0, 2/3)` on Flutter, shortened `transition-duration`
  /// on Web).
  static const Duration defaultCloseAnimationDuration = Duration(
    milliseconds: CoreDuration.instant,
  );

  /// The text message displayed in the tooltip.
  String get message;

  /// Custom tooltip content widget (alternative to message).
  W? get tooltipChild;

  /// The trigger element that activates the tooltip.
  W? get child;

  /// Position of the tooltip relative to the trigger.
  CoreTooltipPosition get position;

  /// Hover wait before the bubble opens — the cursor must rest on the
  /// trigger this long, so gliding across adjacent tooltipped items
  /// opens nothing in passing. `null` defers to [defaultWaitDuration].
  Duration? get waitDuration;

  /// Linger after the cursor leaves before the close starts — the bubble
  /// stays fully visible for this window, so brief leaves and
  /// trigger-to-trigger handoffs do not blink. `null` defers to
  /// [defaultShowDuration].
  Duration? get showDuration;

  /// Floor on the open window measured from the moment the cursor
  /// arrived — a quick leave holds the bubble for the remainder rather
  /// than closing immediately. `null` defers to [defaultMinDuration].
  Duration? get minDuration;

  /// Per-instance tooltip style covering panel chrome + dimensional
  /// + surface effects + nested labelStyle.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreTooltipTheme.style
  ///   → parent component slot override
  ///   → widget.tooltipStyle
  /// ```
  ///
  /// Named [tooltipStyle] (not `style`) so the Web base class
  /// `UiComponent.style: List<Styling>?` still works without
  /// colliding.
  CoreTooltipStyle? get tooltipStyle;
}
