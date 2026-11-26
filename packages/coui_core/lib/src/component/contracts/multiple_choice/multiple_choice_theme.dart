/// Theme data for `MultipleChoice` customisation.
library;

import 'package:coui_core/src/component/contracts/multiple_choice/multiple_choice_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `MultipleChoice`.
///
/// All chrome / dimensional overrides flow through the single [style]
/// slot ({style} only — `MultipleChoice` has no variant enum, so no
/// `variantStyles` slot). Behavioural defaults (`allowUnselect`) are not
/// theme chrome — they live as `static const` on the contract
/// (`CoreMultipleChoiceContract.defaultAllowUnselect`) so the widget
/// default is the single source of truth.
///
/// ### Resolve chain.
///
/// ```text
/// design system default
///   → CoreMultipleChoiceTheme.style              // 프로젝트 공통
///   → parent component slot override
///   → widget per-instance multipleChoiceStyle
/// ```
@immutable
class CoreMultipleChoiceTheme {
  /// Creates a [CoreMultipleChoiceTheme].
  const CoreMultipleChoiceTheme({this.style});

  /// Project-wide composite style applied to every `MultipleChoice`.
  final CoreMultipleChoiceStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreMultipleChoiceTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
