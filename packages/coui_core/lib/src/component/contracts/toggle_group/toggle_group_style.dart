/// Per-instance style for `ToggleGroup`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/clickable/clickable_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/shadow_scale.dart';
import 'package:coui_core/src/effect/state_layer.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/size/component_size.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/size/size.dart' show CoreSize;
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart' show CoreSpace;
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/font_weight.dart' show CoreFontWeight;
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `ToggleGroup` should render.
///
/// `CoreToggleGroupStyle` is **platform-neutral**. Every chrome /
/// dimensional field is a nullable override so a single style object can
/// flow through the merge chain:
///
/// ```text
/// design system default (this class' `static const defaultX`)
///   → CoreToggleGroupTheme.style                  // 프로젝트 공통
///   → widget.toggleGroupStyle                     // 인스턴스별
/// ```
///
/// The shape is a track (`surfaceContainer`) with a small inset
/// holding the segments; the chosen segment is a raised face
/// (`surfaceRaised`) carrying the smallest shadow step. A disabled group
/// goes flat: the track takes `disabledContainer`, the chosen face drops
/// to `surfaceContainerHigh` without a shadow, and every glyph takes
/// `disabledContent`.
///
/// The track sits on the page, so it takes the page's container step. On a
/// floating panel (`surfaceBright`) that step equals the panel itself in
/// Dark, so a component that puts the group inside a panel (the time and
/// colour pickers) states the track one step higher, at
/// `surfaceContainerHigh`, in its own nested slot default.
@immutable
class CoreToggleGroupStyle implements CoreStyle<CoreToggleGroupStyle> {
  /// Creates a [CoreToggleGroupStyle].
  const CoreToggleGroupStyle({
    this.backgroundColor,
    this.selectedColor,
    this.disabledBackgroundColor,
    this.disabledSelectedColor,
    this.selectedShadow,
    this.borderRadius,
    this.itemBorderRadius,
    this.padding,
    this.itemPadding,
    this.labelPadding,
    this.itemHeight,
    this.itemSpacing,
    this.selectedFontWeight,
    this.transitionDuration,
    this.stateLayerColor,
    this.stateLayer,
    this.labelTextStyle,
    this.selectedLabelTextStyle,
    this.disabledLabelTextStyle,
    this.iconStyle,
    this.selectedIconStyle,
    this.disabledIconStyle,
    this.clickableStyle,
  });

  // ─── Design-system defaults ───────────────────────────────────────

  /// Default track fill — `surfaceContainer`, the page's container step.
  /// A group composed into a floating panel takes `surfaceContainerHigh`
  /// from its parent's nested slot default instead (see the class note).
  static const CoreColor defaultBackgroundColor = CoreColor.token(
    CoreColors.surfaceContainer,
  );

  /// Default fill of the chosen segment — the raised face
  /// (`surfaceRaised`) that lifts off the track.
  static const CoreColor defaultSelectedColor = CoreColor.token(
    CoreColors.surfaceRaised,
  );

  /// Default track fill of a disabled group (`disabledContainer`).
  static const CoreColor defaultDisabledBackgroundColor = CoreColor.token(
    CoreColors.disabledContainer,
  );

  /// Default fill of the chosen segment of a disabled group — it sinks to
  /// the track step above (`surfaceContainerHigh`) and loses its shadow.
  static const CoreColor defaultDisabledSelectedColor = CoreColor.token(
    CoreColors.surfaceContainerHigh,
  );

  /// Default shadow under the chosen segment — the smallest step of the
  /// shadow scale ([CoreShadow.xs]), shared by Flutter (`BoxShadow`) and
  /// Web (`box-shadow`). A disabled group paints none.
  static const List<CoreShadowLayer> defaultSelectedShadow = CoreShadow.xs;

  /// Default track corner radius of the `md` row (10 logical px on all
  /// four corners). The `sm` row states its own (8) in [defaultsBySize].
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius10,
  );

  /// Default per-segment corner radius (6 logical px on all four
  /// corners) — the `md` track's 10 minus its 4 inset, so the segment and
  /// the track share a centre. Both size rows use it.
  static const CoreBorderRadius defaultItemBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius6,
  );

  /// Default inset between the track edge and the segments of the `md`
  /// row (4 logical px on all sides): 4 + 32 + 4 = 40, the `md` control
  /// row, so the track lines up with an `md` field or button beside it. A
  /// density leaves it where it is (the ladder does not move 4 or less).
  /// The `sm` row states its own (3) in [defaultsBySize].
  static const CoreEdgeInsets defaultPadding = CoreEdgeInsets.all(
    CoreSpace.space4,
  );

  /// Default padding inside each segment of the `md` row (2 logical px
  /// horizontal, none vertical). The segment's height is fixed and its
  /// content is centred in it, so no vertical inset is needed; a label
  /// segment's remaining horizontal inset lives on the label box
  /// ([defaultLabelPadding]). The `sm` row states none ([defaultsBySize]).
  ///
  /// An icon-only segment does not rely on this inset to be a square: a
  /// segment is never narrower than its height (see [defaultItemHeight]).
  static const CoreEdgeInsets defaultItemPadding = CoreEdgeInsets.symmetric(
    horizontal: CoreSpace.space2,
  );

  /// Default inset of the label box inside a segment (8 logical px
  /// horizontal). Painted only when the item shows its label.
  static const CoreEdgeInsets defaultLabelPadding = CoreEdgeInsets.symmetric(
    horizontal: CoreSpace.space8,
  );

  /// Default fixed segment height of the `md` row (32 logical px); content
  /// is centred vertically inside it. The `sm` row is in [defaultsBySize].
  ///
  /// The height is also the segment's minimum width on both platforms, so
  /// an icon-only segment is a square (`md` 32 × 32, `sm` 26 × 26) while a
  /// label segment wider than its height keeps its own width.
  ///
  /// The group's own row, not a control row — a theme density leaves it
  /// where it is on both platforms (the segment is a part of the track,
  /// not a field that lines up with a text field beside it).
  static const double defaultItemHeight = CoreSize.size32;

  /// Per-size rows. Only `md` and `sm` are stated; any other
  /// [CoreComponentSize] reads the `md` row (see [sizeDefaults]). A field
  /// a row does not state reads the flat `defaultX` (the `md` value).
  ///
  /// - `md` — 32 segment in a 4 inset: a 40 track, the `md` control row.
  ///   Track corner 10, segment inset 2 horizontal, `labelLarge`.
  /// - `sm` — 26 segment in a 3 inset: a 32 track, the `sm` control row,
  ///   so the group sits beside `sm` controls (an editor toolbar). Track
  ///   corner 8, no segment inset, `labelMedium`. Two sm segments plus the
  ///   2 px gap are `3 + 26 + 2 + 26 + 3 = 60`, the height of a time
  ///   picker's hour / minute tile.
  ///
  /// The `sm` inset 3 and segment 26 are the designer's numbers and are off
  /// the 4 px spacing grid and the size scale, so they are stated as
  /// literals here and nowhere else; Web emits them as lengths a density
  /// does not move. The segment corner (6) is the same in both rows.
  ///
  /// The `sm` label rows state a role only (`labelMedium`), so the size,
  /// tracking and line box come with the role while each state's colour
  /// stays the flat default's.
  static const Map<CoreComponentSize, CoreToggleGroupStyle> defaultsBySize = {
    CoreComponentSize.md: CoreToggleGroupStyle(itemHeight: defaultItemHeight),
    CoreComponentSize.sm: CoreToggleGroupStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
      padding: CoreEdgeInsets.all(3),
      itemPadding: CoreEdgeInsets.zero,
      itemHeight: 26,
      labelTextStyle: CoreTextStyle.token(CoreTextStyles.labelMedium),
      selectedLabelTextStyle: CoreTextStyle.token(CoreTextStyles.labelMedium),
      disabledLabelTextStyle: CoreTextStyle.token(CoreTextStyles.labelMedium),
    ),
  };

  /// The size row for [size]: `sm` reads its own row, every other size
  /// reads `md`.
  static CoreToggleGroupStyle sizeDefaults(CoreComponentSize size) =>
      defaultsBySize[size] ?? defaultsBySize[CoreComponentSize.md]!;

  /// Default spacing between segments (2 logical px).
  static const double defaultItemSpacing = CoreSpace.space2;

  /// Default font weight of the chosen segment's label (`semiBold`).
  static const int defaultSelectedFontWeight = CoreFontWeight.semiBold;

  /// Default chosen-state colour transition duration (150 ms).
  static const Duration defaultTransitionDuration = Duration(
    milliseconds: CoreDuration.fast,
  );

  /// Default colour of the state layer laid over a segment while the
  /// pointer is over it — `onSurface`, the ink every control's layer is
  /// made of. The layer takes the segment's own shape and sits over its
  /// face, the chosen segment's raised face included; the face colour and
  /// the shadow are unchanged. A disabled group paints none.
  static const CoreColor defaultStateLayerColor = CoreColor.token(
    CoreColors.onSurface,
  );

  /// Default weights of the segment state layer — [CoreStateLayer.subtle],
  /// the ramp the kit's other light, unfilled controls read (Chip, the
  /// ghost and outlined Button); the track and the raised face are both
  /// light surfaces. Only `hover`
  /// is read: the segment's focus is the ring and a press is the
  /// `Clickable`'s own feedback.
  static const CoreStateLayer defaultStateLayer = CoreStateLayer.subtle;

  /// Default label text style — token-backed `labelLarge` in the
  /// unchosen-segment colour (`onSurfaceVariant`).
  static const CoreTextStyle defaultLabelTextStyle = CoreTextStyle.token(
    CoreTextStyles.labelLarge,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// Default label text style of the chosen segment — `labelLarge` in
  /// `onSurface`. The resolver layers [defaultSelectedFontWeight] on top.
  static const CoreTextStyle defaultSelectedLabelTextStyle =
      CoreTextStyle.token(
        CoreTextStyles.labelLarge,
        color: CoreColor.token(CoreColors.onSurface),
      );

  /// Default label text style of a disabled group — `labelLarge` in
  /// `disabledContent`, for chosen and unchosen segments alike.
  static const CoreTextStyle defaultDisabledLabelTextStyle =
      CoreTextStyle.token(
        CoreTextStyles.labelLarge,
        color: CoreColor.token(CoreColors.disabledContent),
      );

  /// Default icon style of an unchosen segment — 16 logical px in
  /// `onSurfaceVariant`.
  static const CoreIconStyle defaultIconStyle = CoreIconStyle(
    size: CoreIconSize.size16,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// Default icon style of the chosen segment — 16 logical px in
  /// `onSurface`.
  static const CoreIconStyle defaultSelectedIconStyle = CoreIconStyle(
    size: CoreIconSize.size16,
    color: CoreColor.token(CoreColors.onSurface),
  );

  /// Default icon style of a disabled group — 16 logical px in
  /// `disabledContent`, for chosen and unchosen segments alike.
  static const CoreIconStyle defaultDisabledIconStyle = CoreIconStyle(
    size: CoreIconSize.size16,
    color: CoreColor.token(CoreColors.disabledContent),
  );

  /// Default nested [CoreClickableStyle] for the composed per-segment
  /// `Clickable`: the segment paints its own disabled state (flat track,
  /// `disabledContent` ink), so the Clickable's generic dimming is off
  /// (`disabledOpacity: 1`) — it would count the disabled look twice.
  static const CoreClickableStyle defaultClickableStyle = CoreClickableStyle(
    disabledOpacity: 1,
  );

  // ─── Fields ───────────────────────────────────────────────────────

  /// Fill of the track.
  final CoreColor? backgroundColor;

  /// Fill of the chosen segment.
  final CoreColor? selectedColor;

  /// Fill of the track of a disabled group.
  final CoreColor? disabledBackgroundColor;

  /// Fill of the chosen segment of a disabled group.
  final CoreColor? disabledSelectedColor;

  /// Shadow under the chosen segment. An empty list paints none.
  final List<CoreShadowLayer>? selectedShadow;

  /// Track corner radius.
  final CoreBorderRadius? borderRadius;

  /// Per-segment corner radius.
  final CoreBorderRadius? itemBorderRadius;

  /// Inset between the track edge and the segments.
  final CoreEdgeInsets? padding;

  /// Padding inside each segment — its uniform inset around
  /// `[icon][label box]`.
  final CoreEdgeInsets? itemPadding;

  /// Inset of the label box inside a segment (painted only when the item
  /// shows its label).
  final CoreEdgeInsets? labelPadding;

  /// Fixed segment height (logical px); content centres vertically.
  final double? itemHeight;

  /// Spacing between segments (logical px).
  final double? itemSpacing;

  /// Font weight of the chosen segment's label (CSS font-weight integer).
  final int? selectedFontWeight;

  /// Chosen-state colour transition duration.
  final Duration? transitionDuration;

  /// Colour of the state layer laid over a hovered segment.
  final CoreColor? stateLayerColor;

  /// Weights of the segment state layer (only `hover` is read).
  final CoreStateLayer? stateLayer;

  /// Label text style of unchosen segments.
  final CoreTextStyle? labelTextStyle;

  /// Label text style of the chosen segment.
  final CoreTextStyle? selectedLabelTextStyle;

  /// Label text style of a disabled group, chosen and unchosen alike.
  final CoreTextStyle? disabledLabelTextStyle;

  /// Icon style of an unchosen segment's caller-supplied icon.
  final CoreIconStyle? iconStyle;

  /// Icon style of the chosen segment's caller-supplied icon.
  final CoreIconStyle? selectedIconStyle;

  /// Icon style of a disabled group's icons, chosen and unchosen alike.
  final CoreIconStyle? disabledIconStyle;

  /// Style for each segment's `Clickable` — press scale, durations, focus
  /// ring. Laid over [defaultClickableStyle] and passed to the `Clickable`
  /// as is.
  final CoreClickableStyle? clickableStyle;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. Nested slot styles merge
  /// recursively.
  @override
  CoreToggleGroupStyle merge(CoreToggleGroupStyle? other) {
    if (other == null) return this;
    return CoreToggleGroupStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      selectedColor: other.selectedColor ?? selectedColor,
      disabledBackgroundColor:
          other.disabledBackgroundColor ?? disabledBackgroundColor,
      disabledSelectedColor:
          other.disabledSelectedColor ?? disabledSelectedColor,
      selectedShadow: other.selectedShadow ?? selectedShadow,
      borderRadius: other.borderRadius ?? borderRadius,
      itemBorderRadius: other.itemBorderRadius ?? itemBorderRadius,
      padding: other.padding ?? padding,
      itemPadding: other.itemPadding ?? itemPadding,
      labelPadding: other.labelPadding ?? labelPadding,
      itemHeight: other.itemHeight ?? itemHeight,
      itemSpacing: other.itemSpacing ?? itemSpacing,
      selectedFontWeight: other.selectedFontWeight ?? selectedFontWeight,
      transitionDuration: other.transitionDuration ?? transitionDuration,
      stateLayerColor: other.stateLayerColor ?? stateLayerColor,
      stateLayer: other.stateLayer ?? stateLayer,
      labelTextStyle: _mergeText(labelTextStyle, other.labelTextStyle),
      selectedLabelTextStyle: _mergeText(
        selectedLabelTextStyle,
        other.selectedLabelTextStyle,
      ),
      disabledLabelTextStyle: _mergeText(
        disabledLabelTextStyle,
        other.disabledLabelTextStyle,
      ),
      iconStyle: iconStyle?.merge(other.iconStyle) ?? other.iconStyle,
      selectedIconStyle:
          selectedIconStyle?.merge(other.selectedIconStyle) ??
          other.selectedIconStyle,
      disabledIconStyle:
          disabledIconStyle?.merge(other.disabledIconStyle) ??
          other.disabledIconStyle,
      clickableStyle:
          clickableStyle?.merge(other.clickableStyle) ?? other.clickableStyle,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreToggleGroupStyle copyWith({
    CoreColor? backgroundColor,
    CoreColor? selectedColor,
    CoreColor? disabledBackgroundColor,
    CoreColor? disabledSelectedColor,
    List<CoreShadowLayer>? selectedShadow,
    CoreBorderRadius? borderRadius,
    CoreBorderRadius? itemBorderRadius,
    CoreEdgeInsets? padding,
    CoreEdgeInsets? itemPadding,
    CoreEdgeInsets? labelPadding,
    double? itemHeight,
    double? itemSpacing,
    int? selectedFontWeight,
    Duration? transitionDuration,
    CoreColor? stateLayerColor,
    CoreStateLayer? stateLayer,
    CoreTextStyle? labelTextStyle,
    CoreTextStyle? selectedLabelTextStyle,
    CoreTextStyle? disabledLabelTextStyle,
    CoreIconStyle? iconStyle,
    CoreIconStyle? selectedIconStyle,
    CoreIconStyle? disabledIconStyle,
    CoreClickableStyle? clickableStyle,
  }) {
    return CoreToggleGroupStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      selectedColor: selectedColor ?? this.selectedColor,
      disabledBackgroundColor:
          disabledBackgroundColor ?? this.disabledBackgroundColor,
      disabledSelectedColor:
          disabledSelectedColor ?? this.disabledSelectedColor,
      selectedShadow: selectedShadow ?? this.selectedShadow,
      borderRadius: borderRadius ?? this.borderRadius,
      itemBorderRadius: itemBorderRadius ?? this.itemBorderRadius,
      padding: padding ?? this.padding,
      itemPadding: itemPadding ?? this.itemPadding,
      labelPadding: labelPadding ?? this.labelPadding,
      itemHeight: itemHeight ?? this.itemHeight,
      itemSpacing: itemSpacing ?? this.itemSpacing,
      selectedFontWeight: selectedFontWeight ?? this.selectedFontWeight,
      transitionDuration: transitionDuration ?? this.transitionDuration,
      stateLayerColor: stateLayerColor ?? this.stateLayerColor,
      stateLayer: stateLayer ?? this.stateLayer,
      labelTextStyle: labelTextStyle ?? this.labelTextStyle,
      selectedLabelTextStyle:
          selectedLabelTextStyle ?? this.selectedLabelTextStyle,
      disabledLabelTextStyle:
          disabledLabelTextStyle ?? this.disabledLabelTextStyle,
      iconStyle: iconStyle ?? this.iconStyle,
      selectedIconStyle: selectedIconStyle ?? this.selectedIconStyle,
      disabledIconStyle: disabledIconStyle ?? this.disabledIconStyle,
      clickableStyle: clickableStyle ?? this.clickableStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreToggleGroupStyle &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          selectedColor == other.selectedColor &&
          disabledBackgroundColor == other.disabledBackgroundColor &&
          disabledSelectedColor == other.disabledSelectedColor &&
          _shadowEq(selectedShadow, other.selectedShadow) &&
          borderRadius == other.borderRadius &&
          itemBorderRadius == other.itemBorderRadius &&
          padding == other.padding &&
          itemPadding == other.itemPadding &&
          labelPadding == other.labelPadding &&
          itemHeight == other.itemHeight &&
          itemSpacing == other.itemSpacing &&
          selectedFontWeight == other.selectedFontWeight &&
          transitionDuration == other.transitionDuration &&
          stateLayerColor == other.stateLayerColor &&
          stateLayer == other.stateLayer &&
          labelTextStyle == other.labelTextStyle &&
          selectedLabelTextStyle == other.selectedLabelTextStyle &&
          disabledLabelTextStyle == other.disabledLabelTextStyle &&
          iconStyle == other.iconStyle &&
          selectedIconStyle == other.selectedIconStyle &&
          disabledIconStyle == other.disabledIconStyle &&
          clickableStyle == other.clickableStyle;

  @override
  int get hashCode => Object.hashAll([
    backgroundColor,
    selectedColor,
    disabledBackgroundColor,
    disabledSelectedColor,
    if (selectedShadow == null) null else Object.hashAll(selectedShadow!),
    borderRadius,
    itemBorderRadius,
    padding,
    itemPadding,
    labelPadding,
    itemHeight,
    itemSpacing,
    selectedFontWeight,
    transitionDuration,
    stateLayerColor,
    stateLayer,
    labelTextStyle,
    selectedLabelTextStyle,
    disabledLabelTextStyle,
    iconStyle,
    selectedIconStyle,
    disabledIconStyle,
    clickableStyle,
  ]);

  static bool _shadowEq(List<CoreShadowLayer>? a, List<CoreShadowLayer>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static CoreTextStyle? _mergeText(CoreTextStyle? base, CoreTextStyle? other) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}
