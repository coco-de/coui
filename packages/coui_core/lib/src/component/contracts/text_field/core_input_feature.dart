/// Platform-neutral built-in affordances for `TextField`.
///
/// De-legacy of the Flutter `InputFeature` Widget-building system: a pure
/// **data** model both platforms pattern-match on to render the affordance
/// and wire its behaviour, so the same
/// `features: [CoreInputFeature.clear()]` code works on Flutter and Web.
library;

import 'package:coui_core/src/icon/icon_name.dart';
import 'package:meta/meta.dart';

/// Where an input-feature affordance renders relative to the text.
enum CoreInputFeaturePosition {
  /// Before the text (start side).
  leading,

  /// After the text (end side).
  trailing,
}

/// When an input-feature affordance is visible.
enum CoreInputFeatureVisibility {
  /// Always visible.
  always,

  /// Visible only when the field has text.
  textNotEmpty,

  /// Visible only when the field is empty.
  textEmpty,

  /// Visible only while the field is focused.
  focused,

  /// Visible only while the field is hovered.
  hovered,
}

/// How a password-visibility toggle reveals the text.
enum CorePasswordPeekMode {
  /// Tapping toggles between hidden / shown (sticky).
  toggle,

  /// Text is revealed only while the control is pressed and held.
  hold,
}

/// The kind of built-in affordance a [CoreInputFeature] represents.
enum CoreInputFeatureKind {
  /// A password-visibility toggle.
  passwordToggle,

  /// A clear button that empties the field.
  clear,
}

/// A built-in affordance rendered inside a `TextField` — currently a
/// password-visibility toggle or a clear button.
///
/// This is the platform-neutral data model: each `TextField`
/// implementation reads [kind] / [position] / [visibility] to render the
/// affordance and wire its behaviour. Icons are carried as [IconName]
/// tokens (not platform widgets) so the model stays platform-neutral.
@immutable
class CoreInputFeature {
  const CoreInputFeature._({
    required this.kind,
    required this.position,
    required this.visibility,
    this.icon,
    this.iconShown,
    this.semanticLabel,
    this.passwordPeekMode = CorePasswordPeekMode.toggle,
  });

  /// A password-visibility toggle (eye / eye-off) that flips the field's
  /// obscured state.
  ///
  /// - [icon]: resting icon (`null` → eye-off).
  /// - [iconShown]: icon while text is revealed (`null` → eye).
  /// - [mode]: sticky [CorePasswordPeekMode.toggle] or press-and-hold.
  const CoreInputFeature.passwordToggle({
    IconName? icon,
    IconName? iconShown,
    CorePasswordPeekMode mode = .toggle,
    CoreInputFeaturePosition position = .trailing,
    CoreInputFeatureVisibility visibility = .always,
    String? semanticLabel,
  }) : this._(
         kind: .passwordToggle,
         position: position,
         visibility: visibility,
         icon: icon,
         iconShown: iconShown,
         semanticLabel: semanticLabel,
         passwordPeekMode: mode,
       );

  /// A clear button (×) that empties the field. Defaults to showing only
  /// while the field has text.
  ///
  /// - [icon]: clear icon (`null` → ×).
  const CoreInputFeature.clear({
    IconName? icon,
    CoreInputFeaturePosition position = .trailing,
    CoreInputFeatureVisibility visibility = .textNotEmpty,
    String? semanticLabel,
  }) : this._(
         kind: .clear,
         position: position,
         visibility: visibility,
         icon: icon,
         semanticLabel: semanticLabel,
       );

  /// Which built-in affordance this is.
  final CoreInputFeatureKind kind;

  /// Resting-state icon token. `null` → platform default per [kind]
  /// (eye-off for [CoreInputFeatureKind.passwordToggle], × for
  /// [CoreInputFeatureKind.clear]).
  final IconName? icon;

  /// For [CoreInputFeatureKind.passwordToggle], the icon shown while the
  /// text is revealed. `null` → eye.
  final IconName? iconShown;

  /// Where the affordance renders relative to the text.
  final CoreInputFeaturePosition position;

  /// When the affordance is visible.
  final CoreInputFeatureVisibility visibility;

  /// Accessibility label for the affordance button.
  final String? semanticLabel;

  /// Reveal mode for [CoreInputFeatureKind.passwordToggle].
  final CorePasswordPeekMode passwordPeekMode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreInputFeature &&
          runtimeType == other.runtimeType &&
          kind == other.kind &&
          icon == other.icon &&
          iconShown == other.iconShown &&
          position == other.position &&
          visibility == other.visibility &&
          semanticLabel == other.semanticLabel &&
          passwordPeekMode == other.passwordPeekMode;

  @override
  int get hashCode => Object.hash(
    kind,
    icon,
    iconShown,
    position,
    visibility,
    semanticLabel,
    passwordPeekMode,
  );
}
