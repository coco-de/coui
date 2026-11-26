import 'package:coui_core/src/component/contracts/tag/tag_style.dart';

/// The two steps a `Tag` comes in.
///
/// Its own enum rather than `CoreComponentSize`: a tag has two rows, and a
/// shared five-step ladder would make the three it does not have look
/// supported. Each row's height, padding, corner and label role live in
/// [CoreTagStyle.defaultsBySize].
enum CoreTagSize {
  /// 20px tall — for dense rows (a table cell, a list line).
  sm,

  /// 24px tall — the height a tag shares with a status badge. The default.
  md;

  /// Widget default size — the Flutter / Web `Tag` constructors reference
  /// this so the default cannot silently diverge.
  static const CoreTagSize defaultSize = md;
}
