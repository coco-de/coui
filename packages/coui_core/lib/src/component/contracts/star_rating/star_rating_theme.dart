import 'package:coui_core/src/component/contracts/star_rating/star_rating_style.dart';
import 'package:meta/meta.dart';

/// Star rating component theme overrides.
///
/// Per Epic #1302 chrome / dimensional / colour overrides flow through
/// the single [style] field — see [CoreStarRatingStyle] for the merge
/// chain.
///
/// ### Resolve chain.
///
/// ```text
/// design system default
///   → CoreStarRatingTheme.style                      // 프로젝트 공통
///   → parent component slot override
///   → widget per-instance starRatingStyle
/// ```
@immutable
class CoreStarRatingTheme {
  /// Creates a [CoreStarRatingTheme].
  const CoreStarRatingTheme({this.style});

  /// Project-wide composite style applied to every `StarRating`.
  ///
  /// Resolved before any per-instance `widget.starRatingStyle`.
  final CoreStarRatingStyle? style;

  @override
  bool operator ==(Object other) {
    return other is CoreStarRatingTheme && other.style == style;
  }

  @override
  int get hashCode => style.hashCode;
}
