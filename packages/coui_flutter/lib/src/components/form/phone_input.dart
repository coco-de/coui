import 'package:country_flags/country_flags.dart';
import 'package:flutter/services.dart';

import 'package:coui_flutter/coui_flutter.dart';

class PhoneNumber {
  const PhoneNumber(this.country, this.number);

  final Country country;

  final String number; // without country code

  String get fullNumber => '${country.dialCode}$number';

  String? get value => number.isEmpty ? null : fullNumber;

  @override
  String toString() {
    return number.isEmpty ? '' : fullNumber;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PhoneNumber &&
        other.country == country &&
        other.number == number;
  }

  @override
  int get hashCode {
    return country.hashCode ^ number.hashCode;
  }
}

/// Theme data for [PhoneInput].
class PhoneInputTheme {
  /// Theme data for [PhoneInput].
  const PhoneInputTheme({
    this.borderRadius,
    this.countryGap,
    this.flagGap,
    this.flagHeight,
    this.flagShape,
    this.flagWidth,
    this.maxWidth,
    this.padding,
    this.popupConstraints,
  });

  /// The padding of the [PhoneInput].
  final EdgeInsetsGeometry? padding;

  /// The border radius of the [PhoneInput].
  final BorderRadiusGeometry? borderRadius;

  /// The constraints of the country selector popup.
  final BoxConstraints? popupConstraints;

  /// The maximum width of the [PhoneInput].
  final double? maxWidth;

  /// The height of the flag.
  final double? flagHeight;

  /// The width of the flag.
  final double? flagWidth;

  /// The gap between the flag and the country code.
  final double? flagGap;

  /// The gap between the country code and the text field.
  final double? countryGap;

  /// The shape of the flag.
  final Shape? flagShape;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PhoneInputTheme &&
        other.padding == padding &&
        other.borderRadius == borderRadius &&
        other.popupConstraints == popupConstraints &&
        other.maxWidth == maxWidth &&
        other.flagHeight == flagHeight &&
        other.flagWidth == flagWidth &&
        other.flagGap == flagGap &&
        other.countryGap == countryGap &&
        other.flagShape == flagShape;
  }

  @override
  String toString() {
    return 'PhoneInputTheme(padding: $padding, borderRadius: $borderRadius, popupConstraints: $popupConstraints, maxWidth: $maxWidth, flagHeight: $flagHeight, flagWidth: $flagWidth, flagGap: $flagGap, countryGap: $countryGap, flagShape: $flagShape)';
  }

  @override
  int get hashCode => Object.hash(
    padding,
    borderRadius,
    popupConstraints,
    maxWidth,
    flagHeight,
    flagWidth,
    flagGap,
    countryGap,
    flagShape,
  );
}

/// A specialized input widget for entering international phone numbers.
///
/// This widget provides a comprehensive phone number input interface with
/// country selection, automatic formatting, and validation. It displays a
/// country flag, country code, and a text field for the phone number,
/// handling the complexities of international phone number formats.
///
/// The component automatically filters input to ensure only valid phone
/// number characters are entered, and provides a searchable country
/// selector popup for easy country selection. It integrates with the form
/// system to provide phone number validation and data collection.
///
/// Example:
/// ```dart
/// PhoneInput(
///   initialCountry: Country.unitedStates,
///   onChanged: (phoneNumber) {
///     print('Phone: ${phoneNumber.fullNumber}');
///     print('Country: ${phoneNumber.country.name}');
///   },
///   searchPlaceholder: Text('Search countries...'),
/// );
/// ```
class PhoneInput extends StatefulWidget {
  /// Creates a [PhoneInput] widget.
  ///
  /// The widget can be initialized with a specific country or complete phone
  /// number. Various filtering options control how user input is processed
  /// to ensure valid phone number format.
  ///
  /// Parameters:
  /// - [initialCountry] (Country?, optional): Default country when no initial value provided
  /// - [initialValue] (PhoneNumber?, optional): Complete initial phone number with country
  /// - [onChanged] (ValueChanged<PhoneNumber>?, optional): Callback for phone number changes
  /// - [controller] (TextEditingController?, optional): Controller for the number input field
  /// - [filterPlusCode] (bool, default: true): Whether to filter out plus symbols
  /// - [filterZeroCode] (bool, default: true): Whether to filter out leading zeros
  /// - [filterCountryCode] (bool, default: true): Whether to filter out country codes
  /// - [onlyNumber] (bool, default: true): Whether to allow only numeric input
  /// - [countries] (List<Country>?, optional): Specific countries to show in selector
  /// - [searchPlaceholder] (Widget?, optional): Placeholder for country search field
  ///
  /// Example:
  /// ```dart
  /// PhoneInput(
  ///   initialCountry: Country.canada,
  ///   filterPlusCode: true,
  ///   onChanged: (phone) => _validatePhoneNumber(phone),
  /// );
  /// ```
  const PhoneInput({
    this.controller,
    this.countries,
    this.filterCountryCode = true,
    this.filterPlusCode = true,
    this.filterZeroCode = true,
    this.initialCountry,
    this.initialValue,
    super.key,
    this.onChanged,
    this.onlyNumber = true,
  });

  /// The default country to display when no initial value is provided.
  ///
  /// If both [initialCountry] and [initialValue] are null, defaults to
  /// United States. When [initialValue] is provided, its country takes
  /// precedence over this setting.
  final Country? initialCountry;

  /// The initial phone number value including country and number.
  ///
  /// When provided, both the country selector and number field are
  /// initialized with the values from this phone number. Takes precedence
  /// over [initialCountry] for country selection.
  final PhoneNumber? initialValue;

  /// Callback invoked when the phone number changes.
  ///
  /// Called whenever the user changes either the country selection or
  /// the phone number text. The callback receives a [PhoneNumber] object
  /// containing both the selected country and entered number.
  final ValueChanged<PhoneNumber>? onChanged;

  /// Optional text editing controller for the number input field.
  ///
  /// When provided, this controller manages the text content of the phone
  /// number input field. If null, an internal controller is created and managed.
  final TextEditingController? controller;

  /// Whether to filter out plus (+) symbols from input.
  ///
  /// When true, plus symbols are automatically removed from user input
  /// since the country code already provides the international prefix.
  final bool filterPlusCode;

  /// Whether to filter out leading zeros from input.
  ///
  /// When true, leading zeros are automatically removed from the phone number
  /// to normalize the input format according to international standards.
  final bool filterZeroCode;

  /// Whether to filter out country codes from input.
  ///
  /// When true, prevents users from entering the country code digits manually
  /// since the country selector provides this information automatically.
  final bool filterCountryCode;

  /// Whether to allow only numeric characters in the input.
  ///
  /// When true, restricts input to numeric characters only, removing
  /// any letters, symbols, or formatting characters that users might enter.
  final bool onlyNumber;

  /// Optional list of countries to display in the country selector.
  ///
  /// When provided, only these countries will be available for selection
  /// in the country picker popup. If null, all supported countries are available.
  final List<Country>? countries;

  @override
  State<PhoneInput> createState() => _PhoneInputState();
}

class _PhoneInputState extends State<PhoneInput>
    with FormValueSupplier<PhoneNumber, PhoneInput> {
  late Country _country;
  late TextEditingController _controller;

  static bool _filterCountryCode(Country country, String text) {
    return country.name.toLowerCase().contains(text) ||
        country.dialCode.contains(text) ||
        country.code.toLowerCase().contains(text);
  }

  @override
  void initState() {
    super.initState();
    _country =
        widget.initialCountry ??
        widget.initialValue?.country ??
        Country.unitedStates;
    _controller =
        widget.controller ??
        TextEditingController(text: widget.initialValue?.number);
    formValue = value;
    _controller.addListener(_dispatchChanged);
  }

  void _dispatchChanged() {
    widget.onChanged?.call(value);
    formValue = value;
  }

  @override
  void didUpdateWidget(covariant PhoneInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _controller.removeListener(_dispatchChanged);
      _controller = widget.controller ?? TextEditingController();
      _controller.addListener(_dispatchChanged);
    }
  }

  @override
  void didReplaceFormValue(PhoneNumber value) {
    _controller.text = value.toString();
  }

  PhoneNumber get value {
    String text = _controller.text;
    if (widget.filterPlusCode && text.startsWith(_country.dialCode)) {
      text = text.substring(_country.dialCode.length);
    } else if (widget.filterPlusCode && text.startsWith('+')) {
      text = text.substring(1);
    } else if (widget.filterZeroCode && text.startsWith('0')) {
      text = text.substring(1);

      /// E.g. 628123456788 (indonesia) would be 8123456788.
    } else if (widget.filterCountryCode &&
        text.startsWith(_country.dialCode.substring(1))) {
      text = text.substring(_country.dialCode.length - 1);
    }

    return PhoneNumber(_country, text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final componentTheme = ComponentTheme.maybeOf<PhoneInputTheme>(context);

    return IntrinsicHeight(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Select<Country>(
            borderRadius: styleValue(
              themeValue: componentTheme?.borderRadius,
              defaultValue: BorderRadius.only(
                topLeft: theme.radiusMdRadius,
                bottomLeft: theme.radiusMdRadius,
              ),
            ),
            itemBuilder: (context, item) {
              return Row(
                children: [
                  CountryFlag.fromCountryCode(
                    item.code,
                    theme: ImageTheme(
                      width: styleValue(
                        themeValue: componentTheme?.flagWidth,
                        defaultValue: theme.scaling * 24,
                      ),
                      shape: styleValue(
                        themeValue: componentTheme?.flagShape,
                        defaultValue: RoundedRectangle(theme.radiusSm),
                      ),
                    ),
                  ),
                  Gap(
                    styleValue(
                      themeValue: componentTheme?.flagGap,
                      defaultValue: theme.scaling * 8,
                    ),
                  ),
                  Text(item.dialCode),
                ],
              );
            },
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _country = value;
                  _dispatchChanged();
                });
              }
            },
            padding: styleValue(
              themeValue: componentTheme?.padding,
              defaultValue: EdgeInsets.only(
                left: theme.scaling * 8,
                top: theme.scaling * 8,
                right: theme.scaling * 4,
                bottom: theme.scaling * 8,
              ),
            ),
            popoverAlignment: Alignment.topLeft,
            popoverAnchorAlignment: Alignment.bottomLeft,
            popup: SelectPopup<Country>.builder(
              builder: (context, searchQuery) {
                return SelectItemList(
                  children: [
                    for (final country in widget.countries ?? Country.values)
                      if (searchQuery == null ||
                          _filterCountryCode(country, searchQuery))
                        SelectItemButton(
                          value: country,
                          child: Row(
                            children: [
                              CountryFlag.fromCountryCode(
                                country.code,
                                theme: ImageTheme(
                                  width: styleValue(
                                    themeValue: componentTheme?.flagWidth,
                                    defaultValue: theme.scaling * 24,
                                  ),
                                  shape: styleValue(
                                    themeValue: componentTheme?.flagShape,
                                    defaultValue: RoundedRectangle(
                                      theme.radiusSm,
                                    ),
                                  ),
                                ),
                              ),
                              Gap(
                                styleValue(
                                  themeValue: componentTheme?.flagGap,
                                  defaultValue: theme.scaling * 8,
                                ),
                              ),
                              Expanded(child: Text(country.name)),
                              Gap(
                                styleValue(
                                  themeValue: componentTheme?.countryGap,
                                  defaultValue: theme.scaling * 16,
                                ),
                              ),
                              Text(country.dialCode).muted(),
                            ],
                          ),
                        ),
                  ],
                );
              },
            ).asBuilder,
            popupConstraints: styleValue(
              themeValue: componentTheme?.popupConstraints,
              defaultValue: BoxConstraints(
                maxWidth: theme.scaling * 250,
                maxHeight: theme.scaling * 300,
              ),
            ),
            popupWidthConstraint: PopoverConstraint.flexible,
            value: _country,
          ),
          LimitedBox(
            maxWidth: styleValue(
              themeValue: componentTheme?.maxWidth,
              defaultValue: theme.scaling * 200,
            ),
            child: TextField(
              initialValue: widget.initialValue?.number,
              autofillHints: const [AutofillHints.telephoneNumber],
              borderRadius: styleValue(
                themeValue: componentTheme?.borderRadius,
                defaultValue: BorderRadius.only(
                  topRight: theme.radiusMdRadius,
                  bottomRight: theme.radiusMdRadius,
                ),
              ),
              controller: _controller,
              inputFormatters: [
                if (widget.onlyNumber) FilteringTextInputFormatter.digitsOnly,
              ],
              keyboardType: widget.onlyNumber ? TextInputType.phone : null,
            ),
          ),
        ],
      ),
    );
  }
}
