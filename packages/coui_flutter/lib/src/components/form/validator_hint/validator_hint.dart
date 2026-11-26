import 'package:coui_flutter/coui_flutter.dart';

/// A unified validation-hint message for form fields.
///
/// `ValidatorHint` displays a validation message (error / warning /
/// info / success) below a form input, with a leading severity icon.
/// It is the unified replacement for the legacy Flutter and Web
/// `ValidatorHint` — same parameter names, same semantics, full visual
/// parity.
///
/// When [visible] is `false` the component collapses to zero size.
/// The [type] drives the per-type accent colour (applied to both the
/// icon and the message) and the default leading icon.
///
/// Every chrome / typography override flows through the single
/// [validatorHintStyle] field — see [CoreValidatorHintStyle] for the
/// merge chain.
///
/// Mirrors Web `ValidatorHint` 1:1 — same parameter names, same
/// semantics.
///
/// ```dart
/// ValidatorHint(message: Text('This field is required'))
/// ValidatorHint.success(message: Text('Looks good'))
/// ```
class ValidatorHint extends StatelessWidget
    implements CoreValidatorHintContract<Widget> {
  /// Creates a [ValidatorHint].
  const ValidatorHint({
    required this.message,
    this.type = CoreValidatorHintType.defaultType,
    this.visible = true,
    this.icon,
    this.validatorHintStyle,
    super.key,
  });

  /// Creates an error-type [ValidatorHint].
  const ValidatorHint.error({
    required this.message,
    this.visible = true,
    this.icon,
    this.validatorHintStyle,
    super.key,
  }) : type = CoreValidatorHintType.error;

  /// Creates a warning-type [ValidatorHint].
  const ValidatorHint.warning({
    required this.message,
    this.visible = true,
    this.icon,
    this.validatorHintStyle,
    super.key,
  }) : type = CoreValidatorHintType.warning;

  /// Creates an info-type [ValidatorHint].
  const ValidatorHint.info({
    required this.message,
    this.visible = true,
    this.icon,
    this.validatorHintStyle,
    super.key,
  }) : type = CoreValidatorHintType.info;

  /// Creates a success-type [ValidatorHint].
  const ValidatorHint.success({
    required this.message,
    this.visible = true,
    this.icon,
    this.validatorHintStyle,
    super.key,
  }) : type = CoreValidatorHintType.success;

  /// Creates a neutral-type [ValidatorHint] — a line with no severity,
  /// such as a checklist rule not yet met.
  const ValidatorHint.neutral({
    required this.message,
    this.visible = true,
    this.icon,
    this.validatorHintStyle,
    super.key,
  }) : type = CoreValidatorHintType.neutral;

  @override
  final Widget? message;

  @override
  final CoreValidatorHintType type;

  @override
  final bool visible;

  @override
  final Widget? icon;

  @override
  final CoreValidatorHintStyle? validatorHintStyle;

  /// Returns a copy of this [ValidatorHint] with the given fields
  /// replaced. All fields default to this instance's current value when
  /// omitted.
  ValidatorHint copyWith({
    Key? key,
    Widget? message,
    CoreValidatorHintType? type,
    bool? visible,
    Widget? icon,
    CoreValidatorHintStyle? validatorHintStyle,
  }) {
    return ValidatorHint(
      key: key ?? this.key,
      message: message ?? this.message,
      type: type ?? this.type,
      visible: visible ?? this.visible,
      icon: icon ?? this.icon,
      validatorHintStyle: validatorHintStyle ?? this.validatorHintStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }

    final resolved = resolveValidatorHint(
      context,
      type: type,
      validatorHintStyle: validatorHintStyle,
    );

    final defaultIcon = Icon(
      coValidatorHintDefaultIcon(type),
      iconStyle: resolved.iconStyle,
    );

    // A message that appears after the user acted is news, and nothing
    // announced it: the field kept focus, so a screen reader had no reason
    // to read the line that just appeared under it. The seat turns the
    // tone's role into a live region — the one announcement axis Flutter
    // has — from the same Core mapping the Web twin emits as `role`. Its
    // own node (`container`) so the live region is this line, not the
    // whole field it sits in.
    return CoUISemantics(
      role: type.toSemanticRole(),
      container: true,
      child: DefaultTextStyle.merge(
        style: resolved.messageTextStyle,
        child: Row(
          // Row's default centre alignment keeps the severity icon on the
          // message line box — start alignment pinned the 14px glyph to the
          // line-box top, reading visibly higher than the text ink.
          mainAxisSize: .min,
          children: [
            IconTheme.merge(
              data: IconThemeData(
                size: resolved.iconStyle.size,
                color: resolved.accentColor,
              ),
              // Web twin marks this `aria-hidden` — the severity icon
              // restates the message, so reading both is redundant.
              child: ExcludeSemantics(child: icon ?? defaultIcon),
            ),
            Gap(gapStyle: resolved.iconLabelGapStyle),
            if (message != null) Flexible(child: message!),
          ],
        ),
      ),
    );
  }
}

/// Chain sugar for merging a [CoreValidatorHintStyle] patch into
/// [ValidatorHint.validatorHintStyle] without hand-reconstructing every
/// field. Mirrors the Web `ValidatorHint.withStyle` extension so both
/// platforms read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreValidatorHintStyle.merge` right-side-wins semantics).
extension ValidatorHintStyleChain on ValidatorHint {
  /// Returns a copy of this [ValidatorHint] with [patch] merged into
  /// [validatorHintStyle] (patch fields win on conflict).
  ValidatorHint withStyle(CoreValidatorHintStyle patch) => copyWith(
    validatorHintStyle: (validatorHintStyle ?? const CoreValidatorHintStyle())
        .merge(patch),
  );
}
