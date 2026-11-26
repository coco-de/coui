import 'dart:async';

import 'package:coui_flutter/src/page/route_page.dart';
import 'package:flutter/widgets.dart';

/// A navigation stack confined to a detail pane. The containing route's back
/// history tracks each pushed page, so a device back action unwinds this stack.
class NavigationPane extends StatefulWidget {
  /// Creates a pane with a stable first page.
  const NavigationPane({
    required this.builder,
    required this.onClose,
    super.key,
  });

  /// Builds the first page in the pane.
  final WidgetBuilder builder;

  /// Closes the pane when its first page is popped.
  final VoidCallback onClose;

  /// Pushes in the nearest pane, if one exists.
  static Future<void>? maybePush(BuildContext context, WidgetBuilder builder) =>
      _paneOf(context)?.push(builder);

  /// Handles back within the nearest pane, including its first page.
  static bool maybePop(BuildContext context) {
    final pane = _paneOf(context);
    if (pane == null) return false;
    pane.pop();
    return true;
  }

  static _NavigationPaneState? _paneOf(BuildContext context) {
    final pane = context.findAncestorStateOfType<_NavigationPaneState>();
    return pane?._navigator.currentState == Navigator.maybeOf(context)
        ? pane
        : null;
  }

  @override
  State<NavigationPane> createState() => _NavigationPaneState();
}

class _NavigationPaneState extends State<NavigationPane> {
  final _navigator = GlobalKey<NavigatorState>();
  final _history = <LocalHistoryEntry>[];

  Future<void> push(WidgetBuilder builder) async {
    final navigator = _navigator.currentState!;
    final route = RoutePageRoute<void>(builder: builder);
    final outer = ModalRoute.of(context);
    LocalHistoryEntry? entry;
    if (outer != null) {
      late final LocalHistoryEntry historyEntry;
      historyEntry = LocalHistoryEntry(
        onRemove: () {
          if (!_history.remove(historyEntry)) return;
          if (!navigator.mounted || !route.isCurrent) return;
          unawaited(_maybePopFromHost(navigator, route, outer, historyEntry));
        },
      );
      entry = historyEntry;
      _history.add(historyEntry);
      outer.addLocalHistoryEntry(historyEntry);
    }

    try {
      await navigator.push(route);
    } finally {
      if (entry != null && _history.remove(entry)) entry.remove();
    }
  }

  Future<void> _maybePopFromHost(
    NavigatorState navigator,
    Route<void> route,
    ModalRoute<dynamic> outer,
    LocalHistoryEntry entry,
  ) async {
    await navigator.maybePop();
    // A PopScope or a route's own local history can consume back without
    // closing its page. Keep the host and pane histories synchronized.
    if (!mounted || !outer.isActive || !route.isActive) return;
    _history.add(entry);
    outer.addLocalHistoryEntry(entry);
  }

  void pop() {
    final navigator = _navigator.currentState!;
    if (navigator.canPop()) {
      navigator.maybePop();
    } else {
      widget.onClose();
    }
  }

  @override
  void dispose() {
    final entries = _history.reversed.toList();
    _history.clear();
    for (final entry in entries) {
      entry.remove();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PrimaryScrollController.none(
    child: Navigator(
      key: _navigator,
      onGenerateRoute: (_) =>
          RoutePageRoute<void>(builder: (context) => widget.builder(context)),
    ),
  );
}

/// For a pane whose parent has already reserved the physical app-bar strip.
class NavigationPanePadding extends InheritedWidget {
  /// Preserves the original device padding for adaptive chrome in the pane.
  const NavigationPanePadding({
    required this.viewPadding,
    required super.child,
    super.key,
  });

  /// Device padding before a parent applied safe area.
  final EdgeInsets? viewPadding;

  /// Retrieves the original device padding for a nested scaffold.
  static EdgeInsets? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<NavigationPanePadding>()
      ?.viewPadding;

  @override
  bool updateShouldNotify(NavigationPanePadding oldWidget) =>
      viewPadding != oldWidget.viewPadding;
}
