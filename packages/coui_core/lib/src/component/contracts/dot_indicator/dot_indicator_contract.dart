/// Platform-independent contract for unified dot indicator components.
///
/// Defines the interface that all DotIndicator implementations
/// (Flutter, Web) must satisfy.
library;

import 'package:coui_core/src/component/contracts/dot_indicator/dot_indicator_size.dart';
import 'package:coui_core/src/component/contracts/dot_indicator/dot_indicator_style.dart';
import 'package:coui_core/src/component/contracts/scrollable_client/core_axis.dart';

/// Tap callback signature for dot indicator.
typedef CoreDotIndicatorOnChanged = void Function(int index);

/// Contract for a unified dot indicator component.
///
/// Displays a series of dots representing items in a sequence,
/// with one dot highlighted to show the current position.
/// Commonly used with carousels, page views, and stepper interfaces.
///
/// Per Epic #1302 chrome / dimensional overrides flow through the
/// single [dotIndicatorStyle] field — see [CoreDotIndicatorStyle]
/// for the merge chain. [size] is a semantic identifier — its widget
/// default lives on each platform's `DotIndicator` constructor
/// (`= CoreDotIndicatorSize.defaultSize`), mirroring
/// `CoreProgressContract.size`.
///
/// Type parameters:
/// - [W] - platform widget type
///   (Flutter `Widget`, Web `Component`).
abstract interface class CoreDotIndicatorContract<W> {
  /// Current active dot position (0-based).
  int get index;

  /// Total number of dots to display.
  int get length;

  /// Callback when a dot is tapped. Null disables interaction.
  CoreDotIndicatorOnChanged? get onChanged;

  /// Layout direction of dots (default `horizontal`).
  CoreAxis get direction;

  /// Size of the dots and the gap between them — selects the
  /// [CoreDotIndicatorStyle.defaultsBySize] rung. Widget-only semantic
  /// identifier, not theme-overridable (the theme cannot silently change
  /// a caller's `size:`).
  CoreDotIndicatorSize get size;

  /// Per-instance chrome / dimensional style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default (CoreDotIndicatorStyle.defaultX / defaultsBySize)
  ///   → CoreDotIndicatorTheme.style
  ///   → parent component slot override
  ///   → widget.dotIndicatorStyle
  /// ```
  CoreDotIndicatorStyle? get dotIndicatorStyle;
}
