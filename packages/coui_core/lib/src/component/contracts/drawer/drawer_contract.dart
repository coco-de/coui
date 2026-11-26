/// Cross-platform contract for unified drawer components.
library;

import 'package:coui_core/src/component/contracts/drawer/drawer_side.dart';
import 'package:coui_core/src/component/contracts/drawer/drawer_style.dart';

/// Contract for a unified drawer panel.
///
/// Per Epic #1302, every chrome / dimensional / barrier / animation
/// override flows through the single [drawerStyle] field — see
/// [CoreDrawerStyle] for the merge chain. Behaviour fields
/// (`barrierDismissible`, `draggable`, `dismissOnEscape`) and the
/// semantic [side] enum stay flat on the contract.
///
/// Type parameters:
/// - [W] — Widget type (Flutter `Widget`, Web `Component`).
abstract interface class CoreDrawerContract<W> {
  /// Default drag-to-dismiss threshold, as a fraction of the panel's
  /// extent on the slide axis (`0.5` → dragging past 50 % dismisses).
  /// Shared by the Flutter / Web widget const constructors so the same
  /// drag distance dismisses on both.
  ///
  /// A gesture threshold is compared against a live drag fraction and
  /// draws nothing at any value, so it lives on the widget plane
  /// (`core/style-contract.md`: Style slots carry visual chrome only)
  /// rather than in `CoreDrawerStyle`.
  static const double defaultDragDismissThreshold = 0.5;

  /// Default release speed, in logical **pixels per second**, at or above
  /// which a drag toward the docked edge dismisses the panel however short it
  /// was — a flick.
  ///
  /// Distance alone cannot see intent: a quick, short stroke covers a sliver
  /// of the panel and the finger is gone, so judged by distance it snaps
  /// back against what the gesture plainly said. The figure (0.4 px/ms) is a
  /// designer-judgement feel value rather than a derived one: well above a
  /// deliberate slow drag and well below a hard flick. Like
  /// [defaultDragDismissThreshold] it is compared against a live gesture and
  /// draws nothing, so it lives on the widget plane rather than in
  /// `CoreDrawerStyle`.
  static const double defaultDismissVelocity = 400;

  /// Default for [rubberBand] — off, so a draggable drawer keeps stopping dead
  /// at its dock until a caller opts in. Shared by the Flutter / Web widget
  /// const constructors and the Flutter `openDrawer` parameter so the three
  /// cannot silently diverge.
  ///
  /// Whether a drawer stretches at its dock is a matter of feel, and so is
  /// this default. **Designer-judgement value (디자이너 판단 값):** one
  /// constant to flip.
  static const bool defaultRubberBand = false;

  /// Whether releasing a drag that moved the panel [dragDistance] toward the
  /// edge it hides behind dismisses it.
  ///
  /// Two things dismiss, either one enough:
  ///
  /// * **Distance** — the drag covers [threshold] of [panelExtent], the
  ///   panel's own extent on the slide axis. Both platforms ask with the
  ///   panel's own extent — not the viewport's — so a short sheet dismisses
  ///   after the same share of its height on both. A panel with no extent has
  ///   covered nothing.
  /// * **Speed** — the pointer leaves at [velocity] or faster toward that
  ///   edge ([velocityThreshold], [defaultDismissVelocity] unless a caller
  ///   states its own), provided the panel has actually moved toward it.
  ///
  /// [velocity] is in logical **pixels per second** and signed by the way the
  /// panel hides: positive toward the edge it hides behind, so a release
  /// moving back toward the docked edge is negative and never dismisses by
  /// speed. Callers re-sign the platform's own reading to this convention —
  /// Flutter reports pixels per second along the screen axis, a browser's
  /// event deltas are per millisecond and have to be scaled up first. The
  /// distance test is unchanged by speed: a long drag released while moving
  /// back still dismisses, exactly as it did before speed existed.
  static bool dismissesOnRelease({
    required double dragDistance,
    required double panelExtent,
    required double threshold,
    double velocity = 0,
    double velocityThreshold = defaultDismissVelocity,
  }) {
    final share = panelExtent == 0 ? 0.0 : dragDistance / panelExtent;
    if (share >= threshold) return true;

    // A flick has to have moved the panel outward: a speed with nothing
    // behind it (a press that never went anywhere, a pull toward the docked
    // edge) is not a throw.
    return dragDistance > 0 && velocity >= velocityThreshold;
  }

  /// Default for [fillSafeArea] — off, so a drawer keeps every existing
  /// behaviour until a caller opts in. Shared by the Flutter / Web widget
  /// const constructors and the Flutter `openDrawer` parameter so the
  /// three cannot silently diverge.
  static const bool defaultFillSafeArea = false;

  /// Default for [showDragHandle] — off, so a drawer draws no grab handle
  /// until a caller asks for one. Shared by both widgets' const
  /// constructors so the two cannot silently diverge.
  static const bool defaultShowDragHandle = false;

  /// Default for [showCloseButton] — on, so a titled drawer keeps the close
  /// button its header has always had.
  static const bool defaultShowCloseButton = true;

  /// The content displayed inside the drawer panel.
  W get content;

  /// The side from which the drawer slides in.
  CoreDrawerSide get side;

  /// Optional title text shown at the top of the drawer.
  String? get title;

  /// Optional supporting text under [title] in the header — what the
  /// panel is for, in a sentence ("Pick the currency you will receive").
  /// The header renders when either [title] or [description] is set.
  String? get description;

  /// Optional footer row under the content — a divider, then the slot
  /// right-aligned inside [CoreDrawerStyle.footerPadding] (the confirm and
  /// cancel buttons of a panel that finishes a task). Absent by default;
  /// nothing is drawn without it. The slot is one widget: a caller with
  /// several buttons passes a row of its own.
  W? get footer;

  /// Whether to draw the grab handle — a pill on the panel edge that faces
  /// the viewport centre: the top of a bottom sheet, the bottom of a top
  /// sheet, the inner edge of a side drawer. It says the panel can be
  /// dragged away; dragging it, like dragging anywhere on the panel outside
  /// a scrolling body, dismisses past [dragDismissThreshold] — or on a flick
  /// ([defaultDismissVelocity]) — while [draggable]. Defaults to `false`
  /// ([defaultShowDragHandle]).
  bool get showDragHandle;

  /// Whether the header carries its close button. Defaults to `true`
  /// ([defaultShowCloseButton]). A panel without one still closes from the
  /// barrier, the drag, Escape (Web) and the back gesture (Flutter).
  bool get showCloseButton;

  /// Whether tapping the dimmed barrier behind the drawer dismisses
  /// it. Defaults to `true`.
  bool get barrierDismissible;

  /// Whether the user can drag the drawer's edge past
  /// [dragDismissThreshold] — or flick it toward that edge faster than
  /// [defaultDismissVelocity] — to dismiss it. Defaults to `true`.
  bool get draggable;

  /// Drag distance past which releasing dismisses the drawer,
  /// expressed as a fraction of the panel's extent on the slide axis.
  /// Only consulted while [draggable].
  ///
  /// This is the distance half of the release rule only: a release moving
  /// toward the edge at [defaultDismissVelocity] or faster dismisses short
  /// of it ([dismissesOnRelease]).
  double get dragDismissThreshold;

  /// Whether dragging the panel past its dock — further open than fully open —
  /// stretches it instead of stopping dead, and letting go pulls it back.
  /// Defaults to `false` ([defaultRubberBand]). Only consulted while
  /// [draggable].
  ///
  /// The panel's far edge follows the pointer with less and less return,
  /// bounded by a fraction of the panel's own extent, while the docked edge
  /// stays on the viewport edge (`CoreDrawerRubberBand`). It changes nothing
  /// about what dismisses: a pull toward the docked edge is judged by
  /// [dismissesOnRelease] with or without a rubber band, and a release with
  /// the panel stretched is a panel that has covered no distance toward the
  /// edge it hides behind, so it never dismisses — a fling in the open
  /// direction included.
  bool get rubberBand;

  /// Whether the Escape key dismisses the drawer (Web only —
  /// Flutter dismiss is handled via `PopScope`). Defaults to `true`.
  bool get dismissOnEscape;

  /// Whether opening the drawer scales the app content behind it
  /// down (the shadcn "zoom-out" backdrop transform — scale +
  /// animated corner clip). A sheet is a drawer without this
  /// transform. Defaults to `true`. Requires the app-level backdrop
  /// host (installed by the CoUI app shell); silently no-ops without
  /// one.
  bool get transformBackdrop;

  /// Whether the panel's surface (fill, border, radius, shadow) bleeds
  /// into the system safe area — the home indicator / gesture bar under a
  /// bottom sheet, the notch beside a side drawer — on the one edge the
  /// panel is docked to. Defaults to `false`
  /// ([CoreDrawerContract.defaultFillSafeArea]).
  ///
  /// The docked edge is the one the panel slides in from: `bottom` for a
  /// bottom sheet, `left` for a left drawer, and so on. The other three
  /// edges are unaffected.
  ///
  /// Flutter — off (the default): the whole panel sits *inside* the safe
  /// area, so it floats above a bottom inset and the scrim shows in the
  /// strip beneath it. On: the panel reaches the screen edge and the
  /// unconsumed inset becomes padding *inside* the panel, so its content
  /// still clears the inset. The panel's fixed extent (`panelHeight` /
  /// `panelWidth`) includes that bleed.
  ///
  /// Web — the panel is always flush with the viewport edge and adds no
  /// inset of its own, so off changes nothing. On: the docked edge is
  /// padded by the matching `env(safe-area-inset-*)`, keeping content
  /// clear of the inset. That is a no-op unless the page opts into
  /// `viewport-fit=cover`, which is what makes the browser report a
  /// non-zero inset.
  bool get fillSafeArea;

  /// Per-instance drawer style covering panel chrome + dimensional
  /// + barrier + animation overrides plus nested title style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreDrawerTheme.style
  ///   → parent component slot override
  ///   → widget.drawerStyle
  /// ```
  ///
  /// Named [drawerStyle] (not `style`) so the Web base class
  /// `UiComponent.style: List<Styling>?` still works without
  /// colliding.
  CoreDrawerStyle? get drawerStyle;
}
