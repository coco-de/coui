import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/components/menu/context_menu/context_menu_lift.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

/// The preview of an open [ContextMenu]: a second overlay entry beside the
/// menu's own, placed around the box the menu ended up in.
///
/// The menu is positioned by the overlay engine — at the pointer, flipped and
/// shifted into the viewport, held to the room it has — so the preview cannot
/// be laid out before that. The engine reports the panel's resolved box
/// (`onPanelRect`), the box goes to [placeAround], and `CoreContextMenuPreview`
/// says where the preview goes; this class only draws what it is told.
///
/// The preview is drawn in the floating-panel chrome (a [Popup]) so it reads as
/// the menu's companion, ignores the pointer, never takes focus and fades with
/// the menu's own open and close durations. It is laid in the overlay above the
/// menu's entries, where a tap on it falls through to the menu's barrier — a
/// tap on the preview is a tap outside the menu.
final class ContextMenuPreviewHost {
  /// Prepares a preview for a menu opened from [context].
  ContextMenuPreviewHost({
    required BuildContext context,
    required this.previewBuilder,
    required this.openDuration,
    required this.closeDuration,
    this.retract,
  }) : _overlay = Overlay.of(context, rootOverlay: true),
       _direction = Directionality.of(context) {
    // What the menu's own entry captures, so the preview wears the host's
    // themes and scopes instead of the overlay's.
    _themes = InheritedTheme.capture(from: context, to: _overlay.context);
    _data = Data.capture(from: context, to: _overlay.context);
  }

  /// Builds the preview widget. Read each time the entry builds, so a host
  /// that rebuilds with a new preview can ask for a rebuild.
  final Widget Function() previewBuilder;

  /// How long the preview takes to fade in — the menu panel's open duration.
  final Duration openDuration;

  /// How long the preview takes to fade out — the menu panel's close duration.
  final Duration closeDuration;

  /// The frame a lifted menu folds its panel and preview back into the source
  /// with, or `null` for a menu that does not lift. When given, the preview
  /// does not fade by itself as the menu closes: it is painted by this frame,
  /// together with the panel, toward the same point.
  final ValueListenable<CoreContextMenuRetractFrame?>? retract;

  final OverlayState _overlay;
  final TextDirection _direction;
  late final CapturedThemes _themes;
  late final CapturedData _data;

  final ValueNotifier<Rect?> _menu = ValueNotifier(null);
  final ValueNotifier<bool> _closing = ValueNotifier(false);
  OverlayEntry? _entry;
  bool _disposed = false;

  /// Puts the preview in the overlay, above every entry already there. It
  /// draws nothing until the menu's box is known.
  void show() {
    if (_entry != null || _disposed) return;
    final entry = OverlayEntry(builder: _build);
    _entry = entry;
    _overlay.insert(entry);
  }

  /// The menu's resolved box, in the overlay's coordinates.
  void placeAround(Rect menu) {
    if (!_disposed) _menu.value = menu;
  }

  /// Runs the builder again — the host's `preview` changed.
  ///
  /// The host calls this from its `didUpdateWidget`, inside a build, where the
  /// framework refuses a rebuild of an overlay entry (it is not below the
  /// caller); the rebuild then waits for the end of the frame.
  void rebuild() {
    if (_disposed) return;

    final binding = SchedulerBinding.instance;
    if (binding.schedulerPhase != SchedulerPhase.persistentCallbacks) {
      _entry?.markNeedsBuild();

      return;
    }
    binding.addPostFrameCallback((_) {
      if (!_disposed) _entry?.markNeedsBuild();
    });
  }

  /// The menu began to close: fade out.
  void beginClose() {
    if (!_disposed) _closing.value = true;
  }

  /// Removes the entry and releases everything the host holds. The engine
  /// reports after the frame and the menu's futures complete on their own
  /// schedule, so every call that can arrive late checks first.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _entry
      ?..remove()
      ..dispose();
    _entry = null;
    _menu.dispose();
    _closing.dispose();
  }

  Widget _build(BuildContext context) {
    Widget child = Directionality(
      textDirection: _direction,
      child: ListenableBuilder(
        listenable: Listenable.merge([_menu, _closing]),
        builder: (context, _) => _ContextMenuPreviewLayer(
          menu: _menu.value,
          closing: _closing.value,
          direction: _direction,
          openDuration: openDuration,
          closeDuration: closeDuration,
          retract: retract,
          child: previewBuilder(),
        ),
      ),
    );
    child = _themes.wrap(child);

    return _data.wrap(child);
  }
}

class _ContextMenuPreviewLayer extends StatelessWidget {
  const _ContextMenuPreviewLayer({
    required this.menu,
    required this.closing,
    required this.direction,
    required this.openDuration,
    required this.closeDuration,
    required this.retract,
    required this.child,
  });

  final Rect? menu;
  final bool closing;
  final TextDirection direction;
  final Duration openDuration;
  final Duration closeDuration;
  final ValueListenable<CoreContextMenuRetractFrame?>? retract;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // The room the menu itself is kept inside: the engine's margin, and what
    // the system takes — status and home bars, the keyboard.
    final media = MediaQuery.of(context);
    const margin = CorePopoverStyle.defaultViewportPadding;
    final insets =
        EdgeInsets.fromLTRB(
          margin.left,
          margin.top,
          margin.right,
          margin.bottom,
        ) +
        media.padding +
        media.viewInsets;
    // A preview folding back with a lifted menu is faded by the fold, not by
    // its own fade: it stays as it is until the fold moves it.
    final folds = retract != null;
    final shown = menu != null && (folds || !closing);

    Widget placed = _PreviewPlacement(
      menu: menu,
      insets: insets,
      direction: direction,
      child: Popup(children: [child]),
    );
    if (folds) {
      // The placement fills the overlay, so its origin is the overlay's and the
      // pivot needs no conversion.
      placed = ContextMenuRetract(
        frame: retract!,
        origin: () => Offset.zero,
        child: placed,
      );
    }

    // Out of the pointer's and the focus's way, but not out of the semantics
    // tree: it is content the person asked to see beside the menu, so a screen
    // reader reads it as it reads any text, and no one can land on it.
    return IgnorePointer(
      child: ExcludeFocus(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: shown ? 1 : 0),
          duration: shown ? openDuration : closeDuration,
          builder: (context, opacity, child) =>
              Opacity(opacity: opacity, child: child),
          child: placed,
        ),
      ),
    );
  }
}

/// Lays its child around [menu] by `CoreContextMenuPreview.place`.
///
/// It fills the overlay, measures the child at its natural size, asks the rule
/// where that goes, and — when the rule holds the child to a smaller box
/// because no side has the room — lays it out again inside that box. Until the
/// menu's box is known, or when there is no room at all, it paints nothing.
class _PreviewPlacement extends SingleChildRenderObjectWidget {
  const _PreviewPlacement({
    required this.menu,
    required this.insets,
    required this.direction,
    required super.child,
  });

  final Rect? menu;
  final EdgeInsets insets;
  final TextDirection direction;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderPreviewPlacement(menu: menu, insets: insets, direction: direction);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderPreviewPlacement renderObject,
  ) {
    renderObject
      ..menu = menu
      ..insets = insets
      ..direction = direction;
  }
}

class _RenderPreviewPlacement extends RenderShiftedBox {
  _RenderPreviewPlacement({
    required Rect? menu,
    required EdgeInsets insets,
    required TextDirection direction,
  }) : _menu = menu,
       _insets = insets,
       _direction = direction,
       super(null);

  Rect? _menu;
  Rect? get menu => _menu;
  set menu(Rect? value) {
    if (_menu == value) return;
    _menu = value;
    markNeedsLayout();
  }

  EdgeInsets _insets;
  EdgeInsets get insets => _insets;
  set insets(EdgeInsets value) {
    if (_insets == value) return;
    _insets = value;
    markNeedsLayout();
  }

  TextDirection _direction;
  TextDirection get direction => _direction;
  set direction(TextDirection value) {
    if (_direction == value) return;
    _direction = value;
    markNeedsLayout();
  }

  /// What the rule decided at the last layout; `null` until the menu's box is
  /// known.
  CorePreviewPlacement? _placement;

  @override
  void performLayout() {
    size = constraints.biggest;
    final child = this.child;
    if (child == null) return;

    final viewport = CoreMenuBox(
      left: insets.left,
      top: insets.top,
      right: size.width - insets.right,
      bottom: size.height - insets.bottom,
    );
    final room = BoxConstraints(
      maxWidth: viewport.width > 0 ? viewport.width : 0,
      maxHeight: viewport.height > 0 ? viewport.height : 0,
    );
    child.layout(room, parentUsesSize: true);

    final menu = this.menu;
    if (menu == null) {
      _placement = null;

      return;
    }

    var placement = CoreContextMenuPreview.place(
      menu: CoreMenuBox(
        left: menu.left,
        top: menu.top,
        right: menu.right,
        bottom: menu.bottom,
      ),
      previewWidth: child.size.width,
      previewHeight: child.size.height,
      viewport: viewport,
      direction: direction == TextDirection.rtl
          ? CoreTextDirection.rtl
          : CoreTextDirection.ltr,
    );
    if (placement.visible && placement.capped) {
      // The rule held the preview below its natural size: lay it out inside
      // the box it was given.
      child.layout(
        BoxConstraints(
          maxWidth: placement.box.width,
          maxHeight: placement.box.height,
        ),
        parentUsesSize: true,
      );
      placement = CorePreviewPlacement(
        side: placement.side,
        box: CoreMenuBox.fromLTWH(
          placement.box.left,
          placement.box.top,
          child.size.width,
          child.size.height,
        ),
        capped: placement.capped,
      );
    }
    _placement = placement;
    (child.parentData! as BoxParentData).offset = Offset(
      placement.box.left,
      placement.box.top,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_placement?.visible != true) return;
    super.paint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      false;
}
