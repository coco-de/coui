/// Platform-independent contract for unified multi-answer card components.
library;

import 'package:coui_core/src/component/contracts/multi_answer_card/multi_answer_card_style.dart';

/// Contract for a unified selectable answer card component.
///
/// `MultiAnswerCard` is a card-styled selectable surface, typically
/// used in quizzes / surveys where the user picks one or more answers.
/// It carries an opaque [value] and reflects its [selected] state with
/// distinct chrome.
///
/// Per Epic #1302 chrome / dimensional overrides flow through the single
/// [multiAnswerCardStyle] slot. Behavioural / semantic fields (`value`,
/// `selected`, `enabled`, `onChanged`, `child`) stay flat.
///
/// Type parameters:
/// - [T] — the value carried by this card.
/// - [W] — the widget type of the [child] slot.
abstract interface class CoreMultiAnswerCardContract<T, W> {
  /// The value this card represents.
  T get value;

  /// Whether the card is currently selected.
  bool get selected;

  /// Whether the card is interactive.
  bool get enabled;

  /// Called with [value] when the card is tapped.
  void Function(T)? get onChanged;

  /// The content of the card.
  W get child;

  /// Per-instance chrome / dimensional style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreMultiAnswerCardTheme.style
  ///   → parent component slot override
  ///   → widget.multiAnswerCardStyle
  /// ```
  CoreMultiAnswerCardStyle? get multiAnswerCardStyle;
}
