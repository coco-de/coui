/// Platform-independent contract for unified loading indicator components.
library;

import 'package:coui_core/src/component/contracts/loading/loading_style.dart';
import 'package:coui_core/src/component/contracts/loading/loading_tone.dart';
import 'package:coui_core/src/component/contracts/loading/loading_variant.dart';
import 'package:coui_core/src/size/component_size.dart';

/// Contract for a unified loading indicator component.
///
/// Per Epic #1302 every chrome / dimensional override flows through
/// the single [loadingStyle] field — see [CoreLoadingStyle] for the
/// merge chain. Semantic enums (`variant` / `componentSize`) stay
/// flat on the widget.
abstract interface class CoreLoadingContract {
  /// Visual variant of the indicator (spinner / dots / bars / pulse).
  CoreLoadingVariant get variant;

  /// Preset size using [CoreComponentSize]. When null falls back to
  /// the design system default for the variant.
  CoreComponentSize? get componentSize;

  /// Ink of the indicator — see [CoreLoadingTone]. Defaults to
  /// [CoreLoadingTone.defaultTone].
  CoreLoadingTone get tone;

  /// Per-instance chrome / dimensional style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreLoadingTheme.style
  ///   → parent component slot override
  ///   → widget.loadingStyle
  /// ```
  CoreLoadingStyle? get loadingStyle;
}
