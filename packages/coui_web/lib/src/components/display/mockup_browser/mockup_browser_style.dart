import 'dart:math' as math;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/web_resolved_chrome.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' show BuildContext;

// ═══════════════════════════════════════════════════
// Resolved output
// ═══════════════════════════════════════════════════

/// Paint-ready chrome for Web `MockupBrowser`.
///
/// Content fills a relative body beneath an absolute, blurred toolbar.
/// An outline and inset highlight are emitted on the final overlay.
/// Icons and the body surface stay composed Core styles.
class ResolvedMockupBrowser implements WebResolvedChrome {
  /// Creates a [ResolvedMockupBrowser].
  const ResolvedMockupBrowser({
    required this.body,
    required this.domain,
    required this.windowBorder,
    required this.addressIconStyle,
    required this.root,
    required this.frameStyle,
    required this.toolbar,
    required this.controls,
    required this.controlClose,
    required this.controlMinimize,
    required this.controlMaximize,
    required this.nav,
    required this.navIconStyle,
    required this.navDisabledIconStyle,
    required this.addressBar,
    required this.addressBarLabel,
    required this.action,
    required this.actionIconStyle,
    required this.contentInset,
    required this.content,
  });

  /// Paint-ready body slot.
  final WebElementChrome body;

  /// Paint-ready domain slot.
  final WebElementChrome domain;

  /// Paint-ready windowBorder slot.
  final WebElementChrome windowBorder;

  /// Paint-ready addressIconStyle slot.
  final CoreIconStyle addressIconStyle;

  /// Paint-ready chrome for the outer wrapper `<div>` — `w-full` only.
  /// Carries no paint chrome of its own — that lives on [frameStyle].
  @override
  final WebElementChrome root;

  /// Nested [CoreOutlinedContainerStyle] for the window body —
  /// raw-forwarded straight to `OutlinedContainer(containerStyle: …)`;
  /// that widget's own resolver owns fill / outline / radius / shadow
  /// emit (no className / inlineStyles assembly here).
  final CoreOutlinedContainerStyle frameStyle;

  /// Paint-ready chrome for the toolbar row `<div>` — flex centring
  /// className plus the resolved gap / padding / height inline CSS. No
  /// translucent fill over the content backdrop.
  final WebElementChrome toolbar;

  /// Paint-ready chrome for the window-controls group `<div>` — flex
  /// centring + the dot gap inline CSS.
  final WebElementChrome controls;

  /// Paint-ready chrome for the close (red) control dot `<div>` — shared
  /// size / radius inline CSS + the dot's own colour.
  final WebElementChrome controlClose;

  /// Paint-ready chrome for the minimize (amber) control dot `<div>`.
  final WebElementChrome controlMinimize;

  /// Paint-ready chrome for the maximize (green) control dot `<div>`.
  final WebElementChrome controlMaximize;

  /// Paint-ready chrome for the back / forward chevron group `<div>` —
  /// flex centring + the chevron gap inline CSS.
  final WebElementChrome nav;

  /// Back-chevron icon chrome — raw-forwarded to `Icon`.
  final CoreIconStyle navIconStyle;

  /// Forward-chevron icon chrome — raw-forwarded to `Icon`.
  final CoreIconStyle navDisabledIconStyle;

  /// Paint-ready chrome for the address-bar pill `<div>` — vertical flex
  /// centring, flex grow, typography role + token colour classes (dropped
  /// on override) plus the resolved padding / height / radius +
  /// colour-override inline CSS.
  final WebElementChrome addressBar;

  /// Paint-ready chrome for the address-bar label `<div>` inside the pill —
  /// takes the pill's full content width (so the resolved `text-align`
  /// decides where the URL sits) and truncates a long URL with an end
  /// ellipsis. Inherits the pill's typography and colour.
  final WebElementChrome addressBarLabel;

  /// Paint-ready chrome for the trailing action slot `<div>` — flex
  /// centring, no grow.
  final WebElementChrome action;

  /// Trailing action glyph chrome — raw-forwarded to `Icon`.
  final CoreIconStyle actionIconStyle;

  /// Child padding below the toolbar, with optional side/bottom chrome.
  final WebElementChrome contentInset;

  /// Paint-ready chrome for the content card `<div>` — fill colour class
  /// (or inline override) plus the concentric radius and overflow clip
  /// inline CSS.
  final WebElementChrome content;
}

// ═══════════════════════════════════════════════════
// Resolver — entry point
// ═══════════════════════════════════════════════════

/// Resolves [ResolvedMockupBrowser] for the given [context].
///
/// Merge chain:
///
/// ```text
/// design-system default
///   → CoreMockupTheme.style (shared cross-variant fallback)
///   → theme.coreComponentTheme.mockupBrowser.style
///   → widget.mockupBrowserStyle
/// ```
ResolvedMockupBrowser resolveMockupBrowser(
  BuildContext context, {
  CoreMockupBrowserStyle? mockupBrowserStyle,
}) {
  final mkStyle = context.theme.coreComponentTheme?.mockup?.style;
  final browserTheme = context.theme.coreComponentTheme?.mockupBrowser;

  // ─── Merge chain (Stage 1 RESOLVE — Flutter/Web identical) ────────────
  // The shared `CoreMockupTheme.style` carries only the cross-variant
  // background / border / borderRadius, so it maps onto a partial
  // `CoreMockupBrowserStyle` layer slotted below the browser-specific
  // theme + per-instance override.
  final sharedSeed = mkStyle == null
      ? null
      : CoreMockupBrowserStyle(
          backgroundColor: mkStyle.backgroundColor,
          borderColor: mkStyle.borderColor,
          borderRadius: mkStyle.borderRadius,
        );
  final merged = resolveStyleChain(const CoreMockupBrowserStyle(), [
    sharedSeed,
    browserTheme?.style,
    mockupBrowserStyle,
  ]);

  final borderRadius =
      merged.borderRadius ?? CoreMockupBrowserStyle.defaultBorderRadius;
  final chromeWidth =
      merged.chromeWidth ?? CoreMockupBrowserStyle.defaultChromeWidth;
  final borderWidth =
      merged.borderWidth ?? CoreMockupBrowserStyle.defaultBorderWidth;
  final chromeInset = chromeWidth;
  final toolbarHeight =
      merged.toolbarHeight ?? CoreMockupBrowserStyle.defaultToolbarHeight;
  final toolbarPaddingInside =
      merged.toolbarPadding ?? CoreMockupBrowserStyle.defaultToolbarPadding;
  // Content card radius — the override when set, else derived so the
  // card stays concentric with the body: each corner is the body's corner
  // minus the thickness between them (never below zero). Same shape as
  // `OutlinedContainer`'s inner edge; a `default*` constant would
  // decouple the two. `chromeWidth`, not the deflated inset: the card
  // sits `chromeWidth` from the outer edge the body's radius is drawn on.
  final contentBorderRadius =
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

  // ─── Composed OutlinedContainer surface (window body) ────────
  // The body is a composed `OutlinedContainer`, not a hand-rolled `<div>`
  // (`core/style-contract.md`'s child-component-composition rule) —
  // fill / outline / radius / shadow stay `coui_core` domain types,
  // raw-forwarded so `OutlinedContainer`'s own resolver runs the
  // class-XOR-inline emit decision and the shadow variable routing once.
  final frameStyle = CoreOutlinedContainerStyle(
    backgroundColor:
        merged.backgroundColor ?? CoreMockupBrowserStyle.defaultBackgroundColor,
    borderColor: CoreColor.transparent,
    borderRadius: borderRadius,
    borderWidth: 0,
    padding: CoreEdgeInsets.zero,
    boxShadow: merged.boxShadow ?? CoreMockupBrowserStyle.defaultBoxShadow,
  );

  // ─── EMIT Stage 2 (Web, theme-free) ───────────────────────────────────
  // Each colour / typography / radius / padding value routes through the
  // emit family (single class-XOR-inline decision per value). Token-bound
  // defaults emit a Tailwind class (dark-mode reactive); overrides emit
  // inline. No `scheme.resolve` and no hand-rolled override branches.
  final toolbarPaddingEmit = emitSpacing(
    toolbarPaddingInside,
    CoreMockupBrowserStyle.defaultToolbarPadding,
    prefix: 'p',
    cssProperty: 'padding',
  );
  // Semantic control colours emit theme-reactive token classes.
  final controlCloseColorEmit = emitColor(
    merged.controlCloseColor,
    CoreMockupBrowserStyle.defaultControlCloseColor,
    .background,
  );
  final controlMinimizeColorEmit = emitColor(
    merged.controlMinimizeColor,
    CoreMockupBrowserStyle.defaultControlMinimizeColor,
    .background,
  );
  final controlMaximizeColorEmit = emitColor(
    merged.controlMaximizeColor,
    CoreMockupBrowserStyle.defaultControlMaximizeColor,
    .background,
  );
  final controlRadiusEmit = emitRadius(
    merged.controlBorderRadius,
    CoreMockupBrowserStyle.defaultControlBorderRadius,
  );
  final addressBarBackgroundEmit = emitColor(
    merged.addressBarBackgroundColor,
    CoreMockupBrowserStyle.defaultAddressBarBackgroundColor,
    .background,
  );
  // Address-bar label typography — the `addressBarTextStyle` slot carries
  // the full text style. `emitTypography` is the single canonical path: it
  // emits the role on a `text-{role}` class (+ token colour class) and any
  // explicit scalar / raw-colour overlay inline.
  final addressBarTextEmit = emitTypography(
    merged.addressBarTextStyle,
    CoreMockupBrowserStyle.defaultAddressBarTextStyle,
  );
  final addressBarRadiusEmit = emitRadius(
    merged.addressBarBorderRadius,
    CoreMockupBrowserStyle.defaultAddressBarBorderRadius,
  );
  final addressBarPaddingEmit = emitSpacing(
    merged.addressBarPadding,
    CoreMockupBrowserStyle.defaultAddressBarPadding,
    prefix: 'p',
    cssProperty: 'padding',
  );
  final addressBarTextAlignCss =
      (merged.addressBarTextAlign ??
              CoreMockupBrowserStyle.defaultAddressBarTextAlign)
          .toValue();
  final contentBackgroundEmit = emitColor(
    merged.contentBackgroundColor,
    CoreMockupBrowserStyle.defaultContentBackgroundColor,
    .background,
  );

  // Single-axis logical-px dimensions — no preset class, so emit `rem`
  // inline (`(merged.X ?? default)`).
  final toolbarSpacing =
      merged.toolbarSpacing ?? CoreMockupBrowserStyle.defaultToolbarSpacing;
  final controlSize =
      merged.controlSize ?? CoreMockupBrowserStyle.defaultControlSize;
  final controlSpacing =
      merged.controlSpacing ?? CoreMockupBrowserStyle.defaultControlSpacing;
  final navSpacing =
      merged.navSpacing ?? CoreMockupBrowserStyle.defaultNavSpacing;
  final addressBarHeight =
      merged.addressBarHeight ?? CoreMockupBrowserStyle.defaultAddressBarHeight;

  // The exact 88% designer fill is outside Tailwind's named alpha steps.
  // CSS variables keep this inline alpha reactive to the active theme.
  final Emit toolbarBackground = (
    className: '',
    inline: {
      'background-color':
          (merged.toolbarBackgroundColor ??
                  CoreMockupBrowserStyle.defaultToolbarBackgroundColor)
              .toValue(),
    },
  );
  final toolbarBorder = emitColor(
    merged.toolbarBorderColor,
    CoreMockupBrowserStyle.defaultToolbarBorderColor,
    .border,
  );
  final capsuleBackground = emitColor(
    merged.capsuleBackgroundColor,
    CoreMockupBrowserStyle.defaultCapsuleBackgroundColor,
    .background,
  );
  final capsuleRadius = emitRadius(
    merged.capsuleBorderRadius,
    CoreMockupBrowserStyle.defaultCapsuleBorderRadius,
  );
  final capsulePadding = emitSpacing(
    merged.capsulePadding,
    CoreMockupBrowserStyle.defaultCapsulePadding,
    prefix: 'p',
    cssProperty: 'padding',
  );
  final capsuleHeight =
      merged.capsuleHeight ?? CoreMockupBrowserStyle.defaultCapsuleHeight;
  final actionSpacing =
      merged.actionSpacing ?? CoreMockupBrowserStyle.defaultActionSpacing;
  final addressBarSpacing =
      merged.addressBarSpacing ??
      CoreMockupBrowserStyle.defaultAddressBarSpacing;
  final domainSpacing =
      merged.domainSpacing ?? CoreMockupBrowserStyle.defaultDomainSpacing;
  final addressIconStyle = CoreMockupBrowserStyle.defaultAddressIconStyle.merge(
    merged.addressIconStyle,
  );
  final contentText = emitTypography(
    merged.contentTextStyle,
    CoreMockupBrowserStyle.defaultContentTextStyle,
  );
  final windowBorderColor = emitColor(
    merged.borderColor,
    CoreMockupBrowserStyle.defaultBorderColor,
    .border,
  );
  final toolbarBlur =
      merged.toolbarBlur ?? CoreMockupBrowserStyle.defaultToolbarBlur;
  final toolbarBorderWidth =
      merged.toolbarBorderWidth ??
      CoreMockupBrowserStyle.defaultToolbarBorderWidth;
  final highlightColor =
      merged.highlightColor ?? CoreMockupBrowserStyle.defaultHighlightColor;
  final highlightWidth =
      merged.highlightWidth ?? CoreMockupBrowserStyle.defaultHighlightWidth;

  // ─── Local builders ───────────────────────────────────

  /// Composes the outer wrapper `<div>` Tailwind className — `w-full`
  /// only. Carries no paint chrome of its own — that lives on
  /// [frameStyle].
  String buildRootClassName() => '${WebLayout.wFull} h-full';

  /// Composes the toolbar row `<div>` Tailwind className — flex centring
  /// plus the emit-family padding class fragment.
  String buildToolbarClassName() => <String>[
    WebLayout.flex,
    WebLayout.itemsCenter,
    toolbarPaddingEmit.className,
    toolbarBackground.className,
    toolbarBorder.className,
  ].where((cls) => cls.isNotEmpty).join(' ');

  /// Composes the toolbar row `<div>` inline CSS — the group gap, the
  /// emit-family padding override (if any) and the resolved height.
  Styles buildToolbarInlineStyles() => .new(
    raw: {
      'position': 'absolute',
      'top': '0',
      'left': '0',
      'right': '0',
      'border-top-left-radius': '${borderRadius.topLeft / kRemDivisor}rem',
      'border-top-right-radius': '${borderRadius.topRight / kRemDivisor}rem',
      'border-bottom-width': strokeWidthCss(toolbarBorderWidth),
      'border-bottom-style': 'solid',
      'backdrop-filter': 'blur(${toolbarBlur / kRemDivisor}rem)',
      '-webkit-backdrop-filter': 'blur(${toolbarBlur / kRemDivisor}rem)',
      ...?toolbarBackground.inline,
      ...?toolbarBorder.inline,
      'gap': spaceCss(toolbarSpacing),
      ...?toolbarPaddingEmit.inline,
      'height': '${toolbarHeight / kRemDivisor}rem',
    },
  );

  /// Composes the window-controls group `<div>` Tailwind className —
  /// flex centring, never shrinks under the address pill.
  String buildControlsClassName() => <String>[
    WebLayout.flex,
    WebLayout.itemsCenter,
    WebLayout.shrinkZero,
  ].join(' ');

  /// Composes the window-controls group `<div>` inline CSS — the dot gap.
  Styles buildControlsInlineStyles() => .new(
    raw: {'gap': spaceCss(controlSpacing)},
  );

  /// Composes a control dot `<div>` Tailwind className — the structural
  /// flag plus the dot's colour token class from the emit family (empty
  /// when the colour went inline) and the radius class (empty when
  /// overridden).
  String buildControlClassName(Emit colorEmit) => <String>[
    WebLayout.shrinkZero,
    colorEmit.className,
    controlRadiusEmit.className,
  ].where((cls) => cls.isNotEmpty).join(' ');

  /// Composes a control dot `<div>` inline CSS — the always-inline size
  /// shared across the three dots plus any radius / colour override from
  /// the emit family.
  Styles buildControlInlineStyles(Emit colorEmit) => .new(
    raw: {
      'width': '${controlSize / kRemDivisor}rem',
      'height': '${controlSize / kRemDivisor}rem',
      ...?controlRadiusEmit.inline,
      ...?colorEmit.inline,
    },
  );

  /// Composes the chevron group `<div>` Tailwind className — flex
  /// centring, never shrinks under the address pill.
  String buildNavClassName() => <String>[
    WebLayout.flex,
    WebLayout.itemsCenter,
    WebLayout.shrinkZero,
    capsuleBackground.className,
    capsuleRadius.className,
    capsulePadding.className,
  ].where((cls) => cls.isNotEmpty).join(' ');

  /// Composes the chevron group `<div>` inline CSS — the chevron gap.
  Styles buildNavInlineStyles() => .new(
    raw: {
      'gap': spaceCss(navSpacing),
      'height': '${capsuleHeight / kRemDivisor}rem',
      ...?capsuleBackground.inline,
      ...?capsuleRadius.inline,
      ...?capsulePadding.inline,
    },
  );

  /// Composes the address-bar pill `<div>` Tailwind className — vertical
  /// flex centring only (the label child spans the pill, so horizontal
  /// placement is the label's `text-align`, not `justify-content`), flex
  /// grow (`min-w-0` so a long URL shrinks instead of pushing the action
  /// off the bar), no native border, plus the emit-family typography role /
  /// colour / radius / padding class fragments.
  String buildAddressBarClassName() => <String>[
    WebLayout.flex,
    WebLayout.itemsCenter,
    WebLayout.flex1,
    WebLayout.minWZero,
    'border-none',
    addressBarTextEmit.className,
    addressBarBackgroundEmit.className,
    addressBarRadiusEmit.className,
    addressBarPaddingEmit.className,
  ].where((cls) => cls.isNotEmpty).join(' ');

  /// Composes the address-bar pill `<div>` inline CSS — the emit-family
  /// padding / radius / background / typography overlay inline fragments
  /// plus the resolved height.
  Styles buildAddressBarInlineStyles() => .new(
    raw: {
      ...?addressBarPaddingEmit.inline,
      ...?addressBarRadiusEmit.inline,
      ...?addressBarBackgroundEmit.inline,
      ...?addressBarTextEmit.inline,
      'height': '${addressBarHeight / kRemDivisor}rem',
      'gap': spaceCss(addressBarSpacing),
    },
  );

  /// Composes the address-bar label `<div>` Tailwind className — grows to
  /// the pill's full content width (`min-w-0` lets it shrink below the URL's
  /// intrinsic width) and truncates with an end ellipsis.
  String buildAddressBarLabelClassName() => <String>[
    if (merged.addressBarTextAlign != null) WebLayout.flex1,
    WebLayout.minWZero,
    WebLayout.truncate,
  ].join(' ');

  /// Composes the address-bar label `<div>` inline CSS — the resolved text
  /// alignment, which acts because the label spans the pill.
  Styles buildAddressBarLabelInlineStyles() => .new(
    raw: {'text-align': addressBarTextAlignCss},
  );

  /// Composes the trailing action slot `<div>` Tailwind className — flex
  /// centring in a capsule, never shrinks.
  String buildActionClassName() => buildNavClassName();

  Styles buildActionInlineStyles() => .new(
    raw: {
      'gap': spaceCss(actionSpacing),
      'height': '${capsuleHeight / kRemDivisor}rem',
      ...?capsuleBackground.inline,
      ...?capsuleRadius.inline,
      ...?capsulePadding.inline,
    },
  );

  /// Composes the child inset underneath the toolbar overlay.
  ///
  /// Pinned: the top band reserves exactly the toolbar's literal `height`,
  /// and the sides are the chrome width the card's corner radius is
  /// computed from — a re-mapped spacing variable would move the band and
  /// nothing it is measured against.
  Styles buildContentInsetInlineStyles() {
    final inset = pinnedLengthCss(chromeInset);
    return .new(
      raw: {
        'padding': '${pinnedLengthCss(toolbarHeight)} $inset $inset $inset',
      },
    );
  }

  /// Composes the content card `<div>` Tailwind className — the fill
  /// colour token class from the emit family (empty when overridden) plus
  /// the overflow clip so a screenshot child follows the rounded corners.
  String buildContentClassName() => <String>[
    contentBackgroundEmit.className,
    contentText.className,
    WebLayout.overflowHidden,
  ].where((cls) => cls.isNotEmpty).join(' ');

  /// Composes the content card `<div>` inline CSS — the concentric radius
  /// (always inline: it is derived, so no preset class can name it) plus
  /// any fill override from the emit family.
  Styles buildContentInlineStyles() => .new(
    raw: {
      'border-radius': contentBorderRadius.toValue(),
      'height': '100%',
      ...?contentText.inline,
      ...?contentBackgroundEmit.inline,
    },
  );

  // ─── Compose paint-ready chrome (RETURN = bare slot mapping) ──────────
  String buildDomainClassName() => 'flex items-center flex-1 min-w-0';
  Styles buildDomainInlineStyles() =>
      Styles(raw: {'gap': spaceCss(domainSpacing)});
  Styles buildWindowBorderInlineStyles() => Styles(
    raw: {
      'position': 'absolute',
      'inset': '0',
      'pointer-events': 'none',
      'border-radius': borderRadius.toValue(),
      'border-width': strokeWidthCss(borderWidth),
      'border-style': 'solid',
      ...?windowBorderColor.inline,
      'box-shadow':
          'inset 0 ${highlightWidth / kRemDivisor}rem 0 '
          '${highlightColor.toValue()}',
    },
  );

  return ResolvedMockupBrowser(
    body: const WebElementChrome(className: 'relative h-full'),
    domain: WebElementChrome(
      className: buildDomainClassName(),
      inlineStyles: buildDomainInlineStyles(),
    ),
    windowBorder: WebElementChrome(
      className: windowBorderColor.className,
      inlineStyles: buildWindowBorderInlineStyles(),
    ),
    addressIconStyle: addressIconStyle,
    root: WebElementChrome(className: buildRootClassName()),
    frameStyle: frameStyle,
    toolbar: WebElementChrome(
      className: buildToolbarClassName(),
      inlineStyles: buildToolbarInlineStyles(),
    ),
    controls: WebElementChrome(
      className: buildControlsClassName(),
      inlineStyles: buildControlsInlineStyles(),
    ),
    controlClose: WebElementChrome(
      className: buildControlClassName(controlCloseColorEmit),
      inlineStyles: buildControlInlineStyles(controlCloseColorEmit),
    ),
    controlMinimize: WebElementChrome(
      className: buildControlClassName(controlMinimizeColorEmit),
      inlineStyles: buildControlInlineStyles(controlMinimizeColorEmit),
    ),
    controlMaximize: WebElementChrome(
      className: buildControlClassName(controlMaximizeColorEmit),
      inlineStyles: buildControlInlineStyles(controlMaximizeColorEmit),
    ),
    nav: WebElementChrome(
      className: buildNavClassName(),
      inlineStyles: buildNavInlineStyles(),
    ),
    navIconStyle: navIconStyle,
    navDisabledIconStyle: navDisabledIconStyle,
    addressBar: WebElementChrome(
      className: buildAddressBarClassName(),
      inlineStyles: buildAddressBarInlineStyles(),
    ),
    addressBarLabel: WebElementChrome(
      className: buildAddressBarLabelClassName(),
      inlineStyles: buildAddressBarLabelInlineStyles(),
    ),
    action: WebElementChrome(
      className: buildActionClassName(),
      inlineStyles: buildActionInlineStyles(),
    ),
    actionIconStyle: actionIconStyle,
    contentInset: WebElementChrome(
      className: 'h-full',
      inlineStyles: buildContentInsetInlineStyles(),
    ),
    content: WebElementChrome(
      className: buildContentClassName(),
      inlineStyles: buildContentInlineStyles(),
    ),
  );
}
