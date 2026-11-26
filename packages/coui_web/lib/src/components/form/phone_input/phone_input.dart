import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/asset_source_scope.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/base/web_dom_utils.dart';
import 'package:coui_web/src/components/display/divider/divider.dart';
import 'package:coui_web/src/components/form/form/form_controller.dart';
import 'package:coui_web/src/components/form/phone_input/phone_input_style.dart';
import 'package:coui_web/src/components/form/text_field/text_field.dart';
import 'package:coui_web/src/components/icon/icon.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:coui_web/src/components/overlay/popover/popover.dart';
import 'package:coui_web/src/components/overlay/popover/popover_controller.dart';
import 'package:coui_web/src/components/overlay/popover/popover_dom.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart' hide Text;
import 'package:universal_web/web.dart' as web;

/// Per-instance counter for the portaled country-panel id (used to focus the
/// autofocus search field once the `Popover` mounts it).
int _coPhonePanelIdCounter = 0;

/// Per-instance counter for the pseudo-state scope classes
/// (`.co-phone-input-h-<id>` / `-fw-` / `-hb-` / `-ph-`) shared by the
/// affected elements and the scoped `<style>` rules. A raw (token-less)
/// pseudo-state colour override cannot ride a Tailwind pseudo class, so it
/// needs a unique per-instance scope so concurrent instances' rules don't
/// collide. Not a design token.
int _coPhoneScopeIdCounter = 0;

/// Builds the flag SVG URL for an ISO 2-letter country [code] under
/// [baseUrl] (flag-icons filenames are lower-case).
///
/// The flags are the `flag-icons` 4:3 SVGs — the *same* set the Flutter
/// `PhoneInput` bundles through `country_flags`, so both platforms render
/// identical flags instead of platform-dependent emoji glyphs (missing
/// entirely on some desktop browsers). Where they are fetched from is
/// [CouiAssetSourceScope.flagIconsBaseUrlOf] — the public CDN unless an
/// ancestor scope points it at a mirror.
String _flagIconUrl(String baseUrl, String code) =>
    '$baseUrl/${code.toLowerCase()}.svg';

/// A flag box: a single fixed-size `<div>` whose `background-image` is the
/// flag-icons SVG for [code]. A background image (rather than a child `<img>`)
/// keeps the SVG's intrinsic size from inflating the surrounding flex row. The
/// box size / `background-size` chrome comes from the resolver ([boxClass] /
/// [boxStyles]); only the per-country image URL is added here as content.
Component _flagImage({
  required String baseUrl,
  required String code,
  required String boxClass,
  required Styles? boxStyles,
}) => .element(
  tag: 'div',
  classes: boxClass,
  styles: Styles.combine([
    ?boxStyles,
    buildPhoneFlagBackground(_flagIconUrl(baseUrl, code)),
  ]),
  attributes: const {'role': 'img', 'aria-hidden': 'true'},
);

/// The value a [PhoneInput] reports and accepts: a country plus the national
/// number.
///
/// An alias of the shared [CorePhoneNumber] — the Flutter `PhoneInput` names
/// the same type `PhoneNumber`, so a value stored on one platform is the very
/// same type on the other. [CorePhoneNumber.countryCode] and
/// [CorePhoneNumber.dialCode] read straight off the carried country.
typedef PhoneInputValue = CorePhoneNumber;

/// A unified cross-platform phone input for CoUI Web.
///
/// Renders a combined country code selector button and phone number
/// input field. Clicking the country selector toggles a dropdown popup
/// listing the available countries. Uses design tokens from
/// [CorePhoneInputTheme] for consistent styling.
///
/// Resolve priority: widget parameter > CorePhoneInputTheme > defaults.
///
/// Example:
/// ```dart
/// PhoneInput(
///   initialCountry: CoreCountry.unitedStates,
///   placeholder: 'Phone number',
///   onChanged: (value) => print('Phone: ${value.fullNumber}'),
/// )
/// ```
///
/// surface:behind — the root `<div>` paints the field's box directly
/// rather than composing `OutlinedContainer` (the inner number field is
/// deliberately chromeless — `chromelessFieldStyle` — so the root owns
/// the single visible boundary), so what shows through it is the page it
/// is laid on.
///
/// surface:content — a face in the content layer alongside cards and
/// body panels.
class PhoneInput extends UiStatefulComponent
    implements CorePhoneInputContract<Null, PhoneInputValue, CoreCountry> {
  /// Creates a [PhoneInput].
  const PhoneInput({
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
    this.initialCountry,
    this.initialNumber,
    this.initialValue,
    this.onChanged,
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
  /// When provided, its [CorePhoneNumber.country] takes precedence over
  /// [initialCountry] and [CorePhoneNumber.number] over [initialNumber].
  @override
  final PhoneInputValue? initialValue;

  @override
  final CoreValueChanged<PhoneInputValue>? onChanged;

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

  /// Web does not use a text editing controller.
  @override
  Null get controller => null;

  /// Default country list used when [countries] is null — the full shared
  /// 247-country dataset ([CoreCountry.all]), so Web lists the same
  /// countries as the Flutter `PhoneInput` (both derive from `phonecodes`)
  /// instead of a hand-picked 10.
  static List<CoreCountry> get defaultCountries => CoreCountry.all;

  /// Returns a copy of this [PhoneInput] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  PhoneInput copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    Map<String, List<UiEventHandler>>? eventHandlers,
    String? id,
    Key? key,
    UiInputEventHandler? onChange,
    UiMouseEventHandler? onClick,
    UiInputEventHandler? onInput,
    UiKeyboardEventHandler? onKeyDown,
    UiKeyboardEventHandler? onKeyUp,
    UiMouseEventHandler? onMouseEnter,
    UiMouseEventHandler? onMouseLeave,
    CoreCountry? initialCountry,
    String? initialNumber,
    PhoneInputValue? initialValue,
    CoreValueChanged<PhoneInputValue>? onChanged,
    bool? filterPlusCode,
    bool? onlyNumber,
    String? placeholder,
    List<CoreCountry>? countries,
    bool? enabled,
    CorePhoneInputStyle? phoneInputStyle,
  }) {
    return PhoneInput(
      key: key ?? this.key,
      onClick: onClick ?? this.onClick,
      onChanged: onChanged ?? this.onChanged,
      initialValue: initialValue ?? this.initialValue,
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
      initialCountry: initialCountry ?? this.initialCountry,
      initialNumber: initialNumber ?? this.initialNumber,
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

class _PhoneInputState extends State<PhoneInput>
    with FormValueSupplier<PhoneInputValue, PhoneInput> {
  static const _kDivTag = 'div';
  static const _kButtonTag = 'button';
  static const _kSpanTag = 'span';
  static const _kDisabledAttribute = 'disabled';
  static const _kEmptyValue = '';

  late CoreCountry _country;
  late String _number;
  // Anchored country dropdown via the unified `Popover` (same engine as
  // `Select`) — portal-mounted panel with shared chrome, so it is never
  // clipped by the field container. Manual mode: only the selector toggles it.
  final _popover = PopoverController();
  late final String _panelId = 'coui-phone-panel-${_coPhonePanelIdCounter++}';
  // Stable per-instance scope id for the pseudo-state scope classes / scoped
  // `<style>` rules (assigned once so the classes on the elements match the
  // rules in the `<style>` block across rebuilds).
  late final String _scopeId = '${_coPhoneScopeIdCounter++}';
  String _searchQuery = _kEmptyValue;

  /// Index, within the visible countries, of the option the search field's
  /// `aria-activedescendant` points at.
  ///
  /// The panel is a combobox's listbox: DOM focus stays in the search field
  /// (typing keeps filtering) and the arrows move this highlight instead of
  /// focus — the same pattern `Command` and `Autocomplete` use.
  int _highlight = 0;

  String get _listboxId => '$_panelId-listbox';

  String _optionId(int index) => '$_panelId-option-$index';

  List<CoreCountry> get _effectiveCountries =>
      component.countries ?? PhoneInput.defaultCountries;

  List<CoreCountry> get _filteredCountries {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _effectiveCountries;
    return _effectiveCountries.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.dialCode.contains(q) ||
          c.code.toLowerCase().contains(q);
    }).toList();
  }

  /// Number the field is seeded with — `initialValue` wins over
  /// `initialNumber`, matching the documented precedence.
  String? get _seedNumber =>
      component.initialValue?.number ?? component.initialNumber;

  // `_number` holds the *raw* field text; the dial code `filterPlusCode`
  // names is dropped here, on read, by the same `CorePhoneNumber.fromInput`
  // the Flutter `PhoneInput` uses. Reading rather than rewriting is what
  // lets a country change re-interpret the same text against the new dial
  // code.
  PhoneInputValue get _currentValue =>
      .fromInput(_country, _number, filterPlusCode: component.filterPlusCode);

  @override
  void initState() {
    super.initState();
    _country =
        component.initialValue?.country ??
        component.initialCountry ??
        CorePhoneInputContract.defaultInitialCountry;
    _number = _seedNumber ?? _kEmptyValue;
    _popover.addListener(_handlePopoverChanged);
    formValue = _currentValue;
  }

  void _handlePopoverChanged() {
    if (_popover.isOpen) {
      // Open on the current country, so Enter without moving keeps it.
      final current = _filteredCountries.indexOf(_country);
      setState(() => _highlight = current < 0 ? 0 : current);
      // The `autofocus` attribute is unreliable for a portal panel mounted
      // after paint, so focus the search field on the next frame (parity
      // with the Flutter search field's `autofocus`).
      scheduleNextFrame(() {
        focusInputWithin(_panelId);
        scrollElementIntoViewById(_optionId(_highlight));
      });
      return;
    }
    // Reset the search filter whenever the panel closes (the `Popover`
    // owns outside-click / Esc dismissal now).
    if (_searchQuery.isNotEmpty) {
      setState(() => _searchQuery = _kEmptyValue);
    }
  }

  void _toggleOpen() {
    if (!component.enabled) return;
    _popover.toggle();
  }

  void _selectCountry(CoreCountry country) {
    _popover.close();
    setState(() {
      _country = country;
    });
    formValue = _currentValue;
    component.onChanged?.call(_currentValue);
  }

  void _handleSearch(String value) {
    // Controlled only for filtering — the search field itself is uncontrolled
    // (setState re-filters the list; the field keeps its own caret / value).
    setState(() {
      _searchQuery = value;
      // A new filter is a new list — start again from its first match.
      _highlight = 0;
    });
  }

  /// Keys in the search field, which keeps DOM focus: Up/Down move the
  /// highlight and wrap, Enter picks it. Home/End and Left/Right stay with
  /// the field's caret (an editable combobox's text comes first); Escape is
  /// the `Popover`'s, which already closes on it.
  void _handleSearchKeyDown(web.KeyboardEvent event) {
    final visible = _filteredCountries;
    if (visible.isEmpty) return;
    switch (event.key) {
      case 'ArrowDown' || 'ArrowUp':
        event.preventDefault();
        final step = event.key == 'ArrowDown' ? 1 : -1;
        final next =
            ((_highlight + step) % visible.length + visible.length) %
            visible.length;
        setState(() => _highlight = next);
        scheduleNextFrame(() => scrollElementIntoViewById(_optionId(next)));
      case 'Enter':
        event.preventDefault();
        _selectCountry(visible[_highlight.clamp(0, visible.length - 1)]);
    }
  }

  void _handleNumber(String value) {
    // Uncontrolled — the field owns the caret; a setState here would reset
    // it, so this only mirrors the value into the form + notifies the
    // caller. Detection is the one exception: it only calls setState when
    // the detected country actually differs from the current one, so a
    // rebuild (and the caret reset that comes with it) happens exactly when
    // the selector's flag / dial code need to change — not on every
    // keystroke. `_selectCountry` (the dropdown) never routes through here,
    // so an explicit pick is never immediately overridden by detection.
    _number = value;
    final detected = CorePhoneCountryDetector.detect(
      value,
      _effectiveCountries,
    );
    if (detected != null && detected != _country) {
      setState(() {
        _country = detected;
      });
    }
    formValue = _currentValue;
    component.onChanged?.call(_currentValue);
  }

  Component _buildCountrySelector(ResolvedPhoneInput resolved) {
    return Component.element(
      tag: _kButtonTag,
      classes: resolved.countrySelector.className,
      styles: resolved.countrySelector.inlineStyles,
      attributes: {
        'type': 'button',
        'aria-label': CouiLocalizations.of(context).phoneInputSelectCountry,
        'aria-haspopup': 'listbox',
        'aria-expanded': _popover.isOpen ? 'true' : 'false',
        if (!component.enabled) _kDisabledAttribute: _kEmptyValue,
      },
      events: {
        // Prevent the button from taking focus on click. Otherwise the root's
        // `focus-within:` border lights up whenever the dropdown is opened or
        // closed via this trigger — the focus border must track only the phone
        // number field (mirrors Flutter, where the selector is a non-focusing
        // gesture detector). The click still toggles the popover.
        'mousedown': EventHandlers.createMouseEventHandler(
          (event) => event.preventDefault(),
        ),
        // Typed handler (no dynamic dispatch) so dart2js release
        // minification can't desync it. Toggles the manual-mode `Popover`.
        'click': EventHandlers.createMouseEventHandler((event) {
          event.stopPropagation();
          _toggleOpen();
        }),
      },
      children: [
        _flagImage(
          baseUrl: CouiAssetSourceScope.flagIconsBaseUrlOf(context),
          code: _country.code,
          boxClass: resolved.flag.className,
          boxStyles: resolved.flag.inlineStyles,
        ),
        Gap(gapStyle: resolved.flagGapStyle),
        Component.element(
          tag: _kSpanTag,
          classes: resolved.dialCode.className,
          styles: resolved.dialCode.inlineStyles,
          children: [Text(_country.dialCode)],
        ),
        Gap(gapStyle: resolved.flagGapStyle),
        Component.element(
          tag: 'svg',
          classes: resolved.chevron.className,
          styles: resolved.chevron.inlineStyles,
          attributes: const {
            'xmlns': 'http://www.w3.org/2000/svg',
            'viewBox': '0 0 24 24',
            'fill': 'none',
            'stroke': 'currentColor',
            'stroke-linecap': 'round',
            'stroke-linejoin': 'round',
          },
          children: const [
            Component.element(
              tag: 'polyline',
              attributes: {'points': '6 9 12 15 18 9'},
            ),
          ],
        ),
      ],
    );
  }

  Component _buildSearchInput(
    ResolvedPhoneInput resolved, {
    required int visibleCount,
  }) {
    final searchPlaceholder = CouiLocalizations.of(
      context,
    ).searchPlaceholderCountry;
    final hasHighlight = _highlight >= 0 && _highlight < visibleCount;
    // Wrapper carries the search-row layout (full width + border-bottom
    // divider + padding); the composed unified `TextField` is chromeless and
    // uncontrolled — its onChanged re-filters the list without resetting the
    // caret. A `mousedown` stop keeps the click-outside listener from closing.
    return Component.element(
      tag: _kDivTag,
      classes: resolved.searchInput.className,
      styles: resolved.searchInput.inlineStyles,
      events: {
        'mousedown': EventHandlers.createMouseEventHandler(
          (event) => event.stopPropagation(),
        ),
        // Bubbles up from the inner `<input>`. Typed handler, never a
        // `dynamic` cast — dart2js mangles those in release.
        'keydown': EventHandlers.createKeyboardEventHandler(
          _handleSearchKeyDown,
        ),
      },
      children: [
        // Part of this composite: walled off from the enclosing
        // `FormField`, which is shown the composite's own value.
        FormFieldHandleScope.boundary(
          child: TextField(
            onChanged: _handleSearch,
            autofocus: true,
            // The panel is the only boundary: the bare variant with the
            // search glyph in front, closed by the divider after the row.
            variant: .plain,
            prefix: Icon(
              LucideIcons.search,
              iconStyle: resolved.searchIconStyle,
            ),
            textFieldStyle: resolved.searchFieldStyle,
            hintText: searchPlaceholder,
            // `TextField` routes `role` / `aria-*` onto its `<input>` — the
            // element a screen reader is on — which is what lets the reader
            // follow the highlight through `aria-activedescendant`.
            attributes: {
              'role': 'combobox',
              'aria-expanded': 'true',
              'aria-controls': _listboxId,
              'aria-autocomplete': 'list',
              'aria-label': searchPlaceholder,
              if (hasHighlight) 'aria-activedescendant': _optionId(_highlight),
            },
          ),
        ),
      ],
    );
  }

  Component _buildDropdownItem(
    ResolvedPhoneInput resolved,
    CoreCountry country, {
    required int index,
  }) {
    return Component.element(
      tag: _kButtonTag,
      classes: resolved.dropdownItem.className,
      styles: resolved.dropdownItem.inlineStyles,
      attributes: {
        'type': 'button',
        'role': 'option',
        'id': _optionId(index),
        'aria-selected': index == _highlight ? 'true' : 'false',
        // Not a tab stop: the search field holds focus and the arrows move
        // the highlight. A pointer still clicks the row.
        'tabindex': '-1',
      },
      events: {
        'click': EventHandlers.createMouseEventHandler((event) {
          event.stopPropagation();
          _selectCountry(country);
        }),
      },
      children: [
        _flagImage(
          baseUrl: CouiAssetSourceScope.flagIconsBaseUrlOf(context),
          code: country.code,
          boxClass: resolved.dropdownItemFlag.className,
          boxStyles: resolved.dropdownItemFlag.inlineStyles,
        ),
        Gap(gapStyle: resolved.dropdownItemGapStyle),
        Component.element(
          tag: _kSpanTag,
          classes: resolved.dropdownItemName.className,
          styles: resolved.dropdownItemName.inlineStyles,
          children: [Text(country.name)],
        ),
        Gap(gapStyle: resolved.countryGapStyle),
        Component.element(
          tag: _kSpanTag,
          classes: resolved.dropdownItemDialCode.className,
          styles: resolved.dropdownItemDialCode.inlineStyles,
          children: [Text(country.dialCode)],
        ),
        // The selection is the check alone; the filled row is the one under
        // the pointer or the keyboard highlight.
        if (country == _country) ...[
          Gap(gapStyle: resolved.dropdownItemGapStyle),
          Icon(
            LucideIcons.check,
            iconStyle: resolved.dropdownCheckIconStyle,
          ),
        ],
      ],
    );
  }

  Component _buildCountryPanel(ResolvedPhoneInput resolved) {
    final visible = _filteredCountries;

    // The unified `Popover` provides the panel chrome (border / surface /
    // shadow / radius) + placement + portal mount, so this content only lays
    // out the fixed search field on top of the scrollable option list. The
    // [_panelId] lets the open handler focus the search field once mounted.
    return Component.element(
      tag: _kDivTag,
      id: _panelId,
      children: [
        _buildSearchInput(resolved, visibleCount: visible.length),
        Divider(dividerStyle: resolved.dividerStyle),
        Component.element(
          tag: _kDivTag,
          id: _listboxId,
          classes: resolved.dropdown.className,
          styles: resolved.dropdown.inlineStyles,
          attributes: {
            'role': 'listbox',
            'aria-label': CouiLocalizations.of(
              context,
            ).phoneInputSelectCountry,
          },
          children: [
            for (var i = 0; i < visible.length; i++)
              _buildDropdownItem(resolved, visible[i], index: i),
          ],
        ),
      ],
    );
  }

  Component _buildPhoneInput(ResolvedPhoneInput resolved) {
    // Wrapper carries the fill layout so its body typography cascades into
    // the chromeless field. The field stays uncontrolled — seeded once from
    // the initial number so the caret is never reset, mirroring the previous
    // raw input.
    return Component.element(
      tag: _kDivTag,
      classes: resolved.phoneInput.className,
      styles: resolved.phoneInput.inlineStyles,
      children: [
        // Part of this composite: walled off from the enclosing
        // `FormField`, which is shown the composite's own value.
        FormFieldHandleScope.boundary(
          child: TextField(
            onChanged: component.enabled ? _handleNumber : null,
            initialValue: _seedNumber,
            enabled: component.enabled,
            textFieldStyle: resolved.numberFieldStyle,
            type: .tel,
            // `allow(r'\d')` would forbid the `+` the typist now needs to
            // write for the dial code to be stripped at all.
            inputFormatters: component.onlyNumber
                ? [CoreInputFormatters.phoneText()]
                : const [],
            hintText: component.placeholder,
          ),
        ),
      ],
    );
  }

  @override
  void didUpdateComponent(covariant PhoneInput oldComponent) {
    super.didUpdateComponent(oldComponent);
    // `initialValue.country` outranks `initialCountry`, so re-seed from the
    // effective country rather than from `initialCountry` alone — otherwise a
    // caller that only moves `initialValue` never sees the selector follow.
    final next = component.initialValue?.country ?? component.initialCountry;
    final previous =
        oldComponent.initialValue?.country ?? oldComponent.initialCountry;
    if (next != null && next != previous) {
      _country = next;
    }
  }

  @override
  void didReplaceFormValue(PhoneInputValue value) {
    // The number `<input>` is uncontrolled (its `value` is seeded once from
    // `initialNumber`), so an async validator's normalised value is forwarded
    // to the caller via [onChanged] rather than written back into the field.
    component.onChanged?.call(value);
  }

  @override
  void dispose() {
    _popover.removeListener(_handlePopoverChanged);
    _popover.dispose();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolvePhoneInput(
      context,
      enabled: component.enabled,
      scopeId: _scopeId,
      phoneInputStyle: component.phoneInputStyle,
    );
    // Scoped `<style>` fallback for raw (token-less) pseudo-state colour
    // overrides (focus-within border / hover border / hover background /
    // placeholder text) that cannot ride a Tailwind pseudo class — empty on the default /
    // token path, so no `<style>` renders and the output is unchanged.
    final rules = resolvePhoneInputRules(
      context,
      scopeId: _scopeId,
      enabled: component.enabled,
      phoneInputStyle: component.phoneInputStyle,
    );
    final rootAttributes = <String, String>{
      ...component.componentAttributes,
      if (!component.enabled) _kDisabledAttribute: _kEmptyValue,
    };

    final rootEvents = component.events;

    final mergedCss = component.css != null
        ? Styles.combine([?resolved.root.inlineStyles, component.css!])
        : resolved.root.inlineStyles;

    // The bordered field row is the Popover trigger; caller passthrough
    // (id / classes / attributes / events) + the focus-within border live
    // here. The country panel is portal-mounted below the whole field
    // (`bottomStart`, matching Web `top-full left-0`) so it is never clipped.
    final field = Component.element(
      tag: _kDivTag,
      id: component.id,
      classes: component.rootClasses(resolved.root.className),
      styles: mergedCss,
      attributes: rootAttributes,
      events: rootEvents.isEmpty ? null : rootEvents,
      children: [
        // `<style>` is `display: none`, so it never affects the flex row
        // layout; CSS rules are document-global, so a single block here also
        // covers the portal-mounted dropdown rows / search field.
        if (rules.css.isNotEmpty)
          Component.element(tag: 'style', children: [RawText(rules.css)]),
        _buildCountrySelector(resolved),
        // The hairline between the selector and the number is shorter than
        // the row, centred in it.
        Component.element(
          tag: _kDivTag,
          classes: resolved.separator.className,
          styles: resolved.separator.inlineStyles,
          children: [
            Component.element(
              tag: _kDivTag,
              classes: resolved.separatorLine.className,
              styles: resolved.separatorLine.inlineStyles,
              children: [
                Divider(
                  orientation: .vertical,
                  dividerStyle: resolved.separatorDividerStyle,
                ),
              ],
            ),
          ],
        ),
        _buildPhoneInput(resolved),
      ],
    );

    return Popover(
      trigger: field,
      content: _buildCountryPanel(resolved),
      placement: .bottomStart,
      controller: _popover,
      openTrigger: .manual,
      widthConstraint: .anchorFixedSize,
      // Full-width input trigger (like Select) — fill the parent inline-axis
      // instead of the default `intrinsic` (which shrink-wraps the field).
      popoverStyle: resolved.popoverStyle,
    );
  }
}

/// Chain sugar mirroring the Flutter `PhoneInput.withStyle` extension —
/// merges a [CorePhoneInputStyle] patch into [PhoneInput.phoneInputStyle]
/// via the existing [PhoneInput.copyWith].
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
