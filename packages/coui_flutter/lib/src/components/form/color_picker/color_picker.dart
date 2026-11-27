import 'dart:async';
import 'dart:math' as math;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/components/form/color_picker/color_picker_eyedropper.dart';

/// Platform typedef for Flutter `ColorPicker` contract.
///
/// Flutter exchanges colour as a [Color] value at the public API boundary
/// (per Epic #1302 contract design — `Clr` typed slots line up with the
/// nested [CoreColorPickerStyle] generics so the same parameter drives
/// both the value getter and the slot styles' colour token type). Hex
/// string conversion happens internally so the picker UI keeps using

/// Length of a `#RRGGBB` hex string (hash + 6 digits) — the hex
/// input field caps typing at this many characters.
const int _kHexInputMaxLength = 7;

/// Fully-opaque ARGB alpha channel value (`0xFF`). The picker drops
/// alpha, so every decoded colour is composited at full opacity.
const int _kOpaqueAlpha = kColorPickerChannelMaxRgb;

/// Fallback hex used when the current input cannot be parsed as a
/// valid `#RRGGBB` color (e.g. partially-typed buffer). Behaviour
/// value — kept flat on the widget per Epic #1302 원칙 6/7.
const String _kFallbackHex = '#000000';

/// Picker mode tab display order (matches Web `ColorPicker`).
const List<CoreColorPickerMode> _kPickerModeOrder = [
  CoreColorPickerMode.rgb,
  CoreColorPickerMode.hsl,
  CoreColorPickerMode.hsv,
];

/// Localized tab label for [mode], sourced from [CoUILocalizations] so
/// Flutter and Web read the same single-source strings.
String _pickerModeLabel(CoUILocalizations l10n, CoreColorPickerMode mode) {
  return switch (mode) {
    .rgb => l10n.colorPickerTabRGB,
    .hsl => l10n.colorPickerTabHSL,
    .hsv => l10n.colorPickerTabHSV,
  };
}

/// Decodes `#RRGGBB` to a Flutter [Color] (full opacity).
Color _hexToFlutterColor(String hex) {
  final rgb = hexToRgb(hex);
  return Color.fromARGB(_kOpaqueAlpha, rgb.r, rgb.g, rgb.b);
}

/// Whether [color] means "no colour": fully transparent. The picker drops
/// alpha for every real colour, so a transparent value is free to carry
/// the empty state without widening the public API.
bool _isNoColor(Color color) => color.a == 0;

/// Encodes a Flutter [Color] as `#RRGGBB` (alpha dropped).
String _flutterColorToHex(Color color) =>
    color.toHex(includeAlpha: false, includeHashSign: true).toUpperCase();

/// Unified before/after color picker — opens an anchored popover with
/// HSV picker, hue slider, optional alpha slider, mode tabs, and an
/// eye-dropper / Cancel / Save row.
///
/// Mirrors Web `ColorPicker` 1:1 — same contract shape, same popover
/// structure, same interaction model. Public API takes/returns
/// [Color]; internal state uses hex strings (so [hexToRgb] / [rgbToHex]
/// math from `core_color_math.dart` stays platform-shared with Web).
///
/// Per Epic #1302 원칙 6/7/8, semantic enums (`pickerMode` /
/// `promptMode`) and behaviour fields (`color` / `onChanged` /
/// `enabled` / `showAlpha` / `showLabel` / `showHexInput` /
/// `enableEyeDropper` / `dialogTitle` / `placeholder` / `controller`)
/// stay flat on the widget. All chrome / dimensional / nested-slot
/// overrides flow through the single [colorPickerStyle] (a
/// [CoreColorPickerStyle]):
///
/// ```text
/// design system default for color picker
///   → CoreColorPickerTheme.style                  // 프로젝트 공통
///   → parent component slot override
///   → widget.colorPickerStyle                     // 인스턴스별
/// ```
///
/// surface:functional — the picker opens in a `Popover`, anchored over the
/// page.
class ColorPicker extends StatefulWidget
    implements
        CoreColorPickerContract<Widget, Color, ValueChanged<Color>?, Object> {
  /// Creates a [ColorPicker].
  const ColorPicker({
    required this.color,
    super.key,
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
  final Color color;

  @override
  final ValueChanged<Color>? onChanged;

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
  final Widget? dialogTitle;

  @override
  final Widget? placeholder;

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
    ValueChanged<Color>? onChanged,
    Color? color,
    bool? enabled,
    bool? showAlpha,
    bool? showLabel,
    bool? showHexInput,
    CoreColorPickerMode? pickerMode,
    bool? enableEyeDropper,
    CoreColorPickerPromptMode? promptMode,
    Widget? dialogTitle,
    Widget? placeholder,
    Object? controller,
    CoreColorPickerStyle? colorPickerStyle,
  }) {
    return ColorPicker(
      key: key ?? this.key,
      onChanged: onChanged ?? this.onChanged,
      color: color ?? this.color,
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

class _ColorPickerState extends State<ColorPicker> {
  /// Imperative controller for the unified [Popover] hosting the
  /// picker UI. Replaces the legacy hand-rolled `PopoverController`
  /// — Cancel / Save action rows close via `controller.close()` and
  /// the swatch trigger opens via [Popover]'s built-in click
  /// handling.
  final _popoverController = PopoverController();

  /// Visible swatch / hex input value. Tracks the popover's live draft
  /// while it's open so the trigger UI previews the user's selection
  /// as they drag / type. Reverts to [_committedHex] on Cancel.
  late String _hexBuffer;

  /// Last value the user actually committed via Save (or the initial
  /// `widget.color`). Restored when the user cancels out of the
  /// popover — `_hexBuffer` may have drifted during the live preview.
  late String _committedHex;

  /// Whether the trigger shows the empty ("no colour") swatch — the value
  /// was fully transparent and nothing has been picked since. [_hexBuffer]
  /// still holds the fallback hex the popover opens on.
  late bool _isEmptyBuffer;

  /// [_isEmptyBuffer] as of the last commit; restored on Cancel.
  late bool _isEmptyCommitted;

  late CoreColorPickerMode _activeMode;

  /// The value the inline presentation compares the current colour with —
  /// the colour the picker was given before any inline edit. Reset when
  /// the caller hands in a colour the picker did not emit.
  late String _previousHex;

  /// The last hex the inline presentation committed, so [didUpdateWidget]
  /// can tell the caller echoing it back from the caller resetting it.
  String? _lastEmittedHex;

  /// Recent-colors storage shared across every [ColorPicker]
  /// mounted under the same [RecentColorsScope]. `null` when the
  /// picker is rendered outside any scope — the recent grid is
  /// then hidden and the Save flow falls back to local commit only.
  CoreColorHistoryStorage? _historyStorage;

  /// Tracks the previous open-state so [_handlePopoverStateChange]
  /// can route the closed→open and open→closed transitions
  /// independently.
  bool _wasPopoverOpen = false;

  /// Marks "this close cycle is a Save commit, not a Cancel". Set
  /// by the Save callback before calling `controller.close()` and read
  /// (then reset) by [_handlePopoverClosed] so outside-tap / ESC
  /// closes can be distinguished from explicit Save and apply the
  /// Cancel rollback automatically.
  bool _savedThisCycle = false;

  bool get _isEnabled => widget.enabled ?? true;

  @override
  void initState() {
    super.initState();
    _hexBuffer = _flutterColorToHex(widget.color);
    _committedHex = _hexBuffer;
    _isEmptyBuffer = _isNoColor(widget.color);
    _isEmptyCommitted = _isEmptyBuffer;
    _previousHex = _hexBuffer;
    _activeMode =
        widget.pickerMode ?? CoreColorPickerContract.defaultPickerMode;
    _popoverController.addListener(_handlePopoverStateChange);
  }

  /// Listener fired by [_popoverController] every time the popover
  /// flips open / closed. Closed→open snaps the draft state back to
  /// the last committed value; open→closed routes through
  /// [_handlePopoverClosed] to apply the Cancel rollback when the
  /// close was caused by outside-tap / ESC rather than an explicit
  /// Save.
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

  /// Resets the popover's draft state to the last committed value
  /// just before the popover opens, so reopening always starts from
  /// the committed color (Cancel-then-reopen doesn't keep the
  /// abandoned draft).
  void _handlePopoverOpen() {
    setState(() {
      _hexBuffer = _committedHex;
      _isEmptyBuffer = _isEmptyCommitted;
    });
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
    widget.onChanged?.call(_hexToFlutterColor(hex));
    // Push the just-committed color into the shared recent-colors
    // history (when a [RecentColorsScope] is mounted above us).
    final storage = _historyStorage;
    if (storage != null && isValidHexColor(hex)) {
      storage.addHistory(CoreColor.fromHex(hex));
    }
  }

  void _handleHistoryChange() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-resolve the inherited recent-colors storage on every
    // dependency change. When the scope is moved (e.g. the host app
    // remounts) we drop the old subscription and pick up the new
    // storage so the history grid stays accurate.
    final next = RecentColorsScope.maybeOf(context);
    if (identical(next, _historyStorage)) return;
    _historyStorage?.removeListener(_handleHistoryChange);
    _historyStorage = next;
    _historyStorage?.addListener(_handleHistoryChange);
  }

  @override
  void didUpdateWidget(covariant ColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.color != widget.color) {
      _hexBuffer = _flutterColorToHex(widget.color);
      _isEmptyBuffer = _isNoColor(widget.color);
      if (widget.promptMode == .inline && _hexBuffer != _lastEmittedHex) {
        _committedHex = _hexBuffer;
        _previousHex = _hexBuffer;
      }
    }
    if (oldWidget.pickerMode != widget.pickerMode &&
        widget.pickerMode != null) {
      _activeMode = widget.pickerMode!;
    }
  }

  @override
  void dispose() {
    _historyStorage?.removeListener(_handleHistoryChange);
    _popoverController.removeListener(_handlePopoverStateChange);
    _popoverController.dispose();
    super.dispose();
  }

  /// Inline presentation — the panel drawn in place inside a `Popup` box
  /// (no trigger, no shadow). Every draft change is committed as it
  /// happens, so the panel carries a previous / current comparison cell
  /// instead of Cancel / Save.
  Widget _buildInline(
    ResolvedColorPicker resolved, {
    required bool showAlpha,
    required bool enableEyeDropper,
  }) {
    final panel = Popup(
      popupStyle: resolved.inlinePanelStyle,
      children: [
        _PopoverShell(
          initialHex: _hexBuffer,
          initialMode: _activeMode,
          showAlpha: showAlpha,
          enableEyeDropper: enableEyeDropper,
          dialogTitle: widget.dialogTitle,
          resolved: resolved,
          onDraftChanged: _handleInlineDraft,
          onCancel: () {},
          onSave: _handleInlineDraft,
          previousHex: _previousHex,
          enabled: _isEnabled,
        ),
      ],
    );
    // Disabled — the panel stays in view but takes no input.
    return IgnorePointer(ignoring: !_isEnabled, child: panel);
  }

  /// Commits an inline draft as it happens. Unlike the popover's Save, the
  /// recent-colours history is not touched — a drag would push every step.
  void _handleInlineDraft(String hex) {
    if (!mounted || !_isEnabled) return;
    _lastEmittedHex = hex;
    setState(() {
      _hexBuffer = hex;
      _committedHex = hex;
      _isEmptyBuffer = false;
      _isEmptyCommitted = false;
    });
    widget.onChanged?.call(_hexToFlutterColor(hex));
  }

  @override
  Widget build(BuildContext context) {
    // Resolve composite Style through the Epic #1302 nested-merge chain.
    final resolved = resolveColorPicker(
      context,
      colorPickerStyle: widget.colorPickerStyle,
    );

    // Behaviour bits stay flat on the widget; fall back to the
    // single-source `CoreColorPickerContract.defaultX` constants when the
    // widget-level value is null (project-level behaviour defaults are no
    // longer carried on `CoreColorPickerTheme`).
    final showHex =
        widget.showHexInput ?? CoreColorPickerContract.defaultShowHexInput;
    final showLabel =
        widget.showLabel ?? CoreColorPickerContract.defaultShowLabel;
    final showAlpha =
        widget.showAlpha ?? CoreColorPickerContract.defaultShowAlpha;
    final enableEyeDropper =
        widget.enableEyeDropper ??
        CoreColorPickerContract.defaultEnableEyeDropper;

    final promptMode =
        widget.promptMode ?? CoreColorPickerContract.defaultPromptMode;
    if (promptMode == .inline) {
      return _buildInline(
        resolved,
        showAlpha: showAlpha,
        enableEyeDropper: enableEyeDropper,
      );
    }

    final triggerRow = Row(
      mainAxisSize: .min,
      children: [
        _TriggerField(
          hex: _hexBuffer,
          empty: _isEmptyBuffer,
          enabled: _isEnabled,
          placeholder: widget.placeholder,
          resolved: resolved,
        ),
        if (showHex || showLabel) ...[
          Gap(gapStyle: resolved.swatchGapStyle),
          SizedBox(
            width: resolved.hexInputWidth,
            // Part of this composite: walled off from the enclosing
            // `FormField`, which is shown the composite's own value.
            child: Data<FormFieldHandle>.boundary(
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
                selectAllOnFocus: true,
              ),
            ),
          ),
        ],
      ],
    );

    if (!_isEnabled) {
      // Disabled — don't mount a popover at all so taps stay inert.
      return triggerRow;
    }

    return Popover(
      trigger: triggerRow,
      content: _PopoverShell(
        initialHex: _hexBuffer,
        initialMode: _activeMode,
        showAlpha: showAlpha,
        enableEyeDropper: enableEyeDropper,
        dialogTitle: widget.dialogTitle,
        resolved: resolved,
        // Live-preview: keep the trigger swatch / hex input in sync
        // with the popover draft as the user drags / types. Outer
        // `onChanged` callback fires only on Save.
        onDraftChanged: (hex) => setState(() {
          _hexBuffer = hex;
          _isEmptyBuffer = false;
        }),
        // Cancel — [_handlePopoverClosed] performs the rollback
        // when the popover-state listener fires open→closed; we
        // only need to dismiss here.
        onCancel: _popoverController.close,
        onSave: (hex) {
          _commit(hex);
          _savedThisCycle = true;
          _popoverController.close();
        },
      ),
      controller: _popoverController,
      popoverStyle: resolved.popoverStyle,
    );
  }
}

/// Stateful popover content — owns the local `_draftHex` and
/// `_activeMode` state so every keystroke / drag rebuilds the entire
/// children tree (`StatefulBuilder` inside the outer state didn't
/// rebuild because the closure captured the parent state's
/// `_draftHex`).
class _PopoverShell extends StatefulWidget {
  const _PopoverShell({
    required this.initialHex,
    required this.initialMode,
    required this.showAlpha,
    required this.enableEyeDropper,
    required this.dialogTitle,
    required this.resolved,
    required this.onDraftChanged,
    required this.onCancel,
    required this.onSave,
    this.previousHex,
    this.enabled = true,
  });

  final String initialHex;
  final CoreColorPickerMode initialMode;
  final bool showAlpha;
  final bool enableEyeDropper;
  final Widget? dialogTitle;
  final ResolvedColorPicker resolved;

  /// Live-preview hook: fired on every draft hex change (drag, hue
  /// slider, mode input edit) so the trigger swatch / hex field stay
  /// in sync. Outer state should NOT call user's `onChanged` from
  /// here — only on Save.
  final ValueChanged<String> onDraftChanged;

  final VoidCallback onCancel;
  final ValueChanged<String> onSave;

  /// The colour the inline presentation compares the draft with. Non-null
  /// only for the inline presentation, which shows the comparison cell in
  /// place of Cancel / Save.
  final String? previousHex;

  /// Whether the panel's inputs take input — false only for a disabled
  /// inline picker, whose panel stays in view.
  final bool enabled;

  @override
  State<_PopoverShell> createState() => _PopoverShellState();
}

class _PopoverShellState extends State<_PopoverShell> {
  late String _draftHex;
  late CoreColorPickerMode _activeMode;

  /// Hue is tracked separately from [_draftHex] because pure
  /// black / white / gray have undefined hue (saturation == 0). If we
  /// derived hue from hex on every paint, tapping the white corner of
  /// the 2D area would reset the hue gradient to red — making the
  /// area's background swing wildly between every drag step. This
  /// state holds the last user-selected hue (from the hue slider or
  /// from a 2D drag where saturation > 0) and only that drives the
  /// 2D area's right-edge gradient.
  late double _hue;

  @override
  void initState() {
    super.initState();
    _draftHex = widget.initialHex;
    _activeMode = widget.initialMode;
    final rgb = hexToRgb(widget.initialHex);
    _hue = rgbToHsv(r: rgb.r, g: rgb.g, b: rgb.b).h;
  }

  @override
  void didUpdateWidget(covariant _PopoverShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Inline: the panel lives as long as the picker, so a colour the caller
    // hands in (rather than one this panel drafted) resets the draft.
    if (widget.previousHex != null &&
        widget.initialHex != oldWidget.initialHex &&
        widget.initialHex != _draftHex) {
      _draftHex = widget.initialHex;
      final rgb = hexToRgb(widget.initialHex);
      final hsv = rgbToHsv(r: rgb.r, g: rgb.g, b: rgb.b);
      if (hsv.s > 0) _hue = hsv.h;
    }
  }

  void _handleSatValDraft(String hex) {
    if (!mounted || !widget.enabled) return;
    setState(() => _draftHex = hex);
    widget.onDraftChanged(hex);
  }

  void _handleHueDraft(double newHue, String hex) {
    if (!mounted || !widget.enabled) return;
    setState(() {
      _hue = newHue;
      _draftHex = hex;
    });
    widget.onDraftChanged(hex);
  }

  void _handleInputDraft(String hex) {
    if (!mounted || !widget.enabled) return;
    final rgb = hexToRgb(hex);
    final hsv = rgbToHsv(r: rgb.r, g: rgb.g, b: rgb.b);
    setState(() {
      _draftHex = hex;
      // Only adopt the new hue when the colour is chromatic enough to
      // have a meaningful one (avoids hue jumps on grayscale input).
      if (hsv.s > 0) _hue = hsv.h;
    });
    widget.onDraftChanged(hex);
  }

  void _handleModeChanged(CoreColorPickerMode mode) {
    if (!mounted || !widget.enabled || mode == _activeMode) return;
    setState(() => _activeMode = mode);
  }

  Future<void> _handlePickWithEyeDropper() async {
    if (!mounted || !widget.enabled || !isEyeDropperSupported) {
      return;
    }
    final hex = await pickColorWithEyeDropper();
    if (!mounted || !widget.enabled) return;
    if (hex != null && isValidHexColor(hex)) {
      _handleInputDraft(normalizeHexColor(hex));
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolved = widget.resolved;
    // Nullable — `null` means the picker is mounted outside any
    // [RecentColorsScope]. The grid section is then omitted, matching
    // the Web behavior.
    final historyStorage = RecentColorsScope.maybeOf(context);

    // The outer panel chrome (border / shadow / radius / background)
    // is owned by [Popover] itself — this widget only emits the
    // vertical column of picker sections. Adding our own
    // `_PopoverContent` here would double-stack borders / radius and
    // diverge from the Web rendering.
    return SizedBox(
      width: resolved.popoverWidth,
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        // `Column.spacing` consumes a raw double — the resolver already
        // resolved the per-instance override / default so the widget
        // reads `resolved.popoverSpacing` directly (no manual Gap
        // interleave).
        spacing: resolved.popoverSpacing,
        children: [
          ?widget.dialogTitle,
          _ModeTabs(
            onChanged: _handleModeChanged,
            active: _activeMode,
            enabled: widget.enabled,
            toggleGroupStyle: resolved.modeTabsStyle,
          ),
          _SaturationValueArea(
            onChanged: _handleSatValDraft,
            hex: _draftHex,
            hue: _hue,
            size: resolved.popoverWidth,
            borderRadius: resolved.saturationValueBorderRadius,
            pickMarkerSize: resolved.pickMarkerSize,
            handleRingColor: resolved.pickMarkerBorderColor,
            handleRingWidth: resolved.pickMarkerBorderWidth,
            handleShadow: resolved.pickMarkerShadow,
          ),
          _HueSlider(
            onChanged: _handleHueDraft,
            hex: _draftHex,
            hue: _hue,
            barHeight: resolved.sliderHeight,
            pickMarkerSize: resolved.pickMarkerSize,
            handleFillColor: _hexToFlutterColor(_draftHex),
            handleRingColor: resolved.hueMarkerBorderColor,
            handleRingWidth: resolved.hueMarkerBorderWidth,
            handleShadow: resolved.pickMarkerShadow,
            borderRadius: resolved.sliderBorderRadius,
          ),
          if (widget.showAlpha)
            _AlphaSlider(
              hex: _draftHex,
              height: resolved.sliderHeight,
              borderRadius: resolved.sliderBorderRadius,
            ),
          _ModeInputs(
            onChanged: _handleInputDraft,
            mode: _activeMode,
            hex: _draftHex,
            resolved: resolved,
            enabled: widget.enabled,
          ),
          if (historyStorage != null)
            _RecentColorsGrid(
              storage: historyStorage,
              activeHex: _draftHex,
              onPicked: _handleInputDraft,
              enabled: widget.enabled,
              resolved: resolved,
            ),
          _ActionRow(
            enableEyeDropper: widget.enableEyeDropper,
            enabled: widget.enabled,
            onCancel: widget.onCancel,
            onSave: () {
              if (!mounted || !widget.enabled) return;
              widget.onSave(_draftHex);
            },
            onPickEyeDropper: () => unawaited(_handlePickWithEyeDropper()),
            resolved: resolved,
            previousHex: widget.previousHex,
            currentHex: _draftHex,
          ),
        ],
      ),
    );
  }
}

/// The field-shaped trigger — the swatch, the picked hex (or the
/// placeholder when no colour is picked) and a chevron, inside one outlined
/// field box at least [ResolvedColorPicker.triggerMinWidth] wide.
class _TriggerField extends StatelessWidget {
  const _TriggerField({
    required this.hex,
    required this.empty,
    required this.enabled,
    required this.placeholder,
    required this.resolved,
  });

  final String hex;
  final bool empty;
  final bool enabled;

  /// Caller-supplied placeholder, shown instead of the localized one.
  final Widget? placeholder;
  final ResolvedColorPicker resolved;

  @override
  Widget build(BuildContext context) {
    final label = empty
        ? DefaultTextStyle.merge(
            style: resolved.triggerPlaceholderTextStyle,
            maxLines: 1,
            overflow: .ellipsis,
            child:
                placeholder ??
                Text(CoUILocalizations.of(context).colorPickerPlaceholder),
          )
        : Text(
            hex,
            style: resolved.triggerValueTextStyle,
            maxLines: 1,
            overflow: .ellipsis,
          );
    return IntrinsicWidth(
      child: Container(
        constraints: BoxConstraints(minWidth: resolved.triggerMinWidth),
        padding: resolved.triggerPadding,
        decoration: BoxDecoration(
          color: resolved.triggerBackgroundColor,
          border: Border.all(
            color: resolved.triggerBorderColor,
            width: resolved.triggerBorderWidth,
          ),
          borderRadius: resolved.triggerBorderRadius,
        ),
        child: Row(
          spacing: resolved.triggerSpacing,
          children: [
            _Swatch(
              hex: hex,
              empty: empty,
              dashLength: resolved.emptySwatchDashLength,
              dashSpacing: resolved.emptySwatchDashSpacing,
              size: resolved.swatchSize,
              borderColor: resolved.borderColor,
              disabledBorderColor: resolved.disabledBorderColor,
              borderWidth: resolved.borderWidth,
              borderRadius: resolved.swatchBorderRadius,
              enabled: enabled,
            ),
            Expanded(child: label),
            Icon(
              LucideIcons.chevronDown,
              iconStyle: resolved.triggerChevronIconStyle,
            ),
          ],
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.hex,
    required this.empty,
    required this.dashLength,
    required this.dashSpacing,
    required this.size,
    required this.borderColor,
    required this.disabledBorderColor,
    required this.borderWidth,
    required this.borderRadius,
    required this.enabled,
  });

  final String hex;

  /// Paint the empty ("no colour") swatch — a dashed outline, no fill —
  /// instead of [hex].
  final bool empty;
  final double dashLength;
  final double dashSpacing;
  final double size;
  final Color borderColor;
  final Color disabledBorderColor;
  final double borderWidth;
  final BorderRadius borderRadius;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final swatchColor = isValidHexColor(hex)
        ? _hexToFlutterColor(hex)
        : _hexToFlutterColor(_kFallbackHex);
    final edgeColor = enabled ? borderColor : disabledBorderColor;
    // The swatch is a passive visual trigger — click / focus
    // handling is owned by [Popover] (when enabled). The
    // `MouseRegion` cursor stays so hover affordance still reads
    // as interactive.
    //
    // #3469 — this used to have no disabled treatment at all: same
    // border colour, same opacity, only the cursor changed (invisible
    // without hovering). The border now gets the dedicated
    // `disabledBorderColor` token; the fill keeps an opacity multiplier
    // (mirrors the Web resolver) because it shows an arbitrary
    // user-picked colour with no dedicated "disabled" substitute to
    // give it instead — the one case design-tokens.md still allows a
    // multiplier for.
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: Opacity(
        // The empty swatch has no fill to dim — its dashes already take the
        // disabled border colour.
        opacity: enabled || empty
            ? 1
            : CoreClickableStyle.defaultDisabledOpacity,
        child: SizedBox.square(
          dimension: size,
          child: empty
              ? CustomPaint(
                  painter: _DashedOutlinePainter(
                    color: edgeColor,
                    strokeWidth: borderWidth,
                    borderRadius: borderRadius,
                    dashLength: dashLength,
                    dashSpacing: dashSpacing,
                  ),
                )
              : DecoratedBox(
                  decoration: BoxDecoration(
                    color: swatchColor,
                    border: Border.all(color: edgeColor, width: borderWidth),
                    borderRadius: borderRadius,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Paints the empty swatch's dashed rounded-rect outline.
class _DashedOutlinePainter extends CustomPainter {
  const _DashedOutlinePainter({
    required this.color,
    required this.strokeWidth,
    required this.borderRadius,
    required this.dashLength,
    required this.dashSpacing,
  });

  final Color color;
  final double strokeWidth;
  final BorderRadius borderRadius;
  final double dashLength;
  final double dashSpacing;

  @override
  void paint(Canvas canvas, Size size) {
    // A stroke is centred on its path. Keep the complete declared width
    // inside the allocated border box, as Border.all and the Web SVG do.
    final rrect = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, 0, size.width, size.height),
      topLeft: borderRadius.topLeft,
      topRight: borderRadius.topRight,
      bottomRight: borderRadius.bottomRight,
      bottomLeft: borderRadius.bottomLeft,
    ).deflate(strokeWidth / 2);
    final r = rrect.scaleRadii();
    // SVG rect starts at the top-left tangent and travels clockwise.
    // addRRect starts elsewhere, which shifts every dash despite equal tokens.
    final path = Path()
      ..moveTo(r.left + r.tlRadiusX, r.top)
      ..lineTo(r.right - r.trRadiusX, r.top)
      ..arcToPoint(Offset(r.right, r.top + r.trRadiusY), radius: r.trRadius)
      ..lineTo(r.right, r.bottom - r.brRadiusY)
      ..arcToPoint(Offset(r.right - r.brRadiusX, r.bottom), radius: r.brRadius)
      ..lineTo(r.left + r.blRadiusX, r.bottom)
      ..arcToPoint(Offset(r.left, r.bottom - r.blRadiusY), radius: r.blRadius)
      ..lineTo(r.left, r.top + r.tlRadiusY)
      ..arcToPoint(Offset(r.left + r.tlRadiusX, r.top), radius: r.tlRadius)
      ..close();
    final draw = Path();
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = .butt
      ..style = .stroke;
    for (final metric in path.computeMetrics()) {
      var i = 0.0;
      while (i < metric.length) {
        final end = (i + dashLength).clamp(0.0, metric.length);
        final a = metric.getTangentForOffset(i)!;
        final b = metric.getTangentForOffset(end)!;
        final delta = b.position - a.position;
        // Straight dashes have no joins. Use the line primitive for them;
        // keep the extracted contour whenever a dash crosses a corner.
        final straight =
            a.vector == b.vector &&
            ((delta.dy == 0 &&
                    a.vector.dy == 0 &&
                    end - i <= r.width &&
                    delta.dx * a.vector.dx > 0) ||
                (delta.dx == 0 &&
                    a.vector.dx == 0 &&
                    end - i <= r.height &&
                    delta.dy * a.vector.dy > 0));
        if (straight) {
          canvas.drawLine(a.position, b.position, paint);
        } else {
          draw.addPath(metric.extractPath(i, end), .zero);
        }
        i += dashLength + dashSpacing;
      }
    }
    canvas.drawPath(
      draw,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _DashedOutlinePainter old) =>
      color != old.color ||
      strokeWidth != old.strokeWidth ||
      borderRadius != old.borderRadius ||
      dashLength != old.dashLength ||
      dashSpacing != old.dashSpacing;
}

class _ModeTabs extends StatelessWidget {
  const _ModeTabs({
    required this.active,
    required this.enabled,
    required this.onChanged,
    required this.toggleGroupStyle,
  });

  final CoreColorPickerMode active;
  final bool enabled;
  final ValueChanged<CoreColorPickerMode> onChanged;
  final CoreToggleGroupStyle toggleGroupStyle;

  @override
  Widget build(BuildContext context) {
    final l10n = CoUILocalizations.of(context);
    // The shared grouped toggle — one track, the chosen mode a raised
    // face. Same component the Filter segments and the time picker's
    // AM / PM compose.
    return ToggleGroup<CoreColorPickerMode>(
      value: active,
      enabled: enabled,
      onChanged: onChanged,
      toggleGroupStyle: toggleGroupStyle,
      size: CoreColorPickerContract.defaultModeTabsSize,
      // The tabs span the panel, matching the full-width colour area and
      // inputs below; the three modes split the track equally.
      fillWidth: true,
      items: [
        for (final mode in _kPickerModeOrder)
          CoreToggleGroupItem<CoreColorPickerMode, Widget>(
            value: mode,
            label: _pickerModeLabel(l10n, mode),
          ),
      ],
    );
  }
}

/// Round handle marking the picked point on the saturation/value area and
/// the hue bar — a [size] disc in the picked colour with a ring.
class _PickerHandle extends StatelessWidget {
  const _PickerHandle({
    required this.color,
    required this.size,
    required this.ringColor,
    required this.ringWidth,
    required this.shadow,
  });

  final Color color;
  final double size;
  final Color ringColor;
  final double ringWidth;
  final List<BoxShadow> shadow;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          shape: .circle,
          border: Border.all(color: ringColor, width: ringWidth),
          boxShadow: shadow,
        ),
        child: SizedBox.square(dimension: size),
      ),
    );
  }
}

class _SaturationValueArea extends StatelessWidget {
  const _SaturationValueArea({
    required this.hex,
    required this.hue,
    required this.onChanged,
    required this.size,
    required this.borderRadius,
    required this.pickMarkerSize,
    required this.handleRingColor,
    required this.handleRingWidth,
    required this.handleShadow,
  });

  final String hex;
  final double hue;
  final ValueChanged<String> onChanged;
  final BorderRadius borderRadius;
  final double pickMarkerSize;
  final Color handleRingColor;
  final double handleRingWidth;
  final List<BoxShadow> handleShadow;

  /// Fixed square side (the popover's content width). Replaces a bare
  /// `AspectRatio` so the area reports concrete intrinsic dimensions: the
  /// inner `LayoutBuilder` / gradient `SizedBox.expand` can't be measured
  /// for intrinsics, and `Popup`'s `IntrinsicWidth` (content-width panel)
  /// would otherwise throw — hiding the whole popover.
  final double size;

  @override
  Widget build(BuildContext context) {
    final rgb = hexToRgb(hex);
    final hsv = rgbToHsv(r: rgb.r, g: rgb.g, b: rgb.b);
    final maxPercent = kColorPickerChannelMaxPercent.toDouble();
    return SizedBox.square(
      dimension: size,
      child: LayoutBuilder(
        builder: (innerContext, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          void handlePan(Offset local) {
            if (w <= 0 || h <= 0) return;
            final s = (local.dx / w * maxPercent).clamp(0.0, maxPercent);
            final v = ((1 - local.dy / h) * maxPercent).clamp(0.0, maxPercent);
            final next = hsvToRgb(h: hue, s: s, v: v);
            onChanged(rgbToHex(r: next.r, g: next.g, b: next.b));
          }

          // `precise` (crosshair) cursor mirrors the Web SV area
          // — picker convention is that the 2D color sampler shows
          // a crosshair so users know it's a precise-pick surface.
          return MouseRegion(
            cursor: SystemMouseCursors.precise,
            child: GestureDetector(
              onPanDown: (d) => handlePan(d.localPosition),
              onPanUpdate: (d) => handlePan(d.localPosition),
              behavior: .opaque,
              // The area draws no border; the V-axis veil sits inside the
              // rounded clip, so the corners stay clean.
              child: Stacks(
                clipBehavior: .none,
                children: [
                  Position.fill(
                    child: ClipRRect(
                      borderRadius: borderRadius,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white,
                              HSVColor.fromAHSV(1, hue, 1, 1).toColor(),
                            ],
                          ),
                        ),
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: .topCenter,
                              end: .bottomCenter,
                              colors: [Colors.transparent, Colors.black],
                            ),
                          ),
                          child: SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                  Position(
                    left:
                        (hsv.s / maxPercent).clamp(0.0, 1.0) * w -
                        pickMarkerSize / 2,
                    top:
                        (1 - hsv.v / maxPercent).clamp(0.0, 1.0) * h -
                        pickMarkerSize / 2,
                    child: _PickerHandle(
                      color: _hexToFlutterColor(hex),
                      size: pickMarkerSize,
                      ringColor: handleRingColor,
                      ringWidth: handleRingWidth,
                      shadow: handleShadow,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HueSlider extends StatelessWidget {
  const _HueSlider({
    required this.hex,
    required this.hue,
    required this.onChanged,
    required this.barHeight,
    required this.pickMarkerSize,
    required this.handleFillColor,
    required this.handleRingColor,
    required this.handleRingWidth,
    required this.handleShadow,
    required this.borderRadius,
  });

  static const _hueColors = [
    Color(0xFFFF0000),
    Color(0xFFFFFF00),
    Color(0xFF00FF00),
    Color(0xFF00FFFF),
    Color(0xFF0000FF),
    Color(0xFFFF00FF),
    Color(0xFFFF0000),
  ];
  final String hex;
  final double hue;

  /// Reports the new hue and the resulting hex (recomputed by holding
  /// the current S/V from the draft hex constant).
  final void Function(double hue, String hex) onChanged;

  /// Height of the gradient bar (the 8px track).
  final double barHeight;

  /// Side of the round handle; the slider's hit box is this tall, the bar
  /// is centred in it.
  final double pickMarkerSize;

  /// The hue handle is filled with the current colour, like the
  /// saturation handle.
  final Color handleFillColor;
  final Color handleRingColor;
  final double handleRingWidth;
  final List<BoxShadow> handleShadow;

  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final rgb = hexToRgb(hex);
    final hsv = rgbToHsv(r: rgb.r, g: rgb.g, b: rgb.b);
    final maxHue = kColorPickerChannelMaxHue.toDouble();
    return SizedBox(
      height: math.max(pickMarkerSize, barHeight),
      child: LayoutBuilder(
        builder: (innerContext, constraints) {
          final w = constraints.maxWidth;
          void handlePan(Offset local) {
            if (w <= 0) return;
            // Hue is a half-open circle `[0, 360)` — clamp the upper
            // bound just below the wrap-around point.
            final newHue = (local.dx / w * maxHue).clamp(0.0, maxHue - 1);
            final next = hsvToRgb(h: newHue, s: hsv.s, v: hsv.v);
            onChanged(
              newHue,
              rgbToHex(r: next.r, g: next.g, b: next.b),
            );
          }

          // `resizeLeftRight` (↔) cursor mirrors the Web hue
          // slider's `cursor-ew-resize` — picker convention is that
          // a horizontal hue strip reads as a 1D drag handle.
          return MouseRegion(
            cursor: SystemMouseCursors.resizeLeftRight,
            child: GestureDetector(
              onPanDown: (d) => handlePan(d.localPosition),
              onPanUpdate: (d) => handlePan(d.localPosition),
              behavior: .opaque,
              child: Stacks(
                alignment: .center,
                clipBehavior: .none,
                children: [
                  SizedBox(
                    height: barHeight,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: borderRadius,
                        gradient: const LinearGradient(
                          colors: _hueColors,
                        ),
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  Position(
                    left:
                        (hue / maxHue).clamp(0.0, 1.0) * w - pickMarkerSize / 2,
                    top: 0,
                    child: _PickerHandle(
                      color: handleFillColor,
                      size: pickMarkerSize,
                      ringColor: handleRingColor,
                      ringWidth: handleRingWidth,
                      shadow: handleShadow,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AlphaSlider extends StatelessWidget {
  const _AlphaSlider({
    required this.hex,
    required this.height,
    required this.borderRadius,
  });

  final String hex;
  final double height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              if (isValidHexColor(hex))
                _hexToFlutterColor(hex)
              else
                _hexToFlutterColor(_kFallbackHex),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mode-specific numeric inputs that drive the popover's draft hex.
/// Mirrors the Web mode inputs — RGB / HSL / HSV triplet flips
/// with the active tab and edits flow back through `CoreColorMath`.
class _ModeInputs extends StatelessWidget {
  const _ModeInputs({
    required this.mode,
    required this.hex,
    required this.onChanged,
    required this.resolved,
    this.enabled = true,
  });

  final CoreColorPickerMode mode;
  final String hex;
  final ValueChanged<String> onChanged;
  final ResolvedColorPicker resolved;
  final bool enabled;

  void _handleEdit(int channel, int value) {
    onChanged(
      applyColorPickerChannelEdit(
        mode: mode,
        hex: hex,
        channel: channel,
        value: value,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final triplet = colorPickerTriplet(mode, hex);
    // `Row.spacing` consumes a raw double — the resolver already
    // applied the per-instance override / default so the widget reads
    // `resolved.modeInputSpacing` directly (no manual Gap interleave).
    return Row(
      spacing: resolved.modeInputSpacing,
      children: [
        Expanded(
          flex: resolved.modeHexInputFlex,
          child: _HexInputCell(
            hex: hex,
            labelGapStyle: resolved.modeInputLabelGapStyle,
            labelTextStyle: resolved.modeInputLabelTextStyle,
            onChanged: onChanged,
            enabled: enabled,
          ),
        ),
        Expanded(
          child: _ModeInputCell(
            label: triplet.labels.$1,
            value: triplet.values.$1,
            max: triplet.max.$1,
            labelGapStyle: resolved.modeInputLabelGapStyle,
            labelTextStyle: resolved.modeInputLabelTextStyle,
            enabled: enabled,
            onSubmitted: (v) => _handleEdit(0, v),
          ),
        ),
        Expanded(
          child: _ModeInputCell(
            label: triplet.labels.$2,
            value: triplet.values.$2,
            max: triplet.max.$2,
            labelGapStyle: resolved.modeInputLabelGapStyle,
            labelTextStyle: resolved.modeInputLabelTextStyle,
            enabled: enabled,
            onSubmitted: (v) => _handleEdit(1, v),
          ),
        ),
        Expanded(
          child: _ModeInputCell(
            label: triplet.labels.$3,
            value: triplet.values.$3,
            max: triplet.max.$3,
            labelGapStyle: resolved.modeInputLabelGapStyle,
            labelTextStyle: resolved.modeInputLabelTextStyle,
            enabled: enabled,
            onSubmitted: (v) => _handleEdit(2, v),
          ),
        ),
      ],
    );
  }
}

class _ModeInputCell extends StatelessWidget {
  const _ModeInputCell({
    required this.enabled,
    required this.label,
    required this.value,
    required this.max,
    required this.labelGapStyle,
    required this.labelTextStyle,
    required this.onSubmitted,
  });

  final String label;
  final int value;
  final int max;
  final CoreGapStyle labelGapStyle;
  final TextStyle labelTextStyle;
  final ValueChanged<int> onSubmitted;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    // `crossAxisAlignment: .stretch` so the label and input field
    // both fill the cell width — matches the Web flex-col + flex-1
    // layout where the input grows to occupy the cell.
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Center(child: Text(label, style: labelTextStyle)),
        Gap(gapStyle: labelGapStyle),
        // Part of this composite: walled off from the enclosing
        // `FormField`, which is shown the composite's own value.
        Data<FormFieldHandle>.boundary(
          child: TextField(
            key: ValueKey('$label-$value'),
            onChanged: (raw) {
              final parsed = int.tryParse(raw);
              if (parsed == null) return;
              onSubmitted(parsed.clamp(0, max));
            },
            initialValue: '$value',
            enabled: enabled,
            textFieldStyle: const CoreTextFieldStyle(textAlign: .center),
            size: CoreColorPickerContract.defaultModeInputSize,
            maxLength: max.toString().length,
            selectAllOnFocus: true,
            keyboardType: .number,
          ),
        ),
      ],
    );
  }
}

/// The HEX cell at the head of the panel's input row — the same caption +
/// field stack as a channel cell, editing the whole `#RRGGBB` value.
class _HexInputCell extends StatelessWidget {
  const _HexInputCell({
    required this.enabled,
    required this.hex,
    required this.labelGapStyle,
    required this.labelTextStyle,
    required this.onChanged,
  });

  final String hex;
  final CoreGapStyle labelGapStyle;
  final TextStyle labelTextStyle;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Center(child: Text(kColorPickerHexLabel, style: labelTextStyle)),
        Gap(gapStyle: labelGapStyle),
        // Part of this composite: walled off from the enclosing
        // `FormField`, which is shown the composite's own value.
        Data<FormFieldHandle>.boundary(
          child: TextField(
            key: ValueKey('hex-$hex'),
            onChanged: (raw) {
              final normalized = raw.startsWith('#') ? raw : '#$raw';
              if (isValidHexColor(normalized)) {
                onChanged(normalizeHexColor(normalized));
              }
            },
            initialValue: hex,
            enabled: enabled,
            size: CoreColorPickerContract.defaultModeInputSize,
            maxLength: _kHexInputMaxLength,
            selectAllOnFocus: true,
          ),
        ),
      ],
    );
  }
}

/// Recent-colors swatch grid embedded inside the popover. Reads
/// `storage.recentColors` (kept fresh by [_PopoverShellState]'s
/// rebuild on [_PopoverShellState.build] re-resolve) and maps each
/// entry to a small square button. Tapping a swatch routes through
/// [onPicked] which forwards to the picker's
/// `_handleInputDraft` — the user still has to press Save to push
/// the (possibly re-edited) color back into history.
///
/// Geometry is sourced from [ResolvedColorPicker] —
/// `recentSwatchSize`, `recentSwatchSpacing`, `recentColumns` — so
/// Flutter and Web swatch grids stay dimensionally aligned.
class _RecentColorsGrid extends StatelessWidget {
  const _RecentColorsGrid({
    required this.storage,
    required this.enabled,
    required this.activeHex,
    required this.onPicked,
    required this.resolved,
  });

  final CoreColorHistoryStorage storage;
  final bool enabled;
  final String activeHex;
  final ValueChanged<String> onPicked;
  final ResolvedColorPicker resolved;

  @override
  Widget build(BuildContext context) {
    final history = storage.recentColors;
    if (history.isEmpty) return const SizedBox.shrink();
    final activeNormalized = isValidHexColor(activeHex)
        ? normalizeHexColor(activeHex)
        : '';
    // One row, never wrapped: the newest `recentColumns` colours, under the
    // section title.
    final swatches = Row(
      spacing: resolved.recentSwatchSpacing,
      children: [
        for (final color in history.take(resolved.recentColumns))
          _RecentSwatch(
            onTap: () => onPicked(color.toHex()),
            enabled: enabled,
            color: color,
            size: resolved.recentSwatchSize,
            isSelected: color.toHex() == activeNormalized,
            outlineColor: resolved.borderColor,
            primaryColor: resolved.selectedRingColor,
            borderRadius: resolved.recentSwatchBorderRadius,
            clickableStyle: resolved.recentSwatchClickableStyle,
            borderWidth: resolved.recentSwatchBorderWidth,
            selectedBorderWidth: resolved.recentSwatchSelectedBorderWidth,
          ),
      ],
    );
    return Column(
      crossAxisAlignment: .start,
      children: [
        Text(
          CoUILocalizations.of(context).colorPickerRecentTitle,
          style: resolved.recentTitleTextStyle,
        ),
        Gap(gapStyle: resolved.recentTitleGapStyle),
        swatches,
      ],
    );
  }
}

class _RecentSwatch extends StatelessWidget {
  const _RecentSwatch({
    required this.onTap,
    required this.enabled,
    required this.color,
    required this.size,
    required this.isSelected,
    required this.outlineColor,
    required this.primaryColor,
    required this.borderRadius,
    required this.clickableStyle,
    required this.borderWidth,
    required this.selectedBorderWidth,
  });

  final VoidCallback onTap;
  final bool enabled;
  final CoreColor color;
  final double size;
  final bool isSelected;
  final Color outlineColor;
  final Color primaryColor;
  final BorderRadius borderRadius;
  final CoreClickableStyle clickableStyle;
  final double borderWidth;
  final double selectedBorderWidth;

  @override
  Widget build(BuildContext context) {
    // The recent-color swatch composes Clickable — tap / keyboard
    // activation / cursor / press feedback / focus ring (which now gives
    // each swatch keyboard access) flow through the single interaction
    // primitive, mirroring the Web swatch (no hand-rolled MouseRegion +
    // GestureDetector).
    return Clickable(
      onPressed: onTap,
      enabled: enabled,
      clickableStyle: clickableStyle,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.resolve(color).toValue(),
          border: Border.all(
            color: isSelected ? primaryColor : outlineColor,
            width: isSelected ? selectedBorderWidth : borderWidth,
          ),
          borderRadius: borderRadius,
        ),
        width: size,
        height: size,
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.enableEyeDropper,
    required this.enabled,
    required this.onCancel,
    required this.onSave,
    required this.onPickEyeDropper,
    required this.resolved,
    this.previousHex,
    this.currentHex,
  });

  final bool enableEyeDropper;
  final bool enabled;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  /// The stateful shell owns the request and checks its current enabled
  /// state when the host returns, rather than this old row configuration.
  final VoidCallback onPickEyeDropper;

  final ResolvedColorPicker resolved;

  /// Inline presentation only: the colour before the inline edits. When
  /// non-null the row ends with the previous / current comparison cell
  /// instead of Cancel / Save.
  final String? previousHex;

  /// Inline presentation only: the current draft colour.
  final String? currentHex;

  /// Hides the EyeDropper button entirely on platforms where the
  /// browser doesn't expose `window.EyeDropper` (Firefox / Safari /
  /// every native target). Keeps the action row consistent across
  /// support tiers — no dead button.
  bool get _showEyeDropper => enableEyeDropper && isEyeDropperSupported;

  @override
  Widget build(BuildContext context) {
    final l10n = CoUILocalizations.of(context);
    return Row(
      children: [
        // Icon-only, unlike its Cancel / Save siblings whose `Text` children
        // name them. Same key as the Web twin.
        if (_showEyeDropper)
          Semantics(
            button: true,
            label: CoUILocalizations.of(context).colorPickerEyeDropper,
            child: Button(
              onPressed: onPickEyeDropper,
              enabled: enabled,
              variant: .ghost,
              size: .sm,
              child: Icon(
                LucideIcons.pipette,
                iconStyle: resolved.eyeDropperIconStyle,
              ),
            ),
          ),
        const Spacer(),
        if (previousHex case final previous?)
          _CompareCell(
            previousHex: previous,
            currentHex: currentHex ?? previous,
            resolved: resolved,
          )
        else ...[
          Button(
            onPressed: onCancel,
            enabled: enabled,
            variant: .ghost,
            size: .sm,
            // Bind label colour to the variant token explicitly so the
            // Web parity holds (Web's text-inherit otherwise picks up
            // the popover panel's colour instead of the button's own).
            child: Text(l10n.buttonCancel).bodySmall.onSurface,
          ),
          Gap(gapStyle: resolved.actionRowGapStyle),
          Button(
            onPressed: onSave,
            enabled: enabled,
            size: .sm,
            // Default variant is `.primary` — bind label colour to
            // `onPrimary` for the same reason (see Cancel).
            child: Text(l10n.buttonSave).bodySmall.onPrimary,
          ),
        ],
      ],
    );
  }
}

/// The inline presentation's previous / current comparison cell — two
/// square halves inside one outlined, rounded box.
class _CompareCell extends StatelessWidget {
  const _CompareCell({
    required this.previousHex,
    required this.currentHex,
    required this.resolved,
  });

  final String previousHex;
  final String currentHex;
  final ResolvedColorPicker resolved;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: resolved.compareBorderColor,
          width: resolved.compareBorderWidth,
        ),
        borderRadius: resolved.compareBorderRadius,
      ),
      clipBehavior: .antiAlias,
      child: Row(
        mainAxisSize: .min,
        children: [
          SizedBox.square(
            dimension: resolved.compareSwatchSize,
            child: ColoredBox(color: _hexToFlutterColor(previousHex)),
          ),
          SizedBox.square(
            dimension: resolved.compareSwatchSize,
            child: ColoredBox(color: _hexToFlutterColor(currentHex)),
          ),
        ],
      ),
    );
  }
}

/// Chain sugar for merging a [CoreColorPickerStyle] patch into
/// [ColorPicker.colorPickerStyle] without hand-reconstructing every
/// field. Mirrors the Web `ColorPicker.withStyle` extension so both
/// platforms read identically.
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
