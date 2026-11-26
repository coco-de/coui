/// The focus gate around a Flutter preview embedded in a docs page.
///
/// **Client-path import only**: this file carries a Flutter widget, so a
/// server (SSG) import would pull `dart:ui` into the server build. It is
/// reached from the embed widget (`docs_site`'s `preview_app.dart`) alone.
library;

import 'dart:async';
import 'dart:ui' show ViewFocusDirection, ViewFocusEvent, ViewFocusState;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Lets a preview take the framework's focus only while its own view holds
/// the page's.
///
/// ## What it stops
///
/// A Flutter app asks for focus as it starts — the navigator focuses its
/// first route — and the `View` above it answers a focused scope by asking
/// the page for the view's DOM focus. In a docs page that is a preview
/// taking the reader's focus the moment it appears: on load, and again each
/// time a variant is picked. From then on the engine hands every key to the
/// framework first, and the app's default shortcuts keep the arrows and Tab,
/// so the page neither scrolls nor moves its own focus until the reader
/// clicks somewhere else.
///
/// ## How
///
/// Everything under the gate is unfocusable while the view is not the
/// reader's. A focus request made then is dropped, the view's scope never
/// gains focus, and the view never asks for the page's. The framework's
/// focus stays parked outside the preview, so no shortcut of the app answers
/// a key and the page keeps its keys.
///
/// The gate opens when the reader comes in — the engine reports the view
/// focused, or a pointer goes down inside it — and closes when the engine
/// reports the focus gone.
///
/// ## Coming in
///
/// The `View` gives the focus to its first or last stop when its view is
/// focused, but it is told before this gate and finds nothing focusable
/// behind a closed one. So the gate repeats that step once it has opened.
/// Either order of the two ends on the same node.
///
/// A stop is often a scope — the navigator's — and a scope given the focus
/// keeps it on no control. When the focus came by Tab, the gate goes on
/// from the stop the way a Tab press does: into the scope, to its first
/// control or its last. The press that enters the view then lands on a
/// control rather than on the view with nothing focused. Any other way in —
/// a press, a script, the window coming back — gets what the `View` gives
/// it; a press that focused the first control would ring a control the
/// reader did not choose.
///
/// ## With the accessibility tree on
///
/// The gate stays open. Assistive technology moves the focus by acting on a
/// node of the tree, and that action reaches the framework before the engine
/// reports the view focused; a closed gate would drop it, and the node the
/// reader chose would lose to the view's first stop.
///
/// A preview that appears while the tree is on therefore takes the focus as
/// it would with no gate. Closing the gate for that moment would not keep
/// the page's focus where it was: the engine itself focuses the first node
/// of a route that appears, whatever the framework asked for.
///
/// A `Focus` tells the tree what it concluded the last time its own node
/// changed, and hears nothing when an ancestor opens. A control whose
/// focusability changed behind a closed gate is therefore told to the tree
/// as not focusable until it changes again or is focused.
class PreviewFocusGate extends StatefulWidget {
  /// Creates a gate around [child], the app a view embeds.
  const PreviewFocusGate({required this.child, super.key});

  /// The embedded app.
  final Widget child;

  @override
  State<PreviewFocusGate> createState() => _PreviewFocusGateState();
}

class _PreviewFocusGateState extends State<PreviewFocusGate> with WidgetsBindingObserver {
  /// The node whose descendants are the preview. Never focused itself.
  final FocusNode _gate = FocusNode(
    debugLabel: 'Preview focus gate',
    canRequestFocus: false,
    skipTraversal: true,
    descendantsAreFocusable: false,
  );

  int? _viewId;

  /// The engine last reported this view focused.
  bool _viewFocused = false;

  /// A pointer went down in this view since its focus was last reported gone.
  ///
  /// The engine focuses a view that is pressed, but a task later. Something
  /// under the pointer may take the focus during the press itself.
  bool _pressed = false;

  bool get _open => _viewFocused || _pressed || WidgetsBinding.instance.semanticsEnabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
      ..addObserver(this)
      ..addSemanticsEnabledListener(_sync);
    _gate.addListener(_handleGateChanged);
    _sync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _viewId = View.maybeOf(context)?.viewId;
  }

  @override
  void dispose() {
    WidgetsBinding.instance
      ..removeObserver(this)
      ..removeSemanticsEnabledListener(_sync);
    _gate
      ..removeListener(_handleGateChanged)
      ..dispose();
    super.dispose();
  }

  @override
  void didChangeViewFocus(ViewFocusEvent event) {
    final byPointer = _pressed;
    _viewFocused = event.state == ViewFocusState.focused && event.viewId == _viewId;
    if (!_viewFocused) _pressed = false;
    _sync();
    if (_viewFocused) _enter(event.direction, byPointer: byPointer);
  }

  /// Opens the gate, or closes it once nothing under it is focused.
  ///
  /// Closing a node that still holds the focus hands that focus to the
  /// enclosing scope — the view's — and the view answers a focused scope by
  /// asking the page for its focus: the very request the gate exists to stop.
  /// The `View` moves the focus out itself on the event that ends the
  /// reader's stay, so the gate waits for that to land ([_handleGateChanged])
  /// and closes with nothing left to hand over.
  void _sync() {
    if (_open) {
      _gate.descendantsAreFocusable = true;

      return;
    }
    if (_gate.hasFocus) return;
    _gate.descendantsAreFocusable = false;
  }

  void _handleGateChanged() {
    if (_open || _gate.hasFocus || !_gate.descendantsAreFocusable) return;
    // Not from inside the notification: the focus manager is walking the
    // nodes it has to notify, and closing marks this one changed.
    scheduleMicrotask(() {
      if (mounted) _sync();
    });
  }

  void _handlePress() {
    _pressed = true;
    _sync();
  }

  /// Gives the focus to the stop the reader's way in leads to.
  void _enter(ViewFocusDirection direction, {required bool byPointer}) {
    final scope = _gate.enclosingScope;
    if (scope == null) return;
    final policy = FocusTraversalGroup.maybeOfNode(scope) ?? ReadingOrderTraversalPolicy();
    // The `View`'s own choice, made again now that there is something to
    // choose from.
    final stop = switch (direction) {
      ViewFocusDirection.forward => policy.findFirstFocus(scope, ignoreCurrentFocus: true) ?? scope,
      ViewFocusDirection.backward => policy.findLastFocus(scope, ignoreCurrentFocus: true),
      ViewFocusDirection.undefined => scope,
    };
    // The key is still down while the browser moves the focus it caused.
    final byTab =
        !byPointer &&
        direction != ViewFocusDirection.undefined &&
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.tab);
    final forward = direction != ViewFocusDirection.backward;
    final rest = _rest(stop, policy, forward: forward, byTab: byTab);
    if (!byTab) {
      rest.requestFocus();

      return;
    }
    policy.requestFocusCallback(
      rest,
      alignmentPolicy: forward
          ? ScrollPositionAlignmentPolicy.keepVisibleAtEnd
          : ScrollPositionAlignmentPolicy.keepVisibleAtStart,
    );
  }

  /// Where a focus given to [stop] comes to rest.
  ///
  /// A scope hands the focus on to the child it last had focused, and keeps
  /// it when it remembers none. Two things are added to that:
  ///
  /// - A scope that the app named as the one to focus first — the navigator
  ///   names its route — forgets the name when it is asked for the focus
  ///   behind a closed gate: the framework drops a remembered child that
  ///   cannot be focused, and an app asks as it starts. A scope left with a
  ///   single stop, itself a scope, is taken to have named it. Without this
  ///   the focus would rest one scope above the route, out of reach of what
  ///   the route provides — its scroll controller, its actions.
  /// - A Tab goes on into a scope as a Tab press does: to its first stop, or
  ///   its last going backwards, until what is left is a control or a scope
  ///   with nothing in it.
  FocusNode _rest(FocusNode stop, FocusTraversalPolicy policy, {required bool forward, required bool byTab}) {
    var node = stop;
    while (node is FocusScopeNode) {
      final remembered = node.focusedChild;
      FocusNode? next;
      if (remembered != null && remembered.canRequestFocus) {
        next = remembered;
      } else {
        final first = policy.findFirstFocus(node, ignoreCurrentFocus: true);
        final last = policy.findLastFocus(node, ignoreCurrentFocus: true);
        if (byTab) {
          next = forward ? first : last;
        } else if (first is FocusScopeNode && first == last) {
          next = first;
        }
      }
      if (next == null || next == node) break;
      node = next;
    }

    return node;
  }

  @override
  Widget build(BuildContext context) => Focus.withExternalFocusNode(
    focusNode: _gate,
    includeSemantics: false,
    child: _PressFirst(onPress: _handlePress, child: widget.child),
  );
}

/// Reports a pointer going down before anything under it hears of it.
class _PressFirst extends SingleChildRenderObjectWidget {
  const _PressFirst({required this.onPress, required super.child});

  final VoidCallback onPress;

  @override
  _RenderPressFirst createRenderObject(BuildContext context) => _RenderPressFirst(onPress);

  @override
  void updateRenderObject(BuildContext context, _RenderPressFirst renderObject) => renderObject.onPress = onPress;
}

class _RenderPressFirst extends RenderProxyBox {
  _RenderPressFirst(this.onPress);

  VoidCallback onPress;

  /// Joins the result ahead of the children.
  ///
  /// An event is handed to its targets in the order they joined, and a box
  /// normally joins after its children. A listener around the app would hear
  /// of a press after a control under the pointer had already asked for the
  /// focus — and been refused.
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!size.contains(position)) return false;
    result.add(BoxHitTestEntry(this, position));

    return hitTestChildren(result, position: position);
  }

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    if (event is PointerDownEvent) onPress();
  }
}
