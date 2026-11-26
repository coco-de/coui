import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/web_dom_utils.dart' as dom_utils;
import 'package:coui_web/src/components/control/button/button.dart';
import 'package:coui_web/src/components/icon/icon.dart';
import 'package:coui_web/src/components/layout/window_panel/window_panel_style.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart' hide Text;
import 'package:universal_web/web.dart' as web;

/// Pointer distance (logical/CSS px, squared compare) the pointer must
/// travel before a title-bar press becomes a drag — Flutter's precise-
/// pointer pan slop (`kPrecisePointerPanSlop` = 2.0), so click vs drag
/// behave identically to the Flutter `GestureDetector.onPan*` wiring.
const _kPanSlop = 2.0;

/// Web counterpart of `WindowPanel`. Renders a `div`-based window frame
/// with a title bar and optional minimize / maximize / close controls.
///
/// Implements [CoreWindowPanelContract] so call sites match the Flutter
/// side; all styling is delegated to [window_panel_style.dart] to keep the
/// 2-file structure mandated by the unify-component skill.
///
/// surface:functional — the window frame — the box a `Window` floats over
/// the desktop.
class WindowPanel extends UiComponent
    implements CoreWindowPanelContract<Component> {
  /// Creates a [WindowPanel].
  const WindowPanel({
    this.child,
    this.title,
    this.actions,
    this.closable = true,
    this.minimizable = false,
    this.maximizable = false,
    this.onClose,
    this.onMinimize,
    this.onMaximize,
    this.isMinimized = false,
    this.onTitleBarDragStart,
    this.onTitleBarDragUpdate,
    this.onTitleBarDragEnd,
    this.onTitleBarDragCancel,
    this.onTitleBarDoubleTap,
    this.windowPanelStyle,
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'div');

  @override
  final Component? child;

  @override
  final Component? title;

  @override
  final Component? actions;

  @override
  final bool closable;

  @override
  final bool minimizable;

  @override
  final bool maximizable;

  @override
  final CoreVoidCallback? onClose;

  @override
  final CoreVoidCallback? onMinimize;

  @override
  final CoreVoidCallback? onMaximize;

  @override
  final bool isMinimized;

  @override
  final CoreTitleBarDragStartCallback? onTitleBarDragStart;

  @override
  final CoreTitleBarDragUpdateCallback? onTitleBarDragUpdate;

  @override
  final CoreTitleBarDragEndCallback? onTitleBarDragEnd;

  @override
  final CoreTitleBarDragEndCallback? onTitleBarDragCancel;

  @override
  final CoreVoidCallback? onTitleBarDoubleTap;

  @override
  final CoreWindowPanelStyle? windowPanelStyle;
  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);
    attributes.addRole('dialog');
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveWindowPanel(
      context,
      windowPanelStyle: windowPanelStyle,
    );
    final content = child;
    return Component.element(
      tag: tag,
      id: id,
      classes: [
        resolved.root.className,
        ?classes,
      ].join(' ').trim(),
      styles: Styles.combine([
        ?resolved.root.inlineStyles,
        ?css,
      ]),
      // `aria-label` needs `CouiLocalizations.of(context)`, which
      // `configureAttributes` cannot reach (no `BuildContext` there) —
      // so it's merged in here alongside the context-free attributes.
      attributes: {
        ...componentAttributes,
        'aria-label': CouiLocalizations.of(context).windowLabel,
      },
      events: events,
      children: [
        _buildTitleBar(context, resolved),
        if (!isMinimized && content != null)
          div(
            [content],
            classes: resolved.content.className,
            styles: resolved.content.inlineStyles,
          ),
      ],
    );
  }

  @override
  WindowPanel copyWith({
    Component? child,
    Component? title,
    Component? actions,
    bool? closable,
    bool? minimizable,
    bool? maximizable,
    CoreVoidCallback? onClose,
    CoreVoidCallback? onMinimize,
    CoreVoidCallback? onMaximize,
    bool? isMinimized,
    CoreTitleBarDragStartCallback? onTitleBarDragStart,
    CoreTitleBarDragUpdateCallback? onTitleBarDragUpdate,
    CoreTitleBarDragEndCallback? onTitleBarDragEnd,
    CoreTitleBarDragEndCallback? onTitleBarDragCancel,
    CoreVoidCallback? onTitleBarDoubleTap,
    CoreWindowPanelStyle? windowPanelStyle,
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
  }) {
    return WindowPanel(
      key: key ?? this.key,
      title: title ?? this.title,
      actions: actions ?? this.actions,
      closable: closable ?? this.closable,
      minimizable: minimizable ?? this.minimizable,
      maximizable: maximizable ?? this.maximizable,
      onClose: onClose ?? this.onClose,
      onMinimize: onMinimize ?? this.onMinimize,
      onMaximize: onMaximize ?? this.onMaximize,
      isMinimized: isMinimized ?? this.isMinimized,
      onTitleBarDragStart: onTitleBarDragStart ?? this.onTitleBarDragStart,
      onTitleBarDragUpdate: onTitleBarDragUpdate ?? this.onTitleBarDragUpdate,
      onTitleBarDragEnd: onTitleBarDragEnd ?? this.onTitleBarDragEnd,
      onTitleBarDragCancel: onTitleBarDragCancel ?? this.onTitleBarDragCancel,
      onTitleBarDoubleTap: onTitleBarDoubleTap ?? this.onTitleBarDoubleTap,
      windowPanelStyle: windowPanelStyle ?? this.windowPanelStyle,
      id: id ?? this.id,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      attributes: attributes ?? userProvidedAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      child: child ?? this.child,
    );
  }

  Component _buildTitleBar(
    BuildContext context,
    ResolvedWindowPanel resolved,
  ) {
    final dragStart = onTitleBarDragStart;
    final dragUpdate = onTitleBarDragUpdate;
    final dragEnd = onTitleBarDragEnd;
    final dragCancel = onTitleBarDragCancel;
    final doubleTap = onTitleBarDoubleTap;
    final events = <String, EventCallback>{};
    if (dragStart != null ||
        dragUpdate != null ||
        dragEnd != null ||
        dragCancel != null) {
      // Trigger on pointerdown (not mousedown): the drag listeners are
      // pointer events, and on touch devices the compatibility mousedown
      // fires after the gesture's pointerup — registering from it would
      // leak the document listeners. Pointer events also make the
      // title-bar drag work with touch (Flutter onPan* parity).
      events['pointerdown'] = (Object event) {
        if (event case final web.MouseEvent mouseEvent) {
          mouseEvent.preventDefault();
          // `mouseClientX/Y` re-read the coordinates as doubles —
          // browsers deliver sub-pixel mouse positions and the
          // `int`-declared getters throw a cast error on them.
          final clientX = dom_utils.mouseClientX(mouseEvent) ?? 0;
          final clientY = dom_utils.mouseClientY(mouseEvent) ?? 0;
          // Local position relative to the title bar's top-left corner.
          final target = mouseEvent.currentTarget;
          CoreOffset local = CoreOffset(clientX, clientY);
          if (target case final web.Element element) {
            final rect = element.getBoundingClientRect();
            local = CoreOffset(
              clientX - rect.left.toDouble(),
              clientY - rect.top.toDouble(),
            );
          }
          // A drag only starts after the pointer travels past the pan
          // slop (Flutter parity — `onPanStart` never fires for a plain
          // click / double-click, so pressing a maximized window's
          // title no longer restores it and the snap bar stays hidden).
          var started = false;
          // Track subsequent moves/up at document level so the drag
          // survives pointer leaving the title bar.
          var lastClientX = clientX;
          var lastClientY = clientY;
          dom_utils.registerDragListeners(
            onMove: (moveEvent) {
              if (moveEvent case final web.MouseEvent mv) {
                final currentX = dom_utils.mouseClientX(mv) ?? lastClientX;
                final currentY = dom_utils.mouseClientY(mv) ?? lastClientY;
                if (!started) {
                  final totalDx = currentX - clientX;
                  final totalDy = currentY - clientY;
                  if (totalDx * totalDx + totalDy * totalDy <
                      _kPanSlop * _kPanSlop) {
                    return;
                  }
                  started = true;
                  // The slop distance itself is consumed by gesture
                  // detection (Flutter pan parity) — deltas start from
                  // the position where the slop was exceeded.
                  lastClientX = currentX;
                  lastClientY = currentY;
                  if (dragStart != null) {
                    dragStart(local, CoreOffset(currentX, currentY));
                  }
                  return;
                }
                final delta = CoreOffset(
                  currentX - lastClientX,
                  currentY - lastClientY,
                );
                lastClientX = currentX;
                lastClientY = currentY;
                final nextGlobal = CoreOffset(currentX, currentY);
                if (dragUpdate != null) dragUpdate(delta, nextGlobal);
              }
            },
            onUp: (_) {
              if (started && dragEnd != null) dragEnd();
            },
            // Browser aborted the interaction (pointercancel) — mirror
            // Flutter's `onPanCancel` wiring; fall back to end semantics
            // when no cancel handler is supplied.
            onCancel: (_) {
              if (!started) return;
              if (dragCancel != null) {
                dragCancel();
              } else if (dragEnd != null) {
                dragEnd();
              }
            },
            downEvent: event,
          );
        }
      };
    }
    if (doubleTap != null) {
      events['dblclick'] = (event) => doubleTap();
    }
    return div(
      [
        _buildTitle(context, resolved),
        ?actions,
        _buildControls(context, resolved),
      ],
      classes: resolved.titleBar.className,
      styles: resolved.titleBar.inlineStyles,
      events: events.isEmpty ? null : events,
    );
  }

  Component _buildTitle(BuildContext context, ResolvedWindowPanel resolved) {
    return div(
      [
        if (title != null)
          div(
            [title!],
            classes: resolved.title.className,
            styles: resolved.title.inlineStyles,
          ),
      ],
      classes: resolved.titleWrapper.className,
      styles: resolved.titleWrapper.inlineStyles,
    );
  }

  Component _buildControls(
    BuildContext context,
    ResolvedWindowPanel resolved,
  ) {
    final localizations = CouiLocalizations.of(context);
    final buttons = <Component>[
      if (minimizable)
        _controlButton(
          onTap: onMinimize,
          resolved: resolved,
          icon: LucideIcons.minus,
          label: localizations.windowMinimize,
          isClose: false,
        ),
      if (maximizable)
        _controlButton(
          onTap: onMaximize,
          resolved: resolved,
          icon: LucideIcons.square,
          label: localizations.windowMaximize,
          isClose: false,
        ),
      if (closable)
        _controlButton(
          onTap: onClose,
          resolved: resolved,
          icon: LucideIcons.x,
          label: localizations.buttonClose,
          isClose: true,
        ),
    ];
    return div(
      buttons,
      classes: resolved.controls.className,
      styles: resolved.controls.inlineStyles,
    );
  }

  /// Composes one control affordance via the unified `Button(variant:
  /// .plain)` + Lucide vector `Icon` (affordance rule — no raw
  /// `<button>`, no font glyph; the Flutter twin renders the same
  /// vectors). Chrome flows through the resolved nested
  /// `CoreButtonStyle` slot; the icon inherits the button's per-state
  /// `currentColor`. The wrapper `<div>` fences the title-bar gestures
  /// — behaviour, not chrome, so it stays in the widget:
  /// `pointerdown` so a control press never starts a drag, and
  /// `click`/`dblclick` so two quick presses (minimize → restore)
  /// never bubble into the title bar's double-click-maximize (Flutter
  /// parity: the button wins the gesture arena there).
  Component _controlButton({
    required ResolvedWindowPanel resolved,
    required IconName icon,
    required String label,
    required bool isClose,
    required CoreVoidCallback? onTap,
  }) {
    return div(
      [
        Button(
          onPressed: onTap,
          variant: .plain,
          size: .sm,
          buttonStyle: isClose
              ? resolved.closeButtonStyle
              : resolved.controlButtonStyle,
          // Drawn at 20×20; the pointer target reaches the WCAG floor.
          // At the default control spacing the neighbouring floors meet
          // in the gap without overlapping.
          classes: kWebTouchTargetMarker,
          attributes: {'aria-label': label},
          child: Icon(icon, iconStyle: resolved.controlIconStyle),
        ),
      ],
      events: {
        'pointerdown': (event) {
          event.stopPropagation();
        },
        'click': (event) {
          event.stopPropagation();
        },
        'dblclick': (event) {
          event.stopPropagation();
        },
      },
    );
  }
}

/// Chain sugar mirroring the Flutter `WindowPanel.withStyle` extension —
/// merges a [CoreWindowPanelStyle] patch into [WindowPanel.windowPanelStyle]
/// via the existing [WindowPanel.copyWith]. Composition slots (`title` /
/// `child` / `actions`) keep using their own components directly.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreWindowPanelStyle.merge` right-side-wins semantics).
///
/// The getters below are shorter sugar for the same [withStyle] call.
/// Each one is a direct 1:1 alias for a `CoreRadius` primitive — the
/// getter *name* is the token name, so `.radius4` always means
/// `CoreRadius.radius4`, no matter which component it's called on. That
/// fixed name-to-value mapping is what makes a short getter safe to
/// reuse across components — a curated nickname (`.rounded`, `.compact`)
/// would silently map to a different value per component, but a
/// primitive-token getter cannot.
///
/// These are intentionally primitive (not semantic) for now: `.radius4`
/// sets [CoreWindowPanelStyle.borderRadius]. A semantic layer that names
/// these after component-specific intent (decided together with design)
/// is a follow-up once more components adopt this pattern.
///
/// ```dart
/// WindowPanel(title: Text('Editor')).radius4
/// ```
extension WindowPanelStyleChain on WindowPanel {
  /// Returns a copy of this [WindowPanel] with [patch] merged into
  /// [windowPanelStyle] (patch fields win on conflict).
  WindowPanel withStyle(CoreWindowPanelStyle patch) => copyWith(
    windowPanelStyle: (windowPanelStyle ?? const CoreWindowPanelStyle()).merge(
      patch,
    ),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  WindowPanel get radius0 => withStyle(
    const CoreWindowPanelStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius0),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  WindowPanel get radius2 => withStyle(
    const CoreWindowPanelStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  WindowPanel get radius4 => withStyle(
    const CoreWindowPanelStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  WindowPanel get radius6 => withStyle(
    const CoreWindowPanelStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  WindowPanel get radius8 => withStyle(
    const CoreWindowPanelStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  WindowPanel get radius10 => withStyle(
    const CoreWindowPanelStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  WindowPanel get radius12 => withStyle(
    const CoreWindowPanelStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  WindowPanel get radius14 => withStyle(
    const CoreWindowPanelStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  WindowPanel get radius16 => withStyle(
    const CoreWindowPanelStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  WindowPanel get radius20 => withStyle(
    const CoreWindowPanelStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  WindowPanel get radius24 => withStyle(
    const CoreWindowPanelStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  WindowPanel get radius28 => withStyle(
    const CoreWindowPanelStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  WindowPanel get radius32 => withStyle(
    const CoreWindowPanelStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  WindowPanel get radius36 => withStyle(
    const CoreWindowPanelStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  WindowPanel get radius40 => withStyle(
    const CoreWindowPanelStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  WindowPanel get radius48 => withStyle(
    const CoreWindowPanelStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  WindowPanel get radius56 => withStyle(
    const CoreWindowPanelStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  WindowPanel get radius64 => withStyle(
    const CoreWindowPanelStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  WindowPanel get radius9999 => withStyle(
    const CoreWindowPanelStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );
}
