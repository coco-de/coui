import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/base/web_dom_utils.dart' as dom_utils;
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/components/icon/icon.dart';
import 'package:coui_web/src/components/infra/focus_outline/focus_outline.dart';
import 'package:coui_web/src/components/layout/resizable/resizable_style.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:coui_web/src/util/core_to_css.dart' show CoreSemanticRoleToAria;
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

/// Flex precision — ratios stored as integer (ratio × [_kFlexPrecision]).
const _kFlexPrecision = 1000;

/// Ratio → percent conversion factor. Not a design token — pure math for
/// the numbers a screen reader announces for a focused divider, in the
/// same percent-of-container convention as the Flutter twin. The
/// percentage reaches the user two ways: as the spoken sentence in
/// `aria-valuetext` (Flutter: `value` / `increasedValue` /
/// `decreasedValue`), and as the bare numeric `aria-valuenow` /
/// `aria-valuemin` / `aria-valuemax` (Flutter: `minValue` / `maxValue`).
const _kRatioToPercent = 100;

/// Unified resizable component for Web.
///
/// Displays multiple panes with draggable dividers.
///
/// Per Epic #1302 chrome / dimensional overrides flow through the
/// single [resizableStyle] slot. Behavioural fields (`panes`,
/// `direction`, `onResize`) stay flat on the widget.
class Resizable extends UiStatefulComponent
    implements CoreResizableContract<Component> {
  /// Creates a [Resizable].
  const Resizable({
    required this.panes,
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
    this.direction = CoreResizableDirection.horizontal,
    this.onResize,
    this.showDragHandle = CoreResizableContract.defaultShowDragHandle,
    this.optionalDivider = CoreResizableContract.defaultOptionalDivider,
    this.resizableStyle,
  });

  @override
  final List<CoreResizablePaneData<Component>> panes;

  @override
  final CoreResizableDirection direction;

  @override
  final void Function(List<double> sizes)? onResize;

  @override
  final bool showDragHandle;

  /// Whether the divider stays invisible until hovered, focused or dragged.
  ///
  /// The hit area is unchanged while hidden, so the seam is still grabbable.
  @override
  final bool optionalDivider;

  @override
  final CoreResizableStyle? resizableStyle;

  /// Returns a copy of this [Resizable] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Resizable copyWith({
    Key? key,
    UiMouseEventHandler? onClick,
    List<CoreResizablePaneData<Component>>? panes,
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
    CoreResizableDirection? direction,
    void Function(List<double> sizes)? onResize,
    bool? showDragHandle,
    bool? optionalDivider,
    CoreResizableStyle? resizableStyle,
  }) {
    return Resizable(
      key: key ?? this.key,
      onClick: onClick ?? this.onClick,
      panes: panes ?? this.panes,
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
      direction: direction ?? this.direction,
      onResize: onResize ?? this.onResize,
      showDragHandle: showDragHandle ?? this.showDragHandle,
      optionalDivider: optionalDivider ?? this.optionalDivider,
      resizableStyle: resizableStyle ?? this.resizableStyle,
    );
  }

  @override
  State<Resizable> createState() => _ResizableState();
}

class _ResizableState extends State<Resizable> {
  /// Pane sizes and the bounds they satisfy, resolved from
  /// [Resizable.panes] rather than copied out of it — the declared ratios
  /// are intent, and the invariants that make `aria-valuenow` land inside
  /// `[aria-valuemin, aria-valuemax]` only hold after
  /// [CoreResizableLayout.resolve] has fitted them. Shared with the Flutter
  /// twin so a fix here cannot land on one platform only.
  late CoreResizableLayout _layout;

  int? _dragDividerIndex;

  /// Index of the divider holding keyboard focus (`:focus-visible`), if any.
  /// The ring is `FocusOutline`'s job, so the widget needs the flag; the
  /// line's own look is untouched by it.
  int? _focusedDivider;
  double _dragStartPos = 0;
  Object? _containerElement;

  @override
  void initState() {
    super.initState();
    _layout = CoreResizableLayout.resolve(component.panes);
  }

  void _handleMouseDown(int dividerIndex, web.MouseEvent event) {
    event.preventDefault();
    // Through `setState`: the dragged divider picks a different chrome,
    // and a field written silently would leave the old one on screen.
    setState(() => _dragDividerIndex = dividerIndex);
    final isHorizontal = component.direction == .horizontal;
    // `mouseClientX/Y` re-read the coordinates as doubles — browsers
    // deliver sub-pixel mouse positions and the `int`-declared getters
    // throw a cast error on them.
    _dragStartPos =
        (isHorizontal
            ? dom_utils.mouseClientX(event)
            : dom_utils.mouseClientY(event)) ??
        0;

    // Find the flex container: the divider wrapper's parent element is
    // the flex root.
    _containerElement = dom_utils.eventTargetParent(event.currentTarget);

    dom_utils.registerDragListeners(
      onMove: (e) {
        if (e is web.MouseEvent) _handleMouseMove(e);
      },
      onUp: (e) => _handleMouseUp(),
      downEvent: event,
    );
  }

  void _handleMouseMove(web.MouseEvent event) {
    final dividerIndex = _dragDividerIndex;
    final container = _containerElement;
    if (dividerIndex == null || container == null) return;

    final isHorizontal = component.direction == .horizontal;
    final rect = dom_utils.elementRect(container);
    if (rect == null) return;
    final containerSize = isHorizontal ? rect.width : rect.height;
    if (containerSize <= 0) return;

    final currentPos = isHorizontal
        ? dom_utils.mouseClientX(event)
        : dom_utils.mouseClientY(event);
    if (currentPos == null) return;
    final deltaPx = currentPos - _dragStartPos;
    _dragStartPos = currentPos;

    // Unit: px / px = ratio (dimensionless). Same formula as Flutter.
    final deltaRatio = deltaPx / containerSize;
    _applyDeltaRatio(dividerIndex, deltaRatio);
  }

  void _handleMouseUp() {
    _containerElement = null;
    if (_dragDividerIndex == null) return;
    setState(() => _dragDividerIndex = null);
  }

  /// Applies a flex-ratio delta to the pane pair straddling [dividerIndex],
  /// clamped to that divider's reachable range. Shared by pointer drag
  /// ([_handleMouseMove], which first converts a pixel delta to this same
  /// dimensionless ratio) and keyboard resize ([_handleDividerKeyDown],
  /// which already deals in ratios). Mirrors the Flutter twin's
  /// `_applyDeltaRatio` 1:1 — both delegate the geometry to the same
  /// [CoreResizableLayout], so the bounds a drag enforces are the same
  /// object a screen reader reads out of `aria-valuemin`/`aria-valuemax`.
  void _applyDeltaRatio(int dividerIndex, double deltaRatio) {
    final moved = _layout.moveDivider(dividerIndex, deltaRatio);
    if (moved == null) return;

    setState(() => _layout = moved);
    component.onResize?.call(List.of(_layout.sizes));
  }

  // ─── keyboard input ───────────────────────────────────────────────────

  /// WCAG 2.1.1 keyboard path — ARIA APG "window splitter" keyboard
  /// interaction: for a `horizontal` split (vertical divider line,
  /// `aria-orientation="vertical"`) Left/Right move it; for a `vertical`
  /// split (horizontal line, `aria-orientation="horizontal"`) Up/Down
  /// move it. One `CoreResizableContract.defaultKeyboardStepFraction`
  /// per press, applied through the same [_applyDeltaRatio] pointer drag
  /// uses.
  void _handleDividerKeyDown(
    int dividerIndex,
    bool isHorizontal,
    web.KeyboardEvent event,
  ) {
    const step = CoreResizableContract.defaultKeyboardStepFraction;
    final delta = switch (event.key) {
      'ArrowRight' when isHorizontal => step,
      'ArrowLeft' when isHorizontal => -step,
      'ArrowDown' when !isHorizontal => step,
      'ArrowUp' when !isHorizontal => -step,
      _ => null,
    };
    if (delta == null) return;
    event.preventDefault();
    _applyDeltaRatio(dividerIndex, delta);
  }

  @override
  void didUpdateComponent(covariant Resizable oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (CoreResizableLayout.declaresSameGeometry(
      oldComponent.panes,
      component.panes,
    )) {
      return;
    }
    // A pane list that declares different ratios or bounds is a different
    // layout, and the sizes resolved against the old one no longer satisfy
    // it — leaving them is how `aria-valuenow` goes back to sitting outside
    // its own range after the first frame.
    _layout = CoreResizableLayout.resolve(component.panes);
    // The divider being dragged may no longer exist.
    if (_dragDividerIndex != null &&
        component.panes.length != oldComponent.panes.length) {
      _handleMouseUp();
    }
  }

  @override
  Component build(BuildContext context) {
    final isHorizontal = component.direction == .horizontal;
    final paneFlexes = [
      for (final size in _layout.sizes) (size * _kFlexPrecision).round(),
    ];

    final resolved = resolveResizable(
      context,
      direction: component.direction,
      paneFlexes: paneFlexes,
      showDragHandle: component.showDragHandle,
      optionalDivider: component.optionalDivider,
      resizableStyle: component.resizableStyle,
    );

    // Read once for the whole build rather than per divider — and
    // unconditionally, so a single-pane `Resizable` (which draws no
    // divider) still depends on the locale scope.
    final localizations = CouiLocalizations.of(context);

    final children = <Component>[];
    // Panes fill the container flush (no divider gutter) so the content
    // area stays maximal.
    for (int i = 0; i < component.panes.length; i++) {
      final paneChrome = resolved.panes[i];
      children.add(
        div(
          [component.panes[i].content],
          classes: paneChrome.className,
          styles: paneChrome.inlineStyles,
        ),
      );
    }

    // Divider overlays — absolutely positioned on each seam, floating above
    // the content. Each wrapper holds the thin hairline plus (when shown)
    // the centred pill grab handle; hover crossfades both via group-hover.
    final handlePill = resolved.handlePill;
    final handleIconStyle = resolved.handleIconStyle;
    for (int i = 0; i < resolved.dividerWrappers.length; i++) {
      final dividerIndex = i;
      final wrapperChrome = resolved.dividerWrappers[i];
      // Selecting between two resolved chromes rather than composing one:
      // a dragged divider has to stay lit after the pointer outruns it,
      // and that state has no CSS pseudo-class to ride.
      final lineChrome = _dragDividerIndex == dividerIndex
          ? resolved.dividerLineDragging
          : resolved.dividerLine;

      final wrapperChildren = <Component>[
        FocusOutline(
          focused: _focusedDivider == dividerIndex,
          focusOutlineStyle: resolved.focusOutlineStyle,
          // `FocusOutline` renders a plain `<div>` that shrink-wraps as a
          // flex item; the hairline inside spans the cross axis, so the
          // wrapper has to span it too.
          classes: isHorizontal ? WebLayout.hFull : WebLayout.wFull,
          child: div(
            const [],
            classes: lineChrome.className,
            styles: lineChrome.inlineStyles,
          ),
        ),
      ];
      if (handlePill != null) {
        final pillChildren = <Component>[];
        if (handleIconStyle != null) {
          final dots = Icon(
            LucideIcons.gripVertical,
            iconStyle: handleIconStyle,
          );
          final iconWrapper = resolved.handleIconWrapper;
          pillChildren.add(
            iconWrapper != null
                ? div(
                    [dots],
                    classes: iconWrapper.className,
                    styles: iconWrapper.inlineStyles,
                  )
                : dots,
          );
        }
        wrapperChildren.add(
          div(
            pillChildren,
            classes: handlePill.className,
            styles: handlePill.inlineStyles,
          ),
        );
      }

      final range = _layout.dividerRange(dividerIndex);
      // No clamp on any of the three: the position announced is the
      // position laid out, and the sizes reaching this point already sit
      // inside `range` because the layout resolves them there. Rounding is
      // monotonic, so `valuenow` stays inside `[valuemin, valuemax]` after
      // it too.
      final valueNow = (range.now * _kRatioToPercent).round();

      children.add(
        div(
          wrapperChildren,
          classes: wrapperChrome.className,
          styles: wrapperChrome.inlineStyles,
          attributes: {
            // ARIA APG "window splitter" pattern (WCAG 2.1.1) — a
            // `separator` becomes a focusable, arrow-key-adjustable
            // widget once it carries a value range, exactly as `role=
            // "slider"` does for `Slider`. `role="application"`
            // (`DragItem`'s pattern for #3456) does not apply here: that
            // role exists to suppress the browser's virtual cursor for a
            // subtree with an arbitrary multi-target drag session, and a
            // splitter is a single self-contained ARIA widget role
            // instead.
            'role': CoreSemanticRole.separator.ariaRole,
            // A splitter that reports only a number is announced as a
            // value with no subject, so the name below says what the
            // control is and the value text says what its number means.
            // Both are chrome this component draws, so both are read at
            // render time from the active locale instead of being baked
            // in English.
            'aria-label': localizations.resizableDividerLabel,
            'aria-orientation': isHorizontal ? 'vertical' : 'horizontal',
            'aria-valuenow': '$valueNow',
            'aria-valuemin': '${(range.min * _kRatioToPercent).round()}',
            'aria-valuemax': '${(range.max * _kRatioToPercent).round()}',
            'aria-valuetext': localizations.resizableDividerPositionLabel(
              valueNow,
            ),
            'tabindex': '0',
          },
          events: {
            // Trigger on pointerdown because the drag listeners are pointer
            // events — on touch devices the compatibility mousedown fires after
            // the gesture's pointerup and would leak them.
            'pointerdown': EventHandlers.createMouseEventHandler(
              (event) => _handleMouseDown(dividerIndex, event),
            ),
            'keydown': EventHandlers.createKeyboardEventHandler(
              (event) =>
                  _handleDividerKeyDown(dividerIndex, isHorizontal, event),
            ),
            // Helper-based, not a dynamic `event.target` read, so the
            // handler survives dart2js minification (`web-specifics.md`).
            'focus': EventHandlers.createElementTargetEventHandler(
              (_, target) => setState(
                () => _focusedDivider = target.matches(':focus-visible')
                    ? dividerIndex
                    : null,
              ),
            ),
            'blur': (_) => setState(() => _focusedDivider = null),
          },
        ),
      );
    }

    return Component.element(
      tag: 'div',
      id: component.id,
      classes: component.rootClasses(resolved.root.className),
      styles: component.css != null
          ? Styles.combine([?resolved.root.inlineStyles, component.css!])
          : resolved.root.inlineStyles,
      attributes: component.componentAttributes,
      events: component.events,
      children: children,
    );
  }
}

/// Chain sugar mirroring the Flutter `Resizable.withStyle` extension —
/// merges a [CoreResizableStyle] patch into [Resizable.resizableStyle]
/// via the existing [Resizable.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreResizableStyle.merge` right-side-wins semantics).
extension ResizableStyleChain on Resizable {
  /// Returns a copy of this [Resizable] with [patch] merged into
  /// [resizableStyle] (patch fields win on conflict).
  Resizable withStyle(CoreResizableStyle patch) => copyWith(
    resizableStyle: (resizableStyle ?? const CoreResizableStyle()).merge(
      patch,
    ),
  );
}
