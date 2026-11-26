/// Platform-neutral clip behaviour for CoUI component styles.
///
/// CoUI components share a single Style class across Flutter and Web
/// (Epic #1415 option D). Clip behaviour is expressed as
/// [CoreClipMode] in the platform-neutral Style; resolvers convert to
/// Flutter's `Clip` enum or a CSS `overflow` string at render time.
library;

import 'package:coui_core/src/component/contracts/stacks/core_clip_behavior.dart';

/// Clip behaviour applied to a component's bounding box.
///
/// Mirrors Flutter's `Clip` enum so the four modes map 1-to-1; Web
/// flattens [hardEdge] / [antiAlias] / [antiAliasWithSaveLayer] to
/// `overflow: hidden` because CSS has no anti-aliased clip primitive.
enum CoreClipMode {
  /// Do not clip — children may overflow the bounding box.
  none,

  /// Clip with a non-anti-aliased edge.
  ///
  /// Flutter: `Clip.hardEdge`. Web: `overflow: hidden`.
  hardEdge,

  /// Clip with an anti-aliased edge.
  ///
  /// Flutter: `Clip.antiAlias`. Web: `overflow: hidden` (CSS has no
  /// anti-aliased clip — the result is visually equivalent for
  /// straight-edged components but cannot smooth diagonal masks).
  antiAlias,

  /// Clip with an anti-aliased edge inside an offscreen save layer.
  ///
  /// Flutter: `Clip.antiAliasWithSaveLayer`. Web: `overflow: hidden`.
  antiAliasWithSaveLayer;

  /// Maps this clip mode to the matching [CoreClipBehavior]. Both
  /// enums carry the same four values — keeping the conversion next
  /// to the source enum means any future entry added here surfaces a
  /// compile error on the switch instead of silently drifting from
  /// the `CoreOutlinedContainer` counterpart.
  CoreClipBehavior toClipBehavior() {
    return switch (this) {
      .none => .none,
      .hardEdge => .hardEdge,
      .antiAlias => .antiAlias,
      .antiAliasWithSaveLayer => .antiAliasWithSaveLayer,
    };
  }
}
