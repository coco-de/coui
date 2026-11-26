/// Platform-independent contract for `IndexedSwitcher`.
library;

import 'package:coui_core/src/component/contracts/indexed_switcher/indexed_switcher_style.dart';

/// Contract for a unified `IndexedSwitcher` — one of [children] shown at
/// a time, every child kept built, a fade through on each [index] change.
///
/// This is the switch between top-level destinations: the screens a
/// navigation bar, rail or sidebar moves between, or the branches of a
/// router's stateful shell. Every child stays built while hidden, so a
/// destination keeps its scroll position, form input and nested
/// navigation when the user comes back to it — the same as an indexed
/// stack. Only the switch itself changes: the outgoing view fades out,
/// then the incoming view fades in.
///
/// Only the shown child takes pointer input, keyboard focus and a place in
/// the accessibility tree; the outgoing view loses all three the moment
/// the switch starts, while it is still fading out.
///
/// Generic over the platform widget type `W` (Flutter `Widget`, Web
/// `Component`) — all other surfaces are platform-neutral.
abstract interface class CoreIndexedSwitcherContract<W> {
  /// Index of the child that is shown (0-based).
  int get index;

  /// Per-instance transition style — the fade-out and fade-in timing of
  /// [CoreIndexedSwitcherStyle].
  ///
  /// Resolves through the nested-merge chain
  /// (`CoreIndexedSwitcherStyle.defaultX` ← `theme.indexedSwitcher.style`
  /// ← `widget.indexedSwitcherStyle`).
  CoreIndexedSwitcherStyle? get indexedSwitcherStyle;

  /// The views to switch between. Every one stays built; only the child at
  /// [index] is shown.
  List<W> get children;
}
