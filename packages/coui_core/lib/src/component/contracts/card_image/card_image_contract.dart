import 'package:coui_core/src/component/callback_types.dart';
import 'package:coui_core/src/component/contracts/card_image/card_image_style.dart';

/// Platform-independent contract for `CardImage`.
///
/// An interactive card component combining an image with optional title /
/// subtitle / leading / trailing slots. Pressing the card fires
/// [onPressed]; hovering scales the image (configured via
/// [cardImageStyle]).
///
/// Type parameters:
/// - [W] — platform widget/component type (Flutter `Widget`, Web
///   `Component`).
abstract interface class CoreCardImageContract<W> {
  /// Primary image content. Required.
  W get image;

  /// Optional title (typically a `Text` / `Component.text` placed next to
  /// or below the image).
  W? get title;

  /// Optional subtitle (smaller, rendered below [title]).
  W? get subtitle;

  /// Optional leading slot (e.g. icon before the title).
  W? get leading;

  /// Optional trailing slot (e.g. chevron or action after the title).
  W? get trailing;

  /// Tap/click callback. Null disables interaction.
  CoreVoidCallback? get onPressed;

  /// Whether the card reacts to pointer input. Null falls back to
  /// `onPressed != null`.
  bool? get enabled;

  /// Per-instance composite style.
  ///
  /// All chrome (direction / colour / gap / hover scale) lives inside
  /// this slot — there are no flat chrome getters on the contract.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default (CoreCardImageStyle.defaultX)
  ///   → CoreCardImageTheme.style
  ///   → parent component slot override
  ///   → widget.cardImageStyle
  /// ```
  CoreCardImageStyle? get cardImageStyle;
}
