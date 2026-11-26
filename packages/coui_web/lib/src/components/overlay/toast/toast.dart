import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/components/control/button/button.dart';
import 'package:coui_web/src/components/icon/icon.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:coui_web/src/components/overlay/toast/toast_style.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' hide Text;

/// A unified toast notification card for CoUI Web.
///
/// Renders a notification card with [message], optional [description],
/// variant styling, and an optional dismiss button.
///
/// Per Epic #1302, all panel-chrome / dimensional / slot-style
/// overrides flow through [toastStyle] (`CoreToastStyle`).
/// Semantic [variant] stays as a top-level component parameter (원칙
/// 6/7); to change the action's variant inject a [Button] directly
/// via the [action] slot (asChild pattern, 원칙 8).
///
/// Example:
/// ```dart
/// Toast(
///   message: 'Changes saved.',
///   description: 'Your data has been updated successfully.',
///   variant: CoreToastVariant.neutral,
///   onDismiss: () => removeToast(),
/// )
/// ```
///
/// surface:behind — floats over the page and then leaves. What is behind it is
/// whatever the reader was already looking at.
///
/// surface:functional — floats in over the page and leaves; the page is
/// what is behind it.
class Toast extends UiComponent implements CoreToastContract<Component> {
  /// Creates a [Toast].
  Toast({
    required this.message,
    this.description,
    this.variant = CoreToastVariant.defaultVariant,
    this.showIcon = CoreToastContract.defaultShowIcon,
    this.onDismiss,
    this.action,
    this.toastStyle,
    super.key,
    super.id,
  }) : super(tag: 'div');

  @override
  final String message;

  @override
  final String? description;

  @override
  final CoreToastVariant variant;

  @override
  final bool showIcon;

  @override
  final CoreVoidCallback? onDismiss;

  @override
  final Component? action;

  @override
  final CoreToastStyle? toastStyle;

  @override
  Toast copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    String? message,
    String? description,
    CoreToastVariant? variant,
    bool? showIcon,
    CoreVoidCallback? onDismiss,
    Component? action,
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
      id: id ?? this.id,
    );
  }

  @override
  Component build(BuildContext context) {
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
    // this switch ever disagree, the toast would draw an uncoloured glyph
    // or reserve a gap for one it never draws.
    final iconStyle = resolved.iconStyle;

    final contentChildren = <Component>[
      // The leading glyph. No glyph means no gap either — an invisible one
      // would still occupy its width and its spacer. `showIcon` off is the
      // same case by the caller's choice: the glyph and the gap after it
      // leave together, and the text starts at the panel's inset.
      if (showIcon && glyph != null && iconStyle != null) ...[
        Icon(glyph, iconStyle: iconStyle),
        Gap(gapStyle: resolved.iconContentGapStyle),
      ],
      // Content area — message ↔ description spacer is a nested
      // `Gap` (Epic #1603 옵션 B nested-slot forwarding).
      div(
        [
          // Message.
          div(
            [Text(message)],
            classes: resolved.message.className,
            styles: resolved.message.inlineStyles,
          ),
          // Description.
          if (description != null) ...[
            Gap(gapStyle: resolved.messageDescriptionGapStyle),
            div(
              [Text(description!)],
              classes: resolved.description.className,
              styles: resolved.description.inlineStyles,
            ),
          ],
        ],
        classes: resolved.content.className,
        styles: resolved.content.inlineStyles,
      ),
    ];

    // Action widget — forward the nested action-button style slot to a
    // `Button` action (Epic #1603 옵션 B; other action types render
    // as-is via the asChild pattern). The content ↔ action spacer is a
    // nested `Gap` so the gap goes through the unified gap widget.
    final currentAction = action;
    if (currentAction != null) {
      contentChildren.add(Gap(gapStyle: resolved.contentActionGapStyle));
      contentChildren.add(
        currentAction is Button
            ? currentAction.copyWith(
                buttonStyle:
                    (currentAction.variant == CoreButtonVariant.plain
                            ? resolved.plainActionButtonStyle
                            : resolved.actionButtonStyle)
                        .merge(
                          currentAction.buttonStyle,
                        ),
              )
            : currentAction,
      );
    }

    // Close button — unified `Button(variant: .plain)` inside an
    // absolutely-positioned wrapper (the wrapper carries the corner
    // inset; the `plain` variant owns the resting-opacity / hover-fade /
    // foreground). The close glyph is a `Icon` child whose size comes
    // from the slot's `leadingIconStyle` and whose colour is null so it
    // inherits the button foreground.
    if (onDismiss != null) {
      contentChildren.add(
        div(
          [
            Button(
              onPressed: () => onDismiss?.call(),
              variant: .plain,
              shape: .square,
              buttonStyle: resolved.closeButtonStyle,
              attributes: {
                'aria-label': CouiLocalizations.of(context).buttonClose,
              },
              child: Icon(
                LucideIcons.x,
                iconStyle: resolved.closeButtonStyle.leadingIconStyle,
              ),
            ),
          ],
          classes: resolved.closeWrapper.className,
          styles: resolved.closeWrapper.inlineStyles,
        ),
      );
    }

    return Component.element(
      tag: tag,
      id: id,
      classes: [
        resolved.root.className,
        ?classes,
      ].where((c) => c.isNotEmpty).join(' '),
      styles: Styles.combine([
        ?resolved.root.inlineStyles,
        ?this.css,
      ]),
      attributes: {
        ...this.componentAttributes,
        'role': 'status',
        'aria-live': 'polite',
      },
      events: this.events,
      children: contentChildren,
    );
  }
}

/// Chain sugar mirroring the Flutter `Toast.withStyle` extension —
/// merges a [CoreToastStyle] patch into [Toast.toastStyle] via the
/// existing [Toast.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreToastStyle.merge` right-side-wins semantics).
extension ToastStyleChain on Toast {
  /// Returns a copy of this [Toast] with [patch] merged into
  /// [toastStyle] (patch fields win on conflict).
  Toast withStyle(CoreToastStyle patch) =>
      copyWith(toastStyle: (toastStyle ?? const CoreToastStyle()).merge(patch));
}
