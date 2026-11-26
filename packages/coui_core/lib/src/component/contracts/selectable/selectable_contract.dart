/// Platform-independent contract for unified selectable-text components.
///
/// Defines the interface that all `SelectableText` implementations
/// (Flutter, Web) must satisfy.
library;

import 'package:coui_core/src/component/contracts/selectable/selectable_style.dart';
import 'package:coui_core/src/component/contracts/stacks/core_text_direction.dart';
import 'package:coui_core/src/typography/text_align.dart';

/// Contract for a unified selectable-text component.
///
/// A selectable-text renders text that the user can highlight / copy.
/// Flutter resolves selection through `m.SelectableText`; Web applies
/// the CSS `user-select: text` behaviour to a `<span>` element.
///
/// Cursor / text-style overrides flow through the single
/// [selectableTextStyle] slot. Cross-platform behavioural fields
/// (`maxLines`, `textAlign`, …) stay flat on the widget.
///
/// Type parameter:
/// - [W] — Widget type (Flutter `Widget`, Web `Component`).
abstract interface class CoreSelectableTextContract<W> {
  /// Plain text content to display.
  ///
  /// Ignored when [children] is provided (rich-text composition wins).
  String? get text;

  /// Rich-text child nodes. When non-null, [text] is ignored.
  List<W>? get children;

  /// Per-instance cursor / text style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default (CoreSelectableTextStyle.defaultX)
  ///   → CoreSelectableTextTheme.style
  ///   → widget.selectableTextStyle
  /// ```
  CoreSelectableTextStyle? get selectableTextStyle;

  /// Maximum number of lines to render before clipping. `null` → no
  /// limit.
  int? get maxLines;

  /// Horizontal alignment of the text. `null` → inherit.
  CoreTextAlign? get textAlign;

  /// Reading direction of the text. `null` → inherit.
  CoreTextDirection? get textDirection;

  /// Whether the user can select / highlight the text.
  bool get enableInteractiveSelection;

  /// Semantic label exposed to assistive technologies. `null` →
  /// the rendered text content is used.
  String? get semanticsLabel;

  /// Called when the user taps / clicks the text.
  void Function()? get onTap;
}
