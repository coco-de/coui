/// Per-instance style for `Breakpoint`.
library;

import 'package:coui_core/src/component/core_style.dart';
import 'package:meta/meta.dart';

/// Platform-neutral per-instance style for `Breakpoint`.
///
/// Currently an empty token holder — `Breakpoint` has no visual chrome
/// (it renders nothing; tier boundaries are a BEHAVIOUR value that lives
/// on `CoreBreakpointContract.defaultBoundaries`, not here). The slot is
/// kept so that if a visual chrome field is ever needed, the
/// Theme/Style channel is already wired.
@immutable
class CoreBreakpointStyle implements CoreStyle<CoreBreakpointStyle> {
  /// Creates a [CoreBreakpointStyle].
  const CoreBreakpointStyle();

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. There are currently no fields,
  /// so this always returns `this`.
  @override
  CoreBreakpointStyle merge(CoreBreakpointStyle? other) => this;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CoreBreakpointStyle && runtimeType == other.runtimeType);

  @override
  int get hashCode => runtimeType.hashCode;
}
