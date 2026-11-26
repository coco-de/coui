import 'package:coui_flutter/coui_flutter.dart';

/// A unified toast notification card.
///
/// Renders a notification card with [message], optional [description],
/// variant styling, and an optional dismiss button. Designed to be used
/// as the content inside [showToast]'s builder callback.
///
/// Per Epic #1302, all panel-chrome / dimensional / slot-style
/// overrides flow through [toastStyle] (`CoreToastStyle`).
/// Semantic [variant] stays as a top-level widget parameter (원칙 6/7);
/// to change the action's variant inject a [Button] directly via the
/// [action] slot (asChild pattern, 원칙 8).
///
/// Example:
/// ```dart
/// showToast(
///   context: context,
///   builder: (context, overlay) => Toast(
///     message: 'Changes saved.',
///     description: 'Your data has been updated successfully.',
///     onDismiss: overlay.close,
///   ),
/// );
/// ```
///
/// surface:behind — floats over the page and then leaves. What is behind it is
/// whatever the reader was already looking at.
///
/// surface:functional — floats in over the page and leaves; the page is
/// what is behind it.
class Toast extends StatelessWidget implements CoreToastContract<Widget> {
  /// Creates a [Toast].
  const Toast({
    required this.message,
    this.description,
    this.variant = CoreToastVariant.defaultVariant,
    this.showIcon = CoreToastContract.defaultShowIcon,
    this.onDismiss,
    this.action,
    this.toastStyle,
    super.key,
  });

  @override
  final String message;

  @override
  final String? description;

  @override
  final CoreToastVariant variant;

  @override
  final bool showIcon;

  @override
  final VoidCallback? onDismiss;

  @override
  final Widget? action;

  @override
  final CoreToastStyle? toastStyle;

  /// Returns a copy of this [Toast] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Toast copyWith({
    Key? key,
    VoidCallback? onDismiss,
    String? message,
    String? description,
    CoreToastVariant? variant,
    bool? showIcon,
    Widget? action,
    CoreToastStyle? toastStyle,
  }) {
    return Toast(
      key: key ?? this.key,
      message: message ?? this.message,
      description: description ?? this.description,
      variant: variant ?? this.variant,
      showIcon: showIcon ?? this.showIcon,
      onDismiss: onDismiss ?? this.onDismiss,
      action: action ?? this.action,
      toastStyle: toastStyle ?? this.toastStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveToast(
      context,
      variant: variant,
      dismissible: onDismiss != null,
      toastStyle: toastStyle,
    );

    // Which glyph, in one place. `neutral` has none — that absence is what
    // makes it neutral, since all three variants fill with the same inverse
    // surface and ink, and the glyph's shape is what distinguishes them.
    //
    // The identity branches on the variant here rather than living in the
    // Style: it is a semantic identifier, not chrome, the same way `Alert`
    // picks its own.
    final glyph = switch (variant) {
      .success => LucideIcons.circleCheck,
      .destructive => LucideIcons.circleAlert,
      .neutral => null,
    };
    // The resolver reaches the same conclusion from the variant table's
    // `iconColor`. Read together rather than trusting one: if the table and
    // this switch ever disagree, the toast would draw an uncoloured glyph or
    // reserve a gap for one it never draws.
    final iconStyle = resolved.iconStyle;

    // The style's rim rides over the panel, clipped to its corners — the
    // twin of the `kSurfaceRimVar` layer the Web panel appends to its own
    // `box-shadow`. Empty (and so no wrapper at all) under every style that
    // states no rim.
    Widget panel = InsetShadow(
      shadows: resolved.insetBoxShadow,
      radius: resolved.borderRadius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: resolved.backgroundColor,
          border: Border.all(
            color: resolved.borderColor,
            width: resolved.borderWidth,
          ),
          borderRadius: resolved.borderRadius,
          // Behind a translucent fill the cast is painted outside the box
          // instead (below).
          boxShadow: resolved.castOutsideBox ? null : resolved.shadow,
        ),
        // 닫기 버튼은 패널 기준 Position(closeInset)으로 앵커한다 — 패딩
        // 박스 안에서 음수 오프셋으로 돌출시키면 Stack 경계 밖이 되어
        // Flutter hit-test 가 버튼을 통째로 놓친다 (클릭/hover 불능; 웹
        // absolute 는 경계 밖도 히트됨). Stacks 가 패널 전체를 차지하고
        // content 만 Padding 으로 들어가면 버튼이 경계 안에 남는다.
        child: Stacks(
          children: [
            // Content area. The floor is on the padded box, not the row: a
            // one-line toast is shorter than `minHeight` on padding alone,
            // and the row centres its children in whatever height the floor
            // leaves it (Row's default cross alignment).
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: resolved.minHeight),
              child: Padding(
                padding: resolved.padding,
                child: Row(
                  children: [
                    // No glyph means no gap either — an invisible glyph would
                    // still occupy its width and its spacer. `showIcon` off
                    // is the same case by the caller's choice: the glyph and
                    // the gap after it leave together, and the text starts
                    // at the panel's inset.
                    if (showIcon && glyph != null && iconStyle != null) ...[
                      Icon(glyph, iconStyle: iconStyle),
                      Gap(gapStyle: resolved.iconContentGapStyle),
                    ],
                    Expanded(
                      child: Column(
                        mainAxisSize: .min,
                        crossAxisAlignment: .start,
                        children: [
                          // Message.
                          DefaultTextStyle.merge(
                            style: resolved.messageStyle,
                            child: Text(message),
                          ),
                          // Description.
                          if (description != null) ...[
                            Gap(
                              gapStyle: resolved.messageDescriptionGapStyle,
                            ),
                            DefaultTextStyle.merge(
                              style: resolved.descriptionStyle,
                              child: Text(description!),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Action widget — a `Button` action gets the resolved
                    // action chrome merged UNDER its own `buttonStyle`
                    // (variant foreground for the slab; the caller's fields
                    // win). Any other widget passes through (asChild). Same
                    // shape as Web; this side used to drop the slot on the
                    // floor, so a caller override could not fix the
                    // contrast here even when it did on Web.
                    if (action != null) ...[
                      Gap(gapStyle: resolved.contentActionGapStyle),
                      if (action case final Button button)
                        button.copyWith(
                          buttonStyle:
                              (button.variant == CoreButtonVariant.plain
                                      ? resolved.plainActionButtonStyle
                                      : resolved.actionButtonStyle)
                                  .merge(
                                    button.buttonStyle,
                                  ),
                        )
                      else
                        action!,
                    ],
                  ],
                ),
              ),
            ),
            // Close button — unified `Button(variant: .plain)`; the
            // `plain` variant owns the resting-opacity / hover-fade /
            // foreground, and `resolved.closeButtonStyle` (raw-forward)
            // supplies the tap-target padding / close glyph / hover
            // transition / focus-ring / variant foreground. The close
            // glyph is a `Icon` child (size from the slot's
            // `leadingIconStyle`; colour null so it inherits the
            // button's foreground via the ambient `IconTheme`).
            //
            // Pinned top and bottom so the button centres in the band the
            // block insets leave — by default the panel's whole height, so
            // the 40 × 40 circle sits on the panel's centre line however
            // many lines the toast holds. The Web twin centres the same way.
            if (onDismiss != null)
              Position(
                top: resolved.closeInset.top,
                right: resolved.closeInset.right,
                bottom: resolved.closeInset.bottom,
                child: Align(
                  // Icon-only, so the button has no text to name it — without
                  // this the reader announces an unnamed "button". The Web
                  // twin already emits the same string as `aria-label`.
                  child: Semantics(
                    button: true,
                    label: CoUILocalizations.of(context).buttonClose,
                    child: Button(
                      onPressed: onDismiss,
                      variant: .plain,
                      shape: .square,
                      buttonStyle: resolved.closeButtonStyle,
                      child: Icon(
                        LucideIcons.x,
                        iconStyle: resolved.closeButtonStyle.leadingIconStyle,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    // The resolver hands these over only when the panel states a fill,
    // so a fill-less toast never stacks a second backdrop pass. The
    // radius bounds the pass to the panel shape — without it the blur
    // squares off the corners it is drawn behind.
    final effectiveBlur = resolved.surfaceBlur;
    if ((effectiveBlur != null && effectiveBlur > 0) ||
        resolved.surfaceSheen != null) {
      panel = SurfaceBlur(
        borderRadius: resolved.borderRadius,
        surfaceBlur: effectiveBlur,
        surfaceSaturation: resolved.surfaceSaturation,
        surfaceBackdropBrightness: resolved.surfaceBackdropBrightness,
        surfaceSheen: resolved.surfaceSheen,
        // The active material's bend. Every surface that draws the material
        // draws all of it — the frost and the chroma without the bend is a
        // blurred panel, not glass, and the bend is the term the material
        // is named for.
        //
        // Falls back rather than being required: a style that states no
        // refraction leaves this null and the surface simply does not
        // bend, which is how every preset but glass renders.
        refraction: Theme.of(context).surfaceRefraction,
        child: panel,
      );
    }

    // Behind a fill that is not opaque, the cast goes outside the box, around
    // the whole panel with its blur ([ResolvedToast.castOutsideBox]).
    if (resolved.castOutsideBox) {
      panel = InjectedCast(
        shadows: resolved.shadow,
        borderRadius: resolved.borderRadius,
        child: panel,
      );
    }

    return Semantics(
      liveRegion: true,
      child: panel,
    );
  }
}

/// Chain sugar for merging a [CoreToastStyle] patch into
/// [Toast.toastStyle] without hand-reconstructing every field. Mirrors
/// the Web `Toast.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreToastStyle.merge` right-side-wins semantics).
extension ToastStyleChain on Toast {
  /// Returns a copy of this [Toast] with [patch] merged into
  /// [toastStyle] (patch fields win on conflict).
  Toast withStyle(CoreToastStyle patch) =>
      copyWith(toastStyle: (toastStyle ?? const CoreToastStyle()).merge(patch));
}
