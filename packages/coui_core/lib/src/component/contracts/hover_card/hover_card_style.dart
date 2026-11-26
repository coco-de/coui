/// Per-instance style for `HoverCard`.
library;

import 'package:coui_core/src/component/contracts/popup/popup_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `HoverCard` should render.
///
/// The floating panel box is a composed `Popup`, so its chrome (background,
/// border, radius, shadow, padding, width bounds, content colour) is not
/// re-declared here: it flows through the nested [panelStyle]
/// ([CorePopupStyle]) slot and is forwarded raw to `Popup`, the single source
/// of truth for that box (child-component-composition). [defaultPanelStyle]
/// states only what a hover card does differently from a bare `Popup` — it
/// sizes to its content under a ceiling — and every other field inherits
/// `CorePopupStyle`'s own default.
///
/// Placement and timing stay flat: [placementOffset] is the native overlay
/// positioning value, and `openDelay` / `closeDelay` are treated as chrome
/// here — overlay timing tokens belong with the visual surface they govern.
/// Behavioural fields (`trigger`, `content`, `onClose`) and the semantic
/// enum (`placement`) stay flat on the widget.
///
/// HoverCard has no visual variant, so there is no `defaultsByVariant` map.
///
/// ```text
/// design system default (this class' static const defaultX)
///   → CoreHoverCardTheme.style                  // 프로젝트 공통
///   → parent component slot override
///   → widget.hoverCardStyle                     // 인스턴스별
/// ```
@immutable
class CoreHoverCardStyle implements CoreStyle<CoreHoverCardStyle> {
  /// Creates a [CoreHoverCardStyle].
  const CoreHoverCardStyle({
    this.panelStyle,
    this.placementOffset,
    this.openDelay,
    this.closeDelay,
    this.transitionDuration,
  });

  // ─── Design-system defaults ───────────────────────────────────────
  // Variant-independent defaults live as static const here so Flutter
  // and Web resolvers share a single source of truth.

  /// Default panel chrome — the composed `Popup`'s panel box is the single
  /// source of truth, so this carries only the two deliberate hover-card
  /// overrides:
  ///
  /// * `minWidth` = 0 — a hover card sizes to its content; it is not
  ///   min-width-clamped like a dropdown panel's `CorePopupStyle` default.
  /// * `maxWidth` = 256 — without a cap the panel expands to fit its content
  ///   on a single line; long rich text would push it off-screen on Web
  ///   (where the portal mounts to the viewport) and break Flutter Embed
  ///   previews (where the stage's `ViewConstraints` clip overflow).
  ///
  /// Every other panel field — corner (panel role, 12), fill
  /// (`surfaceBright`), border, shadow, content padding (16), content colour
  /// — is left `null` so `Popup`'s resolver fills it from [CorePopupStyle]'s
  /// own defaults, the same face every floating panel carries.
  static const CorePopupStyle defaultPanelStyle = CorePopupStyle(
    minWidth: 0,
    maxWidth: CoreSpace.space256,
  );

  /// Default placement-axis offset between the trigger edge and the
  /// floating panel (4 logical px) — applied along the placement axis
  /// (top/bottom or left/right depending on `CorePopoverPlacement`), the
  /// same distance every floating panel keeps from its trigger.
  static const double defaultPlacementOffset = CoreSpace.space4;

  /// Default delay before showing the hover card after pointer enter
  /// (500 ms).
  static const Duration defaultOpenDelay = Duration(
    milliseconds: CoreDuration.slow,
  );

  /// Default delay before hiding the hover card after pointer exit
  /// (500 ms).
  static const Duration defaultCloseDelay = Duration(
    milliseconds: CoreDuration.slow,
  );

  /// Default fade/scale transition duration for panel enter/exit
  /// (200 ms).
  static const Duration defaultTransitionDuration = Duration(
    milliseconds: CoreDuration.normal,
  );

  // ── Slot Styles (nested) ─────────────────────

  /// Look of the hover card panel, which is a `Popup` — fill, border,
  /// corners, shadow, padding, width limits, content colour. Passed to the
  /// `Popup` as is. `null` → [defaultPanelStyle] (which itself leaves most
  /// fields to `CorePopupStyle`'s defaults).
  ///
  /// One slot for the whole panel, per child-component-composition.
  final CorePopupStyle? panelStyle;

  // ── Layout / timing ──────────────────────────

  /// Placement-axis offset between the trigger edge and the floating
  /// panel override — projected onto the placement axis (top/bottom or
  /// left/right). The native overlay positioning value (not a child-gap
  /// slot).
  final double? placementOffset;

  /// Delay before showing the hover card after pointer enter.
  final Duration? openDelay;

  /// Delay before hiding the hover card after pointer exit.
  final Duration? closeDelay;

  /// Panel enter/exit transition duration override.
  final Duration? transitionDuration;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested [panelStyle] is merged
  /// recursively.
  @override
  CoreHoverCardStyle merge(CoreHoverCardStyle? other) {
    if (other == null) return this;
    return CoreHoverCardStyle(
      panelStyle: _mergePopup(panelStyle, other.panelStyle),
      placementOffset: other.placementOffset ?? placementOffset,
      openDelay: other.openDelay ?? openDelay,
      closeDelay: other.closeDelay ?? closeDelay,
      transitionDuration: other.transitionDuration ?? transitionDuration,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreHoverCardStyle copyWith({
    CorePopupStyle? panelStyle,
    double? placementOffset,
    Duration? openDelay,
    Duration? closeDelay,
    Duration? transitionDuration,
  }) {
    return CoreHoverCardStyle(
      panelStyle: panelStyle ?? this.panelStyle,
      placementOffset: placementOffset ?? this.placementOffset,
      openDelay: openDelay ?? this.openDelay,
      closeDelay: closeDelay ?? this.closeDelay,
      transitionDuration: transitionDuration ?? this.transitionDuration,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreHoverCardStyle &&
          runtimeType == other.runtimeType &&
          panelStyle == other.panelStyle &&
          placementOffset == other.placementOffset &&
          openDelay == other.openDelay &&
          closeDelay == other.closeDelay &&
          transitionDuration == other.transitionDuration;

  @override
  int get hashCode => Object.hash(
    panelStyle,
    placementOffset,
    openDelay,
    closeDelay,
    transitionDuration,
  );

  static CorePopupStyle? _mergePopup(
    CorePopupStyle? base,
    CorePopupStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}
