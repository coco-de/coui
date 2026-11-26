/// Per-instance style for `MockupBrowser`.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/color/core_color_token.dart';
import 'package:coui_core/src/component/contracts/icon/icon_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/effect/opacity_scale.dart';
import 'package:coui_core/src/effect/shadow_scale.dart';
import 'package:coui_core/src/shape/border_radius.dart';
import 'package:coui_core/src/shape/radius_scale.dart';
import 'package:coui_core/src/shape/stroke_width.dart';
import 'package:coui_core/src/size/icon_size.dart';
import 'package:coui_core/src/size/size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/core_text_style_token.dart';
import 'package:coui_core/src/typography/text_align.dart';
import 'package:coui_core/src/typography/text_style_token.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `MockupBrowser` should render.
///
/// The content fills the window underneath an absolute, blurred toolbar.
/// Navigation and actions use capsules; a separate outline is painted last
/// so screenshots and toolbar chrome cannot cover the window border.
/// `chromeWidth` remains an optional left/right/bottom content inset.
///
/// `CoreMockupBrowserStyle` carries chrome / colour / dimensional flat
/// fields. Behavioural / content fields (`showControls`, `addressBar`,
/// `child`) stay flat on the widget / contract.
///
/// ```text
/// design system default
///   → CoreMockupTheme.style (shared cross-variant fallback)
///   → CoreMockupBrowserTheme.style                    // 프로젝트 공통
///   → parent component slot override
///   → widget.mockupBrowserStyle                       // 인스턴스별
/// ```
@immutable
class CoreMockupBrowserStyle implements CoreStyle<CoreMockupBrowserStyle> {
  /// Creates a [CoreMockupBrowserStyle].
  const CoreMockupBrowserStyle({
    this.toolbarBackgroundColor,
    this.toolbarBorderColor,
    this.toolbarBorderWidth,
    this.toolbarBlur,
    this.capsuleBackgroundColor,
    this.capsuleBorderRadius,
    this.capsulePadding,
    this.capsuleHeight,
    this.actionSpacing,
    this.addressBarSpacing,
    this.domainSpacing,
    this.addressIconStyle,
    this.contentTextStyle,
    this.highlightColor,
    this.highlightWidth,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.boxShadow,
    this.chromeWidth,
    this.contentBackgroundColor,
    this.contentBorderRadius,
    this.toolbarHeight,
    this.toolbarPadding,
    this.toolbarSpacing,
    this.controlSize,
    this.controlSpacing,
    this.controlBorderRadius,
    this.controlCloseColor,
    this.controlMinimizeColor,
    this.controlMaximizeColor,
    this.navSpacing,
    this.navIconStyle,
    this.navDisabledIconStyle,
    this.actionIconStyle,
    this.addressBarHeight,
    this.addressBarPadding,
    this.addressBarBorderRadius,
    this.addressBarBackgroundColor,
    this.addressBarTextStyle,
    this.addressBarTextAlign,
  });

  // ─── Design-system defaults ────────────────────

  /// Window body fill below the content and toolbar.
  static const CoreColor defaultBackgroundColor = CoreColor.token(
    CoreColors.surfaceContainerLow,
  );

  /// Quiet outline, painted above the content and toolbar.
  static const CoreColor defaultBorderColor = CoreColor.token(
    CoreColors.outlineVariant,
  );

  /// Default window body outline stroke width (logical px).
  static const double defaultBorderWidth = CoreStrokeWidth.stroke1;

  /// Default window body corner radius.
  static const CoreBorderRadius defaultBorderRadius = CoreBorderRadius.all(
    CoreRadius.radius14,
  );

  /// Default window body drop shadow — the designer two-layer stack the device
  /// mockup casts, so the two read as the same kind of object.
  static const List<CoreShadowLayer> defaultBoxShadow = CoreShadow.xl;

  /// Optional left/right/bottom content inset. Zero fills the window.
  static const double defaultChromeWidth = CoreSpace.space0;

  /// Content fill underneath the toolbar.
  static const CoreColor defaultContentBackgroundColor = CoreColor.token(
    CoreColors.surface,
  );

  /// Default toolbar height (logical px).
  static const double defaultToolbarHeight = CoreSpace.space44;

  /// Default toolbar padding — horizontal symmetric.
  static const CoreEdgeInsets defaultToolbarPadding = CoreEdgeInsets.symmetric(
    horizontal: CoreSpace.space12,
  );

  /// Default spacing (logical px) between the toolbar's groups —
  /// controls, navigation chevrons, address pill, action glyph. Flows into
  /// `Row.spacing` on Flutter and flex `gap` inline CSS on Web.
  static const double defaultToolbarSpacing = CoreSpace.space8;

  /// Default window-control dot diameter (logical px).
  static const double defaultControlSize = CoreSize.size8;

  /// Default spacing (logical px) between adjacent window-control dots.
  static const double defaultControlSpacing = CoreSpace.space6;

  /// Default window-control dot corner radius — a perfect circle.
  static const CoreBorderRadius defaultControlBorderRadius =
      CoreBorderRadius.all(CoreRadius.radius9999);

  /// Close-control semantic status colour; follows the active theme.
  static const CoreColor defaultControlCloseColor = CoreColor.token(
    CoreColors.error,
  );

  /// Minimize-control dot colour — semantic status colour, see
  /// [defaultControlCloseColor].
  static const CoreColor defaultControlMinimizeColor = CoreColor.token(
    CoreColors.warning,
  );

  /// Maximize-control dot colour — semantic status colour, see
  /// [defaultControlCloseColor].
  static const CoreColor defaultControlMaximizeColor = CoreColor.token(
    CoreColors.success,
  );

  /// Default spacing (logical px) between the back and forward chevrons.
  static const double defaultNavSpacing = CoreSpace.space8;

  /// Default back-chevron icon chrome — 12px, `onSurfaceVariant`.
  static const CoreIconStyle defaultNavIconStyle = CoreIconStyle(
    size: CoreIconSize.size12,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// Default forward-chevron icon chrome — 12px, `disabledContent`: the
  /// forward step is drawn as unavailable, the way a fresh page has no
  /// history ahead of it. An unavailable glyph reads in the disabled
  /// content tone, as every disabled icon does; `outlineVariant` is a
  /// border tone, not a glyph tone.
  static const CoreIconStyle defaultNavDisabledIconStyle = CoreIconStyle(
    size: CoreIconSize.size12,
    color: CoreColor.token(CoreColors.disabledContent),
  );

  /// Default trailing action glyph chrome — 12px, `onSurfaceVariant`.
  static const CoreIconStyle defaultActionIconStyle = CoreIconStyle(
    size: CoreIconSize.size12,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// Default address bar pill height (logical px).
  static const double defaultAddressBarHeight = CoreSpace.space28;

  /// Default address bar pill padding — horizontal symmetric.
  static const CoreEdgeInsets defaultAddressBarPadding =
      CoreEdgeInsets.symmetric(horizontal: CoreSpace.space8);

  /// Default address bar pill corner radius.
  static const CoreBorderRadius defaultAddressBarBorderRadius =
      CoreBorderRadius.all(CoreRadius.radius9999);

  /// Translucent address capsule fill.
  static const CoreColor defaultAddressBarBackgroundColor = CoreColor.token(
    CoreColors.surfaceContainer,
    opacity: CoreOpacity.opacity70,
  );

  /// Default address bar text style — `labelSmall` typography token
  /// (12px) carrying the `onSurfaceVariant` text colour role. Text colour
  /// is carried via [CoreTextStyle.color] inside this slot.
  static const CoreTextStyle defaultAddressBarTextStyle = CoreTextStyle.token(
    CoreTextStyles.labelSmall,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// Default address bar text alignment — centred in the pill, the way a
  /// browser shows a URL when the pill fills the toolbar.
  static const CoreTextAlign defaultAddressBarTextAlign = .center;

  /// Toolbar fill; exact designer opacity.
  static const CoreColor defaultToolbarBackgroundColor = CoreColor.token(
    CoreColors.surfaceContainerLow,
    opacity: 0.88,
  );

  /// Toolbar fill; exact designer opacity.
  final CoreColor? toolbarBackgroundColor;

  /// Toolbar bottom divider colour.
  static const CoreColor defaultToolbarBorderColor = CoreColor.token(
    CoreColors.surfaceContainer,
  );

  /// Toolbar bottom divider colour.
  final CoreColor? toolbarBorderColor;

  /// Toolbar bottom divider width.
  static const double defaultToolbarBorderWidth = CoreStrokeWidth.stroke1;

  /// Toolbar bottom divider width.
  final double? toolbarBorderWidth;

  /// Backdrop blur sigma (logical px); designer effect geometry.
  static const double defaultToolbarBlur = 20;

  /// Backdrop blur sigma (logical px); designer effect geometry.
  final double? toolbarBlur;

  /// Navigation and action capsule fill.
  static const CoreColor defaultCapsuleBackgroundColor = CoreColor.token(
    CoreColors.surfaceContainer,
    opacity: CoreOpacity.opacity70,
  );

  /// Navigation and action capsule fill.
  final CoreColor? capsuleBackgroundColor;

  /// Navigation and action capsule radius.
  static const CoreBorderRadius defaultCapsuleBorderRadius =
      CoreBorderRadius.all(CoreRadius.radius9999);

  /// Navigation and action capsule radius.
  final CoreBorderRadius? capsuleBorderRadius;

  /// Navigation and action capsule padding.
  static const CoreEdgeInsets defaultCapsulePadding = CoreEdgeInsets.symmetric(
    horizontal: CoreSpace.space8,
  );

  /// Navigation and action capsule padding.
  final CoreEdgeInsets? capsulePadding;

  /// Navigation and action capsule height.
  static const double defaultCapsuleHeight = CoreSpace.space28;

  /// Navigation and action capsule height.
  final double? capsuleHeight;

  /// Space between share and plus icons.
  static const double defaultActionSpacing = CoreSpace.space8;

  /// Space between share and plus icons.
  final double? actionSpacing;

  /// Space around address bar icon and label slots.
  static const double defaultAddressBarSpacing = CoreSpace.space6;

  /// Space around address bar icon and label slots.
  final double? addressBarSpacing;

  /// Space between lock and domain label.
  static const double defaultDomainSpacing = 3;

  /// Space between lock and domain label.
  final double? domainSpacing;

  /// Lock and reload icon chrome.
  static const CoreIconStyle defaultAddressIconStyle = CoreIconStyle(
    size: CoreIconSize.size10,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// Lock and reload icon chrome.
  final CoreIconStyle? addressIconStyle;

  /// Inherited child typography; explicit child styles take precedence.
  static const CoreTextStyle defaultContentTextStyle = CoreTextStyle.token(
    CoreTextStyles.bodySmall,
    color: CoreColor.token(CoreColors.onSurfaceVariant),
  );

  /// Inherited child typography; explicit child styles take precedence.
  final CoreTextStyle? contentTextStyle;

  /// Inner top highlight: white at 35%.
  static const CoreColor defaultHighlightColor = CoreColor(0x59FFFFFF);

  /// Inner top highlight: white at 35%.
  final CoreColor? highlightColor;

  /// Inner top highlight thickness.
  static const double defaultHighlightWidth = CoreStrokeWidth.stroke1;

  /// Inner top highlight thickness.
  final double? highlightWidth;

  /// Window body fill colour override.
  final CoreColor? backgroundColor;

  /// Window body outline colour override.
  final CoreColor? borderColor;

  /// Window body outline stroke width override (logical px).
  final double? borderWidth;

  /// Window body corner radius override.
  final CoreBorderRadius? borderRadius;

  /// Window body drop shadow override. An explicitly empty list draws no
  /// shadow at all.
  final List<CoreShadowLayer>? boxShadow;

  /// Window thickness override (logical px) — the distance from the
  /// body's outer edge to the content card on the left / right / bottom.
  /// The outline is drawn inside this distance, not outside it.
  final double? chromeWidth;

  /// Content card fill colour override.
  final CoreColor? contentBackgroundColor;

  /// Content card corner radius override.
  ///
  /// **Deliberately has no `default*`** — the resting value is derived,
  /// `borderRadius − chromeWidth` per corner, so the card stays concentric
  /// with the body whichever radius or thickness a caller picks (the same
  /// derivation `OutlinedContainer` makes for its inner edge). A constant
  /// here would decouple the two and let a wider body leave a mismatched
  /// card; the resolver computes the derivation and this slot only
  /// overrides it.
  final CoreBorderRadius? contentBorderRadius;

  /// Toolbar row height override (logical px), measured from the body's
  /// outer edge — the outline is drawn inside it.
  final double? toolbarHeight;

  /// Toolbar padding override. The left / top / right sides are measured
  /// from the body's outer edge — the outline is drawn inside them.
  final CoreEdgeInsets? toolbarPadding;

  /// Spacing override (logical px, pre-scaling) between the toolbar's
  /// groups. Falls back to [defaultToolbarSpacing].
  final double? toolbarSpacing;

  /// Window-control dot diameter override (logical px).
  final double? controlSize;

  /// Spacing override (logical px, pre-scaling) between adjacent
  /// window-control dots. Falls back to [defaultControlSpacing].
  final double? controlSpacing;

  /// Window-control dot corner radius override.
  final CoreBorderRadius? controlBorderRadius;

  /// Close-control dot colour override.
  final CoreColor? controlCloseColor;

  /// Minimize-control dot colour override.
  final CoreColor? controlMinimizeColor;

  /// Maximize-control dot colour override.
  final CoreColor? controlMaximizeColor;

  /// Spacing override (logical px, pre-scaling) between the back and
  /// forward chevrons. Falls back to [defaultNavSpacing].
  final double? navSpacing;

  /// Back-chevron icon chrome override — merged onto
  /// [defaultNavIconStyle] and raw-forwarded to `Icon`.
  final CoreIconStyle? navIconStyle;

  /// Forward-chevron icon chrome override — merged onto
  /// [defaultNavDisabledIconStyle] and raw-forwarded to `Icon`.
  final CoreIconStyle? navDisabledIconStyle;

  /// Trailing action glyph chrome override — merged onto
  /// [defaultActionIconStyle] and raw-forwarded to `Icon`.
  final CoreIconStyle? actionIconStyle;

  /// Address bar pill height override (logical px).
  final double? addressBarHeight;

  /// Address bar pill padding override.
  final CoreEdgeInsets? addressBarPadding;

  /// Address bar pill corner radius override. Falls back to
  /// [defaultAddressBarBorderRadius].
  final CoreBorderRadius? addressBarBorderRadius;

  /// Address bar fill colour override.
  final CoreColor? addressBarBackgroundColor;

  /// Address bar text style override. Text colour is carried via
  /// [CoreTextStyle.color] inside this slot. Defaults to
  /// [defaultAddressBarTextStyle].
  final CoreTextStyle? addressBarTextStyle;

  /// Address bar text alignment override. Defaults to
  /// [defaultAddressBarTextAlign].
  final CoreTextAlign? addressBarTextAlign;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here.
  @override
  CoreMockupBrowserStyle merge(CoreMockupBrowserStyle? other) {
    if (other == null) return this;
    return CoreMockupBrowserStyle(
      toolbarBackgroundColor:
          other.toolbarBackgroundColor ?? toolbarBackgroundColor,
      toolbarBorderColor: other.toolbarBorderColor ?? toolbarBorderColor,
      toolbarBorderWidth: other.toolbarBorderWidth ?? toolbarBorderWidth,
      toolbarBlur: other.toolbarBlur ?? toolbarBlur,
      capsuleBackgroundColor:
          other.capsuleBackgroundColor ?? capsuleBackgroundColor,
      capsuleBorderRadius: other.capsuleBorderRadius ?? capsuleBorderRadius,
      capsulePadding: other.capsulePadding ?? capsulePadding,
      capsuleHeight: other.capsuleHeight ?? capsuleHeight,
      actionSpacing: other.actionSpacing ?? actionSpacing,
      addressBarSpacing: other.addressBarSpacing ?? addressBarSpacing,
      domainSpacing: other.domainSpacing ?? domainSpacing,
      addressIconStyle: _mergeIcon(addressIconStyle, other.addressIconStyle),
      contentTextStyle: _mergeText(contentTextStyle, other.contentTextStyle),
      highlightColor: other.highlightColor ?? highlightColor,
      highlightWidth: other.highlightWidth ?? highlightWidth,
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      boxShadow: other.boxShadow ?? boxShadow,
      chromeWidth: other.chromeWidth ?? chromeWidth,
      contentBackgroundColor:
          other.contentBackgroundColor ?? contentBackgroundColor,
      contentBorderRadius: other.contentBorderRadius ?? contentBorderRadius,
      toolbarHeight: other.toolbarHeight ?? toolbarHeight,
      toolbarPadding: other.toolbarPadding ?? toolbarPadding,
      toolbarSpacing: other.toolbarSpacing ?? toolbarSpacing,
      controlSize: other.controlSize ?? controlSize,
      controlSpacing: other.controlSpacing ?? controlSpacing,
      controlBorderRadius: other.controlBorderRadius ?? controlBorderRadius,
      controlCloseColor: other.controlCloseColor ?? controlCloseColor,
      controlMinimizeColor: other.controlMinimizeColor ?? controlMinimizeColor,
      controlMaximizeColor: other.controlMaximizeColor ?? controlMaximizeColor,
      navSpacing: other.navSpacing ?? navSpacing,
      navIconStyle: _mergeIcon(navIconStyle, other.navIconStyle),
      navDisabledIconStyle: _mergeIcon(
        navDisabledIconStyle,
        other.navDisabledIconStyle,
      ),
      actionIconStyle: _mergeIcon(actionIconStyle, other.actionIconStyle),
      addressBarHeight: other.addressBarHeight ?? addressBarHeight,
      addressBarPadding: other.addressBarPadding ?? addressBarPadding,
      addressBarBorderRadius:
          other.addressBarBorderRadius ?? addressBarBorderRadius,
      addressBarBackgroundColor:
          other.addressBarBackgroundColor ?? addressBarBackgroundColor,
      addressBarTextStyle: _mergeText(
        addressBarTextStyle,
        other.addressBarTextStyle,
      ),
      addressBarTextAlign: other.addressBarTextAlign ?? addressBarTextAlign,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreMockupBrowserStyle copyWith({
    CoreColor? toolbarBackgroundColor,
    CoreColor? toolbarBorderColor,
    double? toolbarBorderWidth,
    double? toolbarBlur,
    CoreColor? capsuleBackgroundColor,
    CoreBorderRadius? capsuleBorderRadius,
    CoreEdgeInsets? capsulePadding,
    double? capsuleHeight,
    double? actionSpacing,
    double? addressBarSpacing,
    double? domainSpacing,
    CoreIconStyle? addressIconStyle,
    CoreTextStyle? contentTextStyle,
    CoreColor? highlightColor,
    double? highlightWidth,
    CoreColor? backgroundColor,
    CoreColor? borderColor,
    double? borderWidth,
    CoreBorderRadius? borderRadius,
    List<CoreShadowLayer>? boxShadow,
    double? chromeWidth,
    CoreColor? contentBackgroundColor,
    CoreBorderRadius? contentBorderRadius,
    double? toolbarHeight,
    CoreEdgeInsets? toolbarPadding,
    double? toolbarSpacing,
    double? controlSize,
    double? controlSpacing,
    CoreBorderRadius? controlBorderRadius,
    CoreColor? controlCloseColor,
    CoreColor? controlMinimizeColor,
    CoreColor? controlMaximizeColor,
    double? navSpacing,
    CoreIconStyle? navIconStyle,
    CoreIconStyle? navDisabledIconStyle,
    CoreIconStyle? actionIconStyle,
    double? addressBarHeight,
    CoreEdgeInsets? addressBarPadding,
    CoreBorderRadius? addressBarBorderRadius,
    CoreColor? addressBarBackgroundColor,
    CoreTextStyle? addressBarTextStyle,
    CoreTextAlign? addressBarTextAlign,
  }) {
    return CoreMockupBrowserStyle(
      toolbarBackgroundColor:
          toolbarBackgroundColor ?? this.toolbarBackgroundColor,
      toolbarBorderColor: toolbarBorderColor ?? this.toolbarBorderColor,
      toolbarBorderWidth: toolbarBorderWidth ?? this.toolbarBorderWidth,
      toolbarBlur: toolbarBlur ?? this.toolbarBlur,
      capsuleBackgroundColor:
          capsuleBackgroundColor ?? this.capsuleBackgroundColor,
      capsuleBorderRadius: capsuleBorderRadius ?? this.capsuleBorderRadius,
      capsulePadding: capsulePadding ?? this.capsulePadding,
      capsuleHeight: capsuleHeight ?? this.capsuleHeight,
      actionSpacing: actionSpacing ?? this.actionSpacing,
      addressBarSpacing: addressBarSpacing ?? this.addressBarSpacing,
      domainSpacing: domainSpacing ?? this.domainSpacing,
      addressIconStyle: addressIconStyle ?? this.addressIconStyle,
      contentTextStyle: contentTextStyle ?? this.contentTextStyle,
      highlightColor: highlightColor ?? this.highlightColor,
      highlightWidth: highlightWidth ?? this.highlightWidth,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      boxShadow: boxShadow ?? this.boxShadow,
      chromeWidth: chromeWidth ?? this.chromeWidth,
      contentBackgroundColor:
          contentBackgroundColor ?? this.contentBackgroundColor,
      contentBorderRadius: contentBorderRadius ?? this.contentBorderRadius,
      toolbarHeight: toolbarHeight ?? this.toolbarHeight,
      toolbarPadding: toolbarPadding ?? this.toolbarPadding,
      toolbarSpacing: toolbarSpacing ?? this.toolbarSpacing,
      controlSize: controlSize ?? this.controlSize,
      controlSpacing: controlSpacing ?? this.controlSpacing,
      controlBorderRadius: controlBorderRadius ?? this.controlBorderRadius,
      controlCloseColor: controlCloseColor ?? this.controlCloseColor,
      controlMinimizeColor: controlMinimizeColor ?? this.controlMinimizeColor,
      controlMaximizeColor: controlMaximizeColor ?? this.controlMaximizeColor,
      navSpacing: navSpacing ?? this.navSpacing,
      navIconStyle: navIconStyle ?? this.navIconStyle,
      navDisabledIconStyle: navDisabledIconStyle ?? this.navDisabledIconStyle,
      actionIconStyle: actionIconStyle ?? this.actionIconStyle,
      addressBarHeight: addressBarHeight ?? this.addressBarHeight,
      addressBarPadding: addressBarPadding ?? this.addressBarPadding,
      addressBarBorderRadius:
          addressBarBorderRadius ?? this.addressBarBorderRadius,
      addressBarBackgroundColor:
          addressBarBackgroundColor ?? this.addressBarBackgroundColor,
      addressBarTextStyle: addressBarTextStyle ?? this.addressBarTextStyle,
      addressBarTextAlign: addressBarTextAlign ?? this.addressBarTextAlign,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreMockupBrowserStyle &&
          runtimeType == other.runtimeType &&
          toolbarBackgroundColor == other.toolbarBackgroundColor &&
          toolbarBorderColor == other.toolbarBorderColor &&
          toolbarBorderWidth == other.toolbarBorderWidth &&
          toolbarBlur == other.toolbarBlur &&
          capsuleBackgroundColor == other.capsuleBackgroundColor &&
          capsuleBorderRadius == other.capsuleBorderRadius &&
          capsulePadding == other.capsulePadding &&
          capsuleHeight == other.capsuleHeight &&
          actionSpacing == other.actionSpacing &&
          addressBarSpacing == other.addressBarSpacing &&
          domainSpacing == other.domainSpacing &&
          addressIconStyle == other.addressIconStyle &&
          contentTextStyle == other.contentTextStyle &&
          highlightColor == other.highlightColor &&
          highlightWidth == other.highlightWidth &&
          backgroundColor == other.backgroundColor &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth &&
          borderRadius == other.borderRadius &&
          _listEq(boxShadow, other.boxShadow) &&
          chromeWidth == other.chromeWidth &&
          contentBackgroundColor == other.contentBackgroundColor &&
          contentBorderRadius == other.contentBorderRadius &&
          toolbarHeight == other.toolbarHeight &&
          toolbarPadding == other.toolbarPadding &&
          toolbarSpacing == other.toolbarSpacing &&
          controlSize == other.controlSize &&
          controlSpacing == other.controlSpacing &&
          controlBorderRadius == other.controlBorderRadius &&
          controlCloseColor == other.controlCloseColor &&
          controlMinimizeColor == other.controlMinimizeColor &&
          controlMaximizeColor == other.controlMaximizeColor &&
          navSpacing == other.navSpacing &&
          navIconStyle == other.navIconStyle &&
          navDisabledIconStyle == other.navDisabledIconStyle &&
          actionIconStyle == other.actionIconStyle &&
          addressBarHeight == other.addressBarHeight &&
          addressBarPadding == other.addressBarPadding &&
          addressBarBorderRadius == other.addressBarBorderRadius &&
          addressBarBackgroundColor == other.addressBarBackgroundColor &&
          addressBarTextStyle == other.addressBarTextStyle &&
          addressBarTextAlign == other.addressBarTextAlign;

  @override
  int get hashCode => Object.hashAll([
    toolbarBackgroundColor,
    toolbarBorderColor,
    toolbarBorderWidth,
    toolbarBlur,
    capsuleBackgroundColor,
    capsuleBorderRadius,
    capsulePadding,
    capsuleHeight,
    actionSpacing,
    addressBarSpacing,
    domainSpacing,
    addressIconStyle,
    contentTextStyle,
    highlightColor,
    highlightWidth,
    backgroundColor,
    borderColor,
    borderWidth,
    borderRadius,
    if (boxShadow != null) Object.hashAll(boxShadow!),
    chromeWidth,
    contentBackgroundColor,
    contentBorderRadius,
    toolbarHeight,
    toolbarPadding,
    toolbarSpacing,
    controlSize,
    controlSpacing,
    controlBorderRadius,
    controlCloseColor,
    controlMinimizeColor,
    controlMaximizeColor,
    navSpacing,
    navIconStyle,
    navDisabledIconStyle,
    actionIconStyle,
    addressBarHeight,
    addressBarPadding,
    addressBarBorderRadius,
    addressBarBackgroundColor,
    addressBarTextStyle,
    addressBarTextAlign,
  ]);

  /// Element-wise list comparison.
  ///
  /// A shadow stack is a list, and Dart list equality is identity, so
  /// without this two structurally identical stacks compare unequal and
  /// every rebuild looks like a change.
  static bool _listEq<T>(List<T>? a, List<T>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i += 1) {
      if (a[i] != b[i]) return false;
    }

    return true;
  }

  static CoreIconStyle? _mergeIcon(CoreIconStyle? base, CoreIconStyle? other) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }

  static CoreTextStyle? _mergeText(
    CoreTextStyle? base,
    CoreTextStyle? other,
  ) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}
