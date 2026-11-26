/// Platform-independent theme for `DescriptionCard`.
library;

import 'package:coui_core/src/component/contracts/description_card/description_card_style.dart';
import 'package:meta/meta.dart';

/// `DescriptionCard` component theme overrides.
///
/// Provides per-component style defaults that can be set at the project
/// level and read by `DescriptionCard` via the inherited theme.
///
/// ### Resolve chain.
///
/// ```text
/// design system default
///   → theme.descriptionCard.style
///   → parent component slot override
///   → widget.descriptionCardStyle
///   → per-row labelTextStyle / valueTextStyle
/// ```
///
/// All chrome / dimensional / text-slot overrides live on the nested
/// [style] slot ([CoreDescriptionCardStyle]). There are no legacy
/// flat chrome / colour fields on the theme — they were merged into
/// the [style] slot in Epic #1370 phase 5.
@immutable
class CoreDescriptionCardTheme {
  /// Creates a [CoreDescriptionCardTheme].
  const CoreDescriptionCardTheme({this.style});

  /// Project-level base style (chrome + dimensional + text slot
  /// overrides). `null` → no project override.
  final CoreDescriptionCardStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CoreDescriptionCardTheme && other.style == style);

  @override
  int get hashCode => style.hashCode;
}
