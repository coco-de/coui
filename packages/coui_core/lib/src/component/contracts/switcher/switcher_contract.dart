/// Platform-independent contract for switcher components.
library;

import 'package:coui_core/src/component/contracts/switcher/switcher_direction.dart';
import 'package:coui_core/src/component/contracts/switcher/switcher_style.dart';

/// Contract for a unified `Switcher` view-switcher component.
///
/// `Switcher` shows one of [items] at a time, animating a slide /
/// fade transition along [direction] when [index] changes. Users may
/// drag to change the active view when [gestureEnabled] is set.
///
/// Generic over the platform widget type `W` (Flutter `Widget`, Web
/// `Component`) — all other surfaces are platform-neutral.
abstract interface class CoreSwitcherContract<W> {
  /// Currently visible child index (0-based).
  int get index;

  /// Child views to switch between.
  List<W> get items;

  /// Direction the new view slides in from when [index] changes.
  CoreSwitcherDirection get direction;

  /// Whether drag / swipe navigation is enabled.
  ///
  /// When false, only programmatic [index] changes switch the view.
  bool get gestureEnabled;

  /// Invoked with the new index after a drag settles on a different
  /// view. Programmatic [index] changes do not invoke this.
  void Function(int)? get onIndexChanged;

  /// Per-instance transition style — the slide / fade
  /// [CoreSwitcherStyle.duration] and [CoreSwitcherStyle.curve].
  ///
  /// Resolves through the nested-merge chain
  /// (`CoreSwitcherStyle.defaultX` ← `theme.switcher.style` ←
  /// `widget.switcherStyle`).
  CoreSwitcherStyle? get switcherStyle;
}
