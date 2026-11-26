/// Per-instance style for `Stacks`.
library;

import 'package:coui_core/src/component/alignment.dart';
import 'package:coui_core/src/component/contracts/stacks/core_clip_behavior.dart';
import 'package:coui_core/src/component/contracts/stacks/core_stack_fit.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:meta/meta.dart';

/// Immutable style describing how a `Stacks` renders.
///
/// `Stacks` is the cross-platform z-stack primitive — children are
/// painted on top of one another at the same position. The chrome
/// surface unique to the stack itself is just three knobs: where
/// non-positioned children sit ([alignment]), how they are sized
/// relative to the parent ([fit]), and how overflowing content is
/// clipped ([clipBehavior]).
///
/// ```text
/// CoreStacksStyle.defaultX            // design-system default (per-field)
///   → CoreStacksTheme.style           // project theme
///   → widget.stacksStyle              // instance override
/// ```
@immutable
class CoreStacksStyle implements CoreStyle<CoreStacksStyle> {
  /// Creates a [CoreStacksStyle].
  const CoreStacksStyle({this.alignment, this.fit, this.clipBehavior});

  /// Design-system default alignment — matches Flutter `Stack`'s
  /// `AlignmentDirectional.topStart`.
  static const CoreAlignment defaultAlignment = .topStart;

  /// Design-system default fit — matches Flutter `Stack`'s
  /// `StackFit.loose`.
  static const CoreStackFit defaultFit = .loose;

  /// Design-system default clip behaviour — matches Flutter `Stack`'s
  /// `Clip.hardEdge`. The Web `Stacks` resolver mirrors the same
  /// default so behaviour is identical across platforms.
  static const CoreClipBehavior defaultClipBehavior = .hardEdge;

  /// Where non-positioned children are aligned inside the stack.
  /// `null` defers to the next layer in the merge chain — ultimately
  /// [defaultAlignment] supplies [CoreAlignment.topStart].
  final CoreAlignment? alignment;

  /// How non-positioned children are sized relative to the parent.
  /// `null` defers to [defaultFit] which supplies
  /// [CoreStackFit.loose].
  final CoreStackFit? fit;

  /// How overflowing content is clipped. `null` defers to
  /// [defaultClipBehavior] which supplies [CoreClipBehavior.hardEdge].
  final CoreClipBehavior? clipBehavior;

  @override
  CoreStacksStyle merge(CoreStacksStyle? other) {
    if (other == null) return this;
    return CoreStacksStyle(
      alignment: other.alignment ?? alignment,
      fit: other.fit ?? fit,
      clipBehavior: other.clipBehavior ?? clipBehavior,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreStacksStyle copyWith({
    CoreAlignment? alignment,
    CoreStackFit? fit,
    CoreClipBehavior? clipBehavior,
  }) => .new(
    alignment: alignment ?? this.alignment,
    fit: fit ?? this.fit,
    clipBehavior: clipBehavior ?? this.clipBehavior,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreStacksStyle &&
          runtimeType == other.runtimeType &&
          alignment == other.alignment &&
          fit == other.fit &&
          clipBehavior == other.clipBehavior;

  @override
  int get hashCode => Object.hash(alignment, fit, clipBehavior);
}
