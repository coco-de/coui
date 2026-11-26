/// Per-instance style for `CardImage`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/basic/basic_style.dart';
import 'package:coui_core/src/component/contracts/button/button_style.dart';
import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/contracts/outlined_container/outlined_container_style.dart';
import 'package:coui_core/src/component/contracts/scrollable_client/core_axis.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/opacity_scale.dart';
import 'package:coui_core/src/effect/shadow_scale.dart';
import 'package:coui_core/src/motion/duration_token.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `CardImage` should render.
///
/// All chrome (colour / gap / hover scale / direction) lives in this slot —
/// the widget / contract expose only `cardImageStyle: CoreCardImageStyle?`.
///
/// Per Epic #1603 (옵션 B 최종) the image → text spacer is rendered
/// through the unified `Gap` widget, so the gap chrome is exposed as
/// the nested [imageContentGapStyle] slot (`CoreGapStyle`) — never as a
/// raw `double` (1:1:1:1 field mapping rule).
///
/// The card is a composed `OutlinedContainer` (both platforms) whose
/// chrome is the nested [containerStyle] slot; the image frame inside it is
/// a second composed `OutlinedContainer`, so its chrome is a single nested
/// [frameStyle] slot
/// (`core/style-contract.md`'s child-component-composition rule) rather
/// than flat colour/radius fields — that one slot carries
/// `OutlinedContainer`'s full chrome (fill, border colour and width,
/// radius, elevation, shadow, surface material …).
///
/// ```text
/// design system default (CoreCardImageStyle.defaultX)
///   → CoreCardImageTheme.style                       // 프로젝트 공통
///   → parent component slot override
///   → widget.cardImageStyle                          // 인스턴스별
/// ```
@immutable
class CoreCardImageStyle implements CoreStyle<CoreCardImageStyle> {
  /// Creates a [CoreCardImageStyle].
  const CoreCardImageStyle({
    this.containerStyle,
    this.disabledContainerStyle,
    this.frameStyle,
    this.contentStyle,
    this.disabledContentOpacity,
    this.imageContentGapStyle,
    this.hoverScale,
    this.normalScale,
    this.hoverDuration,
    this.direction,
  });

  /// Style for the card's own box — the `OutlinedContainer` that holds the
  /// image and the text and draws the card's fill, border, corners and
  /// clip. Laid over [defaultContainerStyle] and passed as is to
  /// `OutlinedContainer(containerStyle: …)`; anything neither states is the
  /// container's own default.
  final CoreOutlinedContainerStyle? containerStyle;

  /// What the card's box changes while the card is disabled — a pressable
  /// card (`onPressed` set) with `enabled: false`. By default it drops the
  /// cast. Laid over [defaultDisabledContainerStyle], and what it states wins
  /// over [containerStyle] while disabled.
  final CoreOutlinedContainerStyle? disabledContainerStyle;

  /// Style for the frame around the image — the `OutlinedContainer` that
  /// draws its fill, border, corners and shadow. Laid over
  /// [defaultFrameStyle] and passed as is to
  /// `OutlinedContainer(containerStyle: …)`.
  final CoreOutlinedContainerStyle? frameStyle;

  /// Style for the text row under the image — the `Basic` that lays out
  /// `leading`, `title`, `subtitle` and `trailing`. Laid over
  /// [defaultContentStyle] and passed as is to `Basic(basicStyle: …)`;
  /// anything neither states is `Basic`'s own default.
  final CoreBasicStyle? contentStyle;

  /// Opacity of the image and the text row while the card is disabled — a
  /// pressable card (`onPressed` set) with `enabled: false`. The card's own
  /// box, border and fill stay at full strength. `null` defers to
  /// [defaultDisabledContentOpacity].
  final double? disabledContentOpacity;

  /// Space between the image and the text. Laid over
  /// [defaultImageContentGapStyle] and passed as is to `Gap(gapStyle: …)`.
  final CoreGapStyle? imageContentGapStyle;

  /// Image scale factor when the card is hovered.
  final double? hoverScale;

  /// Image scale factor when the card is idle.
  final double? normalScale;

  /// Hover scale transition duration override. `null` defers to
  /// [defaultHoverDuration].
  final Duration? hoverDuration;

  /// Layout direction of the image relative to the text slot.
  final CoreAxis? direction;

  // ── Phase 6f defaults — single source of truth ─────

  /// Default card box — `OutlinedContainer`'s own surface, outline and
  /// corners (`surface`, a 1px `outlineVariant` border, 16, clipped), with
  /// [CoreSpace.space14] of room under the text row and the [CoreShadow.xs]
  /// cast.
  ///
  /// Only the bottom inset and the cast are stated here: the image runs to
  /// the card's top and side edges, and everything else is the composed
  /// container's default, so it is not restated.
  static const CoreOutlinedContainerStyle defaultContainerStyle =
      CoreOutlinedContainerStyle(
        boxShadow: CoreShadow.xs,
        padding: CoreEdgeInsets.only(bottom: CoreSpace.space14),
      );

  /// Default disabled card box — the cast is dropped. An explicitly empty
  /// stack, so no surface style contributes a cast in its place.
  static const CoreOutlinedContainerStyle defaultDisabledContainerStyle =
      CoreOutlinedContainerStyle(boxShadow: CoreShadow.none);

  /// Default image frame chrome — a `surfaceContainer` fill under the image,
  /// no border and square corners: the card's box rounds and clips the
  /// image's top corners, so the frame states none of its own.
  static const CoreOutlinedContainerStyle defaultFrameStyle =
      CoreOutlinedContainerStyle(
        backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
        borderColor: .transparent,
        // The constructor form, not `CoreBorderRadius.zero`, for the reason
        // `CoreBasicStyle.defaultPadding` states: it keeps the radius token's
        // provenance and is the only form the Figma reader can evaluate.
        // ignore: use_named_constants
        borderRadius: CoreBorderRadius.all(CoreRadius.radius0),
      );

  /// Default text row — items start-aligned, set in 14 from the start edge
  /// and 10 from the end edge, and the subtitle in `onSurfaceVariant`.
  ///
  /// The two insets differ because they say different things: the start one
  /// lines the text up under the image's edge, the end one only keeps the
  /// trailing chevron off the card's border. They follow the reading
  /// direction for that reason. The title keeps `Basic`'s own (`labelXl`
  /// at semiBold, `onSurface`); only the subtitle's colour is stated.
  static const CoreBasicStyle defaultContentStyle = CoreBasicStyle(
    mainAxisAlignment: .start,
    padding: CoreEdgeInsets.directional(
      start: CoreSpace.space14,
      end: CoreSpace.space10,
    ),
    subtitleTextStyle: CoreTextStyle(
      color: CoreColor.token(CoreColors.onSurfaceVariant),
    ),
  );

  /// Default opacity of the image and the text row while disabled.
  static const double defaultDisabledContentOpacity = CoreOpacity.disabled;

  /// What a pressable card states for the `fixed` button it is wrapped in
  /// (Flutter): no padding, and the app's ambient icon size.
  ///
  /// That button is there for press, focus and the accessibility role while
  /// the card's own chrome shows through, so nothing of its own may reach the
  /// card — and two things did. Its size row's padding inset the image and the
  /// text a second time, and its icon theme redrew every icon inside at the
  /// button's glyph size (16), so the built-in chevron came out smaller than
  /// the card's Web twin draws it. The Web twin is a `role="button"` `<div>`
  /// that adds neither: no inset, and icons at the ambient size
  /// ([CoreIconStyle.defaultAmbientSize]). Forwarded as is, not an override
  /// slot: the card has no padding or glyph size of its own to state.
  static const CoreButtonStyle pressableButtonStyle = CoreButtonStyle(
    padding: CoreEdgeInsets.zero,
    leadingIconStyle: CoreIconStyle(size: CoreIconStyle.defaultAmbientSize),
  );

  /// Default hover scale factor.
  static const double defaultHoverScale = 1.05;

  /// Default idle scale factor.
  static const double defaultNormalScale = 1;

  /// Default image → text gap style — `CoreGapStyle(size: 12)`.
  /// Per-instance override flows through [imageContentGapStyle] (merged
  /// on top of this default).
  static const CoreGapStyle defaultImageContentGapStyle = CoreGapStyle(
    size: CoreSpace.space12,
  );

  /// Default layout direction.
  static const CoreAxis defaultDirection = .vertical;

  /// Default hover scale transition duration (ms).
  static const Duration defaultHoverDuration = Duration(
    milliseconds: CoreDuration.fast,
  );

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreCardImageStyle merge(CoreCardImageStyle? other) {
    if (other == null) return this;
    return CoreCardImageStyle(
      containerStyle: containerStyle == null
          ? other.containerStyle
          : containerStyle!.merge(other.containerStyle),
      disabledContainerStyle: disabledContainerStyle == null
          ? other.disabledContainerStyle
          : disabledContainerStyle!.merge(other.disabledContainerStyle),
      frameStyle: frameStyle == null
          ? other.frameStyle
          : frameStyle!.merge(other.frameStyle),
      contentStyle: contentStyle == null
          ? other.contentStyle
          : contentStyle!.merge(other.contentStyle),
      disabledContentOpacity:
          other.disabledContentOpacity ?? disabledContentOpacity,
      imageContentGapStyle: imageContentGapStyle == null
          ? other.imageContentGapStyle
          : imageContentGapStyle!.merge(other.imageContentGapStyle),
      hoverScale: other.hoverScale ?? hoverScale,
      normalScale: other.normalScale ?? normalScale,
      hoverDuration: other.hoverDuration ?? hoverDuration,
      direction: other.direction ?? direction,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreCardImageStyle copyWith({
    CoreOutlinedContainerStyle? containerStyle,
    CoreOutlinedContainerStyle? disabledContainerStyle,
    CoreOutlinedContainerStyle? frameStyle,
    CoreBasicStyle? contentStyle,
    double? disabledContentOpacity,
    CoreGapStyle? imageContentGapStyle,
    double? hoverScale,
    double? normalScale,
    Duration? hoverDuration,
    CoreAxis? direction,
  }) {
    return CoreCardImageStyle(
      containerStyle: containerStyle ?? this.containerStyle,
      disabledContainerStyle:
          disabledContainerStyle ?? this.disabledContainerStyle,
      frameStyle: frameStyle ?? this.frameStyle,
      contentStyle: contentStyle ?? this.contentStyle,
      disabledContentOpacity:
          disabledContentOpacity ?? this.disabledContentOpacity,
      imageContentGapStyle: imageContentGapStyle ?? this.imageContentGapStyle,
      hoverScale: hoverScale ?? this.hoverScale,
      normalScale: normalScale ?? this.normalScale,
      hoverDuration: hoverDuration ?? this.hoverDuration,
      direction: direction ?? this.direction,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreCardImageStyle &&
          runtimeType == other.runtimeType &&
          containerStyle == other.containerStyle &&
          disabledContainerStyle == other.disabledContainerStyle &&
          frameStyle == other.frameStyle &&
          contentStyle == other.contentStyle &&
          disabledContentOpacity == other.disabledContentOpacity &&
          imageContentGapStyle == other.imageContentGapStyle &&
          hoverScale == other.hoverScale &&
          normalScale == other.normalScale &&
          hoverDuration == other.hoverDuration &&
          direction == other.direction;

  @override
  int get hashCode => Object.hash(
    containerStyle,
    disabledContainerStyle,
    frameStyle,
    contentStyle,
    disabledContentOpacity,
    imageContentGapStyle,
    hoverScale,
    normalScale,
    hoverDuration,
    direction,
  );
}
