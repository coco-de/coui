/// Where a query sits inside a suggestion label.
library;

import 'package:meta/meta.dart';

/// The label split around the part that matches the query.
///
/// The filter that decides which suggestions are listed is a
/// case-insensitive `contains` on the trimmed query; this class locates the
/// first such occurrence so both platforms emphasise the **same** characters
/// wherever the match sits — at the start, in the middle or at the end.
@immutable
class CoreAutocompleteMatch {
  const CoreAutocompleteMatch._({
    required this.before,
    required this.match,
    required this.after,
  });

  /// Splits [label] around the first case-insensitive occurrence of the
  /// trimmed [query].
  ///
  /// An empty query, or a query that is not contained in [label], yields a
  /// split with no match: the whole label is [before].
  factory CoreAutocompleteMatch.of(String label, String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) {
      return CoreAutocompleteMatch._(before: label, match: '', after: '');
    }
    final lowered = label.toLowerCase();
    // Lower-casing can change a string's length for a few scripts, which
    // would shift every offset; the label is then left unemphasised rather
    // than emphasising the wrong characters.
    final start = lowered.length == label.length ? lowered.indexOf(needle) : -1;
    if (start < 0) {
      return CoreAutocompleteMatch._(before: label, match: '', after: '');
    }
    final end = start + needle.length;
    return CoreAutocompleteMatch._(
      before: label.substring(0, start),
      match: label.substring(start, end),
      after: label.substring(end),
    );
  }

  /// The text before the match (the whole label when nothing matches).
  final String before;

  /// The matched text, in the label's own casing. Empty when nothing
  /// matches.
  final String match;

  /// The text after the match.
  final String after;

  /// Whether any part of the label matched.
  bool get hasMatch => match.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreAutocompleteMatch &&
          before == other.before &&
          match == other.match &&
          after == other.after;

  @override
  int get hashCode => Object.hash(before, match, after);
}
