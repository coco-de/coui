import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/base/web_dom_utils.dart';
import 'package:coui_web/src/components/display/badge/badge.dart';
import 'package:coui_web/src/components/display/diff/diff_style.dart';
import 'package:coui_web/src/components/icon/icon.dart';
import 'package:coui_web/src/components/infra/focus_outline/focus_outline.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

/// How far a touch may travel and still count as a tap (CSS px). Past it
/// the finger is scrolling or swiping, not choosing a place.
const double _kTapSlop = 10;

/// Before/after split-view comparison viewer (daisyUI `Diff` pattern).
///
/// Flutter `Diff` 와 동일한 API/렌더링. The split is a thin raised line
/// with a round handle on it. The handle is what to grab: a
/// [CoreDiffStyle.handleHitSize]-wide strip around it takes the pointer, a
/// click or tap anywhere else on the frame moves the split there, and on
/// touch only that strip drags — a finger on the rest of the frame keeps
/// scrolling the page. [beforeLabel] / [afterLabel] name the two sides with
/// a chip in the top corners.
///
/// Chrome and layout overrides flow through the single [diffStyle] slot;
/// every default is a `CoreDiffStyle.defaultX`. All DOM slots' chrome come
/// out of one `resolveDiff` call as a `ResolvedDiff`.
class Diff extends UiStatefulComponent implements CoreDiffContract<Component> {
  /// Creates a [Diff].
  const Diff({
    required this.before,
    required this.after,
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
    this.beforeLabel,
    this.afterLabel,
    this.onPositionChanged,
    this.interactive = true,
    this.ariaLabel,
    this.diffStyle,
  });

  @override
  final Component before;

  @override
  final Component after;

  @override
  final Component? beforeLabel;

  @override
  final Component? afterLabel;

  @override
  final void Function(double position)? onPositionChanged;

  @override
  final bool interactive;

  @override
  final String? ariaLabel;

  @override
  final CoreDiffStyle? diffStyle;

  /// Returns a copy of this [Diff] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Diff copyWith({
    Key? key,
    UiMouseEventHandler? onClick,
    Component? before,
    Component? after,
    Component? beforeLabel,
    Component? afterLabel,
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
    void Function(double position)? onPositionChanged,
    bool? interactive,
    String? ariaLabel,
    CoreDiffStyle? diffStyle,
  }) {
    return Diff(
      key: key ?? this.key,
      onClick: onClick ?? this.onClick,
      before: before ?? this.before,
      after: after ?? this.after,
      beforeLabel: beforeLabel ?? this.beforeLabel,
      afterLabel: afterLabel ?? this.afterLabel,
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
      onPositionChanged: onPositionChanged ?? this.onPositionChanged,
      interactive: interactive ?? this.interactive,
      ariaLabel: ariaLabel ?? this.ariaLabel,
      diffStyle: diffStyle ?? this.diffStyle,
    );
  }

  @override
  State<Diff> createState() => _DiffState();
}

/// Chain sugar mirroring the Flutter `Diff.withStyle` extension —
/// merges a [CoreDiffStyle] patch into [Diff.diffStyle] via the
/// existing [Diff.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreDiffStyle.merge` right-side-wins semantics).
///
/// The getters below are shorter sugar for the same [withStyle] call.
/// Each one is a direct 1:1 alias for a `CoreRadius` / `CoreColors`
/// primitive — the getter *name* is the token name, so `.radius4`
/// always means `CoreRadius.radius4` and `.primary` always means
/// `CoreColors.primary`, no matter which component it's called on.
/// That fixed name-to-value mapping is what makes a short getter safe
/// to reuse across components — a curated nickname (`.rounded`,
/// `.compact`) would silently map to a different value per component,
/// but a primitive-token getter cannot.
///
/// These are intentionally primitive (not semantic) for now: `.radius4`
/// sets [CoreDiffStyle.borderRadius]. A semantic layer that names these
/// after component-specific intent (decided together with design) is
/// a follow-up once more components adopt this pattern.
///
/// ```dart
/// Diff(before: ..., after: ...).radius4
/// ```
extension DiffStyleChain on Diff {
  /// Sets the border color.
  Diff borderColor(CoreColor value) =>
      withStyle(CoreDiffStyle(borderColor: value));

  /// Sets the border width in logical pixels.
  Diff borderWidth(double value) =>
      withStyle(CoreDiffStyle(borderWidth: value));

  /// Returns a copy of this [Diff] with [patch] merged into
  /// [diffStyle] (patch fields win on conflict).
  Diff withStyle(CoreDiffStyle patch) =>
      copyWith(diffStyle: (diffStyle ?? const CoreDiffStyle()).merge(patch));

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  Diff get radius0 => withStyle(
    const CoreDiffStyle(borderRadius: CoreBorderRadius.zero),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  Diff get radius2 => withStyle(
    const CoreDiffStyle(borderRadius: CoreBorderRadius.all(CoreRadius.radius2)),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  Diff get radius4 => withStyle(
    const CoreDiffStyle(borderRadius: CoreBorderRadius.all(CoreRadius.radius4)),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  Diff get radius6 => withStyle(
    const CoreDiffStyle(borderRadius: CoreBorderRadius.all(CoreRadius.radius6)),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  Diff get radius8 => withStyle(
    const CoreDiffStyle(borderRadius: CoreBorderRadius.all(CoreRadius.radius8)),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  Diff get radius10 => withStyle(
    const CoreDiffStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  Diff get radius12 => withStyle(
    const CoreDiffStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  Diff get radius14 => withStyle(
    const CoreDiffStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  Diff get radius16 => withStyle(
    const CoreDiffStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  Diff get radius20 => withStyle(
    const CoreDiffStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  Diff get radius24 => withStyle(
    const CoreDiffStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  Diff get radius28 => withStyle(
    const CoreDiffStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  Diff get radius32 => withStyle(
    const CoreDiffStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  Diff get radius36 => withStyle(
    const CoreDiffStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  Diff get radius40 => withStyle(
    const CoreDiffStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  Diff get radius48 => withStyle(
    const CoreDiffStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  Diff get radius56 => withStyle(
    const CoreDiffStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  Diff get radius64 => withStyle(
    const CoreDiffStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  Diff get radius9999 => withStyle(
    const CoreDiffStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );
}

class _DiffState extends State<Diff> {
  double? _position;

  /// A pointer is holding the split — the root carries
  /// [kDiffDraggingAttribute] and the handle is pressed.
  bool _dragging = false;

  /// Whether the handle's [FocusOutline] shows — only for keyboard focus,
  /// the same gate the Flutter twin applies to `FocusableActionDetector`'s
  /// highlight. The browser's `:focus-visible` is read on every `focus`
  /// event but does not decide alone: a press that this component answers
  /// by focusing the root itself is a script focus, which Chrome can match
  /// — on a page that has had no focus yet, and after keyboard use.
  bool _focused = false;

  /// Remembers that the focus about to arrive is the one a mouse press asked
  /// for, so it never shows the ring (see [_focused]).
  final _focusModality = CoreInputFocusModality();

  /// How far the pointer was from the handle's centre when it took hold
  /// (CSS px). Grabbing the disc off-centre keeps the split where it is
  /// instead of snapping the line under the pointer.
  double _grabOffset = 0;

  void Function()? _detachDrag;

  @override
  void didUpdateComponent(Diff oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (!component.interactive) {
      _detachDrag?.call();
      _detachDrag = null;
      _dragging = false;
      _focused = false;
    }
  }

  @override
  void dispose() {
    _detachDrag?.call();
    super.dispose();
  }

  void _setPosition(double next) {
    final clamped = next.clamp(0.0, 1.0);
    if (clamped == _position) return;
    setState(() => _position = clamped);
    component.onPositionChanged?.call(clamped);
  }

  /// Promotes a pointer-focused comparison back to a visible focus, which
  /// is when the ring becomes meaningful. Called only from the keys this
  /// component handles, matching the Flutter twin's promote points.
  void _promotePointerFocus() {
    if (!_focused) setState(() => _focused = true);
  }

  /// Maps a pointer x (client px) to a split position inside [root].
  void _moveTo(Object? root, double clientX) {
    final rect = elementRect(root);
    if (rect == null || rect.width <= 0) return;
    _setPosition((clientX - rect.left - _grabOffset) / rect.width);
  }

  /// Closes a pointer gesture.
  void _endDrag() {
    if (!_dragging) return;
    _detachDrag?.call();
    _detachDrag = null;
    setState(() {
      _dragging = false;
      _grabOffset = 0;
    });
  }

  /// A pointer lands on the comparison. A mouse takes hold wherever it
  /// lands; a finger or stylus takes hold only on the handle's strip, and
  /// anywhere else it is a tap if it lifts without travelling.
  void _handlePointerDown(Object event) {
    if (!component.interactive || _dragging || !isPrimaryPointerPress(event)) {
      return;
    }
    final root = eventCurrentTarget(event);
    final clientX = mouseClientX(event);
    final clientY = mouseClientY(event);
    final rect = elementRect(root);
    if (clientX == null || clientY == null || rect == null) return;
    if (rect.width <= 0) return;

    final strip = descendantRect(root, '.$kDiffHandleStripMarker');
    final inStrip =
        strip != null &&
        clientX >= strip.left &&
        clientX <= strip.left + strip.width;
    final centre = strip == null ? 0.0 : strip.left + strip.width / 2;
    final isMouse = (pointerTypeOf(event) ?? 'mouse') == 'mouse';

    // Grabbing the comparison hides the ring even when it was already
    // showing. `:focus-visible` is only read on the `focus` event, which
    // does not re-fire for a press on an element that already holds focus.
    if (_focused) setState(() => _focused = false);

    if (isMouse || inStrip) {
      if (isMouse) {
        // Suppresses the browser's native image drag and text selection,
        // which would end the gesture before it starts. It also skips the
        // focus a press would give, so the root takes it here — and says
        // the press caused it, because the browser may not: it can read a
        // script focus as keyboard focus. A finger or stylus is not
        // intercepted, so the browser gives its own press focus.
        preventDefault(event);
        _focusModality.pointerDown();
        focusElement(root);
      }
      setState(() {
        _dragging = true;
        _grabOffset = inStrip ? clientX - centre : 0;
      });
      if (!inStrip) _moveTo(root, clientX);
      // A finger that lands on the strip and lifts without travelling is a
      // tap, and a tap moves the split to where it landed — the Flutter twin
      // gets that from its frame-wide tap recognizer, which a drag only
      // outranks once the finger moves.
      var moved = false;
      _detachDrag = registerDragListeners(
        onMove: (e) {
          final x = mouseClientX(e);
          final y = mouseClientY(e);
          if (x == null || y == null) return;
          if ((x - clientX).abs() > _kTapSlop ||
              (y - clientY).abs() > _kTapSlop) {
            moved = true;
          }
          _moveTo(root, x);
        },
        onUp: (_) {
          final tap = !isMouse && !moved;
          _endDrag();
          if (tap) _moveTo(root, clientX);
        },
        // A gesture the browser aborts (touch turned scroll, the OS took
        // the pointer) still has to release the handle.
        onCancel: (_) => _endDrag(),
        downEvent: event,
      );
      return;
    }

    // A finger off the strip: a tap if it lifts near where it landed. A
    // browser that starts scrolling sends `pointercancel` instead of
    // `pointerup`, which is how a swipe is told from a tap.
    var tapping = true;
    _detachDrag = registerDragListeners(
      onMove: (e) {
        final x = mouseClientX(e);
        final y = mouseClientY(e);
        if (x == null || y == null) return;
        if ((x - clientX).abs() > _kTapSlop ||
            (y - clientY).abs() > _kTapSlop) {
          tapping = false;
        }
      },
      onUp: (e) {
        _detachDrag = null;
        final x = mouseClientX(e);
        if (tapping && x != null) {
          _grabOffset = 0;
          _moveTo(root, x);
        }
      },
      onCancel: (_) => _detachDrag = null,
      downEvent: event,
    );
  }

  /// ARIA APG "Slider" keyboard interaction — Left / Right move one
  /// [keyboardStep], Page Down / Page Up one [keyboardPageStep], Home / End
  /// jump to the ends.
  void _handleKeyDown(
    web.KeyboardEvent event, {
    required double currentPosition,
    required double keyboardStep,
    required double keyboardPageStep,
  }) {
    final next = switch (event.key) {
      'ArrowLeft' => currentPosition - keyboardStep,
      'ArrowRight' => currentPosition + keyboardStep,
      'PageDown' => currentPosition - keyboardPageStep,
      'PageUp' => currentPosition + keyboardPageStep,
      'Home' => 0.0,
      'End' => 1.0,
      _ => null,
    };
    if (next == null) return;
    preventDefault(event);
    _promotePointerFocus();
    _setPosition(next);
  }

  @override
  Component build(BuildContext context) {
    // Behavioural runtime-tuning seeds (initial split position + keyboard
    // steps) are read off the same merge chain via the separate entry
    // point — kept off `ResolvedDiff` (pure chrome). The chrome resolver
    // falls back to the identical `initialPosition` seed when
    // `currentPosition` is null (first build), so the `--co-diff-pos`
    // variable and the widget `_position` seed stay in sync.
    final tuning = resolveDiffTuning(
      context,
      diffStyle: component.diffStyle,
    );
    final resolved = resolveDiff(
      context,
      currentPosition: _position,
      diffStyle: component.diffStyle,
    );
    final currentPosition = _position ?? tuning.initialPosition;
    final interactive = component.interactive;

    return div(
      [
        div(
          [
            div(
              [component.after],
              classes: resolved.afterLayer.className,
              styles: resolved.afterLayer.inlineStyles,
            ),
            div(
              [component.before],
              classes: resolved.beforeLayer.className,
              styles: resolved.beforeLayer.inlineStyles,
            ),
            div(
              const [],
              classes: resolved.resizer.className,
              styles: resolved.resizer.inlineStyles,
            ),
            if (component.beforeLabel != null)
              div(
                [
                  Badge(
                    size: .sm,
                    badgeStyle: resolved.labelBadgeStyle,
                    child: component.beforeLabel,
                  ),
                ],
                classes: resolved.beforeLabelHost.className,
                styles: resolved.beforeLabelHost.inlineStyles,
              ),
            if (component.afterLabel != null)
              div(
                [
                  Badge(
                    size: .sm,
                    badgeStyle: resolved.labelBadgeStyle,
                    child: component.afterLabel,
                  ),
                ],
                classes: resolved.afterLabelHost.className,
                styles: resolved.afterLabelHost.inlineStyles,
              ),
            if (resolved.edge case final edge?)
              div(
                const [],
                classes: edge.className,
                styles: edge.inlineStyles,
              ),
          ],
          classes: resolved.clip.className,
          styles: resolved.clip.inlineStyles,
        ),
        if (interactive)
          div(
            [
              FocusOutline(
                focused: _focused,
                focusOutlineStyle: resolved.focusOutlineStyle,
                classes: resolved.handleHost.className,
                css: resolved.handleHost.inlineStyles,
                child: div(
                  [
                    // Decorative — the slider role on the root carries the
                    // meaning, so the glyph is hidden from assistive tech.
                    Icon(
                      LucideIcons.chevronsLeftRight,
                      iconStyle: resolved.handleIconStyle,
                      attributes: const {'aria-hidden': 'true'},
                    ),
                  ],
                  classes: resolved.handleDisc.className,
                  styles: resolved.handleDisc.inlineStyles,
                ),
              ),
            ],
            classes: resolved.handleStrip.className,
            styles: resolved.handleStrip.inlineStyles,
          ),
      ],
      id: component.id,
      classes: component.rootClasses(resolved.root.className),
      styles: component.css != null
          ? Styles.combine([?resolved.root.inlineStyles, component.css!])
          : resolved.root.inlineStyles,
      attributes: {
        ...component.componentAttributes,
        // An interactive comparison is a value on a range, not a group:
        // the arrow keys move the split and nothing announced that it had
        // moved, or where it was. A reader heard "group" and then
        // silence, so the control existed only for people who could see
        // it. Non-interactive stays a group — there is no value to
        // report when the split cannot move.
        //
        // `role="slider"` requires the value triple; a slider without it
        // is announced as an empty one, which is worse than a group.
        'role': interactive ? CoreSemanticRole.slider.ariaRole : 'group',
        if (interactive) ...{
          'aria-valuemin': '0',
          'aria-valuemax': '100',
          'aria-valuenow': (currentPosition * kPercentScale).round().toString(),
          'aria-valuetext': CouiLocalizations.of(
            context,
          ).diffPositionLabel((currentPosition * kPercentScale).round()),
        },
        'aria-label': ?component.ariaLabel,
        if (interactive) 'tabindex': '0',
        if (_dragging) kDiffDraggingAttribute: '',
      },
      events: !interactive
          ? component.events
          : {
              ...component.events,
              'pointerdown': _handlePointerDown,
              // The ring is Dart-driven here because `FocusOutline` takes
              // a boolean, so the `:focus-visible` match the browser
              // already computed is read off the target — unless a mouse
              // press asked for this focus — and forwarded.
              // Typed handler: dart2js release minifies dynamic
              // `event.target` dispatches into mangled names.
              'focus': EventHandlers.createElementTargetEventHandler(
                (_, target) => setState(
                  () => _focused = _focusModality.focus(
                    platformShowsRing: target.matches(':focus-visible'),
                  ),
                ),
              ),
              // A press on a root that already held focus raises no `focus`
              // event, so leaving is where that press is forgotten.
              'blur': (_) {
                _focusModality.blur();
                setState(() => _focused = false);
              },
              'keydown': EventHandlers.createKeyboardEventHandler(
                (event) => _handleKeyDown(
                  event,
                  currentPosition: currentPosition,
                  keyboardStep: tuning.keyboardStep,
                  keyboardPageStep: tuning.keyboardPageStep,
                ),
              ),
            },
    );
  }
}
