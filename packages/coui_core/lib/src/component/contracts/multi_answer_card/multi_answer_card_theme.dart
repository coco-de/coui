/// Theme data for `MultiAnswerCard` customisation.
library;

import 'package:coui_core/src/component/contracts/multi_answer_card/multi_answer_card_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `MultiAnswerCard`.
///
/// Per Epic #1302 chrome / dimensional / colour overrides flow through
/// the single [style] field — see [CoreMultiAnswerCardStyle] for the
/// merge chain.
///
/// ### Resolve chain.
///
/// ```text
/// design system default
///   → CoreMultiAnswerCardTheme.style              // 프로젝트 공통
///   → parent component slot override
///   → widget per-instance multiAnswerCardStyle
/// ```
@immutable
class CoreMultiAnswerCardTheme {
  /// Creates a [CoreMultiAnswerCardTheme].
  const CoreMultiAnswerCardTheme({this.style});

  /// Project-wide composite style applied to every `MultiAnswerCard`.
  final CoreMultiAnswerCardStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreMultiAnswerCardTheme && other.style == style;

  @override
  int get hashCode => style.hashCode;
}
