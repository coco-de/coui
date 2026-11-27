import 'dart:async';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/components/control/button/button.dart';
import 'package:coui_web/src/components/control/toggle_group/toggle_group.dart';
import 'package:coui_web/src/components/form/color_picker/color_picker_dom.dart';
import 'package:coui_web/src/components/form/color_picker/color_picker_style.dart';
import 'package:coui_web/src/components/form/form/form_controller.dart';
import 'package:coui_web/src/components/form/text_field/text_field.dart';
import 'package:coui_web/src/components/icon/icon.dart';
import 'package:coui_web/src/components/infra/clickable/clickable.dart';
import 'package:coui_web/src/components/infra/popup/popup.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:coui_web/src/components/overlay/popover/popover.dart';
import 'package:coui_web/src/components/overlay/popover/popover_controller.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:coui_web/src/components/text/text_extension.dart';
import 'package:coui_web/src/overlay/recent_colors_scope.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart' hide Text;

/// Length of a `#RRGGBB` hex string (hash + 6 digits) — the hex
/// input field caps typing at this many characters.
const int _kHexInputMaxLength = 7;

/// Fallback hex used when the current input cannot be parsed as a
/// valid `#RRGGBB` color (e.g. partially-typed buffer). Behaviour
/// value — kept flat on the component per Epic #1302 원칙 6/7.
const String _kFallbackHex = '#000000';

/// Picker mode tab display order (matches Flutter `ColorPicker`).
const List<CoreColorPickerMode> _kPickerModeOrder = [
  CoreColorPickerMode.rgb,
  CoreColorPickerMode.hsl,
  CoreColorPickerMode.hsv,
];

/// Localized tab label for [mode], sourced from [CouiLocalizations] so
/// Flutter and Web read the same single-source strings.
String _pickerModeLabel(CouiLocalizations l10n, CoreColorPickerMode mode) {
  return switch (mode) {
    .rgb => l10n.colorPickerTabRGB,
    .hsl => l10n.colorPickerTabHSL,
    .hsv => l10n.colorPickerTabHSV,
  };
}

/// Process-level counter for popover scope ids.
int _coColorPickerIdCounter = 0;

/// Unified before/after color picker — opens an anchored popover with
/// HSV picker, hue slider, optional alpha slider, mode tabs, and an
/// eye-dropper / Cancel / Save row.
///
/// Mirrors Flutter `ColorPicker` 1:1 — same hex string contract,
/// same popover structure, same interaction model.
///
/// Per Epic #1302 원칙 6/7/8, semantic enums (`pickerMode` /
/// `promptMode`) and behaviour fields (`color` / `onChanged` /
/// `enabled` / `showAlpha` / `showLabel` / `showHexInput` /
/// `enableEyeDropper` / `dialogTitle` / `placeholder` / `controller`)
/// stay flat on the component. All chrome / dimensional / nested-slot
/// overrides flow through the single [colorPickerStyle] (a
/// [CoreColorPickerStyle]):
///
/// ```text
/// design system default for color picker
///   → CoreColorPickerTheme.style                  // 프로젝트 공통
///   → parent component slot override
///   → component.colorPickerStyle                  // 인스턴스별
/// ```
///
/// surface:functional — the picker opens in a `Popover`, anchored over the
/// page.
class ColorPicker extends UiStatefulComponent
    implements
        CoreColorPickerContract<
          Component,
          String,
          CoreValueChanged<String>?,
          Object
        > {
  /// Creates a [ColorPicker].
  const ColorPicker({
    required this.color,
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
    this.onChanged,
    this.enabled,
    this.showAlpha,
    this.showLabel,
    this.showHexInput,
    this.pickerMode,
    this.enableEyeDropper,
    this.promptMode,
    this.dialogTitle,
    this.placeholder,
    this.controller,
    this.colorPickerStyle,
  });

  @override
  final String color;

  @override
  final CoreValueChanged<String>? onChanged;

  @override
  final bool? enabled;

  @override
  final bool? showAlpha;

  @override
  final bool? showLabel;

  @override
  final bool? showHexInput;

  @override
  final CoreColorPickerMode? pickerMode;

  @override
  final bool? enableEyeDropper;

  @override
  final CoreColorPickerPromptMode? promptMode;

  @override
  final Component? dialogTitle;

  @override
  final Component? placeholder;

  @override
  final Object? controller;

  /// Per-instance composite Style — covers popover / dialog / preset
  /// swatch button / hex input slot styles plus label / description /
  /// error text styles. See [CoreColorPickerStyle] for the merge chain.
  @override
  final CoreColorPickerStyle? colorPickerStyle;

  /// Returns a copy of this [ColorPicker] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  ColorPicker copyWith({
    Key? key,
    UiMouseEventHandler? onClick,
    CoreValueChanged<String>? onChanged,
    String? color,
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
    bool? enabled,
    bool? showAlpha,
    bool? showLabel,
    bool? showHexInput,
    CoreColorPickerMode? pickerMode,
    bool? enableEyeDropper,
    CoreColorPickerPromptMode? promptMode,
    Component? dialogTitle,
    Component? placeholder,
    Object? controller,
    CoreColorPickerStyle? colorPickerStyle,
  }) {
    return ColorPicker(
      key: key ?? this.key,
      onClick: onClick ?? this.onClick,
      onChanged: onChanged ?? this.onChanged,
      color: color ?? this.color,
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
      enabled: enabled ?? this.enabled,
      showAlpha: showAlpha ?? this.showAlpha,
      showLabel: showLabel ?? this.showLabel,
      showHexInput: showHexInput ?? this.showHexInput,
      pickerMode: pickerMode ?? this.pickerMode,
      enableEyeDropper: enableEyeDropper ?? this.enableEyeDropper,
      promptMode: promptMode ?? this.promptMode,
      dialogTitle: dialogTitle ?? this.dialogTitle,
      placeholder: placeholder ?? this.placeholder,
      controller: controller ?? this.controller,
      colorPickerStyle: colorPickerStyle ?? this.colorPickerStyle,
    );
  }

  @override
  State<ColorPicker> createState() => _ColorPickerState();
}

/// Chain sugar mirroring the Flutter `ColorPicker.withStyle` extension —
/// merges a [CoreColorPickerStyle] patch into
/// [ColorPicker.colorPickerStyle] via the existing [ColorPicker.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreColorPickerStyle.merge` right-side-wins semantics).
extension ColorPickerStyleChain on ColorPicker {
  /// Sets the border color.
  ColorPicker borderColor(CoreColor value) =>
      withStyle(CoreColorPickerStyle(borderColor: value));

  /// Sets the border width in logical pixels.
  ColorPicker borderWidth(double value) =>
      withStyle(CoreColorPickerStyle(borderWidth: value));

  /// Returns a copy of this [ColorPicker] with [patch] merged into
  /// [colorPickerStyle] (patch fields win on conflict).
  ColorPicker withStyle(CoreColorPickerStyle patch) => copyWith(
    colorPickerStyle: (colorPickerStyle ?? const CoreColorPickerStyle()).merge(
      patch,
    ),
  );
}

class _ColorPickerState extends State<ColorPicker> {
  /// Imperative controller for the unified [Popover] hosting the
  /// picker UI. Driven by the swatch trigger and the Cancel / Save
  /// action row inside the popover — replaces the legacy hand-rolled
  /// `_popoverOpen` flag + outside-click document listener (handled
  /// by [Popover] itself now).
  final _popoverController = PopoverController();

  /// Visible swatch / hex input value. Tracks the popover's live
  /// draft while it's open so the trigger UI previews the user's
  /// selection as they drag / types. Reverts to [_committedHex] on
  /// Cancel.
  late String _hexBuffer;

  /// Last value the user actually committed via Save (or the initial
  /// `component.color`). Restored when the user cancels out of the
  /// popover — `_hexBuffer` may have drifted during the live preview.
  late String _committedHex;

  /// Whether the trigger shows the empty ("no colour") swatch — the
  /// value was not a valid hex and nothing has been picked since.
  /// [_hexBuffer] still holds the fallback hex the popover opens on.
  late bool _isEmptyBuffer;

  /// [_isEmptyBuffer] as of the last commit; restored on Cancel.
  late bool _isEmptyCommitted;

  late String _draftHex;
  late CoreColorPickerMode _activeMode;
  late final String _scopeId;

  /// The value the inline presentation compares the current colour with —
  /// the colour the picker was given before any inline edit. Reset when
  /// the caller hands in a colour the picker did not emit.
  late String _previousHex;

  /// The last hex the inline presentation committed, so
  /// `didUpdateComponent` can tell the caller echoing it back from the
  /// caller resetting it.
  String? _lastEmittedHex;

  bool get _isInline =>
      (component.promptMode ?? CoreColorPickerContract.defaultPromptMode) ==
      .inline;

  /// Recent-colors storage shared across every [ColorPicker] mounted
  /// under the same [RecentColorsScope] (typically the one `CoUIWeb`
  /// installs at the application root). `null` when the picker is
  /// rendered outside any scope — the recent-colors row is then
  /// hidden and the Save flow falls back to a no-op.
  CoreColorHistoryStorage? _historyStorage;

  bool get _isEnabled => component.enabled ?? true;

  // Keep SSR and the first client tree identical. Browser capabilities are
  // read only after that tree has been finalized, then on normal rebuilds.
  bool _eyeDropperCapabilityReady = false;

  @override
  void initState() {
    super.initState();
    _hexBuffer = isValidHexColor(component.color)
        ? normalizeHexColor(component.color)
        : _kFallbackHex;
    _committedHex = _hexBuffer;
    _draftHex = _hexBuffer;
    _previousHex = _hexBuffer;
    _isEmptyBuffer = !isValidHexColor(component.color);
    _isEmptyCommitted = _isEmptyBuffer;
    _scopeId = 'co-color-picker-${_coColorPickerIdCounter++}';
    _activeMode =
        component.pickerMode ?? CoreColorPickerContract.defaultPickerMode;
    _popoverController.addListener(_handlePopoverStateChange);
    if (kIsWeb) {
      context.binding.addPostFrameCallback(() {
        if (!mounted) return;
        setState(() => _eyeDropperCapabilityReady = true);
      });
    }
  }

  /// Tracks the previous open-state so [_handlePopoverStateChange]
  /// can fire `_handlePopoverOpen` only on the closed → open
  /// transition (and not e.g. on every theme rebuild).
  bool _wasPopoverOpen = false;

  /// Marks "this close cycle is a Save commit, not a Cancel". Set
  /// by [_handleSave] before calling `controller.close()` and read
  /// (then reset) by [_handlePopoverClosed] so outside-tap / ESC
  /// closes can be distinguished from explicit Save and apply the
  /// Cancel rollback automatically.
  bool _savedThisCycle = false;

  /// Listener fired by [_popoverController] every time the popover
  /// flips open / closed. The `closed → open` transition snaps the
  /// draft state back to the last committed value (so reopening
  /// always starts from the committed color); the `open → closed`
  /// transition routes through [_handlePopoverClosed] to apply the
  /// Cancel rollback when the close was caused by outside-tap / ESC
  /// rather than an explicit Save.
  void _handlePopoverStateChange() {
    final nextOpen = _popoverController.isOpen;
    if (!_wasPopoverOpen && nextOpen) {
      _handlePopoverOpen();
    }
    if (_wasPopoverOpen && !nextOpen) {
      _handlePopoverClosed();
    }
    _wasPopoverOpen = nextOpen;
  }

  /// Runs on every popover close (Cancel button, Save button,
  /// outside-tap, or ESC). Save sets [_savedThisCycle] before
  /// closing — anything else falls through to the Cancel rollback
  /// so the trigger swatch / hex input snaps back to the last
  /// committed color.
  void _handlePopoverClosed() {
    final wasSave = _savedThisCycle;
    _savedThisCycle = false;
    if (wasSave) return;
    setState(() {
      _draftHex = _committedHex;
      _hexBuffer = _committedHex;
      _isEmptyBuffer = _isEmptyCommitted;
    });
  }

  void _commit(String hex) {
    if (!mounted || !_isEnabled) return;
    setState(() {
      _hexBuffer = hex;
      _committedHex = hex;
      _isEmptyBuffer = false;
      _isEmptyCommitted = false;
    });
    component.onChanged?.call(hex);
  }

  /// Resets the popover's draft state to the last committed value
  /// just before the popover opens, so reopening always starts from
  /// the committed color (Cancel-then-reopen doesn't keep the
  /// abandoned draft).
  void _handlePopoverOpen() {
    setState(() {
      _draftHex = _committedHex;
      _hexBuffer = _committedHex;
      _isEmptyBuffer = _isEmptyCommitted;
    });
  }

  void _setDraft(String hex) {
    if (!mounted || !_isEnabled) return;
    if (_isInline) {
      // Inline: every edit is committed as it happens. The recent-colours
      // history is not touched — a drag would push every step.
      _lastEmittedHex = hex;
      setState(() {
        _draftHex = hex;
        _hexBuffer = hex;
        _committedHex = hex;
        _isEmptyBuffer = false;
        _isEmptyCommitted = false;
      });
      component.onChanged?.call(hex);
      return;
    }
    // Live-preview: also update `_hexBuffer` so the trigger swatch and
    // the hex input field stay in sync with the popover draft as the
    // user drags / types. Outer `onChanged` callback fires only on
    // Save (via `_commit`).
    setState(() {
      _draftHex = hex;
      _hexBuffer = hex;
      _isEmptyBuffer = false;
    });
  }

  /// Handles a tap on a recent-color swatch — routes the swatch's hex
  /// into the live draft (the user still presses Save to commit).
  void handleRecentSwatchPick(String hex) => _setDraft(hex);

  /// Listener fired by [_historyStorage] whenever the recent-colors
  /// list changes (another picker pushed / cleared, or
  /// `CoUIWeb.initialRecentColors` updated). Triggers a rebuild so
  /// the history grid reflects the new snapshot.
  void _handleHistoryChange() {
    if (!mounted) return;
    setState(() {});
  }

  void _handleSave() {
    if (!mounted || !_isEnabled) return;
    final committed = _draftHex;
    _commit(committed);
    // Push the just-committed color into the shared recent-colors
    // history. `_historyStorage` is null when the picker is mounted
    // outside any [RecentColorsScope] (e.g. legacy raw usage); the
    // Save path then falls back to the local commit only.
    final storage = _historyStorage;
    if (storage != null && isValidHexColor(committed)) {
      storage.addHistory(CoreColor.fromHex(committed));
    }
    // Mark this close as a Save so [_handlePopoverClosed] skips
    // the Cancel rollback.
    _savedThisCycle = true;
    _popoverController.close();
  }

  void _handleCancel() {
    // [_handlePopoverClosed] performs the rollback; here we only
    // need to dismiss the popover. Outside-tap / ESC reach the
    // same close path through [Popover] without going through
    // this method.
    _popoverController.close();
  }

  Future<void> _handlePickWithEyeDropper() async {
    if (!mounted || !_isEnabled) return;
    if (!kIsWeb || !isEyeDropperSupported) return;
    final hex = await pickColorWithEyeDropper();
    if (!mounted || !_isEnabled) return;
    if (hex != null && isValidHexColor(hex)) {
      _setDraft(normalizeHexColor(hex));
    }
  }

  Component _buildSwatch(BuildContext context, ResolvedColorPicker resolved) {
    // Use `_hexBuffer` (not `component.color`) so the trigger swatch
    // previews the popover's live draft as the user drags / types,
    // matching Flutter's parity.
    final hex = isValidHexColor(_hexBuffer) ? _hexBuffer : _kFallbackHex;
    if (_isEmptyBuffer) {
      // Empty ("no colour") swatch: no fill, a dashed outline drawn as an
      // SVG overlay (deterministic dash pattern, same as Flutter's painter).
      return Component.element(
        tag: 'button',
        classes: resolved.swatchEmpty.className,
        styles: resolved.swatchEmpty.inlineStyles,
        attributes: {
          'type': 'button',
          'aria-label': CouiLocalizations.of(context).colorPickerSelectLabel,
          if (!_isEnabled) 'disabled': '',
        },
        children: [
          Component.element(
            tag: 'svg',
            classes: resolved.swatchDashOverlay.className,
            styles: resolved.swatchDashOverlay.inlineStyles,
            attributes: const {'aria-hidden': 'true'},
            children: [
              Component.element(
                tag: 'rect',
                styles: resolved.swatchDashRect.inlineStyles,
                children: const [],
              ),
            ],
          ),
        ],
      );
    }
    // Click / keyboard / focus handling is owned by [Popover] —
    // the swatch is a passive visual trigger that paints the current
    // hex preview. `aria-haspopup` / `aria-expanded` are likewise
    // emitted by [Popover] on its own scope wrapper.
    return Component.element(
      tag: 'button',
      classes: resolved.swatch.className,
      styles: Styles.combine([
        ?resolved.swatch.inlineStyles,
        Styles(raw: {'background-color': hex}),
      ]),
      attributes: {
        'type': 'button',
        'aria-label': CouiLocalizations.of(context).colorPickerSelectLabel,
        if (!_isEnabled) 'disabled': '',
      },
      children: const [],
    );
  }

  /// The field-shaped trigger — swatch, picked hex (or the placeholder
  /// when no colour is picked) and a chevron in one outlined field.
  Component _buildTriggerField(
    BuildContext context,
    ResolvedColorPicker resolved,
  ) {
    final placeholder = component.placeholder;
    return Component.element(
      tag: 'div',
      classes: resolved.triggerField.className,
      styles: resolved.triggerField.inlineStyles,
      children: [
        _buildSwatch(context, resolved),
        if (_isEmptyBuffer)
          Component.element(
            tag: 'span',
            classes: resolved.triggerPlaceholder.className,
            styles: resolved.triggerPlaceholder.inlineStyles,
            children: [
              placeholder ??
                  Text(CouiLocalizations.of(context).colorPickerPlaceholder),
            ],
          )
        else
          Component.element(
            tag: 'span',
            classes: resolved.triggerValue.className,
            styles: resolved.triggerValue.inlineStyles,
            children: [Text(_hexBuffer)],
          ),
        Icon(
          LucideIcons.chevronDown,
          iconStyle: resolved.triggerChevronIconStyle,
        ),
      ],
    );
  }

  Component _buildHexInput(
    BuildContext context,
    ResolvedColorPicker resolved,
  ) {
    return Component.element(
      tag: 'div',
      classes: resolved.hexInputWrap.className,
      styles: resolved.hexInputWrap.inlineStyles,
      children: [
        // Part of this composite: walled off from the enclosing
        // `FormField`, which is shown the composite's own value.
        FormFieldHandleScope.boundary(
          child: TextField(
            key: ValueKey(_isEmptyBuffer ? '' : _hexBuffer),
            onChanged: (raw) {
              final normalized = raw.startsWith('#') ? raw : '#$raw';
              if (isValidHexColor(normalized)) {
                _commit(normalizeHexColor(normalized));
              }
            },
            initialValue: _isEmptyBuffer ? '' : _hexBuffer,
            enabled: _isEnabled,
            textFieldStyle: resolved.hexInputStyle,
            maxLength: _kHexInputMaxLength,
            autocorrect: false,
            selectAllOnFocus: true,
          ),
        ),
      ],
    );
  }

  /// Picker UI fed into [Popover] as its `content`. The outer
  /// chrome (panel border / shadow / radius / role="dialog") is
  /// owned by [Popover] itself, so this helper only emits the
  /// vertical column of picker sections (mode tabs, SV area, hue,
  /// alpha, inputs, recent grid, action row).
  Component _buildPopoverContent(
    BuildContext context,
    ResolvedColorPicker resolved,
    bool showAlpha,
    bool enableEyeDropper,
  ) {
    final dialogTitle = component.dialogTitle;

    // Vertical `gap` between popover sections is rendered natively by
    // the `flex flex-col` parent's CSS `gap` declaration baked into
    // `resolved.popoverContent.inlineStyles` — no manual `Gap`
    // interleave needed.
    return Component.element(
      tag: 'div',
      classes: resolved.popoverContent.className,
      styles: resolved.popoverContent.inlineStyles,
      attributes: {
        'aria-label': CouiLocalizations.of(context).colorPickerLabel,
      },
      children: [
        ?dialogTitle,
        _buildModeTabs(context, resolved),
        _buildSaturationValueArea(context, resolved),
        _buildHueSlider(context, resolved),
        if (showAlpha) _buildAlphaSlider(context, resolved),
        _buildModeInputs(context, resolved),
        if (_historyStorage != null) _buildRecentColorsGrid(context, resolved),
        _buildActionRow(context, resolved, enableEyeDropper),
      ],
    );
  }

  /// Recent-colors swatch grid — visible whenever the picker is
  /// mounted under a [RecentColorsScope]. Each swatch is a small
  /// rounded button that, when clicked, sets the picker's draft to
  /// that color so the SV / hue / hex inputs reflect the choice. The
  /// caller still has to press Save to commit + push the (possibly
  /// re-edited) color back into history.
  ///
  /// Geometry is sourced from [ResolvedColorPicker] —
  /// `recentSwatchSize`, `recentSwatchSpacing`, `recentColumns` — so the
  /// Flutter `ColorHistoryGrid` and this Web grid stay
  /// dimensionally aligned.
  Component _buildRecentColorsGrid(
    BuildContext context,
    ResolvedColorPicker resolved,
  ) {
    final storage = _historyStorage;
    if (storage == null) return const Component.empty();
    final history = storage.recentColors;
    if (history.isEmpty) return const Component.empty();
    final l10n = CouiLocalizations.of(context);
    // The newest `recentColumns` colours under the section title — the
    // same count the Flutter row takes.
    return Component.element(
      tag: 'div',
      classes: resolved.recentSection.className,
      styles: resolved.recentSection.inlineStyles,
      children: [
        Component.element(
          tag: 'span',
          classes: resolved.recentTitle.className,
          styles: resolved.recentTitle.inlineStyles,
          children: [Text(l10n.colorPickerRecentTitle)],
        ),
        Gap(gapStyle: resolved.recentTitleGapStyle),
        Component.element(
          tag: 'div',
          classes: resolved.recentColorsGrid.className,
          styles: resolved.recentColorsGrid.inlineStyles,
          attributes: {'aria-label': l10n.colorPickerRecentLabel},
          children: [
            for (final color in history)
              _buildRecentSwatch(context, resolved, color),
          ],
        ),
      ],
    );
  }

  Component _buildRecentSwatch(
    BuildContext context,
    ResolvedColorPicker resolved,
    CoreColor color,
  ) {
    // `color` may be a semantic token (e.g. seeded via
    // `CoUIWeb.initialRecentColors` with `CoreColor.token(...)`); a
    // colour picker needs a concrete `#RRGGBB` to display / compare, and
    // `toHex()` throws on an unresolved token — so resolve through the
    // active scheme first (#2123).
    final resolvedColor = context.colorScheme.resolve(color);
    final hex = resolvedColor.toHex();
    final isSelected = normalizeHexColor(hex) == normalizeHexColor(_draftHex);
    final swatchChrome = isSelected
        ? resolved.recentSwatchSelected
        : resolved.recentSwatchUnselected;
    // The recent-color swatch composes Clickable — tap / keyboard
    // activation / cursor / press feedback / focus ring (which gives each
    // swatch keyboard access) flow through the single interaction
    // primitive, mirroring the Flutter swatch. The inner `<div>` keeps
    // only the visual swatch chrome (size / radius / hover ring / selected
    // ring / background colour).
    return Clickable(
      onPressed: () => handleRecentSwatchPick(hex),
      enabled: _isEnabled,
      attributes: {
        'aria-label': CouiLocalizations.of(context).colorPickerRecentColor(hex),
      },
      clickableStyle: resolved.recentSwatchClickableStyle,
      child: Component.element(
        tag: 'div',
        classes: swatchChrome.className,
        styles: Styles.combine([
          ?swatchChrome.inlineStyles,
          Styles(raw: {'background-color': color.toValue()}),
        ]),
      ),
    );
  }

  /// Mode-specific numeric inputs that drive `_draftHex`. The input
  /// triplet matches the active tab — RGB / HSL / HSV — and edits
  /// flow back through `CoreColorMath` so the swatch and the 2D
  /// picker reflect changes in real time.
  Component _buildModeInputs(
    BuildContext context,
    ResolvedColorPicker resolved,
  ) {
    final activeHex = isValidHexColor(_draftHex) ? _draftHex : _hexBuffer;
    final triplet = colorPickerTriplet(_activeMode, activeHex);
    Component cell(int channel, String label, int value, int max) => .element(
      tag: 'div',
      classes: resolved.modeInputCell.className,
      styles: resolved.modeInputCell.inlineStyles,
      children: [
        _buildModeInputCell(
          context,
          resolved: resolved,
          label: label,
          value: value,
          max: max,
          channel: channel,
        ),
      ],
    );
    // Horizontal `gap` between the three RGB/HSL/HSV cells is rendered
    // natively by the `flex` parent's CSS `gap` declaration baked into
    // `resolved.modeInputsRow.inlineStyles` — no manual `Gap`
    // interleave needed.
    return Component.element(
      tag: 'div',
      classes: resolved.modeInputsRow.className,
      styles: resolved.modeInputsRow.inlineStyles,
      children: [
        Component.element(
          tag: 'div',
          classes: resolved.modeHexInputCell.className,
          styles: resolved.modeHexInputCell.inlineStyles,
          children: [_buildHexInputCell(context, resolved, activeHex)],
        ),
        cell(0, triplet.labels.$1, triplet.values.$1, triplet.max.$1),
        cell(1, triplet.labels.$2, triplet.values.$2, triplet.max.$2),
        cell(2, triplet.labels.$3, triplet.values.$3, triplet.max.$3),
      ],
    );
  }

  /// The HEX cell at the head of the panel's input row — the same caption +
  /// field stack as a channel cell, editing the whole `#RRGGBB` value.
  Component _buildHexInputCell(
    BuildContext context,
    ResolvedColorPicker resolved,
    String hex,
  ) {
    return Component.element(
      tag: 'div',
      classes: resolved.modeInputCellInner.className,
      styles: resolved.modeInputCellInner.inlineStyles,
      children: [
        Component.element(
          tag: 'div',
          classes: resolved.modeInputLabel.className,
          styles: resolved.modeInputLabel.inlineStyles,
          children: [
            Component.element(
              tag: 'span',
              classes: resolved.modeInputLabelText.className,
              styles: resolved.modeInputLabelText.inlineStyles,
              children: const [Text(kColorPickerHexLabel)],
            ),
          ],
        ),
        Gap(gapStyle: resolved.modeInputLabelGapStyle),
        // Part of this composite: walled off from the enclosing
        // `FormField`, which is shown the composite's own value.
        FormFieldHandleScope.boundary(
          child: TextField(
            key: ValueKey('hex-$hex'),
            onChanged: (raw) {
              final normalized = raw.startsWith('#') ? raw : '#$raw';
              if (isValidHexColor(normalized)) {
                _setDraft(normalizeHexColor(normalized));
              }
            },
            initialValue: hex,
            enabled: _isEnabled,
            size: CoreColorPickerContract.defaultModeInputSize,
            maxLength: _kHexInputMaxLength,
            autocorrect: false,
            selectAllOnFocus: true,
          ),
        ),
      ],
    );
  }

  Component _buildModeInputCell(
    BuildContext context, {
    required ResolvedColorPicker resolved,
    required String label,
    required int value,
    required int max,
    required int channel,
  }) {
    return Component.element(
      tag: 'div',
      classes: resolved.modeInputCellInner.className,
      styles: resolved.modeInputCellInner.inlineStyles,
      children: [
        // `leading-none` collapses the wrapper's inherited body
        // line-height down to the label glyph height — without it
        // the wrapper div carried the root body role's line box
        // around the smaller label span, inflating the gap between
        // the hue slider above and the input row below versus
        // Flutter.
        Component.element(
          tag: 'div',
          classes: resolved.modeInputLabel.className,
          styles: resolved.modeInputLabel.inlineStyles,
          children: [
            Component.element(
              tag: 'span',
              classes: resolved.modeInputLabelText.className,
              styles: resolved.modeInputLabelText.inlineStyles,
              children: [Text(label)],
            ),
          ],
        ),
        Gap(gapStyle: resolved.modeInputLabelGapStyle),
        // Part of this composite: walled off from the enclosing
        // `FormField`, which is shown the composite's own value.
        FormFieldHandleScope.boundary(
          child: TextField(
            key: ValueKey('$label-$value'),
            onChanged: (raw) {
              final parsed = int.tryParse(raw);
              if (parsed == null) return;
              _applyChannelEdit(
                channel: channel,
                value: parsed.clamp(0, max),
              );
            },
            initialValue: '$value',
            enabled: _isEnabled,
            textFieldStyle: const CoreTextFieldStyle(
              textAlign: .center,
            ),
            size: CoreColorPickerContract.defaultModeInputSize,
            maxLength: '$max'.length,
            autocorrect: false,
            selectAllOnFocus: true,
          ),
        ),
      ],
    );
  }

  void _applyChannelEdit({required int channel, required int value}) {
    final activeHex = isValidHexColor(_draftHex) ? _draftHex : _hexBuffer;
    _setDraft(
      applyColorPickerChannelEdit(
        mode: _activeMode,
        hex: activeHex,
        channel: channel,
        value: value,
      ),
    );
  }

  Component _buildModeTabs(
    BuildContext context,
    ResolvedColorPicker resolved,
  ) {
    final l10n = CouiLocalizations.of(context);
    // The shared grouped toggle — one track, the chosen mode a raised
    // face. Same component the Filter segments and the time picker's
    // AM / PM compose.
    return ToggleGroup<CoreColorPickerMode>(
      value: _activeMode,
      enabled: _isEnabled,
      onChanged: (mode) {
        if (!mounted || !_isEnabled) return;
        if (mode != _activeMode) setState(() => _activeMode = mode);
      },
      toggleGroupStyle: resolved.modeTabsStyle,
      size: CoreColorPickerContract.defaultModeTabsSize,
      // The tabs span the panel, matching the full-width colour area and
      // inputs below; the three modes split the track equally.
      fillWidth: true,
      items: [
        for (final mode in _kPickerModeOrder)
          CoreToggleGroupItem<CoreColorPickerMode, Component>(
            value: mode,
            label: _pickerModeLabel(l10n, mode),
          ),
      ],
    );
  }

  Component _buildSaturationValueArea(
    BuildContext context,
    ResolvedColorPicker resolved,
  ) {
    final activeHex = isValidHexColor(_draftHex) ? _draftHex : _hexBuffer;
    final rgb = hexToRgb(activeHex);
    final hsv = rgbToHsv(r: rgb.r, g: rgb.g, b: rgb.b);
    final background =
        'linear-gradient(to top, #000, transparent), '
        'linear-gradient(to right, #fff, '
        'hsl(${hsv.h.toStringAsFixed(0)}, 100%, 50%))';

    final satValId = '$_scopeId-satval';
    return Component.element(
      tag: 'div',
      id: satValId,
      classes: resolved.saturationValueArea.className,
      styles: Styles.combine([
        ?resolved.saturationValueArea.inlineStyles,
        Styles(raw: {'background': background}),
      ]),
      // No `role="application"`. That role tells assistive tech to hand
      // every keystroke to this element and suppress browse-mode
      // navigation — a trade worth making only if the element actually
      // intercepts arbitrary keys. This surface has no keydown handler at
      // all right now (mouse/drag only), so the role bought nothing and
      // only turned off navigation for whatever was reached via this
      // element. Real keyboard operability for this 2D surface (arrow
      // keys nudging saturation/value) is a separate, larger gap than a
      // role removal — tracked as a follow-up rather than folded in here.
      attributes: {
        'aria-label': CouiLocalizations.of(context).colorPickerSaturationValue,
        if (!_isEnabled) 'aria-disabled': 'true',
      },
      events: {
        'mousedown': (event) => _handleSatValPointer(event, satValId),
        'mousemove': (event) {
          if (isMouseEventDragging(event)) {
            _handleSatValPointer(event, satValId);
          }
        },
      },
      children: [
        // Picked-point handle: x = saturation, y = inverse value.
        _buildHandle(
          resolved,
          left: hsv.s,
          top: 100 - hsv.v,
          fill: activeHex,
        ),
      ],
    );
  }

  /// Round picked-point handle at ([left], [top]) percent of its host,
  /// filled with [fill].
  Component _buildHandle(
    ResolvedColorPicker resolved, {
    required double left,
    required double top,
    String? fill,
    WebElementChrome? chrome,
  }) {
    final handle = chrome ?? resolved.handle;
    return Component.element(
      tag: 'div',
      classes: handle.className,
      styles: Styles.combine([
        ?handle.inlineStyles,
        Styles(
          raw: {
            'left': '${left.clamp(0, 100)}%',
            'top': '${top.clamp(0, 100)}%',
            'background-color': ?fill,
          },
        ),
      ]),
      children: const [],
    );
  }

  void _handleSatValPointer(Object event, String elementId) {
    if (!mounted || !_isEnabled) return;
    final ratio = readMouseEventLocalRatio(event, elementId);
    if (ratio == null) return;
    const pct = 100;
    final s = ratio.x * pct;
    final v = (1 - ratio.y) * pct;
    final activeHex = isValidHexColor(_draftHex) ? _draftHex : _hexBuffer;
    final rgb = hexToRgb(activeHex);
    final hsv = rgbToHsv(r: rgb.r, g: rgb.g, b: rgb.b);
    final next = hsvToRgb(h: hsv.h, s: s, v: v);
    _setDraft(rgbToHex(r: next.r, g: next.g, b: next.b));
  }

  Component _buildHueSlider(
    BuildContext context,
    ResolvedColorPicker resolved,
  ) {
    const hueGradient =
        'linear-gradient(to right,'
        ' #f00 0%, #ff0 17%, #0f0 33%, #0ff 50%,'
        ' #00f 67%, #f0f 83%, #f00 100%)';

    final hueId = '$_scopeId-hue';
    final activeHex = isValidHexColor(_draftHex) ? _draftHex : _hexBuffer;
    final rgb = hexToRgb(activeHex);
    final hue = rgbToHsv(r: rgb.r, g: rgb.g, b: rgb.b).h;
    return Component.element(
      tag: 'div',
      id: hueId,
      classes: resolved.hueSlider.className,
      styles: resolved.hueSlider.inlineStyles,
      attributes: {
        'role': 'slider',
        'aria-label': CouiLocalizations.of(context).colorHue,
        if (!_isEnabled) 'aria-disabled': 'true',
      },
      events: {
        'mousedown': (event) => _handleHuePointer(event, hueId),
        'mousemove': (event) {
          if (isMouseEventDragging(event)) {
            _handleHuePointer(event, hueId);
          }
        },
      },
      children: [
        Component.element(
          tag: 'div',
          classes: resolved.hueTrack.className,
          styles: Styles.combine([
            ?resolved.hueTrack.inlineStyles,
            const Styles(raw: {'background': hueGradient}),
          ]),
          children: const [],
        ),
        _buildHandle(
          resolved,
          left: hue / 360 * 100,
          top: 50,
          fill: activeHex,
          chrome: resolved.hueHandle,
        ),
      ],
    );
  }

  void _handleHuePointer(Object event, String elementId) {
    if (!mounted || !_isEnabled) return;
    final ratio = readMouseEventLocalRatio(event, elementId);
    if (ratio == null) return;
    const hueMax = 359.0;
    final h = ratio.x * hueMax;
    final activeHex = isValidHexColor(_draftHex) ? _draftHex : _hexBuffer;
    final rgb = hexToRgb(activeHex);
    final hsv = rgbToHsv(r: rgb.r, g: rgb.g, b: rgb.b);
    final next = hsvToRgb(h: h, s: hsv.s, v: hsv.v);
    _setDraft(rgbToHex(r: next.r, g: next.g, b: next.b));
  }

  Component _buildAlphaSlider(
    BuildContext context,
    ResolvedColorPicker resolved,
  ) {
    final activeHex = isValidHexColor(_draftHex) ? _draftHex : _kFallbackHex;
    final background =
        'linear-gradient(to right, transparent, $activeHex), '
        'repeating-conic-gradient(#ccc 0 25%, #fff 0 50%)';

    return Component.element(
      tag: 'div',
      classes: resolved.alphaSlider.className,
      styles: Styles.combine([
        ?resolved.alphaSlider.inlineStyles,
        Styles(
          raw: {
            'background': background,
            'background-size': '100% 100%, 12px 12px',
          },
        ),
      ]),
      attributes: {
        'role': 'slider',
        'aria-label': CouiLocalizations.of(context).colorAlpha,
        if (!_isEnabled) 'aria-disabled': 'true',
      },
      children: const [],
    );
  }

  Component _buildActionRow(
    BuildContext context,
    ResolvedColorPicker resolved,
    bool enableEyeDropper,
  ) {
    final l10n = CouiLocalizations.of(context);
    return Component.element(
      tag: 'div',
      classes: resolved.actionRow.className,
      styles: resolved.actionRow.inlineStyles,
      children: [
        if (enableEyeDropper) _buildEyeDropperButton(context, resolved),
        Component.element(
          tag: 'div',
          classes: resolved.actionRowSpacer.className,
          styles: resolved.actionRowSpacer.inlineStyles,
          children: const [],
        ),
        if (_isInline)
          _buildCompareCell(resolved)
        else ...[
          Button(
            onPressed: _handleCancel,
            enabled: _isEnabled,
            variant: .ghost,
            size: .sm,
            // Bind the label colour explicitly — same outcome as the
            // Flutter side.
            child: Text(l10n.buttonCancel).bodySmall.onSurface,
          ),
          Gap(gapStyle: resolved.actionRowGapStyle),
          Button(
            onPressed: _handleSave,
            enabled: _isEnabled,
            size: .sm,
            // See comment above; bind to `.onPrimary` to match the
            // primary variant the button itself uses.
            child: Text(l10n.buttonSave).bodySmall.onPrimary,
          ),
        ],
      ],
    );
  }

  /// The inline presentation's previous / current comparison cell — two
  /// square halves inside one outlined, rounded box.
  Component _buildCompareCell(ResolvedColorPicker resolved) {
    Component half(String hex) => Component.element(
      tag: 'span',
      classes: resolved.compareSwatch.className,
      styles: Styles.combine([
        ?resolved.compareSwatch.inlineStyles,
        Styles(raw: {'background-color': hex}),
      ]),
      children: const [],
    );
    return Component.element(
      tag: 'span',
      classes: resolved.compareCell.className,
      styles: resolved.compareCell.inlineStyles,
      children: [half(_previousHex), half(_draftHex)],
    );
  }

  Component _buildEyeDropperButton(
    BuildContext context,
    ResolvedColorPicker resolved,
  ) {
    // Icon-only — every other control in this panel already carries an
    // aria-label; this one was the gap. `colorPickerPreviewLabel` is the
    // *capture preview image*, not this trigger, so it needs its own key.
    return Button(
      onPressed: () => unawaited(_handlePickWithEyeDropper()),
      enabled: _isEnabled,
      variant: .ghost,
      size: .sm,
      attributes: {
        'aria-label': CouiLocalizations.of(context).colorPickerEyeDropper,
      },
      child: Icon(
        LucideIcons.pipette,
        iconStyle: resolved.eyeDropperIconStyle,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-resolve the inherited recent-colors storage on every
    // dependency change. `RecentColorsScope.maybeOf` walks the
    // ancestor chain — when the scope is moved (e.g. the host app
    // swaps its `CoUIWeb` config) we drop the old subscription and
    // pick up the new storage so the history grid stays accurate.
    final next = RecentColorsScope.maybeOf(context);
    if (identical(next, _historyStorage)) return;
    _historyStorage?.removeListener(_handleHistoryChange);
    _historyStorage = next;
    _historyStorage?.addListener(_handleHistoryChange);
  }

  @override
  void didUpdateComponent(covariant ColorPicker oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.color != component.color) {
      if (isValidHexColor(component.color)) {
        final next = normalizeHexColor(component.color);
        _hexBuffer = next;
        _committedHex = next;
        _draftHex = next;
        _isEmptyBuffer = false;
        _isEmptyCommitted = false;
        if (_isInline && next != _lastEmittedHex) _previousHex = next;
      } else {
        _isEmptyBuffer = true;
        _isEmptyCommitted = true;
      }
    }
    if (oldComponent.pickerMode != component.pickerMode &&
        component.pickerMode != null) {
      _activeMode = component.pickerMode!;
    }
  }

  @override
  void dispose() {
    _historyStorage?.removeListener(_handleHistoryChange);
    _popoverController.removeListener(_handlePopoverStateChange);
    _popoverController.dispose();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    // Resolve composite Style through the Epic #1302 nested-merge chain.
    final resolved = resolveColorPicker(
      context,
      scopeId: _scopeId,
      colorPickerStyle: component.colorPickerStyle,
    );
    // Scoped `<style>` rules — non-empty only when a raw (token-less)
    // `borderColor` override moves the recent-swatch hover ring off the
    // Tailwind `ring-*` scale (class XOR rule). Empty on the default
    // (token) path, so no `<style>` markup is emitted then.
    final rules = resolveColorPickerRules(
      context,
      scopeId: _scopeId,
      colorPickerStyle: component.colorPickerStyle,
    );

    // Behaviour bits stay flat on the component; fall back to the
    // single-source `CoreColorPickerContract.defaultX` constants when the
    // component-level value is null (project-level behaviour defaults are
    // no longer carried on `CoreColorPickerTheme`).
    final showLabel =
        component.showLabel ?? CoreColorPickerContract.defaultShowLabel;
    final showHexInput =
        component.showHexInput ?? CoreColorPickerContract.defaultShowHexInput;
    final showAlpha =
        component.showAlpha ?? CoreColorPickerContract.defaultShowAlpha;
    final enableEyeDropper =
        (component.enableEyeDropper ??
            CoreColorPickerContract.defaultEnableEyeDropper) &&
        (!_eyeDropperCapabilityReady || isEyeDropperSupported);

    // Trigger row — swatch (+ optional hex input) which the user
    // clicks to open the popover. [Popover] adds its own
    // `aria-haspopup="dialog"` / `aria-expanded` to the wrapper it
    // builds around this row, so the swatch button itself stays a
    // plain visual trigger.
    if (_isInline) {
      final panel = Popup(
        popupStyle: resolved.inlinePanelStyle,
        // Keep the same panel owner across enable changes. Its existing
        // pointer chrome complements each composed control's disabled state.
        classes: _isEnabled ? null : resolved.inlineInert.className,
        css: _isEnabled ? null : resolved.inlineInert.inlineStyles,
        children: [
          _buildPopoverContent(context, resolved, showAlpha, enableEyeDropper),
        ],
      );
      return div(
        [
          // `<style>` is `display: none`, so it never affects layout.
          if (rules.css.isNotEmpty)
            Component.element(tag: 'style', children: [RawText(rules.css)]),
          // Disabled values remain visible and accessible; each child owns
          // its disabled semantics, while the panel rejects pointer hits.
          panel,
        ],
        id: component.id ?? _scopeId,
        classes: component.rootClasses(resolved.root.className),
        styles: component.css != null
            ? Styles.combine([?resolved.root.inlineStyles, component.css!])
            : resolved.root.inlineStyles,
        attributes: {
          ...component.componentAttributes,
          'role': 'group',
          if (!_isEnabled) 'aria-disabled': 'true',
        },
        events: component.events,
      );
    }

    final triggerChildren = [
      _buildTriggerField(context, resolved),
      if (showLabel || showHexInput) ...[
        Gap(gapStyle: resolved.swatchGapStyle),
        _buildHexInput(context, resolved),
      ],
    ];

    final triggerRow = div(
      triggerChildren,
      classes: resolved.triggerRow.className,
      styles: resolved.triggerRow.inlineStyles,
      attributes: {
        'role': 'group',
        if (!_isEnabled) 'aria-disabled': 'true',
      },
    );

    if (!_isEnabled) {
      // Skip mounting [Popover] entirely when the picker is
      // disabled — the trigger row stays inert and no popover can
      // open. Matches Flutter `ColorPicker.enabled = false`.
      return div(
        [
          // `<style>` is `display: none`, so it never affects layout.
          if (rules.css.isNotEmpty)
            Component.element(tag: 'style', children: [RawText(rules.css)]),
          triggerRow,
        ],
        id: component.id ?? _scopeId,
        classes: component.rootClasses(resolved.root.className),
        styles: component.css != null
            ? Styles.combine([?resolved.root.inlineStyles, component.css!])
            : resolved.root.inlineStyles,
        attributes: component.componentAttributes,
        events: component.events,
      );
    }

    return div(
      [
        // `<style>` is `display: none`, so it never affects layout — it
        // carries the recent-swatch hover-ring rule only when a raw
        // border-colour override is present.
        if (rules.css.isNotEmpty)
          Component.element(tag: 'style', children: [RawText(rules.css)]),
        Popover(
          trigger: triggerRow,
          content: _buildPopoverContent(
            context,
            resolved,
            showAlpha,
            enableEyeDropper,
          ),
          controller: _popoverController,
          popoverStyle: resolved.popoverStyle,
        ),
      ],
      id: component.id ?? _scopeId,
      classes: component.rootClasses(resolved.root.className),
      styles: component.css != null
          ? Styles.combine([?resolved.root.inlineStyles, component.css!])
          : resolved.root.inlineStyles,
      attributes: {...component.componentAttributes, 'role': 'group'},
      events: component.events,
    );
  }
}
