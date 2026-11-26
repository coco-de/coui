/// Platform-independent contract for carousel components.
///
/// Defines the interface that all carousel implementations
/// (Flutter, Web) must satisfy.
library;

import 'package:coui_core/src/component/contracts/carousel/carousel_alignment.dart';
import 'package:coui_core/src/component/contracts/carousel/carousel_item_builder.dart';
import 'package:coui_core/src/component/contracts/carousel/carousel_size.dart';
import 'package:coui_core/src/component/contracts/carousel/carousel_size_constraint.dart';
import 'package:coui_core/src/component/contracts/carousel/carousel_style.dart';
import 'package:coui_core/src/component/contracts/carousel/carousel_transition.dart';
import 'package:coui_core/src/component/contracts/carousel/carousel_variant.dart';
import 'package:coui_core/src/component/contracts/scrollable_client/core_axis.dart';
import 'package:coui_core/src/motion/easing_scale.dart';

/// Contract for a carousel component.
///
/// Every chrome / dimensional override flows through the single
/// [carouselStyle] field — see [CoreCarouselStyle]. Everything on this
/// interface is either content, layout policy, or behaviour, and both
/// platforms honour all of it.
///
/// Type parameters:
/// - [W] - platform widget type (Flutter `Widget`, Web `Component`).
///
/// The only carousel field kept off this contract is the Flutter
/// `controller`: programmatic control is a Flutter runtime-infrastructure
/// type whose Web counterpart is the stateless DOM itself.
abstract interface class CoreCarouselContract<W> {
  // === Content ===

  /// Direct list of items — the eager cross-platform content API.
  List<W>? get items;

  /// Builds slides on demand, as an alternative to [items].
  ///
  /// Paired with [itemCount] so a bounded (`wrap: false`) carousel knows
  /// where the list ends.
  CoreCarouselItemBuilder<W>? get itemBuilder;

  /// Total number of items.
  int? get itemCount;

  // === Transition ===

  /// Motion used between slides (`sliding` / `fading`) plus the gap between
  /// adjacent slides.
  CoreCarouselTransition get transition;

  /// Easing curve for slide transitions.
  CoreCubicBezier get curve;

  /// Duration of a slide transition.
  Duration get speed;

  // === Auto-play ===

  /// Duration each item is displayed before auto-advancing.
  ///
  /// Absent while auto-playing means
  /// [CoreCarouselStyle.defaultAutoplayInterval].
  Duration? get duration;

  /// Per-index override of [duration].
  CoreCarouselDurationBuilder? get durationBuilder;

  /// Transition duration used for auto-play advances. Falls back to [speed].
  ///
  /// Also extends the interval between auto-play advances, so a slow
  /// auto-play transition does not eat into the slide's display time.
  Duration? get autoplaySpeed;

  /// Whether to auto-play. `null` derives it from the presence of an
  /// interval: `autoPlay ?? (durationBuilder != null || duration != null)`.
  ///
  /// The flag is nullable so the two platforms can agree on one gate. They
  /// did not before: Flutter never read this field and auto-played whenever
  /// a [duration] was given, while Web gated on the field and ignored a
  /// lone [duration]. `autoPlay: true` did nothing on Flutter and
  /// `duration:` alone did nothing on Web — the same code auto-played on
  /// exactly one platform, in opposite directions.
  ///
  /// Deriving the default from the interval keeps both prior behaviours
  /// intact (a caller who passed only [duration] still auto-plays; a caller
  /// who passed neither still does not) while making the explicit values
  /// mean what they say on both sides — including `false`, which previously
  /// could not turn Flutter's auto-play off at all.
  bool? get autoPlay;

  /// Whether auto-play advances backwards.
  bool get autoplayReverse;

  /// Whether to wait one full [duration] before the first auto-advance.
  bool get waitOnStart;

  /// Whether to show slide indicators.
  bool get showIndicators;

  /// Whether to show prev / next navigation buttons.
  ///
  /// Nullable so the answer can come from [variant]: `slide` shows them
  /// and `banner` does not, because two 32-px discs on an 88-px strip
  /// leave no strip. A stated value wins either way — the same shape
  /// `enabled` takes on the controls in this kit, where the default is
  /// derived rather than fixed.
  bool? get showNavigation;

  // === Navigation ===

  /// Current slide index.
  int get currentIndex;

  /// Called when the current index changes.
  void Function(int)? get onIndexChanged;

  // === Layout ===

  /// Where the active slide sits inside the viewport when a slide is
  /// smaller than the viewport.
  CoreCarouselAlignment get alignment;

  /// What kind of thing is being cycled — arbitrary slides, or a thin
  /// promotional strip.
  ///
  /// A layout choice, not chrome, and it decides two things at once:
  /// `slide` floats the dots over the viewport (anchored by
  /// [CoreCarouselStyle.indicatorInset]) and shows the prev / next
  /// controls; `banner` puts the dots in flow under it (separated by
  /// [CoreCarouselStyle.indicatorBelowGapStyle]) and hides the controls,
  /// because an 88-px strip has room for neither.
  CoreCarouselVariant get variant;

  /// Which set of interior metrics the parts inside the carousel use.
  ///
  /// Not the carousel's own extent — that comes from its parent. Today it
  /// picks the indicator dot size.
  CoreCarouselSize get size;

  /// Axis the carousel scrolls along.
  CoreAxis get direction;

  /// Whether item order is reversed along the carousel axis.
  bool get reverse;

  /// How far one slide extends along the carousel axis.
  CoreCarouselSizeConstraint get sizeConstraint;

  // === Behavior ===

  /// Whether items wrap around (infinite scroll).
  bool get wrap;

  /// Whether to pause auto-play on hover.
  bool get pauseOnHover;

  /// Whether the carousel can be dragged / swiped.
  bool get draggable;

  /// Whether to drop drag inertia on release and snap straight away.
  bool get disableDraggingVelocity;

  /// Whether a single drag gesture may advance at most one slide.
  bool get disableOverheadScrolling;

  /// Per-instance carousel chrome / dimensional / slot style.
  CoreCarouselStyle? get carouselStyle;
}
