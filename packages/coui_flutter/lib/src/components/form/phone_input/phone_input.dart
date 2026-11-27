import 'package:coui_flutter/coui_flutter.dart';
import 'package:country_flags/country_flags.dart' as country_flags;
import 'package:flutter/services.dart';

// flag-icons flags are authored at a 4:3 aspect (viewBox 640×480); the Web
// `PhoneInput` renders the very same flag-icons SVGs, so both platforms show
// identical flags instead of platform-dependent emoji glyphs. Not a design
// token — it is the intrinsic aspect ratio of the flag artwork.
const double _kFlagAspectRatio = 4 / 3;

/// A unified cross-platform phone input component.
///
/// Renders a single bordered container holding a country selector trigger
/// and a phone number text field separated by an internal divider. Tapping
/// the selector opens a custom popover (search input + country listbox)
/// that mirrors the Web `PhoneInput` dropdown, so both platforms share
/// the same visual structure and UX.
///
/// Resolve priority: widget parameter > CorePhoneInputTheme > defaults.
///
/// Example:
/// ```dart
/// PhoneInput(
///   initialCountry: CoreCountry.unitedStates,
///   onChanged: (phoneNumber) {
///     print('Phone: ${phoneNumber.fullNumber}');
///   },
/// )
/// ```
///
/// surface:behind — the outer `Container` paints the field's box directly
/// rather than composing `OutlinedContainer` (the inner number `TextField`
/// is deliberately chromeless so the outer box owns the single visible
/// boundary), so what shows through it is the page it is laid on.
///
/// surface:content — a face in the content layer alongside cards and
/// body panels.
class PhoneInput extends StatefulWidget
    implements
        CorePhoneInputContract<
          TextEditingController?,
          PhoneNumber,
          CoreCountry
        > {
  /// Creates a [PhoneInput].
  const PhoneInput({
    super.key,
    this.initialCountry,
    this.initialNumber,
    this.initialValue,
    this.onChanged,
    this.controller,
    this.filterPlusCode = CorePhoneInputContract.defaultFilterPlusCode,
    this.onlyNumber = true,
    this.placeholder,
    this.countries,
    this.enabled = true,
    this.phoneInputStyle,
  });

  @override
  final CoreCountry? initialCountry;

  @override
  final String? initialNumber;

  /// Combined initial phone number (country + number).
  ///
  /// When provided, its [PhoneNumber.country] takes precedence over
  /// [initialCountry] and [PhoneNumber.number] over [initialNumber].
  @override
  final PhoneNumber? initialValue;

  @override
  final ValueChanged<PhoneNumber>? onChanged;

  @override
  final TextEditingController? controller;

  /// Whether to filter out plus (+) symbols from input.
  @override
  final bool filterPlusCode;

  @override
  final bool onlyNumber;

  @override
  final String? placeholder;

  @override
  final List<CoreCountry>? countries;

  @override
  final bool enabled;

  @override
  final CorePhoneInputStyle? phoneInputStyle;

  /// Returns a copy of this [PhoneInput] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  PhoneInput copyWith({
    Key? key,
    PhoneNumber? initialValue,
    ValueChanged<PhoneNumber>? onChanged,
    CoreCountry? initialCountry,
    String? initialNumber,
    TextEditingController? controller,
    bool? filterPlusCode,
    bool? onlyNumber,
    String? placeholder,
    List<CoreCountry>? countries,
    bool? enabled,
    CorePhoneInputStyle? phoneInputStyle,
  }) {
    return PhoneInput(
      key: key ?? this.key,
      onChanged: onChanged ?? this.onChanged,
      initialValue: initialValue ?? this.initialValue,
      initialCountry: initialCountry ?? this.initialCountry,
      initialNumber: initialNumber ?? this.initialNumber,
      controller: controller ?? this.controller,
      filterPlusCode: filterPlusCode ?? this.filterPlusCode,
      onlyNumber: onlyNumber ?? this.onlyNumber,
      placeholder: placeholder ?? this.placeholder,
      countries: countries ?? this.countries,
      enabled: enabled ?? this.enabled,
      phoneInputStyle: phoneInputStyle ?? this.phoneInputStyle,
    );
  }

  @override
  State<PhoneInput> createState() => _PhoneInputState();
}

/// Chain sugar for merging a [CorePhoneInputStyle] patch into
/// [PhoneInput.phoneInputStyle] without hand-reconstructing every field.
/// Mirrors the Web `PhoneInput.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CorePhoneInputStyle.merge` right-side-wins semantics).
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
/// sets [CorePhoneInputStyle.borderRadius] and `.primary` sets
/// [CorePhoneInputStyle.backgroundColor]. A semantic layer that names
/// these after component-specific intent (decided together with design)
/// is a follow-up once more components adopt this pattern.
///
/// ```dart
/// PhoneInput().radius4.surface
/// ```
extension PhoneInputStyleChain on PhoneInput {
  /// Sets the background paint and preserves the other style fields.
  PhoneInput backgroundColor(CoreColor value) =>
      withStyle(CorePhoneInputStyle(backgroundColor: value));

  /// Returns a copy of this [PhoneInput] with [patch] merged into
  /// [phoneInputStyle] (patch fields win on conflict).
  PhoneInput withStyle(CorePhoneInputStyle patch) => copyWith(
    phoneInputStyle: (phoneInputStyle ?? const CorePhoneInputStyle()).merge(
      patch,
    ),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  PhoneInput get radius0 => withStyle(
    const CorePhoneInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius0),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  PhoneInput get radius2 => withStyle(
    const CorePhoneInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  PhoneInput get radius4 => withStyle(
    const CorePhoneInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  PhoneInput get radius6 => withStyle(
    const CorePhoneInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  PhoneInput get radius8 => withStyle(
    const CorePhoneInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  PhoneInput get radius10 => withStyle(
    const CorePhoneInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  PhoneInput get radius12 => withStyle(
    const CorePhoneInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  PhoneInput get radius14 => withStyle(
    const CorePhoneInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  PhoneInput get radius16 => withStyle(
    const CorePhoneInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  PhoneInput get radius20 => withStyle(
    const CorePhoneInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  PhoneInput get radius24 => withStyle(
    const CorePhoneInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  PhoneInput get radius28 => withStyle(
    const CorePhoneInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  PhoneInput get radius32 => withStyle(
    const CorePhoneInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  PhoneInput get radius36 => withStyle(
    const CorePhoneInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  PhoneInput get radius40 => withStyle(
    const CorePhoneInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  PhoneInput get radius48 => withStyle(
    const CorePhoneInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  PhoneInput get radius56 => withStyle(
    const CorePhoneInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  PhoneInput get radius64 => withStyle(
    const CorePhoneInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  PhoneInput get radius9999 => withStyle(
    const CorePhoneInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  PhoneInput get primary => withStyle(
    const CorePhoneInputStyle(
      backgroundColor: CoreColor.token(CoreColors.primary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  PhoneInput get secondary => withStyle(
    const CorePhoneInputStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  PhoneInput get tertiary => withStyle(
    const CorePhoneInputStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  PhoneInput get surface => withStyle(
    const CorePhoneInputStyle(
      backgroundColor: CoreColor.token(CoreColors.surface),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  PhoneInput get surfaceContainer => withStyle(
    const CorePhoneInputStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  PhoneInput get error => withStyle(
    const CorePhoneInputStyle(
      backgroundColor: CoreColor.token(CoreColors.error),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  PhoneInput get success => withStyle(
    const CorePhoneInputStyle(
      backgroundColor: CoreColor.token(CoreColors.success),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  PhoneInput get warning => withStyle(
    const CorePhoneInputStyle(
      backgroundColor: CoreColor.token(CoreColors.warning),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  PhoneInput get info => withStyle(
    const CorePhoneInputStyle(
      backgroundColor: CoreColor.token(CoreColors.info),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  PhoneInput get outline => withStyle(
    const CorePhoneInputStyle(
      backgroundColor: CoreColor.token(CoreColors.outline),
    ),
  );

  /// `backgroundColor: CoreColor.transparent`.
  PhoneInput get transparent => withStyle(
    const CorePhoneInputStyle(backgroundColor: .transparent),
  );
}

class _PhoneInputState extends State<PhoneInput>
    with FormValueSupplier<PhoneNumber, PhoneInput> {
  static bool _matchesQuery(CoreCountry country, String query) {
    final lower = query.toLowerCase();
    return country.name.toLowerCase().contains(lower) ||
        country.dialCode.contains(lower) ||
        country.code.toLowerCase().contains(lower);
  }

  late CoreCountry _country;
  late TextEditingController _controller;
  bool _focused = false;
  // Whether the pointer is over the outer box. State DETECTION lives here;
  // the border colour it selects is the resolver's `hoverBorderColor`.
  bool _hovered = false;
  // Anchored country dropdown via the unified `Popover` (same engine as
  // `Select`) — portal-mounted panel with shared chrome. Driven in manual
  // mode so only the country-selector tap toggles it (not the number field).
  final _popover = PopoverController();

  @override
  void initState() {
    super.initState();
    _country =
        widget.initialValue?.country ??
        widget.initialCountry ??
        CorePhoneInputContract.defaultInitialCountry;
    _controller =
        widget.controller ??
        TextEditingController(
          text: widget.initialValue?.number ?? widget.initialNumber,
        );
    formValue = _value;
    _controller.addListener(_handleTextChanged);
  }

  /// Countries detection and the picker search within — `widget.countries`
  /// when the caller narrowed it, the full shared dataset otherwise. A
  /// single getter so both consumers stay in sync (previously the picker
  /// content inlined this and detection would have had to repeat it).
  List<CoreCountry> get _effectiveCountries =>
      widget.countries ?? CoreCountry.all;

  // Bound to the controller, so it only fires when the typist edits the
  // number field — not when `_handleSelectCountry` sets the country
  // explicitly via the dropdown (that path calls `_handleChanged` directly,
  // skipping detection so an explicit pick is never immediately overridden).
  void _handleTextChanged() {
    final detected = CorePhoneCountryDetector.detect(
      _controller.text,
      _effectiveCountries,
    );
    if (detected != null && detected != _country) {
      setState(() => _country = detected);
    }
    _handleChanged();
  }

  void _handleChanged() {
    widget.onChanged?.call(_value);
    formValue = _value;
  }

  void _handleSelectCountry(CoreCountry country) {
    _popover.close();
    if (country == _country) return;
    setState(() {
      _country = country;
    });
    _handleChanged();
  }

  void _handleSelectorTap() {
    if (!widget.enabled) return;
    _popover.toggle();
  }

  void _handleHoverEnter(PointerEnterEvent _) {
    if (!widget.enabled) return;
    setState(() => _hovered = true);
  }

  void _handleHoverExit(PointerExitEvent _) {
    if (_hovered) setState(() => _hovered = false);
  }

  @override
  void didUpdateWidget(covariant PhoneInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _controller.removeListener(_handleTextChanged);
      _controller = widget.controller ?? TextEditingController();
      _controller.addListener(_handleTextChanged);
    }
    // `initialValue.country` outranks `initialCountry`, so re-seed from the
    // effective country rather than from `initialCountry` alone — otherwise a
    // caller that only moves `initialValue` never sees the selector follow.
    // The Web twin does exactly this; without it, mutating the value after
    // mount moved the selector on one platform only.
    final next = widget.initialValue?.country ?? widget.initialCountry;
    final previous =
        oldWidget.initialValue?.country ?? oldWidget.initialCountry;
    if (next != null && next != previous) {
      setState(() => _country = next);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    _popover.dispose();
    super.dispose();
  }

  @override
  void didReplaceFormValue(PhoneNumber value) {
    _controller.text = value.toString();
  }

  // Filtering lives in `CorePhoneNumber.fromInput` so the Web `PhoneInput`
  // strips the same prefixes in the same order from the same raw text —
  // a hand-copied chain on each platform is how the two drift apart.
  PhoneNumber get _value => .fromInput(
    _country,
    _controller.text,
    filterPlusCode: widget.filterPlusCode,
  );

  @override
  Widget build(BuildContext context) {
    final resolved = resolvePhoneInput(
      context,
      enabled: widget.enabled,
      phoneInputStyle: widget.phoneInputStyle,
    );

    final borderRadius = resolved.borderRadius;
    final resolvedMaxWidth = resolved.maxWidth;

    final content = Focus(
      onFocusChange: (focused) {
        if (focused != _focused) setState(() => _focused = focused);
      },
      canRequestFocus: false,
      // Tracks focus of any inner field (number input) so the outer
      // container can own the single focus boundary — the popover search
      // field lives in a separate overlay focus tree and is excluded.
      skipTraversal: true,
      // The row takes the height the box leaves inside its border: the box
      // itself is `resolved.height` (below), the way Web's border-box root
      // is — so the field is exactly the text field's row beside it.
      child: Row(
        crossAxisAlignment: .stretch,
        children: [
          _CountrySelectorTrigger(
            onTap: _handleSelectorTap,
            country: _country,
            enabled: widget.enabled,
            resolved: resolved,
          ),
          // The hairline between the selector and the number is shorter than
          // the box, centred in the row.
          Center(
            child: SizedBox(
              height: resolved.separatorHeight,
              child: Divider(
                orientation: .vertical,
                dividerStyle: resolved.dividerStyle,
              ),
            ),
          ),
          // Number field fills the remaining row width, capped at
          // `maxWidth` — mirrors Web's `w-full` + `max-width: maxWidth`.
          // The row is `mainAxisSize: .max` (below) so the field grows to
          // fill (placeholder no longer truncates) and shrinks in a narrow
          // parent (no overflow).
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: resolvedMaxWidth),
              child: Padding(
                padding: resolved.inputFieldPadding,
                // Part of this composite: walled off from the enclosing
                // `FormField`, which is shown the composite's own value.
                child: Data<FormFieldHandle>.boundary(
                  child: TextField(
                    enabled: widget.enabled,
                    // Outer container owns the visual boundary — inner field
                    // is chromeless via the unified Style slot.
                    textFieldStyle: resolved.numberFieldStyle,
                    hintText: widget.placeholder,
                    controller: _controller,
                    keyboardType: widget.onlyNumber ? .phone : null,
                    // Shared with Web through `CoreInputFormatters` rather
                    // than Flutter's `digitsOnly`: the dial code is only
                    // stripped when the typist writes it, so `+` has to be
                    // typeable — digits-only made that impossible.
                    inputFormatters: [
                      if (widget.onlyNumber) TextInputFormatters.phoneText(),
                    ],
                    autofillHints: const [AutofillHints.telephoneNumber],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // The `Container` draws the rounded border and insets the content by the
    // border width, so the content (and its hover background) sits *inside* the
    // border — matching Web, where the border-box + `overflow-hidden` keep the
    // hover fill within the border. The inner content is then clipped by an
    // explicit `ClipRRect` at the *inner* radius (outer − border width) so the
    // hover background's corners follow the border's inner curve — no square
    // bleed (which `Container.clipBehavior` left on Flutter Web / canvaskit)
    // and no corner gap.
    final innerCornerRadius = (borderRadius.topLeft.x - resolved.borderWidth)
        .clamp(0.0, double.infinity);
    // The fill can only turn translucent under a style that actually folds
    // `surfaceOpacity` into it (glass) — every non-glass preset leaves
    // [ResolvedPhoneInput.surfaceOpacity] null, and an opaque-in-every-
    // state fill cannot tell `BoxDecoration.boxShadow` apart from
    // `InjectedCast` (its own doc comment says so). So the shadow only
    // moves off the decoration when translucency is actually possible —
    // baking it in otherwise keeps this byte-identical to the four
    // presets the preset-render baseline holds still.
    final canTurnTranslucent = resolved.surfaceOpacity != null;
    // `disabled > focus > hover > rest` — the outer box owns the one border,
    // so focus (any inner field) outranks a pointer over it, and a disabled
    // field takes no hover step.
    final borderColor = _focused
        ? resolved.focusBorderColor
        : widget.enabled && _hovered
        ? resolved.hoverBorderColor
        : resolved.borderColor;
    final decoratedBody = MouseRegion(
      onEnter: _handleHoverEnter,
      onExit: _handleHoverExit,
      child: Container(
        // The whole box, border included — Web's root is `height` with
        // `box-sizing: border-box`, and a text field's row counts its border
        // too. On the content row it was the border's two widths taller than
        // both.
        height: resolved.height,
        decoration: BoxDecoration(
          color: resolved.backgroundColor,
          border: Border.all(
            color: borderColor,
            width: resolved.borderWidth,
          ),
          borderRadius: borderRadius,
          boxShadow: canTurnTranslucent ? null : resolved.boxShadow,
        ),
        child: ClipRRect(
          borderRadius: .all(.circular(innerCornerRadius)),
          child: content,
        ),
      ),
    );

    // `SurfaceBlur` sits inside the cast rather than around it — a no-op
    // when the field paints no fill (a transparent `backgroundColor`
    // preset) or the active style states no material.
    final withMaterial = SurfaceBlur(
      borderRadius: borderRadius,
      surfaceBlur: resolved.surfaceBlur,
      surfaceSaturation: resolved.surfaceSaturation,
      surfaceBackdropBrightness: resolved.surfaceBackdropBrightness,
      surfaceSheen: resolved.surfaceSheen,
      refraction: Theme.of(context).surfaceRefraction,
      child: decoratedBody,
    );

    // Moves the cast off `BoxDecoration.boxShadow` (which paints a filled
    // shape behind the box and lets a translucent fill blend with its own
    // shadow) and onto `InjectedCast`, which knocks the box out of the
    // shadow the way CSS does (`core/theme-axis-composition.md` — "그림자
    // 는 두 플랫폼이 다른 곳에 칠한다") — only reached when translucency
    // is actually possible; see `canTurnTranslucent` above.
    final decorated = canTurnTranslucent
        ? InjectedCast(
            shadows: resolved.boxShadow,
            borderRadius: borderRadius,
            child: withMaterial,
          )
        : withMaterial;

    // The unified Popover anchors the country panel below the whole field
    // and portal-mounts it, so it is never clipped. Manual mode — the
    // selector tap toggles the controller. A fixed anchor-width constraint
    // gives the panel a definite width so the inner list is never queried
    // for an intrinsic width it cannot provide.
    const queryMatcher = _matchesQuery;
    final field = Popover(
      trigger: decorated,
      content: _CountryPickerPopup(
        countries: _effectiveCountries,
        selected: _country,
        maxHeight: resolved.popupMaxHeight,
        onSelected: _handleSelectCountry,
        matchesQuery: queryMatcher,
        resolved: resolved,
      ),
      placement: .bottomStart,
      controller: _popover,
      openTrigger: .manual,
      widthConstraint: .anchorFixedSize,
      // The field is a full-width input (like Select / DatePicker), so the
      // trigger wrapper must fill its parent — the default `intrinsic` wraps
      // it in `IntrinsicWidth` and collapses the fill-width row (placeholder
      // truncated to `Phone`).
      popoverStyle: resolved.popoverStyle,
    );

    // Apply disabled opacity for visual parity with Web (`opacity-50`).
    // Web twin: aria-label on the country selector plus listbox/option roles.
    // Whether the country list is showing is stated once, by `Popover` on
    // the trigger node it builds. Stating it here too gave the field two
    // `expanded` flags, and this one was read at build time only — an
    // outside tap closed the list without rebuilding this widget, so it
    // kept announcing "expanded".
    return Semantics(
      container: true,
      label: CoUILocalizations.of(context).phoneInputSelectCountry,
      child: widget.enabled
          ? field
          : IgnorePointer(
              child: Opacity(
                opacity: resolved.disabledOpacity,
                child: field,
              ),
            ),
    );
  }
}

/// Internal country selector trigger button.
///
/// Renders the flag, dial code, and a chevron icon. Mirrors Web
/// `PhoneInputCountrySelectorStyle` (padding, gap) — no hover fill, the
/// box's own border carries the pointer.
class _CountrySelectorTrigger extends StatelessWidget {
  const _CountrySelectorTrigger({
    required this.country,
    required this.enabled,
    required this.onTap,
    required this.resolved,
  });

  final CoreCountry country;
  final bool enabled;
  final VoidCallback onTap;
  final ResolvedPhoneInput resolved;

  @override
  Widget build(BuildContext context) {
    // No hover fill: the box's own border carries the pointer.
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        behavior: .opaque,
        child: Padding(
          padding: resolved.selectorPadding,
          child: Row(
            mainAxisSize: .min,
            children: [
              ClipRRect(
                borderRadius: resolved.flagBorderRadius,
                child: country_flags.CountryFlag.fromCountryCode(
                  country.code,
                  theme: country_flags.ImageTheme(
                    width: resolved.flagSize * _kFlagAspectRatio,
                    height: resolved.flagSize,
                  ),
                ),
              ),
              Gap(gapStyle: resolved.flagGapStyle),
              Text(
                country.dialCode,
                style: enabled
                    ? resolved.dialCodeTextStyleEnabled
                    : resolved.dialCodeTextStyleDisabled,
              ),
              Gap(gapStyle: resolved.flagGapStyle),
              Icon(
                LucideIcons.chevronDown,
                iconStyle: enabled
                    ? resolved.chevronIconStyleEnabled
                    : resolved.chevronIconStyleDisabled,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Internal popup with search field and country list.
///
/// Mirrors the Web custom dropdown layout (search on top, listbox below)
/// so both platforms share the same country-selection UX.
class _CountryPickerPopup extends StatefulWidget {
  const _CountryPickerPopup({
    required this.countries,
    required this.selected,
    required this.maxHeight,
    required this.onSelected,
    required this.matchesQuery,
    required this.resolved,
  });

  final List<CoreCountry> countries;
  final CoreCountry selected;
  final double maxHeight;
  final ValueChanged<CoreCountry> onSelected;
  final bool Function(CoreCountry country, String query) matchesQuery;
  final ResolvedPhoneInput resolved;

  @override
  State<_CountryPickerPopup> createState() => _CountryPickerPopupState();
}

class _CountryPickerPopupState extends State<_CountryPickerPopup> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleQueryChanged);
  }

  void _handleQueryChanged() {
    final next = _searchController.text;
    if (next == _query) return;
    setState(() {
      _query = next;
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleQueryChanged);
    _searchController.dispose();
    super.dispose();
  }

  List<CoreCountry> get _filtered {
    final trimmed = _query.trim();
    if (trimmed.isEmpty) return widget.countries;
    return widget.countries
        .where((c) => widget.matchesQuery(c, trimmed))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final resolved = widget.resolved;

    // No `Card` wrapper — the unified `Popover` renders this content inside
    // its shared panel chrome (border / surface / radius / shadow); the
    // panel states no inset, so the search row and its divider run edge to
    // edge and only the list carries its own inset. The panel width comes
    // from the Popover's `anchorFixedSize` constraint, so the `ListView`
    // gets a definite width and is never queried for its (undefined)
    // intrinsic width.
    // Search field stays fixed on top; only the option list is capped at
    // `maxHeight` and scrolls (matching Web, where `max-height` sits on the
    // listbox — so the panel height is search + divider + list on both).
    return TextFieldTapRegion(
      child: Column(
        mainAxisSize: .min,
        children: [
          // Part of this composite: walled off from the enclosing
          // `FormField`, which is shown the composite's own value.
          Data<FormFieldHandle>.boundary(
            child: TextField(
              autofocus: true,
              // The panel is the only boundary: the bare variant with the
              // search glyph in front, closed by the divider below.
              variant: .plain,
              prefix: Icon(
                LucideIcons.search,
                iconStyle: resolved.searchIconStyle,
              ),
              textFieldStyle: resolved.searchFieldStyle,
              hintText: CoUILocalizations.of(
                context,
              ).searchPlaceholderCountry,
              controller: _searchController,
            ),
          ),
          Divider(
            dividerStyle: resolved.dividerStyle,
          ),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: widget.maxHeight),
            child: filtered.isEmpty
                ? Padding(
                    padding: resolved.dropdownListPadding,
                    child: Padding(
                      padding: resolved.dropdownItemPadding,
                      child: Text(
                        CoUILocalizations.of(context).emptyCountryList,
                        style: resolved.dropdownDialCodeTextStyle,
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: resolved.dropdownListPadding,
                    itemBuilder: (itemContext, index) {
                      final country = filtered[index];
                      return _CountryPickerItem(
                        onTap: () => widget.onSelected(country),
                        country: country,
                        selected: country == widget.selected,
                        resolved: resolved,
                      );
                    },
                    itemCount: filtered.length,
                  ),
          ),
        ],
      ),
    );
  }
}

/// Internal list item inside the country picker popup.
class _CountryPickerItem extends StatefulWidget {
  const _CountryPickerItem({
    required this.country,
    required this.selected,
    required this.onTap,
    required this.resolved,
  });

  final CoreCountry country;
  final bool selected;
  final VoidCallback onTap;
  final ResolvedPhoneInput resolved;

  @override
  State<_CountryPickerItem> createState() => _CountryPickerItemState();
}

class _CountryPickerItemState extends State<_CountryPickerItem> {
  bool _hovered = false;

  void _handleHoverEnter(PointerEnterEvent _) {
    setState(() => _hovered = true);
  }

  void _handleHoverExit(PointerExitEvent _) {
    if (_hovered) {
      setState(() => _hovered = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolved = widget.resolved;

    // The selection is the check alone; the only filled row is the one
    // under the pointer.
    final background = _hovered ? resolved.hoverColor : Colors.transparent;

    return MouseRegion(
      onEnter: _handleHoverEnter,
      onExit: _handleHoverExit,
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: .opaque,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: resolved.dropdownItemBorderRadius,
          ),
          child: Padding(
            padding: resolved.dropdownItemPadding,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: resolved.flagBorderRadius,
                  child: country_flags.CountryFlag.fromCountryCode(
                    widget.country.code,
                    theme: country_flags.ImageTheme(
                      width: resolved.dropdownFlagSize * _kFlagAspectRatio,
                      height: resolved.dropdownFlagSize,
                    ),
                  ),
                ),
                Gap(gapStyle: resolved.dropdownItemGapStyle),
                Expanded(
                  child: Text(
                    widget.country.name,
                    style: resolved.bodyTextStyle,
                    overflow: .ellipsis,
                  ),
                ),
                Gap(gapStyle: resolved.dropdownItemGapStyle),
                Text(
                  widget.country.dialCode,
                  style: resolved.dropdownDialCodeTextStyle,
                ),
                if (widget.selected) ...[
                  Gap(gapStyle: resolved.dropdownItemGapStyle),
                  Icon(
                    LucideIcons.check,
                    iconStyle: resolved.dropdownCheckIconStyle,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The value a [PhoneInput] reports and accepts: a country plus the national
/// number.
///
/// An alias of the shared [CorePhoneNumber] — the Web `PhoneInput` names the
/// same type `PhoneInputValue`, so a value stored on one platform is the very
/// same type on the other.
typedef PhoneNumber = CorePhoneNumber;
