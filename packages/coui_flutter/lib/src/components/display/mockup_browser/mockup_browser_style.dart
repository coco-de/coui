import 'dart:math' as math;

import 'package:coui_flutter/coui_flutter.dart';

// ═══════════════════════════════════════════════════
// ResolvedMockupBrowser
// ═══════════════════════════════════════════════════

/// Paint-ready resolver output for Flutter `MockupBrowser`.
///
/// Content fills a Stack beneath a clipped, blurred toolbar; the final
/// overlay owns the outline and the inner top highlight. All dimensions
/// are scaled here, while composed Icon and OutlinedContainer styles are
/// forwarded in Core units for their own resolvers.
class ResolvedMockupBrowser {
  /// Creates a [ResolvedMockupBrowser].
  const ResolvedMockupBrowser({
    required this.toolbarBackgroundColor,
    required this.toolbarBorderColor,
    required this.toolbarBorderWidth,
    required this.toolbarBlur,
    required this.toolbarBorderRadius,
    required this.windowBorderDecoration,
    required this.windowBorderRadius,
    required this.highlightShadows,
    required this.capsuleHeight,
    required this.capsulePadding,
    required this.capsuleBorderRadius,
    required this.capsuleBackgroundColor,
    required this.actionSpacing,
    required this.addressBarSpacing,
    required this.domainSpacing,
    required this.expandDomainLabel,
    required this.addressIconStyle,
    required this.contentTextStyle,
    required this.containerStyle,
    required this.toolbarHeight,
    required this.toolbarPadding,
    required this.toolbarSpacing,
    required this.controlSize,
    required this.controlSpacing,
    required this.controlBorderRadius,
    required this.controlCloseColor,
    required this.controlMinimizeColor,
    required this.controlMaximizeColor,
    required this.navSpacing,
    required this.navIconStyle,
    required this.navDisabledIconStyle,
    required this.actionIconStyle,
    required this.addressBarHeight,
    required this.addressBarPadding,
    required this.addressBarBorderRadius,
    required this.addressBarBackgroundColor,
    required this.addressBarTextStyle,
    required this.addressBarTextAlign,
    required this.contentInset,
    required this.contentBackgroundColor,
    required this.contentBorderRadius,
  });

  /// Resolved toolbarBackgroundColor chrome.
  final Color toolbarBackgroundColor;

  /// Resolved toolbarBorderColor chrome.
  final Color toolbarBorderColor;

  /// Resolved toolbarBorderWidth chrome.
  final double toolbarBorderWidth;

  /// Resolved toolbarBlur chrome.
  final double toolbarBlur;

  /// Resolved toolbarBorderRadius chrome.
  final BorderRadius toolbarBorderRadius;

  /// Resolved windowBorderDecoration chrome.
  final BoxDecoration windowBorderDecoration;

  /// Outer rounded path for the border highlight.
  final BorderRadius windowBorderRadius;

  /// Resolved highlightShadows chrome.
  final List<BoxShadow> highlightShadows;

  /// Resolved capsuleHeight chrome.
  final double capsuleHeight;

  /// Resolved capsulePadding chrome.
  final EdgeInsets capsulePadding;

  /// Resolved capsuleBorderRadius chrome.
  final BorderRadius capsuleBorderRadius;

  /// Resolved capsuleBackgroundColor chrome.
  final Color capsuleBackgroundColor;

  /// Resolved actionSpacing chrome.
  final double actionSpacing;

  /// Resolved addressBarSpacing chrome.
  final double addressBarSpacing;

  /// Resolved domainSpacing chrome.
  final double domainSpacing;

  /// Whether an explicit alignment override needs the full domain width.
  final bool expandDomainLabel;

  /// Resolved addressIconStyle chrome.
  final CoreIconStyle addressIconStyle;

  /// Resolved contentTextStyle chrome.
  final TextStyle contentTextStyle;

  /// [CoreOutlinedContainerStyle] for the composed `OutlinedContainer`
  /// window body — `OutlinedContainer`'s contract input. Fill / outline /
  /// radius / shadow stay `coui_core` domain types so the receiving widget
  /// runs its own colour / radius resolution + scaling once.
  final CoreOutlinedContainerStyle containerStyle;

  /// Full toolbar overlay height (logical px, post-scaling).
  final double toolbarHeight;

  /// Toolbar padding measured from the outer edge (post-scaling).
  final EdgeInsets toolbarPadding;

  /// Spacing between the toolbar's groups (post-scaling) — `Row.spacing`
  /// does not self-scale, so it is pre-multiplied here.
  final double toolbarSpacing;

  /// Window-control dot diameter (post-scaling).
  final double controlSize;

  /// Spacing between adjacent window-control dots (post-scaling).
  final double controlSpacing;

  /// Window-control dot corner radius (post-scaling).
  final BorderRadius controlBorderRadius;

  /// Close-control dot colour.
  final Color controlCloseColor;

  /// Minimize-control dot colour.
  final Color controlMinimizeColor;

  /// Maximize-control dot colour.
  final Color controlMaximizeColor;

  /// Spacing between the back and forward chevrons (post-scaling).
  final double navSpacing;

  /// Back-chevron icon chrome — raw-forwarded to `Icon`.
  final CoreIconStyle navIconStyle;

  /// Forward-chevron icon chrome — raw-forwarded to `Icon`.
  final CoreIconStyle navDisabledIconStyle;

  /// Trailing action glyph chrome — raw-forwarded to `Icon`.
  final CoreIconStyle actionIconStyle;

  /// Address bar pill height (logical px, post-scaling).
  final double addressBarHeight;

  /// Address bar pill padding (post-scaling).
  final EdgeInsets addressBarPadding;

  /// Address bar pill corner radius (post-scaling).
  final BorderRadius addressBarBorderRadius;

  /// Address bar pill fill colour.
  final Color addressBarBackgroundColor;

  /// Address bar label text style — typography role merged with the
  /// `addressBarTextStyle` slot, foreground colour bound (paint-ready).
  final TextStyle addressBarTextStyle;

  /// Address bar label alignment inside the pill.
  final TextAlign addressBarTextAlign;

  /// Child inset: toolbar height above and optional chrome at the sides
  /// and bottom. The content background still fills the window.
  final EdgeInsets contentInset;

  /// Content card fill colour.
  final Color contentBackgroundColor;

  /// Content card corner radius (post-scaling) — the override when one
  /// is set, else `borderRadius − chromeWidth` per corner so the card
  /// stays concentric with the body.
  final BorderRadius contentBorderRadius;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedMockupBrowser] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default (CoreMockupBrowserStyle.defaultX)
///   → theme.coreComponentTheme.mockup.style (shared cross-variant)
///   → theme.coreComponentTheme.mockupBrowser.style
///   → widget.mockupBrowserStyle
/// ```
///
/// The shared `CoreMockupTheme.style` (cross-variant background /
/// border / borderRadius) is folded into the chain as the lowest
/// override layer, so the per-field fallback is a single
/// `resolveStyleChain` pass.
ResolvedMockupBrowser resolveMockupBrowser(
  BuildContext context, {
  CoreMockupBrowserStyle? mockupBrowserStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final mkTheme = theme.coreComponentTheme?.mockup;
  final browserTheme = theme.coreComponentTheme?.mockupBrowser;

  // ─── Merge chain ──────────────────────────────────────
  // The shared `CoreMockupTheme.style` only carries the cross-variant
  // background / border / borderRadius, so it maps onto a partial
  // `CoreMockupBrowserStyle` layer slotted below the browser-specific
  // theme + per-instance override.
  final sharedSeed = mkTheme?.style == null
      ? null
      : CoreMockupBrowserStyle(
          backgroundColor: mkTheme!.style!.backgroundColor,
          borderColor: mkTheme.style!.borderColor,
          borderRadius: mkTheme.style!.borderRadius,
        );
  final merged = resolveStyleChain(const CoreMockupBrowserStyle(), [
    sharedSeed,
    browserTheme?.style,
    mockupBrowserStyle,
  ]);

  // ─── Stage 1 RESOLVE — Core values (Flutter / Web identical) ──────────
  final borderRadius =
      merged.borderRadius ?? CoreMockupBrowserStyle.defaultBorderRadius;
  final chromeWidth =
      merged.chromeWidth ?? CoreMockupBrowserStyle.defaultChromeWidth;
  final borderWidthCore =
      merged.borderWidth ?? CoreMockupBrowserStyle.defaultBorderWidth;
  final chromeInset = chromeWidth;
  final toolbarRowHeight =
      merged.toolbarHeight ?? CoreMockupBrowserStyle.defaultToolbarHeight;
  final toolbarPaddingInside =
      merged.toolbarPadding ?? CoreMockupBrowserStyle.defaultToolbarPadding;
  // Content card radius — the override when set, else derived so the
  // card stays concentric with the body: each corner is the body's
  // corner minus the thickness between them (never below zero, so a
  // body squarer than its chrome is thick yields a square card rather
  // than a negative radius). Same shape as `OutlinedContainer`'s inner
  // edge; a `default*` constant would decouple the two. `chromeWidth`,
  // not the deflated inset: the card sits `chromeWidth` from the outer
  // edge the body's radius is drawn on.
  final contentBorderRadiusCore =
      merged.contentBorderRadius ??
      CoreBorderRadius.only(
        topLeft: math.max(0, borderRadius.topLeft - chromeWidth),
        topRight: math.max(0, borderRadius.topRight - chromeWidth),
        bottomLeft: math.max(0, borderRadius.bottomLeft - chromeWidth),
        bottomRight: math.max(0, borderRadius.bottomRight - chromeWidth),
      );
  final navIconStyle = CoreMockupBrowserStyle.defaultNavIconStyle.merge(
    merged.navIconStyle,
  );
  final navDisabledIconStyle = CoreMockupBrowserStyle
      .defaultNavDisabledIconStyle
      .merge(merged.navDisabledIconStyle);
  final actionIconStyle = CoreMockupBrowserStyle.defaultActionIconStyle.merge(
    merged.actionIconStyle,
  );

  // ─── Composed OutlinedContainer surface (window body) ──
  // The body is a composed `OutlinedContainer`, not a hand-rolled
  // `Container` (`core/style-contract.md`'s child-component-composition
  // rule) — fill / outline / radius / shadow stay `coui_core` domain types
  // because `OutlinedContainer`'s own resolver runs the
  // `scheme.resolve(...).toValue()` step, bends the shadow through the
  // active surface style and applies `theme.scaling` itself.
  final containerStyle = CoreOutlinedContainerStyle(
    backgroundColor:
        merged.backgroundColor ?? CoreMockupBrowserStyle.defaultBackgroundColor,
    borderColor: CoreColor.transparent,
    borderRadius: borderRadius,
    borderWidth: 0,
    padding: CoreEdgeInsets.zero,
    boxShadow: merged.boxShadow ?? CoreMockupBrowserStyle.defaultBoxShadow,
  );

  // ─── Stage 2 EMIT — paint-ready Flutter values ────────────────────────
  final borderWidth = theme.geometry.stroke(borderWidthCore, scaling: scaling);
  final toolbarHeight = toolbarRowHeight * scaling;
  final toolbarPadding =
      toolbarPaddingInside.toValue(geometry: theme.geometry) * scaling;
  final toolbarSpacing =
      theme.geometry.space(
        merged.toolbarSpacing ?? CoreMockupBrowserStyle.defaultToolbarSpacing,
      ) *
      scaling;

  final controlSize =
      (merged.controlSize ?? CoreMockupBrowserStyle.defaultControlSize) *
      scaling;
  final controlSpacing =
      theme.geometry.space(
        merged.controlSpacing ?? CoreMockupBrowserStyle.defaultControlSpacing,
      ) *
      scaling;
  final controlBorderRadius =
      ((merged.controlBorderRadius ??
              CoreMockupBrowserStyle.defaultControlBorderRadius)
          .toValue(geometry: theme.geometry)) *
      scaling;
  // Semantic status colours follow the active scheme.
  final controlCloseColor = scheme
      .resolve(
        merged.controlCloseColor ??
            CoreMockupBrowserStyle.defaultControlCloseColor,
      )
      .toValue();
  final controlMinimizeColor = scheme
      .resolve(
        merged.controlMinimizeColor ??
            CoreMockupBrowserStyle.defaultControlMinimizeColor,
      )
      .toValue();
  final controlMaximizeColor = scheme
      .resolve(
        merged.controlMaximizeColor ??
            CoreMockupBrowserStyle.defaultControlMaximizeColor,
      )
      .toValue();

  final navSpacing =
      theme.geometry.space(
        merged.navSpacing ?? CoreMockupBrowserStyle.defaultNavSpacing,
      ) *
      scaling;

  final addressBarHeight =
      (merged.addressBarHeight ??
          CoreMockupBrowserStyle.defaultAddressBarHeight) *
      scaling;
  final addressBarPadding =
      ((merged.addressBarPadding ??
              CoreMockupBrowserStyle.defaultAddressBarPadding)
          .toValue(geometry: theme.geometry)) *
      scaling;
  final addressBarBorderRadius =
      ((merged.addressBarBorderRadius ??
              CoreMockupBrowserStyle.defaultAddressBarBorderRadius)
          .toValue(geometry: theme.geometry)) *
      scaling;
  final addressBarBackgroundColor = scheme
      .resolve(
        merged.addressBarBackgroundColor ??
            CoreMockupBrowserStyle.defaultAddressBarBackgroundColor,
      )
      .toValue();
  // Address-bar label typography — compose the design-system role default
  // with the per-instance override (composite `.merge`), bind the resolved
  // foreground colour, then materialise through `.toValue(theme:, color:)`
  // in one step. The foreground colour is resolved from the slot's own
  // colour (caller override else the `onSurfaceVariant` default carried
  // inside `defaultAddressBarTextStyle`).
  final addressBarTextColor = scheme
      .resolve(
        merged.addressBarTextStyle?.color ??
            CoreMockupBrowserStyle.defaultAddressBarTextStyle.color!,
      )
      .toValue();
  final addressBarTextStyle = CoreMockupBrowserStyle.defaultAddressBarTextStyle
      .merge(merged.addressBarTextStyle)
      .toValue(color: addressBarTextColor, theme: theme);
  final addressBarTextAlign =
      (merged.addressBarTextAlign ??
              CoreMockupBrowserStyle.defaultAddressBarTextAlign)
          .toValue();

  // Child content starts below the overlay; the content fill covers the
  // entire window, including the toolbar backdrop.
  final scaledChromeInset = chromeInset * scaling;
  final contentInset = EdgeInsets.only(
    top: toolbarHeight,
    left: scaledChromeInset,
    right: scaledChromeInset,
    bottom: scaledChromeInset,
  );
  final contentBackgroundColor = scheme
      .resolve(
        merged.contentBackgroundColor ??
            CoreMockupBrowserStyle.defaultContentBackgroundColor,
      )
      .toValue();
  final contentBorderRadius =
      contentBorderRadiusCore.toValue(geometry: theme.geometry) * scaling;

  final windowRadius = borderRadius.toValue(geometry: theme.geometry) * scaling;
  final toolbarBorderRadius = BorderRadius.only(
    topLeft: windowRadius.topLeft,
    topRight: windowRadius.topRight,
  );
  final toolbarBackgroundColor = scheme
      .resolve(
        merged.toolbarBackgroundColor ??
            CoreMockupBrowserStyle.defaultToolbarBackgroundColor,
      )
      .toValue();
  final toolbarBorderColor = scheme
      .resolve(
        merged.toolbarBorderColor ??
            CoreMockupBrowserStyle.defaultToolbarBorderColor,
      )
      .toValue();
  final toolbarBorderWidth = theme.geometry.stroke(
    merged.toolbarBorderWidth ??
        CoreMockupBrowserStyle.defaultToolbarBorderWidth,
    scaling: scaling,
  );
  final toolbarBlur =
      (merged.toolbarBlur ?? CoreMockupBrowserStyle.defaultToolbarBlur) *
      scaling;
  final windowBorderDecoration = BoxDecoration(
    borderRadius: windowRadius,
    border: Border.all(
      color: scheme
          .resolve(
            merged.borderColor ?? CoreMockupBrowserStyle.defaultBorderColor,
          )
          .toValue(),
      width: borderWidth,
    ),
  );
  final highlightShadows =
      <CoreShadowLayer>[
        (
          offsetX: 0,
          offsetY:
              merged.highlightWidth ??
              CoreMockupBrowserStyle.defaultHighlightWidth,
          blurRadius: 0,
          spreadRadius: 0,
          opacity: 1,
          inset: true,
        ),
      ].toValue(
        base: scheme
            .resolve(
              merged.highlightColor ??
                  CoreMockupBrowserStyle.defaultHighlightColor,
            )
            .toValue(),
        geometry: theme.geometry,
        scale: scaling,
      );
  final capsuleHeight =
      (merged.capsuleHeight ?? CoreMockupBrowserStyle.defaultCapsuleHeight) *
      scaling;
  final capsulePadding =
      (merged.capsulePadding ?? CoreMockupBrowserStyle.defaultCapsulePadding)
          .toValue(geometry: theme.geometry) *
      scaling;
  final capsuleBorderRadius =
      (merged.capsuleBorderRadius ??
              CoreMockupBrowserStyle.defaultCapsuleBorderRadius)
          .toValue(geometry: theme.geometry) *
      scaling;
  final capsuleBackgroundColor = scheme
      .resolve(
        merged.capsuleBackgroundColor ??
            CoreMockupBrowserStyle.defaultCapsuleBackgroundColor,
      )
      .toValue();
  final actionSpacing =
      theme.geometry.space(
        merged.actionSpacing ?? CoreMockupBrowserStyle.defaultActionSpacing,
      ) *
      scaling;
  final addressBarSpacing =
      theme.geometry.space(
        merged.addressBarSpacing ??
            CoreMockupBrowserStyle.defaultAddressBarSpacing,
      ) *
      scaling;
  final domainSpacing =
      theme.geometry.space(
        merged.domainSpacing ?? CoreMockupBrowserStyle.defaultDomainSpacing,
      ) *
      scaling;
  final addressIconStyle = CoreMockupBrowserStyle.defaultAddressIconStyle.merge(
    merged.addressIconStyle,
  );
  final contentTextStyle = CoreMockupBrowserStyle.defaultContentTextStyle
      .merge(merged.contentTextStyle)
      .toValue(
        theme: theme,
        color: scheme
            .resolve(
              merged.contentTextStyle?.color ??
                  CoreMockupBrowserStyle.defaultContentTextStyle.color!,
            )
            .toValue(),
      );

  final expandDomainLabel = merged.addressBarTextAlign != null;

  return ResolvedMockupBrowser(
    toolbarBackgroundColor: toolbarBackgroundColor,
    toolbarBorderColor: toolbarBorderColor,
    toolbarBorderWidth: toolbarBorderWidth,
    toolbarBlur: toolbarBlur,
    toolbarBorderRadius: toolbarBorderRadius,
    windowBorderDecoration: windowBorderDecoration,
    windowBorderRadius: windowRadius,
    highlightShadows: highlightShadows,
    capsuleHeight: capsuleHeight,
    capsulePadding: capsulePadding,
    capsuleBorderRadius: capsuleBorderRadius,
    capsuleBackgroundColor: capsuleBackgroundColor,
    actionSpacing: actionSpacing,
    addressBarSpacing: addressBarSpacing,
    domainSpacing: domainSpacing,
    expandDomainLabel: expandDomainLabel,
    addressIconStyle: addressIconStyle,
    contentTextStyle: contentTextStyle,
    containerStyle: containerStyle,
    toolbarHeight: toolbarHeight,
    toolbarPadding: toolbarPadding,
    toolbarSpacing: toolbarSpacing,
    controlSize: controlSize,
    controlSpacing: controlSpacing,
    controlBorderRadius: controlBorderRadius,
    controlCloseColor: controlCloseColor,
    controlMinimizeColor: controlMinimizeColor,
    controlMaximizeColor: controlMaximizeColor,
    navSpacing: navSpacing,
    navIconStyle: navIconStyle,
    navDisabledIconStyle: navDisabledIconStyle,
    actionIconStyle: actionIconStyle,
    addressBarHeight: addressBarHeight,
    addressBarPadding: addressBarPadding,
    addressBarBorderRadius: addressBarBorderRadius,
    addressBarBackgroundColor: addressBarBackgroundColor,
    addressBarTextStyle: addressBarTextStyle,
    addressBarTextAlign: addressBarTextAlign,
    contentInset: contentInset,
    contentBackgroundColor: contentBackgroundColor,
    contentBorderRadius: contentBorderRadius,
  );
}
