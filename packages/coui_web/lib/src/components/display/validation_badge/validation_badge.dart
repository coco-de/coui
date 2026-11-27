import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/display/validation_badge/validation_badge_style.dart';
import 'package:coui_web/src/components/icon/icon.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:jaspr/dom.dart' show Styles;
import 'package:jaspr/jaspr.dart' hide Text;

/// Cross-platform validation badge — communicates the result of a single
/// validation rule (pending / valid / invalid) with a colored chip-style
/// container, an icon, and a label.
///
/// Per Epic #1603 옵션 B 최종 the semantic identifiers (`state`, `size`)
/// stay on the widget; every chrome / colour override flows through the
/// single [style] (a [CoreValidationBadgeStyle]). The state icon glyph
/// is picked here from the semantic `state` prop (mirrors `Alert`
/// variant → icon switch); the theme cannot override it.
///
/// ```dart
/// ValidationBadge(
///   label: '8 characters or more',
///   state: password.length >= 8
///       ? CoreValidationState.valid
///       : CoreValidationState.invalid,
/// );
/// ```
///
/// surface:behind — whatever the badge is set inline against. Its root
/// is a fixed `<span>` — wrapping it in `OutlinedContainer`'s `<div>`
/// would break the inline flow it is meant to sit in (#4358) — so the
/// marker is restated on this element directly.
///
/// surface:content — a state chip in the content layer, not a floating
/// affordance: no sticky, fixed, or overlay mount.
class ValidationBadge extends UiComponent
    implements CoreValidationBadgeContract {
  /// Creates a [ValidationBadge].
  const ValidationBadge({
    required this.label,
    required this.state,
    this.labelMaxLines,
    this.labelOverflow,
    super.attributes,
    super.classes,
    super.css,
    super.eventHandlers,
    super.id,
    super.key,
    this.pendingIcon,
    this.validIcon,
    this.invalidIcon,
    this.size,
    this.style,
  }) : super(tag: 'span');

  /// Bool-based factory: `isValid` true → valid, false → invalid.
  factory ValidationBadge.fromBool({
    required String label,
    required bool isValid,
    Key? key,
    int? labelMaxLines,
    CoreTextOverflow? labelOverflow,
    IconName? validIcon,
    IconName? invalidIcon,
    CoreValidationBadgeSize? size,
    CoreValidationBadgeStyle? style,
  }) => ValidationBadge(
    key: key,
    label: label,
    labelMaxLines: labelMaxLines,
    labelOverflow: labelOverflow,
    state: isValid ? .valid : .invalid,
    validIcon: validIcon,
    invalidIcon: invalidIcon,
    size: size,
    style: style,
  );

  /// Three-state factory: untouched input shows pending; touched input
  /// shows valid/invalid based on [isValid].
  factory ValidationBadge.withPending({
    required String label,
    required bool hasInput,
    required bool isValid,
    Key? key,
    int? labelMaxLines,
    CoreTextOverflow? labelOverflow,
    IconName? pendingIcon,
    IconName? validIcon,
    IconName? invalidIcon,
    CoreValidationBadgeSize? size,
    CoreValidationBadgeStyle? style,
  }) {
    final CoreValidationState state = !hasInput
        ? .pending
        : isValid
        ? .valid
        : .invalid;
    return ValidationBadge(
      key: key,
      label: label,
      labelMaxLines: labelMaxLines,
      labelOverflow: labelOverflow,
      state: state,
      pendingIcon: pendingIcon,
      validIcon: validIcon,
      invalidIcon: invalidIcon,
      size: size,
      style: style,
    );
  }

  @override
  final String label;

  @override
  final int? labelMaxLines;

  @override
  final CoreTextOverflow? labelOverflow;

  @override
  final CoreValidationState state;

  @override
  final IconName? pendingIcon;

  @override
  final IconName? validIcon;

  @override
  final IconName? invalidIcon;

  @override
  final CoreValidationBadgeSize? size;

  @override
  final CoreValidationBadgeStyle? style;

  @override
  ValidationBadge copyWith({
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
    String? label,
    int? labelMaxLines,
    CoreTextOverflow? labelOverflow,
    CoreValidationState? state,
    IconName? pendingIcon,
    IconName? validIcon,
    IconName? invalidIcon,
    CoreValidationBadgeSize? size,
    CoreValidationBadgeStyle? style,
  }) {
    return ValidationBadge(
      key: key ?? this.key,
      label: label ?? this.label,
      labelMaxLines: labelMaxLines ?? this.labelMaxLines,
      labelOverflow: labelOverflow ?? this.labelOverflow,
      state: state ?? this.state,
      attributes: attributes ?? userAttributes,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      id: id ?? this.id,
      pendingIcon: pendingIcon ?? this.pendingIcon,
      validIcon: validIcon ?? this.validIcon,
      invalidIcon: invalidIcon ?? this.invalidIcon,
      size: size ?? this.size,
      style: style ?? this.style,
    );
  }

  @override
  Component build(BuildContext context) {
    // Resolve the effective size (widget → default) here so the resolver
    // receives a concrete non-null `size` — mirrors PoC (Alert /
    // Button) where semantic identifiers are widget-side. `size` is a
    // semantic identifier, so the theme cannot override it
    // (style-contract.md — Theme carries no `size` slot).
    final effectiveSize = size ?? CoreValidationBadgeStyle.defaultSize;

    final resolved = resolveValidationBadge(
      context,
      state: state,
      size: effectiveSize,
      validationBadgeStyle: style,
      labelMaxLines: labelMaxLines,
      labelOverflow: labelOverflow,
    );
    final clampStated = labelMaxLines != null || labelOverflow != null;

    // Icon glyph follows the widget's semantic `state` prop (Epic
    // #1603 옵션 B 최종 — semantic identifiers are widget-only; the
    // theme cannot override them). Per-state caller overrides win.
    final iconForState = switch (state) {
      .pending => pendingIcon,
      .valid => validIcon,
      .invalid => invalidIcon,
    };
    final icon =
        iconForState ??
        switch (state) {
          .pending => LucideIcons.clock,
          .valid => LucideIcons.check,
          .invalid => LucideIcons.x,
        };

    return Component.element(
      tag: 'span',
      id: id,
      classes: rootClasses(resolved.root.className),
      styles: css != null
          ? Styles.combine([?resolved.root.inlineStyles, css!])
          : resolved.root.inlineStyles,
      attributes: {...componentAttributes, 'role': 'status'},
      events: events,
      children: [
        Icon(icon, iconStyle: resolved.iconStyle),
        Component.element(
          tag: 'span',
          classes: resolved.label.className,
          styles: resolved.label.inlineStyles,
          children: [
            // Both `null` leaves the clamp to the resolver's `truncate`
            // utility. Once the caller states either half, the other half
            // falls back to the contract default the Flutter twin reads.
            Text(
              label,
              maxLines: clampStated
                  ? labelMaxLines ??
                        CoreValidationBadgeContract.defaultLabelMaxLines
                  : null,
              overflow: clampStated
                  ? labelOverflow ??
                        CoreValidationBadgeContract.defaultLabelOverflow
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}

/// Chain sugar mirroring the Flutter `ValidationBadge.withStyle` extension
/// — merges a [CoreValidationBadgeStyle] patch into
/// [ValidationBadge.style] via the existing [ValidationBadge.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreValidationBadgeStyle.merge` right-side-wins semantics).
extension ValidationBadgeStyleChain on ValidationBadge {
  /// Sets the border width in logical pixels.
  ValidationBadge borderWidth(double value) =>
      withStyle(CoreValidationBadgeStyle(borderWidth: value));

  /// Returns a copy of this [ValidationBadge] with [patch] merged into
  /// [style] (patch fields win on conflict).
  ValidationBadge withStyle(CoreValidationBadgeStyle patch) =>
      copyWith(style: (style ?? const CoreValidationBadgeStyle()).merge(patch));
}
