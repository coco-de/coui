import 'package:gap/gap.dart' as gap_package;

import '../../constants/spacing.dart';

/// A widget that provides spacing between other widgets.
///
/// This is a wrapper around the [gap_package.Gap] widget that provides
/// convenient named constructors for common spacing values defined in
/// the design system.
///
/// Example:
/// ```dart
/// Column(
///   children: [
///     Text('First item'),
///     const Gap.medium(), // 16px gap
///     Text('Second item'),
///   ],
/// )
/// ```
class Gap extends gap_package.Gap {
  /// Creates a gap with the specified extent.
  ///
  /// The [mainAxisExtent] argument must not be null.
  const Gap(
    super.mainAxisExtent, {
    super.key,
    super.crossAxisExtent,
  });

  /// Creates an extra small gap (4px).
  const Gap.xSmall({super.key})
    : super(
        Spacing.xSmall,
      );

  /// Creates a small gap (8px).
  const Gap.small({super.key})
    : super(
        Spacing.small,
      );

  /// Creates a medium gap (16px).
  const Gap.medium({super.key})
    : super(
        Spacing.medium,
      );

  /// Creates a large gap (24px).
  const Gap.large({super.key})
    : super(
        Spacing.large,
      );

  /// Creates an extra large gap (32px).
  const Gap.xLarge({super.key})
    : super(
        Spacing.xLarge,
      );
}
