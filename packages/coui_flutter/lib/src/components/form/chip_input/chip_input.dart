import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/components/form/chip_input/chip_input_wrap.dart';
import 'package:flutter/services.dart'
    show Clipboard, PointerEnterEvent, PointerExitEvent;

/// Unified cross-platform chip input with token-based rendering.
///
/// `ChipInput` is a multi-value text input — users type text and press
/// Enter to add chips; each chip carries a remove button. The chip list
/// is a `List<String>` so the API is identical on Flutter and Web.
///
/// Per Epic #1302 all chrome / dimensional overrides flow through the
/// single [chipInputStyle] (a [CoreChipInputStyle]). The nested-merge
/// chain:
///
/// ```text
/// design system default
///   → CoreChipInputTheme.style
///   → parent component slot override
///   → widget.chipInputStyle
/// ```
///
/// Example:
/// ```dart
/// ChipInput(
///   chips: tags,
///   placeholder: 'Add a tag...',
///   onChanged: (chips) => setState(() => tags = chips),
/// )
/// ```
///
/// surface:behind — the frame paints its own box directly rather than
/// composing `OutlinedContainer` (the inline entry field is deliberately
/// chromeless so the frame owns the single visible boundary), so what
/// shows through it is the page it is laid on.
///
/// surface:content — a face in the content layer alongside cards and
/// body panels.
class ChipInput extends StatefulWidget
    implements
        CoreChipInputContract<
          ValueChanged<List<String>>?,
          ValueChanged<String>?
        > {
  /// Creates a [ChipInput].
  const ChipInput({
    super.key,
    this.chips = const [],
    this.placeholder,
    this.enabled = true,
    this.maxChips,
    this.onChanged,
    this.onSubmitted,
    this.pasteSplitter,
    this.chipInputStyle,
  });

  @override
  final List<String> chips;

  @override
  final String? placeholder;

  @override
  final bool enabled;

  @override
  final int? maxChips;

  @override
  final ValueChanged<List<String>>? onChanged;

  @override
  final ValueChanged<String>? onSubmitted;

  /// Splits pasted text into chips. `null` leaves paste untouched.
  ///
  /// The intercept is installed only when this is non-null — see
  /// [_ChipInputState._buildEntryField] for why an always-on override
  /// would break ordinary pasting.
  @override
  final List<String> Function(String pasted)? pasteSplitter;

  @override
  final CoreChipInputStyle? chipInputStyle;

  /// Returns a copy of this [ChipInput] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  ChipInput copyWith({
    Key? key,
    ValueChanged<List<String>>? onChanged,
    List<String>? chips,
    String? placeholder,
    bool? enabled,
    int? maxChips,
    ValueChanged<String>? onSubmitted,
    List<String> Function(String pasted)? pasteSplitter,
    CoreChipInputStyle? chipInputStyle,
  }) {
    return ChipInput(
      key: key ?? this.key,
      onChanged: onChanged ?? this.onChanged,
      chips: chips ?? this.chips,
      placeholder: placeholder ?? this.placeholder,
      enabled: enabled ?? this.enabled,
      maxChips: maxChips ?? this.maxChips,
      onSubmitted: onSubmitted ?? this.onSubmitted,
      pasteSplitter: pasteSplitter ?? this.pasteSplitter,
      chipInputStyle: chipInputStyle ?? this.chipInputStyle,
    );
  }

  @override
  State<ChipInput> createState() => _ChipInputState();
}

class _ChipInputState extends State<ChipInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;
  bool _hovered = false;

  bool get _canAddMore =>
      widget.maxChips == null || widget.chips.length < widget.maxChips!;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChanged);
    // Inline-field self-sizing — the field width follows the typed
    // text (or the placeholder when empty), so rebuild on every edit.
    _controller.addListener(_handleTextChanged);
  }

  void _handleTextChanged() {
    setState(() {});
  }

  void _handleFocusChanged() {
    if (_focused != _focusNode.hasFocus) {
      setState(() => _focused = _focusNode.hasFocus);
    }
  }

  void _handleHoverEnter(PointerEnterEvent _) {
    if (!_hovered) setState(() => _hovered = true);
  }

  void _handleHoverExit(PointerExitEvent _) {
    if (_hovered) setState(() => _hovered = false);
  }

  void _handleSubmitted(String text) {
    final value = text.trim();
    if (value.isEmpty) return;
    widget.onSubmitted?.call(value);
    _controller.clear();
    _focusNode.requestFocus();
  }

  /// Turns clipboard text into chips through the caller's splitter.
  ///
  /// Reads the clipboard itself rather than the entry buffer: the intent
  /// is intercepted before the text is inserted, so the buffer does not
  /// have it yet.
  Future<void> _handlePaste(List<String> Function(String) splitter) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final pasted = data?.text;
    if (pasted == null || pasted.isEmpty) return;
    if (!mounted) return;

    final next = CoreChipInputContract.chipsAfterPaste(
      existing: widget.chips,
      pasted: pasted,
      splitter: splitter,
      maxChips: widget.maxChips,
    );
    // Identity means the paste contributed nothing — a field already at
    // `maxChips`, or separators with only blanks between them.
    if (identical(next, widget.chips)) return;

    widget.onChanged?.call(next);
  }

  void _handleRemove(int index) {
    final next = [...widget.chips];
    final _ = next.removeAt(index);
    widget.onChanged?.call(next);
  }

  /// Chromeless unified `TextField` — the ChipInput frame owns the
  /// visible boundary; the field renders only the caret + text +
  /// placeholder (mirrors the Web twin's composed TextField).
  ///
  /// The `Actions` wrapper is built **only** when a splitter was
  /// supplied. `Action.overridable` hands the whole intent to an ancestor
  /// override once it finds one that is enabled, replacing
  /// `EditableText`'s own paste action outright — so an always-present
  /// wrapper that returned early for a null splitter would not fall
  /// through to the default, it would insert nothing at all and ordinary
  /// pasting would simply stop working.
  Widget _buildEntryField() {
    // Part of this composite: walled off from the enclosing
    // `FormField`, which is shown the composite's own value.
    final field = Data<FormFieldHandle>.boundary(
      child: TextField(
        onSubmitted: _handleSubmitted,
        enabled: widget.enabled,
        variant: CoreChipInputStyle.fieldVariant,
        textFieldStyle: CoreChipInputStyle.chromelessFieldStyle,
        hintText: widget.placeholder,
        controller: _controller,
        focusNode: _focusNode,
      ),
    );

    final splitter = widget.pasteSplitter;
    if (splitter == null) return field;

    return Actions(
      actions: {
        PasteTextIntent: CallbackAction<PasteTextIntent>(
          onInvoke: (_) {
            unawaited(_handlePaste(splitter));

            return null;
          },
        ),
      },
      child: field,
    );
  }

  Widget _buildChip(int index, ResolvedChipInput resolved) {
    // Composed unified `Chip` — the badge box / label / remove button
    // are the Chip's responsibility; ChipInput only forwards its
    // compact-pill chrome through the nested `chipStyle` slot.
    return Chip(
      label: widget.chips[index],
      variant: CoreChipInputStyle.chipVariant,
      emphasis: CoreChipInputStyle.chipEmphasis,
      size: CoreChipInputStyle.chipSize,
      enabled: widget.enabled,
      onRemove: widget.enabled ? () => _handleRemove(index) : null,
      chipStyle: resolved.chipStyle,
    );
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveChipInput(
      context,
      chipInputStyle: widget.chipInputStyle,
    );

    // The fill can only turn translucent under a style that actually folds
    // `surfaceOpacity` into it (glass) — every non-glass preset leaves
    // [ResolvedChipInput.surfaceOpacity] null, and an opaque-in-every-
    // state fill cannot tell `BoxDecoration.boxShadow` apart from
    // `InjectedCast` (its own doc comment says so). So the shadow only
    // moves off the decoration when translucency is actually possible —
    // baking it in otherwise keeps this byte-identical to the four
    // presets the preset-render baseline holds still.
    final canTurnTranslucent = resolved.surfaceOpacity != null;
    // `disabled > focus > hover > rest` — a focused frame is ringed by
    // `FocusOutline` and keeps its resting border, a disabled one has no
    // hover step. Only a choice between resolved colours is made here.
    final borderColor = !widget.enabled
        ? resolved.disabledBorderColor
        : !_focused && _hovered
        ? resolved.hoverBorderColor
        : resolved.borderColor;
    final backgroundColor = widget.enabled
        ? resolved.backgroundColor
        : resolved.disabledBackgroundColor;
    final decoratedFrame = Container(
      padding: resolved.padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(
          color: borderColor,
          width: resolved.borderWidth,
        ),
        borderRadius: resolved.borderRadius,
        boxShadow: canTurnTranslucent ? null : resolved.boxShadow,
      ),
      // Fill the available width (Web twin's `w-full`) — the chips +
      // self-sized inline field otherwise shrink-wrap the frame.
      width: .infinity,
      constraints: BoxConstraints(minHeight: resolved.minHeight),
      // The chips, then the entry field — which takes what is left of its
      // row, as the Web twin's `flex: 1` field does (`ChipInputWrap`).
      child: ChipInputWrap(
        spacing: resolved.chipSpacing,
        minFieldWidth: CoreChipInputContract.defaultInputMinWidth,
        fillsLast: _canAddMore,
        textDirection: Directionality.of(context),
        children: [
          for (int i = 0; i < widget.chips.length; i += 1)
            _buildChip(i, resolved),
          if (_canAddMore)
            // Chromeless unified TextField — the ChipInput frame owns the
            // visible boundary; the field renders only the caret + text +
            // placeholder (mirrors the Web twin's composed TextField).
            Padding(
              padding: resolved.inputPadding,
              child: _buildEntryField(),
            ),
        ],
      ),
    );

    // `SurfaceBlur` sits inside the cast rather than around it — a no-op
    // when the frame paints no fill (transparent override) or the active
    // style states no material.
    final withMaterial = SurfaceBlur(
      borderRadius: resolved.borderRadius,
      surfaceBlur: resolved.surfaceBlur,
      surfaceSaturation: resolved.surfaceSaturation,
      surfaceBackdropBrightness: resolved.surfaceBackdropBrightness,
      surfaceSheen: resolved.surfaceSheen,
      refraction: Theme.of(context).surfaceRefraction,
      child: decoratedFrame,
    );

    // Moves the cast off `BoxDecoration.boxShadow` (which paints a filled
    // shape behind the box and lets a translucent fill blend with its own
    // shadow) and onto `InjectedCast`, which knocks the box out of the
    // shadow the way CSS does (`core/theme-axis-composition.md` — "그림자
    // 는 두 플랫폼이 다른 곳에 칠한다") — only reached when translucency
    // is actually possible; see `canTurnTranslucent` above.
    final frame = canTurnTranslucent
        ? InjectedCast(
            shadows: resolved.boxShadow,
            borderRadius: resolved.borderRadius,
            child: withMaterial,
          )
        : withMaterial;

    // Web twin: role="group" + aria-label.
    return Semantics(
      container: true,
      label: CoUILocalizations.of(context).chipInputLabel,
      child: MouseRegion(
        onEnter: _handleHoverEnter,
        onExit: _handleHoverExit,
        cursor: widget.enabled
            ? SystemMouseCursors.text
            : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: widget.enabled ? _focusNode.requestFocus : null,
          child: FocusOutline(
            focused: _focused,
            focusOutlineStyle: resolved.focusOutlineStyle,
            child: frame,
          ),
        ),
      ),
    );
  }
}

/// Chain sugar for merging a [CoreChipInputStyle] patch into
/// [ChipInput.chipInputStyle] without hand-reconstructing every field.
/// Mirrors the Web `ChipInput.withStyle` extension so both platforms
/// read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreChipInputStyle.merge` right-side-wins semantics).
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
/// sets [CoreChipInputStyle.borderRadius] and `.primary` sets
/// [CoreChipInputStyle.backgroundColor]. A semantic layer that names
/// these after component-specific intent (decided together with
/// design) is a follow-up once more components adopt this pattern.
///
/// ```dart
/// ChipInput(chips: tags).radius4.surface
/// ```
extension ChipInputStyleChain on ChipInput {
  /// Sets the background paint and preserves the other style fields.
  ChipInput backgroundColor(CoreColor value) =>
      withStyle(CoreChipInputStyle(backgroundColor: value));

  /// Returns a copy of this [ChipInput] with [patch] merged into
  /// [chipInputStyle] (patch fields win on conflict).
  ChipInput withStyle(CoreChipInputStyle patch) => copyWith(
    chipInputStyle: (chipInputStyle ?? const CoreChipInputStyle()).merge(patch),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  ChipInput get radius0 => withStyle(
    const CoreChipInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius0),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  ChipInput get radius2 => withStyle(
    const CoreChipInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  ChipInput get radius4 => withStyle(
    const CoreChipInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  ChipInput get radius6 => withStyle(
    const CoreChipInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  ChipInput get radius8 => withStyle(
    const CoreChipInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  ChipInput get radius10 => withStyle(
    const CoreChipInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  ChipInput get radius12 => withStyle(
    const CoreChipInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  ChipInput get radius14 => withStyle(
    const CoreChipInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  ChipInput get radius16 => withStyle(
    const CoreChipInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  ChipInput get radius20 => withStyle(
    const CoreChipInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  ChipInput get radius24 => withStyle(
    const CoreChipInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  ChipInput get radius28 => withStyle(
    const CoreChipInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  ChipInput get radius32 => withStyle(
    const CoreChipInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  ChipInput get radius36 => withStyle(
    const CoreChipInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  ChipInput get radius40 => withStyle(
    const CoreChipInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  ChipInput get radius48 => withStyle(
    const CoreChipInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  ChipInput get radius56 => withStyle(
    const CoreChipInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  ChipInput get radius64 => withStyle(
    const CoreChipInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  ChipInput get radius9999 => withStyle(
    const CoreChipInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  ChipInput get primary => withStyle(
    const CoreChipInputStyle(
      backgroundColor: CoreColor.token(CoreColors.primary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  ChipInput get secondary => withStyle(
    const CoreChipInputStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  ChipInput get tertiary => withStyle(
    const CoreChipInputStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  ChipInput get surface => withStyle(
    const CoreChipInputStyle(
      backgroundColor: CoreColor.token(CoreColors.surface),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  ChipInput get surfaceContainer => withStyle(
    const CoreChipInputStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  ChipInput get error => withStyle(
    const CoreChipInputStyle(
      backgroundColor: CoreColor.token(CoreColors.error),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  ChipInput get success => withStyle(
    const CoreChipInputStyle(
      backgroundColor: CoreColor.token(CoreColors.success),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  ChipInput get warning => withStyle(
    const CoreChipInputStyle(
      backgroundColor: CoreColor.token(CoreColors.warning),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  ChipInput get info => withStyle(
    const CoreChipInputStyle(backgroundColor: CoreColor.token(CoreColors.info)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  ChipInput get outline => withStyle(
    const CoreChipInputStyle(
      backgroundColor: CoreColor.token(CoreColors.outline),
    ),
  );

  /// `backgroundColor: CoreColor.transparent`.
  ChipInput get transparent => withStyle(
    const CoreChipInputStyle(backgroundColor: .transparent),
  );
}
