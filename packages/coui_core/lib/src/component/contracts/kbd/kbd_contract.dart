/// Platform-independent contract for unified keyboard key components.
///
/// Defines the interface that all Kbd implementations
/// (Flutter, Web) must satisfy.
library;

import 'package:coui_core/src/component/contracts/kbd/kbd_style.dart';

/// Contract for a unified keyboard key component.
///
/// Per Epic #1302 chrome / dimensional overrides flow through the
/// single [kbdStyle] slot. Behavioural fields (`keys`) stay flat.
///
/// Implementations render one or more keyboard keys as adjacent key boxes —
/// no glyph sits between them (a shortcut written *inside a sentence* is
/// text such as "Ctrl+S", not a `Kbd`). Single-key usage is supported
/// through the `Kbd.single` named constructor on each platform; a widget
/// key (e.g. an `Icon` glyph — see [keyContent]) through `Kbd.icon`.
///
/// One `Kbd` is one combination, and it is announced as **one** name rather
/// than one fragment per key — see [label].
abstract interface class CoreKbdContract<W> {
  /// Keyboard keys to display. Each entry is rendered as a separate
  /// key box, in the order given.
  ///
  /// The combination is announced as the entries joined by a space
  /// (`['Ctrl', 'S']` → "Ctrl S").
  List<String> get keys;

  /// Widget key content — when non-null the component renders a single
  /// key box holding this widget instead of the [keys] texts.
  ///
  /// The canonical use is an `Icon` glyph (`Kbd.icon`): icon fonts ship
  /// identically on both platforms, so symbol keys (`⏎` / `⌘` …) render
  /// pixel-identical where text glyphs would fall to per-platform font
  /// fallback (Flutter web routes Miscellaneous-Technical codepoints to
  /// Noto Symbols even when the key font covers them).
  W? get keyContent;

  /// Accessible name of the [keyContent] key.
  ///
  /// A glyph says nothing to a screen reader, so a `Kbd.icon` key is only
  /// announced when it is named here. `null` for a text key — its name is
  /// derived from [keys] — and `null` leaves an icon key silent, which is
  /// right where a neighbouring text already names the action (a footer
  /// hint such as "Move up" beside its arrow key).
  String? get label;

  /// Per-instance chrome / dimensional / text style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreKbdTheme.style
  ///   → parent component slot override
  ///   → widget.kbdStyle
  /// ```
  CoreKbdStyle? get kbdStyle;
}
