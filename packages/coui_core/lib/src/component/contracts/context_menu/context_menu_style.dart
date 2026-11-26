/// Per-instance style for `ContextMenu`.
library;

import 'package:coui_core/src/component/contracts/menu/menu_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/opacity_scale.dart';
import 'package:coui_core/src/effect/shadow_scale.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_role.dart';
import 'package:meta/meta.dart';

/// Immutable style for a `ContextMenu`.
///
/// A `ContextMenu` is a `Menu` shown in a pointer-anchored overlay, so its
/// panel chrome is the composed `Menu`'s chrome. Following child-component-
/// composition (nest the *direct* child's `CoreXxxStyle`), this carries the
/// whole [menuStyle] ([CoreMenuStyle] — panel box via `popupStyle`, the
/// per-row `MenuItem` chrome via `itemStyle`, the divider, the heading
/// typography …) raw-forwarded to the inner `Menu`.
///
/// The rest of the style is the look of the opt-in lift (`liftChild`): how
/// far the pressed child rises ([liftScale], [liftDuration]), what it rises
/// over ([liftDimOpacity]) and with ([liftCast], [liftRadius]), and how small
/// the panel folds as the menu closes ([retractScale]). They are visual
/// values, so an app restyles them here — per instance, or for every context
/// menu through the theme — and both seats read them from the resolved style.
/// What stays on the contract is the timing of the gesture the lift waits on
/// (the hold, the delay before the rise, the slops): it is behaviour, and the
/// two seats must keep it identical whatever a style says. Semantic enums
/// live on the widget.
///
/// Kept as its own type (not shared with `CoreDropdownMenuStyle`) so the two
/// anchored-menu surfaces can diverge — a context menu opens flush at the
/// pointer (no trigger↔panel gap, hence no `menuOffset` field), a dropdown
/// beneath its trigger.
///
/// ```text
/// CoreContextMenuStyle.defaultX                    // 디자인 시스템 기본값
///   → CoreContextMenuTheme.style                   // 컨텍스트 메뉴 공통
///   → widget.contextMenuStyle                      // 인스턴스별
///
/// CoreMenuTheme.style                              // 전역 메뉴 공통
///   → CoreContextMenuTheme.style.menuStyle         // 컨텍스트 메뉴 공통
///   → widget.contextMenuStyle.menuStyle            // 인스턴스별
/// ```
@immutable
class CoreContextMenuStyle implements CoreStyle<CoreContextMenuStyle> {
  /// Creates a [CoreContextMenuStyle].
  const CoreContextMenuStyle({
    this.menuStyle,
    this.liftScale,
    this.liftDuration,
    this.liftDimOpacity,
    this.liftCast,
    this.liftRadius,
    this.retractScale,
  });

  /// Design-system default for the composed `Menu`. Empty on purpose —
  /// a context menu *is* a `Menu` in a pointer-anchored overlay and
  /// states nothing about its chrome, so every field comes from
  /// `CoreMenuStyle`'s own defaults and the per-instance [menuStyle]
  /// merges on top. Naming the (empty) partial keeps a future
  /// divergence a one-line edit here instead of a resolver reaching
  /// into `CoreMenuStyle.defaultX` field by field.
  static const CoreMenuStyle defaultMenuStyle = CoreMenuStyle();

  /// The size the lifted child reaches, as a multiple of its own — 1.04.
  ///
  /// A designer-judgement value: native iOS lifts a row to about 1.04×. A
  /// larger factor reads as a pop-out and crowds the menu; a smaller one is
  /// lost under the shadow.
  static const double defaultLiftScale = 1.04;

  /// How long the lift takes to reach its full size — [CoreDuration.moderate]
  /// (300 ms), along `CoreContextMenuLift.easing`. Releasing early takes the
  /// same time to come back, from where it got to.
  ///
  /// A designer-judgement value: shorter reads as a snap, longer runs into the
  /// hold (a touch's rise is held to what the hold leaves after the delay,
  /// `CoreContextMenuLift.riseDuration`). A transition-tier duration, so
  /// reduced motion makes it instant: the lifted state is still shown, without
  /// the motion that gets there.
  static const Duration defaultLiftDuration = Duration(
    milliseconds: CoreDuration.moderate,
  );

  /// How dark the page behind the lifted child gets — [CoreOpacity.opacity20]
  /// of the `scrim` colour, at full lift.
  ///
  /// A designer-judgement value, and deliberately lighter than the modal
  /// scrim ([CoreOpacity.scrim], 30%): the page must stay readable, since the
  /// menu is about something on it, and a dim as strong as the modal's reads
  /// as a dialog.
  static const double defaultLiftDimOpacity = CoreOpacity.opacity20;

  /// The shadow the lifted child casts, at full lift — [CoreShadow.lg], the
  /// level of the menu panel that opens beside it.
  ///
  /// The lift scales every layer's offset, blur, spread and opacity by its
  /// progress, so the shadow grows with the child instead of fading in under
  /// it. A designer-judgement value: [CoreShadow.md] is a quieter lift,
  /// [CoreShadow.xl] a higher one.
  static const List<CoreShadowLayer> defaultLiftCast = CoreShadow.lg;

  /// The corner radius of the box the lifted child's shadow is cast from —
  /// [CoreRadiusRole.surface] (16).
  ///
  /// The lift cannot know the shape of an arbitrary child, so the shadow
  /// hugs a rounded box of this radius around it; the child itself is never
  /// clipped. A designer-judgement value: it matches a card or a grouped row,
  /// and a child with a very different shape (a circle, a pill) gets a shadow
  /// that is visibly a rounded box.
  static const CoreBorderRadius defaultLiftRadius = CoreBorderRadius.all(
    CoreRadiusRole.surface,
  );

  /// The size the menu panel and the preview shrink to as they fold back into
  /// the child when the menu closes, as a multiple of their own — 0.3. They
  /// reach it as they finish fading out, so the last of it is not seen.
  ///
  /// A designer-judgement value: nearer 1 reads as the ordinary
  /// shrink-and-fade of a popup, nearer 0 as being sucked into the source. How
  /// long the fold takes is the panel's own `closeAnimationDuration`.
  static const double defaultRetractScale = 0.3;

  /// Style for the `Menu` inside — the whole look of the menu: the panel
  /// box ([CoreMenuStyle.popupStyle]), each `MenuItem` row
  /// ([CoreMenuStyle.itemStyle]), the divider, the heading text and so on.
  /// Passed as is to the inner `Menu`'s `menuStyle`, where the `Menu` lays
  /// it over `CoreMenuTheme.style`; `null` leaves the inner `Menu` at its
  /// design-system defaults.
  final CoreMenuStyle? menuStyle;

  /// The size the lifted child reaches, as a multiple of its own.
  /// `null` defers to [defaultLiftScale].
  ///
  /// Held to 1 or more by the engine (`CoreContextMenuLift.scale`): a smaller
  /// number would make the child shrink as it "rises".
  final double? liftScale;

  /// How long the lift takes to reach its full size, and to come back from
  /// where it got to when a press ends early. `null` defers to
  /// [defaultLiftDuration].
  ///
  /// A touch's rise has to end before the hold does, so that the child is
  /// fully lifted when the menu appears. A longer duration is therefore held
  /// to what the hold leaves after the delay — on both seats, from one Core
  /// function (`CoreContextMenuLift.riseDuration`), and never to more than
  /// stated here. An opening with no hold has nothing to finish before and
  /// rises over the duration stated.
  ///
  /// Reduced motion reads the duration stated here, by the tier it belongs to
  /// (`CoreReducedMotion`): a rise of at most `transitionCeilingMs` is
  /// transition motion and becomes a jump (the lifted state is still shown); a
  /// longer one is display timing the policy leaves alone, and a held touch's
  /// is then shortened to the room the hold leaves like any other.
  final Duration? liftDuration;

  /// How dark the page behind the lifted child gets at full lift, as a share
  /// of the `scrim` colour. `null` defers to [defaultLiftDimOpacity].
  ///
  /// Held to 0..1 by the engine (`CoreContextMenuLift.dim`).
  final double? liftDimOpacity;

  /// The shadow the lifted child casts at full lift. `null` defers to
  /// [defaultLiftCast]; an empty list lifts the child without a cast.
  final List<CoreShadowLayer>? liftCast;

  /// The corner radius of the box the lifted child's shadow is cast from.
  /// `null` defers to [defaultLiftRadius].
  final CoreBorderRadius? liftRadius;

  /// The size the menu panel and the preview shrink to as they fold back into
  /// the child, as a multiple of their own. `null` defers to
  /// [defaultRetractScale].
  ///
  /// Held to 0..1 by the engine (`CoreContextMenuRetract.endScaleOf`).
  final double? retractScale;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. The nested [menuStyle] slot is
  /// merged recursively.
  @override
  CoreContextMenuStyle merge(CoreContextMenuStyle? other) {
    if (other == null) return this;
    return CoreContextMenuStyle(
      menuStyle: _mergeMenu(menuStyle, other.menuStyle),
      liftScale: other.liftScale ?? liftScale,
      liftDuration: other.liftDuration ?? liftDuration,
      liftDimOpacity: other.liftDimOpacity ?? liftDimOpacity,
      liftCast: other.liftCast ?? liftCast,
      liftRadius: other.liftRadius ?? liftRadius,
      retractScale: other.retractScale ?? retractScale,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreContextMenuStyle copyWith({
    CoreMenuStyle? menuStyle,
    double? liftScale,
    Duration? liftDuration,
    double? liftDimOpacity,
    List<CoreShadowLayer>? liftCast,
    CoreBorderRadius? liftRadius,
    double? retractScale,
  }) {
    return CoreContextMenuStyle(
      menuStyle: menuStyle ?? this.menuStyle,
      liftScale: liftScale ?? this.liftScale,
      liftDuration: liftDuration ?? this.liftDuration,
      liftDimOpacity: liftDimOpacity ?? this.liftDimOpacity,
      liftCast: liftCast ?? this.liftCast,
      liftRadius: liftRadius ?? this.liftRadius,
      retractScale: retractScale ?? this.retractScale,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreContextMenuStyle &&
          runtimeType == other.runtimeType &&
          menuStyle == other.menuStyle &&
          liftScale == other.liftScale &&
          liftDuration == other.liftDuration &&
          liftDimOpacity == other.liftDimOpacity &&
          _sameShadow(liftCast, other.liftCast) &&
          liftRadius == other.liftRadius &&
          retractScale == other.retractScale;

  @override
  int get hashCode => Object.hashAll([
    menuStyle,
    liftScale,
    liftDuration,
    liftDimOpacity,
    ...?liftCast,
    liftRadius,
    retractScale,
  ]);

  /// Layer-wise comparison — a shadow stack is a list, and two equal
  /// stacks built separately are different objects.
  static bool _sameShadow(
    List<CoreShadowLayer>? a,
    List<CoreShadowLayer>? b,
  ) {
    if (identical(a, b)) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }

    return true;
  }

  static CoreMenuStyle? _mergeMenu(CoreMenuStyle? base, CoreMenuStyle? other) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}
