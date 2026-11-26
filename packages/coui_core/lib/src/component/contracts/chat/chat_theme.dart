/// Project-level theme overrides for chat components.
library;

import 'package:coui_core/src/component/contracts/chat/chat_style.dart';
import 'package:coui_core/src/component/contracts/chat/chat_variant.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `Chat` row chrome.
///
/// Per Epic #1415 all 시각 chrome flows through the single [style]
/// slot — see [CoreChatStyle] for the merge chain.
///
/// ### Resolve chain.
///
/// ```text
/// CoreChatStyle.defaultX
///   → CoreChatTheme.style                          // project-wide
///   → parent component slot override
///   → widget.chatStyle                             // per-instance
/// ```
@immutable
class CoreChatTheme {
  /// Creates a [CoreChatTheme].
  const CoreChatTheme({this.style});

  /// Project-level base style. `null` → no project override.
  final CoreChatStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreChatTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}

/// Project-level theme overrides for `ChatBubble`.
///
/// Per Epic #1415 chrome flows through the single [style] slot;
/// per-variant overrides flow through [variantStyles].
///
/// ### Resolve chain.
///
/// ```text
/// CoreChatBubbleStyle.defaultX
///   → CoreChatBubbleStyle.defaultsByVariant[variant]
///   → CoreChatBubbleTheme.style                    // project-wide
///   → CoreChatBubbleTheme.variantStyles[variant]   // per-variant
///   → parent component slot override
///   → widget.chatBubbleStyle                       // per-instance
/// ```
@immutable
class CoreChatBubbleTheme {
  /// Creates a [CoreChatBubbleTheme].
  const CoreChatBubbleTheme({this.style, this.variantStyles});

  /// Project-level base style. `null` → no project override.
  final CoreChatBubbleStyle? style;

  /// Per-variant override styles. Keys missing from the map fall back
  /// to [CoreChatBubbleStyle.defaultsByVariant].
  final Map<CoreChatBubbleVariant, CoreChatBubbleStyle>? variantStyles;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CoreChatBubbleTheme &&
        runtimeType == other.runtimeType &&
        style == other.style &&
        _mapEquals(variantStyles, other.variantStyles);
  }

  @override
  int get hashCode => Object.hash(style, _mapHash(variantStyles));
}

bool _mapEquals(
  Map<CoreChatBubbleVariant, CoreChatBubbleStyle>? a,
  Map<CoreChatBubbleVariant, CoreChatBubbleStyle>? b,
) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return false;
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key)) return false;
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}

int _mapHash(Map<CoreChatBubbleVariant, CoreChatBubbleStyle>? map) {
  if (map == null) return 0;
  return Object.hashAllUnordered(
    map.entries.map((entry) => Object.hash(entry.key, entry.value)),
  );
}
