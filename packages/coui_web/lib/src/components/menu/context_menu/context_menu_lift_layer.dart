import 'package:coui_web/src/components/menu/context_menu/context_menu_lift.dart';
import 'package:coui_web/src/components/menu/context_menu/context_menu_style.dart';
import 'package:coui_web/src/overlay/overlay_motion.dart'
    show kLiftDimAttribute;
import 'package:coui_web/src/overlay/top_layer.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

/// What a lifted `ContextMenu` source draws: a dim over the page and, above
/// it, a second rendering of the source's child at the original's place.
///
/// It is its own stateful component, a child of the menu's root and not part of
/// the portalled panel, for two reasons. The portal re-creates the panel's DOM
/// node on every render, so a layer drawn there would be torn down and rebuilt
/// on every frame of the lift, and every `setState` of the menu re-renders the
/// portal and restarts the panel's keyframes. A layer that redraws itself —
/// each frame, from the lift's own clock — touches nothing but its own subtree.
///
/// ```text
/// layer (<div fixed inset-0 popover>)          // top layer: over the page
///   ├─ dim (<div absolute inset-0>)
///   └─ copy (<div absolute>)                   // the source's box, scaled, casting
///        └─ child                              // a second build
/// ```
///
/// The layer joins the top layer when it is inserted, ahead of the menu's
/// panel, so the panel — the interactive thing — is above it; the copy is a
/// picture. It ignores the pointer (the press that is waiting out its hold is
/// on the original, underneath), is hidden from assistive technology and made
/// inert (the original is what a person reads and reaches), and the child it
/// holds is built again from the same component, so it has no state of its own.
class ContextMenuLiftLayer extends StatefulComponent {
  /// Creates the layer with the DOM id [id], drawing what [lift] says with the
  /// numbers [runtime] settled, and holding a second build of [child].
  const ContextMenuLiftLayer({
    required this.id,
    required this.lift,
    required this.runtime,
    required this.child,
    super.key,
  });

  /// The layer's id, so a test of the page can find it.
  final String id;

  /// The clock and the box: how far the lift has come, and where the source
  /// is.
  final ContextMenuLift lift;

  /// The menu's settled numbers: the size, dim, cast and corners the copy is
  /// drawn with.
  final ResolvedContextMenuRuntime runtime;

  /// The source's child, built a second time for the copy.
  final Component child;

  @override
  State<ContextMenuLiftLayer> createState() => _ContextMenuLiftLayerState();
}

class _ContextMenuLiftLayerState extends State<ContextMenuLiftLayer> {
  @override
  void initState() {
    super.initState();
    component.lift.addListener(_handleChange);
  }

  @override
  void didUpdateComponent(covariant ContextMenuLiftLayer oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.lift == component.lift) return;
    oldComponent.lift.removeListener(_handleChange);
    component.lift.addListener(_handleChange);
  }

  @override
  void dispose() {
    component.lift.removeListener(_handleChange);
    super.dispose();
  }

  void _handleChange() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Component build(BuildContext context) {
    final lift = component.lift;
    final source = lift.source;
    if (source == null) return const Component.fragment([]);

    final resolved = resolveContextMenuLift(
      context,
      progress: lift.progress,
      source: source,
      runtime: component.runtime,
    );

    return div(
      [
        div(
          const [],
          classes: resolved.dim.className,
          styles: resolved.dim.inlineStyles,
          attributes: const {kLiftDimAttribute: ''},
        ),
        div(
          [component.child],
          classes: resolved.copy.className,
          styles: resolved.copy.inlineStyles,
        ),
      ],
      id: component.id,
      classes: resolved.root.className,
      styles: resolved.root.inlineStyles,
      attributes: {
        ...TopLayer.attributesFor(context),
        // A picture, not a control: out of the accessibility tree, the tab
        // order and the pointer's way, so the original is the only thing a
        // person can reach or hear.
        'aria-hidden': 'true',
        'inert': '',
      },
    );
  }
}
