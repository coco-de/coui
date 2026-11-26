/// Platform-independent contract for unified skeleton components.
///
/// Defines the interface that all Skeleton implementations
/// (Flutter, Web) must satisfy.
library;

import 'package:coui_core/src/component/contracts/skeleton/skeleton_style.dart';
import 'package:coui_core/src/component/contracts/skeleton/skeleton_variant.dart';

/// Contract for a unified skeleton component.
///
/// Per Epic #1302 every chrome / dimensional / animation override
/// flows through the single [skeletonStyle] field — see
/// [CoreSkeletonStyle] for the merge chain. The semantic `variant` enum
/// stays flat on the widget. Whether a skeleton is drawn at all is the
/// caller's condition (`if (loading) Skeleton(...)`), so the contract
/// carries no on/off toggle.
///
/// `width` / `height` are **not** contract members — their
/// representation genuinely diverges per platform (Flutter `double?`
/// logical pixels vs Web `String?` CSS value). They stay as flat,
/// platform-typed widget fields rather than forcing a dimensional
/// generic onto the contract.
///
/// `Skeleton` has no widget-type slot, so the contract carries no
/// `<W>` generic.
abstract interface class CoreSkeletonContract {
  /// The visual variant (shape) of the skeleton.
  CoreSkeletonVariant get variant;

  /// Per-instance chrome / dimensional / animation style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreSkeletonTheme.style
  ///   → parent component slot override
  ///   → widget.skeletonStyle
  /// ```
  CoreSkeletonStyle? get skeletonStyle;
}
