import 'package:coui_flutter/coui_flutter.dart';

/// Paint-ready resolver output for Flutter `Alert`.
///
/// Widget tree (`alert.dart` decides which optional branches render):
///
/// ```text
/// ConstrainedBox (minHeight)
///   └─ OutlinedContainer (containerStyle — fill / border / radius / padding)
///        └─ Row (gap via Gap between children — iconContentGapStyle)
///             ├─ Icon (variant icon, iconStyle)   // when leading == null
///             │  or IconTheme (iconStyle.size, iconColor)
///             │       └─ leading                  // when leading != null
///             ├─ Expanded > Column
///             │    ├─ DefaultTextStyle (titleTextStyle)
///             │    │    └─ Text (title, titleMaxLines / titleOverflow)
///             │    └─ Padding (top: titleBottomPadding) // stacked only, and
///             │         └─ DefaultTextStyle               // only when
///             │              └─ Text (description)        // description != null
///             ├─ action                            // rendered only when action != null
///             └─ Button.plain (closeButtonStyle)  // rendered only when onDismiss != null
///                  └─ Icon (closeButtonStyle.leadingIconStyle)
/// ```
///
/// Every field is paint-ready: Flutter framework widgets receive their
/// native type (`Color`, `BorderRadius`, `EdgeInsets`, `TextStyle`),
/// child CoUI components receive their contract type
/// (`Icon` ← `CoreIconStyle`, `FocusOutline` ←
/// `CoreFocusOutlineStyle`). Scaling is pre-applied so the widget
/// does not multiply by `theme.scaling` itself.
///
/// Per Epic #1603 옵션 B 최종: no scalar semantic metadata is exposed
/// here — the widget's `variant` prop drives the glyph selection
/// directly. The theme cannot override the variant.
class ResolvedAlert {
  /// Creates a [ResolvedAlert].
  const ResolvedAlert({
    required this.containerStyle,
    required this.backgroundColor,
    required this.borderColor,
    required this.borderRadius,
    required this.borderWidth,
    required this.padding,
    required this.iconContentGapStyle,
    required this.titleTextStyle,
    required this.descriptionTextStyle,
    required this.iconStyle,
    required this.titleBottomPadding,
    required this.closeButtonStyle,
    required this.actionButtonStyle,
    required this.minHeight,
    required this.dismissColor,
    required this.iconColor,
    required this.titleMaxLines,
    required this.titleOverflow,
  });

  /// Child-component contract slot for the composed `OutlinedContainer`,
  /// which owns the panel box — fill, border, radius, padding, and the
  /// style's injected cast.
  ///
  /// Carries *pre-EMIT* Core values on purpose: `OutlinedContainer` runs
  /// the same `scheme.resolve` / `geometry.stroke` / scaling steps this
  /// resolver would, so handing it finished Flutter values would bend
  /// them twice.
  ///
  /// The paint-ready [backgroundColor] / [borderColor] / [borderRadius] /
  /// [borderWidth] / [padding] below stay for the callers that read them
  /// directly; the box itself is no longer drawn from them.
  final CoreOutlinedContainerStyle containerStyle;

  /// Effective panel background fill.
  final Color backgroundColor;

  /// Effective border stroke colour.
  final Color borderColor;

  /// Effective border radius (scaling pre-applied).
  final BorderRadius borderRadius;

  /// Effective border stroke width (logical px).
  final double borderWidth;

  /// Effective padding (scaling pre-applied).
  final EdgeInsetsGeometry padding;

  /// Nested [CoreGapStyle] slot for the gap between the leading icon
  /// and the content column / trailing slots — forwarded straight to
  /// `Gap(gapStyle: …)`. `Gap` runs its own resolve step, so this
  /// slot is the merged design-system default + per-instance override
  /// in pre-scaling units (the receiving widget owns scaling).
  final CoreGapStyle iconContentGapStyle;

  /// Paint-ready title [TextStyle] — the layout's title role
  /// (`labelLarge` at 600 stacked, `bodySmall` inline) composed with the
  /// resolved title colour and the `titleStyle` slot's overrides
  /// (font size / weight / colour).
  final TextStyle titleTextStyle;

  /// Paint-ready description [TextStyle] — same composition as
  /// [titleTextStyle], from `theme.typography.bodySmall`.
  final TextStyle descriptionTextStyle;

  /// Variant-icon [CoreIconStyle] passed to `Icon(iconStyle: ...)`.
  /// `size` and `color` are both filled in (size + slot override as a token
  /// size — `Icon` applies the theme scaling itself; colour from variant or
  /// slot override).
  final CoreIconStyle iconStyle;

  /// Bottom padding under the title (scaling applied) — gap between
  /// title and description.
  final double titleBottomPadding;

  /// Nested `CoreButtonStyle` slot for the dismiss affordance —
  /// `CoreAlertStyle.defaultCloseButtonStyle` chained with the
  /// variant-foreground injection layer (icon colour at the idle
  /// opacity, full icon colour on hover) and the per-instance
  /// override, then raw-forwarded to
  /// `Button(variant: .plain, buttonStyle: …)`. `Button` resolves
  /// its own padding / radius / hover-fade / focus ring and
  /// self-applies `theme.scaling`.
  final CoreButtonStyle closeButtonStyle;

  /// Nested `CoreButtonStyle` slot — forwarded to the action when it is
  /// a `Button`. `null` when the caller supplied no action-button
  /// chrome override. Mirrors the Web `ResolvedAlert.actionButtonStyle`
  /// slot (Epic #2210 RULE E coverage).
  final CoreButtonStyle? actionButtonStyle;

  /// Minimum card height (logical px, scaling applied). Paired with centre
  /// cross-axis alignment in the widget so a description-less alert keeps
  /// the same height instead of collapsing around one line. `0` in the
  /// inline layout, which has no floor.
  final double minHeight;

  /// Resolved dismiss-glyph colour, at full strength — the alert no longer
  /// dims it with an opacity multiplier.
  final Color dismissColor;

  /// Resolved tone-glyph colour — the same colour [iconStyle] carries as a
  /// token, finished, for the ambient `IconTheme` a caller's `leading`
  /// widget sits under. A bare icon passed as `leading` then matches the
  /// glyph it replaces.
  final Color iconColor;

  /// Title line cap — `1` in the inline layout, `null` (wrap freely) in
  /// the stacked one.
  final int? titleMaxLines;

  /// How a capped title ends — an ellipsis in the inline layout, `null`
  /// (the framework default) in the stacked one.
  final TextOverflow? titleOverflow;
}

/// Resolves [ResolvedAlert] for [Alert].
///
/// Single entry point — reads [CoreAlertTheme] from
/// `Theme.of(context).coreComponentTheme` itself so callers never
/// touch `coreComponentTheme` directly.
///
/// Merge chain: variant chrome ([CoreAlertStyle.defaultsByVariant])
/// + layout measurements ([CoreAlertStyle.defaultsByLayout]) + chrome
/// defaults ([CoreAlertStyle] `static const default*`) →
/// [CoreAlertTheme.style] → [CoreAlertTheme.variantStyles] →
/// `widget.alertStyle`. The semantic [variant] and [layout] are
/// widget-only (Epic #1603 옵션 B 최종) — the theme cannot override
/// them. [layout] defaults to [CoreAlertLayout.defaultLayout], so a caller
/// that predates it resolves the stacked panel it always did.
ResolvedAlert resolveAlert(
  BuildContext context, {
  required CoreAlertVariant variant,
  CoreAlertLayout layout = CoreAlertLayout.defaultLayout,
  CoreAlertStyle? alertStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final alertTheme = theme.coreComponentTheme?.alert;

  // ─── Merge chain ──────────────────────────────────────
  final merged = resolveStyleChain(const CoreAlertStyle(), [
    alertTheme?.style,
    alertTheme?.variantStyles?[variant],
    alertStyle,
  ]);

  // ─── Token tables ─────────────────────────────────────
  // Per Epic #1603 옵션 B 최종: the widget's `variant` prop drives the
  // variant token table directly — the theme cannot override the
  // semantic variant.
  final variantStyle = CoreAlertStyle.defaultsByVariant[variant]!;
  // The layout's measurements — padding, floor, gap, glyph size, title role
  // and colour. Read under the merge chain, so an override wins in either
  // layout. Every row states all six, hence the `!` below.
  final chrome = CoreAlertStyle.defaultsByLayout[layout]!;

  // ─── Resolved chrome (plain values, scaling pre-applied) ─
  // Surface-level chrome (background / border / foreground) resolves
  // to plain Flutter `Color` here because the widget paints with
  // `DecoratedBox` / `Border.all` directly. Nested component slots
  // (`iconStyle` / `titleTextStyle`) keep the value-type the child
  // component's contract accepts — `Icon` takes `CoreIconStyle?`,
  // `DefaultTextStyle` takes `TextStyle`.
  final bgColor = scheme
      .resolve(merged.backgroundColor ?? variantStyle.backgroundColor)
      .toValue();
  // No border by design (`defaultBorderWidth` is stroke0). The slot stays
  // so a caller can still opt one back in; when nothing states a colour it
  // resolves transparent, and the zero width means nothing paints anyway.
  final bdColor = scheme
      .resolve(merged.borderColor ?? CoreAlertStyle.defaultBorderColor)
      .toValue();
  // A tone's title takes the glyph's colour; `neutral` states none and keeps
  // the layout's. `titleColor` outranks `foregroundColor` here and on Web.
  final fgColor = scheme
      .resolve(
        merged.titleColor ??
            merged.foregroundColor ??
            variantStyle.titleColor ??
            chrome.titleColor!,
      )
      .toValue();
  final descriptionColor = scheme
      .resolve(merged.foregroundColor ?? variantStyle.descriptionColor)
      .toValue();
  final dismissCore = merged.dismissColor ?? CoreAlertStyle.defaultDismissColor;
  final dismissColor = scheme.resolve(dismissCore).toValue();
  final minHeight = (merged.minHeight ?? chrome.minHeight!) * scaling;

  // The panel box is composed, not drawn here — `OutlinedContainer` owns
  // it, the way the card's does. Passing Core values (not the resolved
  // ones below) is what keeps the geometry bend applied exactly once:
  // that component runs `scheme.resolve` / `geometry.stroke` / scaling
  // itself. Composing is also what gets this surface the style's injected
  // cast, which it drew nothing of while it owned its own `BoxDecoration`.
  final authoredBorderWidth =
      merged.borderWidth ?? CoreAlertStyle.defaultBorderWidth;
  // This surface qualifies for a style's contributed boundary: it draws
  // its own opaque fill and reads as one discrete object, and at either
  // layout's height (the 64 floor, the 44 strip) a contributed stroke has
  // room to sit without swallowing it (unlike a switch track or a progress
  // rail).
  //
  // It needs the contribution rather than the stroke floor because the
  // redesign took its border away. A floor can only raise a width that is
  // already painted, so the moment the authored width became 0 the floor
  // had nothing to lift and this surface went unboxed under a style whose
  // whole identity is that everything is boxed. That is a change to how
  // Alert renders under `neoBrutalism`, not a change to Alert.
  final injectedBorder = resolveInjectedBorderSpec(
    theme,
    authoredWidth: authoredBorderWidth,
  );

  final containerStyle = CoreOutlinedContainerStyle(
    backgroundColor: merged.backgroundColor ?? variantStyle.backgroundColor,
    // No border by design; the slot stays so a caller can opt one back in,
    // and a caller who does outranks the contribution.
    borderColor: merged.borderColor ?? injectedBorder?.color,
    borderRadius: merged.borderRadius ?? CoreAlertStyle.defaultBorderRadius,
    borderWidth: injectedBorder?.width ?? authoredBorderWidth,
    padding: merged.padding ?? chrome.padding,
  );

  final borderRadius =
      ((merged.borderRadius ?? CoreAlertStyle.defaultBorderRadius).toValue(
        geometry: theme.geometry,
      )) *
      scaling;
  // Border width is the only chrome left in pre-scaling units: a stroke
  // width is a physical hairline, not a layout dimension, so it must not
  // grow with `theme.scaling` (Epic #1603 C12 — stroke width is
  // deliberately unscaled, mirroring the Web border-width-in-px rule).
  final borderWidth = theme.geometry.stroke(
    merged.borderWidth ?? CoreAlertStyle.defaultBorderWidth,
  );
  // The stacked panel's horizontal padding is asymmetric (16 leading /
  // 12 trailing), so it is declared directionally and must stay that way
  // through to paint — flattening it would be right in English and wrong
  // in Arabic.
  final padding =
      ((merged.padding ?? chrome.padding!).toGeometry(
        geometry: theme.geometry,
      )) *
      scaling;
  // Nested `CoreGapStyle` slot — merge the layout's gap with the
  // per-instance override and forward raw (pre-scaling) to `Gap`, which
  // runs its own resolve / scaling step.
  final iconContentGapStyle = chrome.iconContentGapStyle!.merge(
    merged.iconContentGapStyle,
  );
  // Merge the layout's icon style with the per-instance override. The size
  // stays a token size: `Icon` multiplies its own box by the theme scaling
  // (and reads its stroke rule from the token size), so a size multiplied
  // here would be multiplied again — 16 drawn 25 on a 1.25× screen. The
  // merged colour (variant fallback) flows through as `CoreColor` because
  // `Icon` runs the final `scheme.resolve` itself.
  final mergedIconStyle = chrome.iconStyle!.merge(merged.iconStyle);
  final iconSize = mergedIconStyle.size!;
  final titleBottomPadding =
      theme.geometry.space(
        merged.titleBottomMargin ?? CoreAlertStyle.defaultTitleBottomMargin,
      ) *
      scaling;

  // ─── Paint-ready typography ───────────────────────────
  // EMIT Stage 2 (Flutter) — `style.toValue(theme:)` materialises the
  // token role (`labelLarge` / `bodySmall`) through the active theme
  // and resolves any explicit slot colour through the scheme. The
  // `color:` override forces the alert foreground when the per-instance
  // slot carries no explicit colour, so the text tracks the variant
  // foreground. Single primitive — no hand-rolled fontSize/fontWeight
  // assembly (badge reference parity).
  final baseTitleCore = chrome.titleStyle!.merge(merged.titleStyle);
  final titleTextStyle = baseTitleCore.toValue(
    color: merged.titleStyle?.color == null ? fgColor : null,
    theme: theme,
  );

  final baseDescriptionCore = CoreAlertStyle.defaultDescriptionStyle.merge(
    merged.descriptionStyle,
  );
  // Description reads `onSurfaceVariant` on every tone (the variant row
  // states it), unless the caller's `foregroundColor` says otherwise.
  final descriptionTextStyle = baseDescriptionCore.toValue(
    color: merged.descriptionStyle?.color == null ? descriptionColor : null,
    theme: theme,
  );

  // ─── Variant icon style ───────────────────────────────
  // `Icon` accepts `CoreIconStyle?`; colour stays as `CoreColor` so
  // `Icon`'s own resolver runs the final `scheme.resolve` step.
  final iconColorCore = mergedIconStyle.color ?? variantStyle.iconColor;
  final iconStyle = CoreIconStyle(size: iconSize, color: iconColorCore);
  // The same colour, finished, for the ambient `IconTheme` a caller's
  // `leading` widget sits under — `IconThemeData` takes a `Color`.
  final iconColor = scheme.resolve(iconColorCore).toValue();

  // ─── Title line cap ───────────────────────────────────
  // The layout states the cap (`CoreAlertLayout.titleMaxLines`) and Web
  // reads the same one: the inline strip is one line by definition, so the
  // title ellipsizes rather than wrapping. The full title stays the
  // accessible name.
  final titleMaxLines = layout.titleMaxLines;
  final titleOverflow = titleMaxLines == null ? null : TextOverflow.ellipsis;

  // ─── Dismiss button (Button.plain) chrome ───────────
  // Chained `defaultCloseButtonStyle` (4-px tap padding, 4-px corner
  // radius, 150 ms hover transition, 16-px close glyph), tinted with
  // `dismissCore` below, then the per-instance override on top (so a
  // caller `closeButtonStyle` still wins). Raw-forwarded
  // to `Button(variant: .plain, buttonStyle: …)` — the button
  // resolves its own padding / icon / hover-fade / focus-ring and
  // self-applies `theme.scaling`, so the resolver does NOT scale here
  // (Anti-Pattern A, mirrors the toast close button).
  // The glyph states `on-surface-variant` outright, resting and hovered
  // alike. A tint multiplied by an opacity resolves against whatever
  // panel sits behind it, so no contrast guard can read the result; a
  // token can. A caller wanting a different dismiss colour sets
  // `closeButtonStyle.foregroundColor` to a token.
  final closeButtonStyle = CoreAlertStyle.defaultCloseButtonStyle
      .merge(
        CoreButtonStyle(
          foregroundColor: dismissCore,
          hoverForegroundColor: dismissCore,
        ),
      )
      .merge(merged.closeButtonStyle);

  // Action-button slot — raw-forwarded as a nested Style slot. The widget
  // lays it under a `Button` action's own `buttonStyle`, the same as Web.
  final actionButtonStyle = merged.actionButtonStyle;

  return ResolvedAlert(
    containerStyle: containerStyle,
    backgroundColor: bgColor,
    borderColor: bdColor,
    borderRadius: borderRadius,
    borderWidth: borderWidth,
    padding: padding,
    iconContentGapStyle: iconContentGapStyle,
    titleTextStyle: titleTextStyle,
    descriptionTextStyle: descriptionTextStyle,
    iconStyle: iconStyle,
    titleBottomPadding: titleBottomPadding,
    closeButtonStyle: closeButtonStyle,
    actionButtonStyle: actionButtonStyle,
    minHeight: minHeight,
    dismissColor: dismissColor,
    iconColor: iconColor,
    titleMaxLines: titleMaxLines,
    titleOverflow: titleOverflow,
  );
}
