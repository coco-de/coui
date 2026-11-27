import 'dart:async';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/components/form/form/form_controller.dart';
import 'package:coui_web/src/components/form/toggle/toggle_style.dart';
import 'package:coui_web/src/components/form/toggle/toggle_lens_dom.dart';
import 'package:coui_web/src/components/infra/clickable/clickable.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:coui_web/src/overlay/coui_web_dom.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' hide Text;

/// Unified cross-platform toggle (switch) for CoUI Web with token-based
/// rendering.
///
/// Semantic enums (`variant`, `size`) stay as widget parameters because
/// they identify the toggle instance. All chrome / dimensional /
/// nested-slot overrides flow through the single [toggleStyle] (a
/// [CoreToggleStyle]).
///
/// Uses custom `<span>` rendering (not native `<input>`) to achieve
/// visual parity with Flutter Toggle. Both platforms share the same
/// design tokens from [CoreToggleVariantStyle] and
/// [CoreToggleStyle.defaultsBySize].
///
/// When placed inside a [Form] with a [FormController] (via a `FormField`),
/// the toggle reports its [value] through [FormValueSupplier] so the form
/// tracks and validates it — matching Flutter `Toggle`.
///
/// Example:
/// ```dart
/// Toggle(
///   value: true,
///   label: 'Dark mode',
///   onChanged: (v) => print('Toggled: $v'),
/// )
/// ```
///
/// surface:content — a control box that sits in the flow, not something
/// mounted over content.
///
/// surface:functional — the transient lens, mounted over the track and the
/// thumb only while the thumb travels after the user flips the switch; for
/// its whole life both pass behind it.
class Toggle extends UiStatefulComponent
    implements
        CoreToggleContract<
          Component,
          CoreFocusNode,
          CoreStatesController,
          Object
        > {
  /// Creates a [Toggle].
  const Toggle({
    super.key,
    this.value = false,
    this.onChanged,
    this.enabled,
    this.prefix,
    this.suffix,
    this.label,
    this.labelMaxLines,
    this.labelOverflow,
    this.variant = CoreToggleVariant.defaultVariant,
    this.size = CoreComponentSize.md,
    this.toggleStyle,
    this.name,
    super.id,
  });

  // === State ===

  @override
  final bool value;

  @override
  final CoreValueChanged<bool>? onChanged;

  /// Whether the toggle is enabled. `null` (the default) falls back to
  /// `onChanged != null` so a toggle with no callback reads as disabled —
  /// matching the Flutter `Toggle._enabled` getter (Flutter is the
  /// cross-platform reference). Pass `true`/`false` to force it.
  @override
  final bool? enabled;

  /// Effective interactive state — explicit [enabled] wins, else the
  /// presence of an [onChanged] callback decides (Flutter parity).
  bool get _effectiveEnabled => enabled ?? (onChanged != null);

  // === Content ===

  @override
  final Component? prefix;

  @override
  final Component? suffix;

  @override
  final String? label;

  @override
  final int? labelMaxLines;

  @override
  final CoreTextOverflow? labelOverflow;

  // === Semantic identity (widget params, not chrome) ===

  @override
  final CoreToggleVariant variant;

  @override
  final CoreComponentSize size;

  // === Style (chrome / dimensional / nested slot) ===

  @override
  final CoreToggleStyle? toggleStyle;

  // === Form ===

  @override
  final String? name;

  // === Contract defaults (Web-limited fields) ===

  @override
  CoreFocusNode? get focusNode => null;

  @override
  CoreStatesController? get statesController => null;

  @override
  Object? get controller => null;

  // === Public overrides ===

  /// Returns a copy of this toggle with the given fields replaced.
  Toggle copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    bool? value,
    CoreValueChanged<bool>? onChanged,
    bool? enabled,
    String? label,
    int? labelMaxLines,
    CoreTextOverflow? labelOverflow,
    CoreToggleVariant? variant,
    CoreComponentSize? size,
    Component? prefix,
    Component? suffix,
    CoreToggleStyle? toggleStyle,
    String? name,
  }) {
    return Toggle(
      key: key ?? this.key,
      onChanged: onChanged ?? this.onChanged,
      value: value ?? this.value,
      enabled: enabled ?? this.enabled,
      prefix: prefix ?? this.prefix,
      suffix: suffix ?? this.suffix,
      label: label ?? this.label,
      labelMaxLines: labelMaxLines ?? this.labelMaxLines,
      labelOverflow: labelOverflow ?? this.labelOverflow,
      variant: variant ?? this.variant,
      size: size ?? this.size,
      toggleStyle: toggleStyle ?? this.toggleStyle,
      name: name ?? this.name,
      id: id ?? this.id,
    );
  }

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);
    attributes.add('role', 'switch');
    attributes.add('aria-checked', value.toString());
    if (!_effectiveEnabled) {
      attributes.add('aria-disabled', 'true');
    }
    attributes.add('tabindex', _effectiveEnabled ? '0' : '-1');
  }

  @override
  State<Toggle> createState() => _ToggleState();
}

int _toggleDomId = 0;

class _ToggleState extends State<Toggle> with FormValueSupplier<bool, Toggle> {
  /// Counts value changes, so each travel mounts a fresh lens element and
  /// its animations start from the first frame again.
  int _lensRun = 0;

  /// Whether the transient lens is in the DOM — only for one thumb travel.
  bool _lensMounted = false;

  Timer? _lensTimer;
  late final String _thumbId = 'co-toggle-thumb-${_toggleDomId++}';
  String get _lensId => '$_thumbId-lens-$_lensRun';
  ToggleLensRuntime? _lensRuntime;

  /// Set when the user flips the switch — pointer or keyboard, both reach
  /// [_handleActivate] through the composing `Clickable` — and cleared once
  /// the frame that flip schedules has run.
  ///
  /// Only a value change that lands while it is set rides the lens: the
  /// update the user's own flip brings. A value the app sets in code — a
  /// form reset, a "turn all on" — arrives with it clear and moves the thumb
  /// with no lens. The Flutter twin arms and clears on the same clock.
  bool _lensArmed = false;

  @override
  void initState() {
    super.initState();
    formValue = component.value;
  }

  @override
  void didUpdateComponent(covariant Toggle oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (!component._effectiveEnabled) {
      _lensTimer?.cancel();
      _lensRuntime?.dispose();
      _lensMounted = false;
    }
    if (component.value != oldComponent.value) {
      formValue = component.value;
      if (_lensArmed) _startLens();
    }
  }

  /// The user's flip — every input path the composing `Clickable` takes
  /// (click, Space, Enter) ends here.
  void _handleActivate() {
    final onChanged = component.onChanged;
    if (onChanged == null) return;
    _armLens();
    onChanged(!component.value);
  }

  /// Marks the next value change as the user's own.
  ///
  /// Through `setState`, so a frame is scheduled even when the host ignores
  /// the flip — the post-frame clear then always runs, and the mark cannot
  /// outlive the gesture into a later change the app makes in code. A host
  /// that answers the flip synchronously rebuilds in that same frame, before
  /// the clear.
  void _armLens() {
    setState(() => _lensArmed = true);
    context.binding.addPostFrameCallback(() => _lensArmed = false);
  }

  @override
  void dispose() {
    _lensTimer?.cancel();
    _lensRuntime?.dispose();
    super.dispose();
  }

  /// Mounts the lens for one thumb travel. A disabled toggle does not read
  /// as a material surface, so it gets no lens — the Flutter twin's gate.
  ///
  /// Reduced motion suppresses it outright: the lens rides the thumb's
  /// travel, which is transition-tier motion. The duration variable the
  /// lens animates on already collapses to zero there (and its base
  /// opacity is zero, so a zero-length run shows nothing), but the
  /// preference is read here too, so the element is never mounted at all —
  /// the Flutter twin, whose travel settles to zero before this point, does
  /// the same.
  void _startLens() {
    if (!component._effectiveEnabled) return;
    if (kIsWeb && prefersReducedMotion) return;
    final timing = resolveToggleTiming(
      context,
      variant: component.variant,
      toggleStyle: component.toggleStyle,
    );
    _lensTimer?.cancel();
    _lensRun += 1;
    _lensMounted = true;
    _lensRuntime?.dispose();
    if (kIsWeb) {
      _lensRuntime = ToggleLensRuntime(thumbId: _thumbId, lensId: _lensId)
        ..follow();
    }
    _lensTimer = Timer(timing.lensLifetime, _handleLensTravelled);
  }

  void _handleLensTravelled() {
    if (!mounted) return;
    _lensRuntime?.dispose();
    _lensRuntime = null;
    setState(() => _lensMounted = false);
  }

  // A form replacing the value (a reset, a restore) is the app speaking, not
  // the user — it reports through `onChanged` but does not arm the lens.
  @override
  void didReplaceFormValue(bool value) {
    component.onChanged?.call(value);
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveToggle(
      context,
      variant: component.variant,
      size: component.size,
      value: component.value,
      enabled: component._effectiveEnabled,
      toggleStyle: component.toggleStyle,
    );
    // The state layer and the track's focus ring are a blend / a
    // descendant outline, so — like Chip — they ride scoped rules
    // rather than a preset utility class. Re-walks the same merge chain
    // `resolveToggle` just did; empty on `!enabled`.
    final rules = resolveToggleRules(
      context,
      variant: component.variant,
      value: component.value,
      enabled: component._effectiveEnabled,
      toggleStyle: component.toggleStyle,
    );

    final value = component.value;

    // Visual-only track — activation / keyboard / focus live on the
    // composing Clickable root, which carries role="switch" and takes its
    // accessible name from the label content.
    //
    // A `<span>`, because that is what this is. As a `<button>` it had to
    // be told not to be one four times over — `type` to disarm submit,
    // `tabindex=-1` to leave the tab order, `aria-hidden` to leave the
    // a11y tree, and (once the pointer-target hit area stopped covering it)
    // `pointer-events:none`, because a button that accepts the pointer
    // takes click focus and would seat the focused node inside
    // `aria-hidden="true"`, while Tailwind's preflight `button{cursor:
    // pointer}` — which has no `:disabled` carve-out — would beat the
    // root's `cursor-not-allowed`. An element that needs four suppressions
    // to stop behaving like a button is not one. A span needs none: it is
    // not focusable, carries no preflight cursor, and the click bubbles to
    // the root exactly as the label's own span already does.
    //
    // `disabled` went with it. It was never read — the disabled track
    // colour is chosen in Dart (`variantScale.disabled*Track`), not by any
    // `:disabled` selector.
    final trackButton = Component.element(
      tag: 'span',
      classes: resolved.track.className,
      styles: resolved.track.inlineStyles,
      attributes: {
        'aria-hidden': 'true',
        'data-state': value ? 'checked' : 'unchecked',
      },
      children: [
        span(
          const [],
          id: _thumbId,
          classes: resolved.thumb.className,
          styles: resolved.thumb.inlineStyles,
          attributes: {
            'data-state': value ? 'checked' : 'unchecked',
          },
        ),
      ],
    );

    // The lens — only while the thumb travels. It joins the row right after
    // the track; its margins (resolver) cancel its own footprint, so the
    // row lays out exactly as at rest and nothing wraps the track for it.
    // Its keyframes ride inside it, so they mount and leave together and
    // the resting markup carries neither.
    final lens = _lensMounted && rules.lensCss.isNotEmpty
        ? Component.element(
            key: ValueKey(_lensRun),
            tag: 'span',
            id: _lensId,
            classes: resolved.lens.className,
            styles: resolved.lens.inlineStyles,
            attributes: const {'aria-hidden': 'true'},
            children: [
              Component.element(
                tag: 'style',
                children: [RawText(rules.lensCss)],
              ),
            ],
          )
        : null;

    // Hidden input for form submission.
    final name = component.name;
    final hiddenInput = name != null
        ? Component.element(
            tag: 'input',
            attributes: {
              'type': 'checkbox',
              'name': name,
              if (value) 'checked': '',
              'class': 'sr-only',
              'tabindex': '-1',
              'aria-hidden': 'true',
            },
          )
        : null;

    final currentLabel = component.label;
    final currentOnChanged = component.onChanged;

    // Flutter twin: `Clickable(child: Row(prefix, track, label))` —
    // Clickable owns tap / keyboard activation / cursor / press /
    // disabled opacity; the content wrapper below is pure content (a
    // `<span>`, not a `<label>` — see the Checkbox twin for the label
    // double-click rationale).
    //
    // `kWebTouchTargetMarker` on the root — pointer target expansion
    // (WCAG 2.5.8), mirrors Flutter's `TouchTarget` wrap. The two
    // smallest track heights (16, 20) draw under the 24px floor; the
    // marker only widens where a pointer is accepted around the root.
    //
    // `rules.scopeClass` on the root too — `:hover` / `:active` /
    // `:focus-visible` land on the actually focusable/pressable element,
    // which IS this Clickable root; the scoped rules reach the track one
    // level in.
    final userClasses = component.classes;
    final rootClasses = [
      kWebTouchTargetMarker,
      if (rules.scopeClass.isNotEmpty) rules.scopeClass,
      if (userClasses != null && userClasses.isNotEmpty) userClasses,
    ].join(' ');
    return Clickable(
      onPressed: component._effectiveEnabled && currentOnChanged != null
          ? _handleActivate
          : null,
      onClick: component.onClick,
      attributes: component.componentAttributes,
      classes: rootClasses,
      css: component.css,
      eventHandlers: component.eventHandlers,
      id: component.id,
      onChange: component.onChange,
      onInput: component.onInput,
      onKeyDown: component.onKeyDown,
      onKeyUp: component.onKeyUp,
      onMouseEnter: component.onMouseEnter,
      onMouseLeave: component.onMouseLeave,
      // Effective enabled drives the whole interaction surface —
      // not-allowed cursor, no focus, no activation. The generic
      // disabled fade stays off via the nested clickableStyle slot
      // (the toggle paints its own disabled tokens).
      enabled: component._effectiveEnabled,
      enableFeedback: component._effectiveEnabled,
      // The ring is the track's (scoped `:focus-visible` rule above),
      // not the row's — mirrors the Flutter twin's `focusOutline: false`.
      focusOutline: false,
      clickableStyle: resolved.clickableStyle,
      child: Component.element(
        tag: 'span',
        classes: resolved.root.className,
        styles: resolved.root.inlineStyles,
        children: [
          // `<style>` is `display: none` — never joins the flex row.
          if (rules.css.isNotEmpty)
            Component.element(
              tag: 'style',
              children: [RawText(rules.css)],
            ),
          ?hiddenInput,
          ?component.prefix,
          trackButton,
          ?lens,
          ?component.suffix,
          if (currentLabel != null)
            Component.element(
              tag: 'span',
              classes: resolved.labelWrapper.className,
              children: [
                Text(
                  currentLabel,
                  maxLines: component.labelMaxLines,
                  overflow: component.labelOverflow,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Chain sugar mirroring the Flutter `Toggle.withStyle` extension —
/// merges a [CoreToggleStyle] patch into [Toggle.toggleStyle] via the
/// existing [Toggle.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreToggleStyle.merge` right-side-wins semantics).
extension ToggleStyleChain on Toggle {
  /// Sets the content padding.
  Toggle contentPadding(CoreEdgeInsets value) =>
      withStyle(CoreToggleStyle(padding: value));

  /// Returns a copy of this [Toggle] with [patch] merged into
  /// [toggleStyle] (patch fields win on conflict).
  Toggle withStyle(CoreToggleStyle patch) => copyWith(
    toggleStyle: (toggleStyle ?? const CoreToggleStyle()).merge(patch),
  );
}
