/// Data models for `Command` — items, groups, scopes.
library;

import 'package:meta/meta.dart';

/// One selectable row in a `Command` palette.
@immutable
class CoreCommandItem<W> {
  /// Creates a row.
  const CoreCommandItem({
    required this.value,
    required this.label,
    this.overline,
    this.icon,
    this.shortcut,
    this.keywords = const [],
    this.enabled = true,
  });

  /// Stable identifier reported to `onSelect`.
  final String value;

  /// Display text — the primary filter target. See [matchesQuery].
  final String label;

  /// Category read *above* the label — where a result comes from, which
  /// in a search that mixes sections has to be read before the title. Set,
  /// the row becomes two lines and the label takes the title role.
  final String? overline;

  /// Optional leading glyph. Off by default: in a document search an icon
  /// carries no information and only pushes the first letter along.
  final W? icon;

  /// Keyboard shortcut hint, rendered as a key cap.
  final String? shortcut;

  /// Search aliases — not shown. The query matches these with the same
  /// substring rule as [label] (cmdk `keywords`).
  final List<String> keywords;

  /// Whether the row can be chosen. A disabled row is skipped by arrow
  /// navigation and drawn in the disabled foreground.
  final bool enabled;

  /// Whether this row survives [query] — trimmed, case-insensitive
  /// substring on [label] or any [keywords] entry. An empty query matches
  /// every row. [overline] is not a filter target.
  bool matchesQuery(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    if (label.toLowerCase().contains(q)) return true;
    for (final keyword in keywords) {
      if (keyword.toLowerCase().contains(q)) return true;
    }
    return false;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CoreCommandItem<W> || runtimeType != other.runtimeType) {
      return false;
    }
    if (value != other.value ||
        label != other.label ||
        overline != other.overline ||
        icon != other.icon ||
        shortcut != other.shortcut ||
        enabled != other.enabled) {
      return false;
    }
    if (keywords.length != other.keywords.length) return false;
    for (var i = 0; i < keywords.length; i++) {
      if (keywords[i] != other.keywords[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    value,
    label,
    overline,
    icon,
    shortcut,
    enabled,
    Object.hashAll(keywords),
  );
}

/// A titled run of items.
@immutable
class CoreCommandGroup<W> {
  /// Creates a group.
  const CoreCommandGroup({required this.items, this.heading, this.scope});

  /// Group heading, rendered above the run. `null` renders none.
  final String? heading;

  /// The scope this group belongs to (a [CoreCommandScope.value]). `null`
  /// means the group shows in every scope.
  final String? scope;

  /// The rows, in render order.
  final List<CoreCommandItem<W>> items;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CoreCommandGroup<W> || runtimeType != other.runtimeType) {
      return false;
    }
    if (heading != other.heading || scope != other.scope) return false;
    if (items.length != other.items.length) return false;
    for (var i = 0; i < items.length; i++) {
      if (items[i] != other.items[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(heading, scope, Object.hashAll(items));
}

/// A scope chip — a named subset of the groups.
///
/// Rendered as a `Chip` under the search field. Arrow Left / Right move
/// between scopes without touching the query: narrowing the range is a
/// second action, and the words already typed are the first.
@immutable
class CoreCommandScope {
  /// Creates a scope.
  const CoreCommandScope({required this.value, required this.label});

  /// Matches [CoreCommandGroup.scope].
  final String value;

  /// Chip text.
  final String label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreCommandScope &&
          runtimeType == other.runtimeType &&
          value == other.value &&
          label == other.label;

  @override
  int get hashCode => Object.hash(value, label);
}
