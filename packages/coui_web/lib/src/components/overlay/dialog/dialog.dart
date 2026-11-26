// File structure mirrors `_PopoverState` (overrides → handlers →
// DOM → render) for cross-platform readability.

import 'dart:async';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/components/control/button/button.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:coui_web/src/components/overlay/dialog/dialog_style.dart';
import 'package:coui_web/src/components/overlay/popover/popover_dom.dart';
import 'package:coui_web/src/overlay/barrier_press_tracker.dart';
import 'package:coui_web/src/overlay/coui_web_dom.dart';
import 'package:coui_web/src/overlay/overlay_controller.dart';
import 'package:coui_web/src/overlay/overlay_portal.dart';
import 'package:coui_web/src/overlay/top_layer.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';

/// Gives each mounted dialog its own title id, so the panel can name itself
/// by it (`aria-labelledby`) without two open dialogs pointing at one title.
int _coDialogIdCounter = 0;

/// Unified cross-platform dialog for CoUI Web.
///
/// Renders a modal dialog (backdrop + panel) above the application
/// tree. The dialog is portaled into the root `OverlayHost` dialog
/// layer when one is available so it sits above any open popovers /
/// menus / tooltips and isn't clipped by ancestor `overflow: hidden`
/// or `transform` containers.
///
/// `open` is a controlled prop — host code drives visibility via
/// state; the dialog itself does not manage its own open state beyond
/// the exit animation window. When `open` flips to `false`, the panel
/// plays its exit transition (`CoreDialogStyle.transitionDuration`,
/// `CoreEasing.exit` — mirrors Flutter's `reverseCurve`) and
/// stays mounted for that long before the portal entry is actually
/// cleared; reduced-motion unmounts immediately. Re-opening mid-exit
/// (rapid toggle) cancels the pending unmount.
///
/// Mirrors Flutter `Dialog` 1:1 — same parameter names, same
/// chrome tokens.
///
/// Example:
/// ```dart
/// Dialog(
///   open: true,
///   title: text('Confirm'),
///   content: text('Are you sure?'),
///   actions: [
///     Button(
///       variant: CoreButtonVariant.outline,
///       onPressed: handleCancel,
///       child: text('Cancel'),
///     ),
///     Button(
///       onPressed: handleConfirm,
///       child: text('Confirm'),
///     ),
///   ],
///   onClose: handleClose,
/// )
/// ```
///
/// surface:functional — a modal route mounts this panel over the page it
/// covers.
class Dialog extends UiStatefulComponent
    implements CoreDialogContract<Component> {
  /// Creates a [Dialog].
  const Dialog({
    super.attributes,
    super.classes,
    super.css,
    super.eventHandlers,
    super.id,
    super.key,
    super.onChange,
    super.onClick,
    super.onInput,
    super.onKeyDown,
    super.onKeyUp,
    super.onMouseEnter,
    super.onMouseLeave,
    this.title,
    this.content,
    this.leading,
    this.trailing,
    this.actions,
    this.open = true,
    this.onClose,
    this.dialogStyle,
  });

  @override
  final Component? title;

  @override
  final Component? content;

  @override
  final Component? leading;

  @override
  final Component? trailing;

  @override
  final List<Component>? actions;

  @override
  final bool open;

  @override
  final CoreVoidCallback? onClose;

  @override
  final CoreDialogStyle? dialogStyle;

  /// Returns a copy of this [Dialog] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Dialog copyWith({
    Key? key,
    UiMouseEventHandler? onClick,
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    Map<String, List<UiEventHandler>>? eventHandlers,
    String? id,
    UiInputEventHandler? onChange,
    UiInputEventHandler? onInput,
    UiKeyboardEventHandler? onKeyDown,
    UiKeyboardEventHandler? onKeyUp,
    UiMouseEventHandler? onMouseEnter,
    UiMouseEventHandler? onMouseLeave,
    Component? title,
    Component? content,
    Component? leading,
    Component? trailing,
    List<Component>? actions,
    bool? open,
    CoreVoidCallback? onClose,
    CoreDialogStyle? dialogStyle,
  }) {
    return Dialog(
      key: key ?? this.key,
      onClick: onClick ?? this.onClick,
      attributes: attributes ?? userAttributes,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      id: id ?? this.id,
      onChange: onChange ?? this.onChange,
      onInput: onInput ?? this.onInput,
      onKeyDown: onKeyDown ?? this.onKeyDown,
      onKeyUp: onKeyUp ?? this.onKeyUp,
      onMouseEnter: onMouseEnter ?? this.onMouseEnter,
      onMouseLeave: onMouseLeave ?? this.onMouseLeave,
      title: title ?? this.title,
      content: content ?? this.content,
      leading: leading ?? this.leading,
      trailing: trailing ?? this.trailing,
      actions: actions ?? this.actions,
      open: open ?? this.open,
      onClose: onClose ?? this.onClose,
      dialogStyle: dialogStyle ?? this.dialogStyle,
    );
  }

  @override
  State<Dialog> createState() => _DialogState();
}

class _DialogState extends State<Dialog> {
  bool _isMounted = false;

  /// The id the title slot wears, which the panel's `aria-labelledby` reads.
  final String _titleId = 'co-dialog-title-${_coDialogIdCounter++}';

  /// Whether [attributes] already carry an accessible name for the panel.
  static bool _callerNamedIt(Map<String, String> attributes) =>
      attributes.containsKey('aria-label') ||
      attributes.containsKey('aria-labelledby');

  /// Barrier dismiss follows the pointerdown start target — a press
  /// that starts on the panel and releases over the backdrop must NOT
  /// dismiss (text-selection / slider drags), only a press that both
  /// starts and ends on the backdrop does.
  final BarrierPressTracker _barrierPressTracker = BarrierPressTracker();

  /// Portal handle — set when the dialog (backdrop + panel) is
  /// mounted on the host overlay layer; null when the dialog is
  /// closed or no [OverlayPortal] exists in the ancestor chain
  /// (test contexts without `CoUIWeb` fall back to inline rendering).
  OverlayController? _overlayController;
  int? _overlayToken;

  /// Detaches the document-level Escape listener.
  void Function()? _disposeKeydown;

  /// Whether the panel is playing its exit animation (`co-dialog-panel-
  /// exit` / `co-overlay-fade-exit`) before unmount. `component.open`
  /// alone controls whether the *caller* wants the dialog open; this
  /// keeps the panel mounted a beat longer so the exit keyframe has
  /// something to animate (see class doc).
  bool _closing = false;

  /// Pending exit timer — non-null while the panel is animating out
  /// after [_startClosing]. Cancelled if the dialog is reopened before
  /// the animation completes (rapid toggle).
  Timer? _closeTimer;

  /// Close-animation duration, cached from the single `build` resolve
  /// so [didUpdateComponent] sizes [_closeTimer] without resolving
  /// again (it fires between builds, before the new one runs).
  Duration _transitionDuration = CoreDialogStyle.defaultTransitionDuration;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    // Escape rides the same condition as the dismissible barrier:
    // `onClose` is what makes this dialog dismissible at all. Menus,
    // popovers and the drawer already listen; the dialog — the most
    // modal surface of the four — had no key handler whatsoever.
    if (component.onClose != null) {
      _disposeKeydown = registerDocumentKeydownListener((key) {
        if (key == 'Escape' && component.open) component.onClose?.call();
      });
    }
  }

  @override
  void didUpdateComponent(covariant Dialog oldComponent) {
    super.didUpdateComponent(oldComponent);
    // Field mutation only — no `setState` here. `didUpdateComponent`
    // runs mid-rebuild (the parent already passed a new `component`,
    // and `build()` runs right after this returns), so the change is
    // picked up by that imminent build; wrapping it in `setState`
    // would ask the framework to schedule a *second* build during the
    // current one (mirrors `Popover.didUpdateComponent`'s
    // `_resolvedPlacement` field mutation, same reasoning).
    if (oldComponent.open && !component.open) {
      _startClosing();
    } else if (!oldComponent.open && component.open && _closing) {
      // Reopened mid-exit (rapid toggle) — the pending unmount below is
      // cancelled and the imminent build re-enters with the panel
      // still mounted.
      _closeTimer?.cancel();
      _closeTimer = null;
      _closing = false;
    }
  }

  /// Starts the exit window: keeps the panel mounted (playing the exit
  /// keyframe) for [_transitionDuration], then unmounts. Reduced
  /// motion collapses the transition tier to zero
  /// ([CoreReducedMotion]), so the panel unmounts on the very next
  /// build instead — no CSS override reaches this Dart-side timer, so
  /// the duration itself must shrink to zero here.
  void _startClosing() {
    final duration = CoreReducedMotion.resolve(
      _transitionDuration,
      reduce: prefersReducedMotion,
    );
    if (duration <= .zero) return;
    _closing = true;
    _closeTimer?.cancel();
    _closeTimer = Timer(duration, () {
      _closeTimer = null;
      if (!_isMounted) return;
      setState(() => _closing = false);
    });
  }

  @override
  void dispose() {
    _isMounted = false;
    _closeTimer?.cancel();
    _closeTimer = null;
    _disposeKeydown?.call();
    _disposeKeydown = null;
    _unmountPortal();
    super.dispose();
  }

  void _unmountPortal() {
    final controller = _overlayController;
    final token = _overlayToken;
    if (controller != null && token != null) {
      controller.unmount(token);
    }
    _overlayController = null;
    _overlayToken = null;
  }

  /// Builds the backdrop + panel pair as a single `display: contents`
  /// wrapper so the controller stores one component per dialog
  /// instance (avoids token bookkeeping for two separate entries).
  /// [closing] merges the exit-keyframe `animation` (`resolveDialogMotion`)
  /// onto the backdrop/panel chrome in place of the enter keyframe.
  Component _buildOverlayTree({
    required ResolvedDialog resolved,
    required ResolvedDialogTiming timing,
    required bool closing,
  }) {
    final motion = resolveDialogMotion(
      closing: closing,
      transitionDuration: Duration(milliseconds: timing.transitionDurationMs),
    );
    final onClose = component.onClose;
    final backdrop = div(
      const [],
      classes: resolved.backdrop.className,
      styles: Styles.combine([
        ?resolved.backdrop.inlineStyles,
        ?motion.backdrop.inlineStyles,
      ]),
      // Scrim and panel are separate top-layer elements (the `contents`
      // root below cannot be one): both `fixed`, both need the viewport
      // as containing block. Promoted in document order, so the scrim
      // stays under the panel.
      attributes: TopLayer.attributesFor(context),
      events: onClose != null
          ? {
              'pointerdown': (_) =>
                  _barrierPressTracker.handleBarrierPointerDown(),
              'click': (_) => _barrierPressTracker.handleBarrierClick(onClose),
            }
          : null,
    );

    final title = component.title;
    final leading = component.leading;
    final trailing = component.trailing;
    final contentNode = component.content;
    final actions = component.actions;
    final hasHeader = title != null || leading != null || trailing != null;
    final hasFooter = actions != null && actions.isNotEmpty;

    // Panel presses re-arm the barrier tracker (bubbling from all
    // panel content) so a drag that starts here and ends on the
    // backdrop is never treated as a barrier dismiss. Caller-supplied
    // 'pointerdown' handlers keep firing after the tracker hook.
    final userEvents = component.events;
    final userPointerDown = userEvents['pointerdown'];
    final panelEvents = <String, EventCallback>{
      ...userEvents,
      'pointerdown': (event) {
        _barrierPressTracker.handlePanelPointerDown();
        userPointerDown?.call(event);
      },
    };

    // Nested `CoreGapStyle` slots — forwarded straight to
    // `Gap(gapStyle: …)` siblings: `sectionGapStyle` on the header row
    // (between leading/title/trailing) and above the content,
    // `actionsGapStyle` above the footer (parity with the Flutter
    // widget).
    final sectionGap = Gap(gapStyle: resolved.sectionGapStyle);
    final actionsGap = Gap(gapStyle: resolved.actionsGapStyle);

    // A stretched actions row seats each action in its cell; otherwise
    // (`actionCell == null`) the action is a direct child of the footer.
    final actionCell = resolved.actionCell;
    Component seatAction(Component action) => actionCell == null
        ? action
        : div(
            [action],
            classes: actionCell.className,
            styles: actionCell.inlineStyles,
          );

    final dialogPanel = div(
      [
        if (hasHeader)
          div(
            [
              if (leading != null) ...[leading, sectionGap],
              if (title != null)
                div(
                  [title],
                  id: _titleId,
                  classes: resolved.titleSlot.className,
                  styles: resolved.titleSlot.inlineStyles,
                ),
              if (trailing != null) ...[sectionGap, trailing],
            ],
            classes: resolved.header.className,
            styles: resolved.header.inlineStyles,
          ),
        if (contentNode != null) ...[
          sectionGap,
          div(
            [contentNode],
            classes: resolved.content.className,
            styles: resolved.content.inlineStyles,
          ),
        ],
        if (hasFooter) ...[
          actionsGap,
          div(
            [
              // Forward the nested action-button style slot to each
              // `Button` action (Epic #1603 옵션 B); other action
              // types render as-is via the asChild pattern.
              for (final action in actions)
                if (action case final Button button
                    when resolved.actionButtonStyle != null)
                  seatAction(
                    button.copyWith(
                      buttonStyle: resolved.actionButtonStyle!.merge(
                        button.buttonStyle,
                      ),
                    ),
                  )
                else
                  seatAction(action),
            ],
            classes: resolved.footer.className,
            styles: resolved.footer.inlineStyles,
          ),
        ],
      ],
      id: component.id,
      classes: component.rootClasses(
        '${resolved.panel.className} ${motion.panel.className}',
      ),
      styles: Styles.combine([
        ?resolved.panel.inlineStyles,
        ?motion.panel.inlineStyles,
        ?component.css,
      ]),
      attributes: {
        ...TopLayer.attributesFor(context),
        // The title is the dialog's name — unless the caller already named
        // it, which is theirs to say and is not overwritten.
        if (title != null && !_callerNamedIt(component.componentAttributes))
          'aria-labelledby': _titleId,
        ...component.componentAttributes,
        'role': CoreSemanticRole.dialog.ariaRole,
        'aria-modal': 'true',
      },
      events: panelEvents,
    );

    return div(
      [backdrop, dialogPanel],
      classes: resolved.root.className,
      styles: resolved.root.inlineStyles,
    );
  }

  @override
  Component build(BuildContext context) {
    // Resolver finishes className + inlineStyles synthesis (Epic #1601
    // PoC — `WebResolvedChrome` contract). `co_dialog` reads the paint-
    // ready strings directly without invoking the top-level builder
    // helpers.
    final resolved = resolveDialog(
      context,
      actionCount: component.actions?.length ?? 0,
      dialogStyle: component.dialogStyle,
    );
    // Behaviour timing rides its own resolver (category E) rather than
    // the paint-ready chrome bundle — `ResolvedDialog` may only carry
    // `WebElementChrome` slots and nested `CoreXxxStyle` slots.
    final timing = resolveDialogTiming(
      context,
      dialogStyle: component.dialogStyle,
    );
    // Cached so `didUpdateComponent` (which fires between builds, with
    // no chance to resolve again) sizes the exit timer correctly.
    _transitionDuration = Duration(milliseconds: timing.transitionDurationMs);

    // The panel stays mounted through its exit window even after the
    // caller has already flipped `open` to false — `_closing` is what
    // keeps it alive (see `_startClosing`); `component.open` alone
    // would unmount it before the exit keyframe ever plays.
    final visible = component.open || _closing;
    final overlayTree = visible
        ? _buildOverlayTree(
            resolved: resolved,
            timing: timing,
            closing: _closing,
          )
        : null;

    final portal = OverlayPortal.maybeOf(context);
    final portalled = portal != null;
    if (portalled) {
      _schedulePortalSync(
        portal.controller,
        portal.capture(context, overlayTree),
      );
    } else if (_overlayController != null) {
      _unmountPortal();
    }

    if (portalled) {
      // The backdrop + panel live entirely on the overlay host's
      // dialog layer — emit nothing in place of the call site so
      // Dialog can be mounted directly inside layout flows
      // (Card / Column / etc.) without leaving a hole in the layout.
      return div(
        const [],
        classes: resolved.hidden.className,
        styles: resolved.hidden.inlineStyles,
      );
    }

    // SSR / test fallback — no portal host in the ancestor chain, so
    // render the dialog inline at the call site like the legacy
    // `UiComponent` implementation did.
    if (!visible) {
      return div(
        const [],
        classes: resolved.hidden.className,
        styles: resolved.hidden.inlineStyles,
      );
    }
    return overlayTree ??
        div(
          const [],
          classes: resolved.hidden.className,
          styles: resolved.hidden.inlineStyles,
        );
  }

  void _schedulePortalSync(OverlayController controller, Component? entry) {
    unawaited(
      Future<void>.microtask(() {
        if (!_isMounted) return;
        if (entry == null) {
          if (_overlayController != null) _unmountPortal();
          return;
        }
        if (_overlayController != controller) {
          _unmountPortal();
          _overlayController = controller;
        }
        final token = _overlayToken;
        if (token == null) {
          _overlayToken = controller.mount(
            layer: .dialog,
            panel: entry,
            modal: true,
          );
        } else {
          controller.update(token, entry);
        }
      }),
    );
  }
}

/// Chain sugar mirroring the Flutter `Dialog.withStyle` extension —
/// merges a [CoreDialogStyle] patch into [Dialog.dialogStyle] via the
/// existing [Dialog.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreDialogStyle.merge` right-side-wins semantics).
extension DialogStyleChain on Dialog {
  /// Returns a copy of this [Dialog] with [patch] merged into
  /// [dialogStyle] (patch fields win on conflict).
  Dialog withStyle(CoreDialogStyle patch) => copyWith(
    dialogStyle: (dialogStyle ?? const CoreDialogStyle()).merge(patch),
  );
}
