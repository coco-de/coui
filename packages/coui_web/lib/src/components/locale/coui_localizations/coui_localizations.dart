import 'package:coui_core/coui_core.dart' show CoreClockFormat;
import 'package:jaspr/jaspr.dart';

import 'ar_coui_localizations.dart';
import 'coui_localizations_scope.dart';
import 'de_coui_localizations.dart';
import 'es_coui_localizations.dart';
import 'fr_coui_localizations.dart';
import 'it_coui_localizations.dart';
import 'ja_coui_localizations.dart';
import 'ko_coui_localizations.dart';
import 'pt_coui_localizations.dart';
import 'ru_coui_localizations.dart';
import 'zh_hans_coui_localizations.dart';

// Locale-implementation registry keyed by bare ISO language code (country
// / script subtags are ignored). Add a new locale by adding one entry
// here — mirrors the Flutter `CoUILocalizationsDelegate` registry.
// Every entry except `en` (the Default below) is generated from the single
// slang source in packages/coui_i10n/chrome/ — see
// `cross-platform/localization.md` "번역 파이프라인". `zh` serves the
// Simplified Chinese strings for every Chinese locale.
const _kCouiLocalizationsByLanguageCode = <String, CouiLocalizations>{
  'ar': ArCouiLocalizations(),
  'de': DeCouiLocalizations(),
  'es': EsCouiLocalizations(),
  'fr': FrCouiLocalizations(),
  'it': ItCouiLocalizations(),
  'ja': JaCouiLocalizations(),
  'ko': KoCouiLocalizations(),
  'pt': PtCouiLocalizations(),
  'ru': RuCouiLocalizations(),
  'zh': ZhHansCouiLocalizations(),
};

/// Resolves the [CouiLocalizations] implementation for [languageCode],
/// falling back to [DefaultCouiLocalizations.instance] when [languageCode]
/// has no registered implementation.
CouiLocalizations resolveCouiLocalizationsFor(String languageCode) {
  return _kCouiLocalizationsByLanguageCode[languageCode] ??
      DefaultCouiLocalizations.instance;
}

/// Date part enumeration for localization.
enum DatePart {
  /// Day of month.
  day,

  /// Month of year.
  month,

  /// Year.
  year,
}

/// Time part enumeration for localization.
enum TimePart {
  /// Hour component.
  hour,

  /// Minute component.
  minute,

  /// Second component.
  second,
}

/// Time of day representation for web.
class TimeOfDay {
  /// Creates a TimeOfDay.
  const TimeOfDay({required this.hour, required this.minute, this.second = 0});

  /// Hour (0-23).
  final int hour;

  /// Minute (0-59).
  final int minute;

  /// Second (0-59).
  final int second;
}

/// Size unit locale configuration.
class SizeUnitLocale {
  /// Creates a SizeUnitLocale.
  const SizeUnitLocale(this.base, this.units);

  /// Base for unit conversion (e.g. 1024 for bytes).
  final int base;

  /// Unit labels in ascending order.
  final List<String> units;
}

/// Abstract localization interface for CoUI web components.
///
/// Provides localized strings and formatting functions for UI components.
/// This is the web equivalent of the Flutter CoUILocalizations, providing
/// the same localization contract without Flutter framework dependencies.
///
/// Key Features:
/// - **Date/Time Formatting**: Locale-aware date and time formatting.
/// - **Form Validation Messages**: Localized form error strings.
/// - **UI Labels**: Component-specific label strings.
/// - **Number Formatting**: Locale-aware number display.
/// - **Duration Formatting**: Human-readable duration strings.
///
/// Example:
/// ```dart
/// final localizations = DefaultCouiLocalizations.instance;
/// final formatted = localizations.formatDateTime(DateTime.now());
/// final error = localizations.formNotEmpty;
/// ```
abstract class CouiLocalizations {
  /// Creates a CouiLocalizations instance.
  const CouiLocalizations();

  /// Gets the default instance.
  static CouiLocalizations get instance => DefaultCouiLocalizations.instance;

  /// Retrieves the nearest [CouiLocalizations] from [context]'s ambient
  /// [CouiLocalizationsScope], or `null` if none is found.
  static CouiLocalizations? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedComponentOfExactType<CouiLocalizationsScope>()
        ?.localizations;
  }

  /// Retrieves the nearest [CouiLocalizations] from [context]'s ambient
  /// [CouiLocalizationsScope], falling back to
  /// [DefaultCouiLocalizations.instance] when no scope is found — mirrors
  /// Flutter `CoUILocalizations.of(context)`'s exact
  /// `Localizations.of(context, CoUILocalizations) ??
  /// DefaultCoUILocalizations.instance` semantics.
  static CouiLocalizations of(BuildContext context) {
    return maybeOf(context) ?? DefaultCouiLocalizations.instance;
  }

  /// Formats a number for display.
  String formatNumber(double value);

  /// Form validation: less than.
  String formLessThan(double value);

  /// Form validation: greater than.
  String formGreaterThan(double value);

  /// Form validation: less than or equal to.
  String formLessThanOrEqualTo(double value);

  /// Form validation: greater than or equal to.
  String formGreaterThanOrEqualTo(double value);

  /// Form validation: between inclusively.
  String formBetweenInclusively(double max, double min);

  /// Form validation: between exclusively.
  String formBetweenExclusively(double max, double min);

  /// Form validation: minimum length.
  String formLengthLessThan(int value);

  /// Form validation: maximum length.
  String formLengthGreaterThan(int value);

  /// Gets the abbreviation for a date part.
  String getDatePartAbbreviation(DatePart part) {
    switch (part) {
      case .year:
        return dateYearAbbreviation;

      case .month:
        return dateMonthAbbreviation;

      case .day:
        return dateDayAbbreviation;
    }
  }

  /// Formats a DateTime for display.
  String formatDateTime(
    DateTime dateTime, {
    bool showDate = true,
    bool showSeconds = false,
    bool showTime = true,
    bool use24HourFormat = true,
  });

  /// Formats a TimeOfDay for display.
  String formatTimeOfDay(
    TimeOfDay time, {
    bool showSeconds = false,
    bool use24HourFormat = true,
  });

  /// Data table selected rows label.
  String dataTableSelectedRows(int count, int total);

  /// Gets abbreviated weekday name.
  String getAbbreviatedWeekday(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return abbreviatedMonday;

      case DateTime.tuesday:
        return abbreviatedTuesday;

      case DateTime.wednesday:
        return abbreviatedWednesday;

      case DateTime.thursday:
        return abbreviatedThursday;

      case DateTime.friday:
        return abbreviatedFriday;

      case DateTime.saturday:
        return abbreviatedSaturday;

      case DateTime.sunday:
        return abbreviatedSunday;

      default:
        throw ArgumentError.value(weekday, 'weekday');
    }
  }

  /// Formats a month of a year for display — the header above a calendar
  /// month grid (`January 2026`, `2026년 1월`, `2026年1月`).
  ///
  /// Word order is the locale's (CLDR `yMMMM`), so a header can't be built
  /// by concatenating [getMonth] and the year. Locale classes override this;
  /// the base keeps the English order so a custom locale written before
  /// this member existed keeps compiling.
  String formatMonthYear(int month, int year) => '${getMonth(month)} $year';

  /// Gets full month name.
  String getMonth(int month) {
    switch (month) {
      case DateTime.january:
        return monthJanuary;

      case DateTime.february:
        return monthFebruary;

      case DateTime.march:
        return monthMarch;

      case DateTime.april:
        return monthApril;

      case DateTime.may:
        return monthMay;

      case DateTime.june:
        return monthJune;

      case DateTime.july:
        return monthJuly;

      case DateTime.august:
        return monthAugust;

      case DateTime.september:
        return monthSeptember;

      case DateTime.october:
        return monthOctober;

      case DateTime.november:
        return monthNovember;

      case DateTime.december:
        return monthDecember;

      default:
        throw ArgumentError.value(month, 'month');
    }
  }

  /// Gets abbreviated month name.
  String getAbbreviatedMonth(int month) {
    switch (month) {
      case DateTime.january:
        return abbreviatedJanuary;

      case DateTime.february:
        return abbreviatedFebruary;

      case DateTime.march:
        return abbreviatedMarch;

      case DateTime.april:
        return abbreviatedApril;

      case DateTime.may:
        return abbreviatedMay;

      case DateTime.june:
        return abbreviatedJune;

      case DateTime.july:
        return abbreviatedJuly;

      case DateTime.august:
        return abbreviatedAugust;

      case DateTime.september:
        return abbreviatedSeptember;

      case DateTime.october:
        return abbreviatedOctober;

      case DateTime.november:
        return abbreviatedNovember;

      case DateTime.december:
        return abbreviatedDecember;

      default:
        throw ArgumentError.value(month, 'month');
    }
  }

  /// Formats a Duration for display.
  String formatDuration(
    Duration duration, {
    bool showDays = true,
    bool showHours = true,
    bool showMinutes = true,
    bool showSeconds = true,
  });

  /// Gets the abbreviation for a time part.
  String getTimePartAbbreviation(TimePart part) {
    switch (part) {
      case .hour:
        return timeHoursAbbreviation;

      case .minute:
        return timeMinutesAbbreviation;

      case .second:
        return timeSecondsAbbreviation;
    }
  }

  /// Form validation: not empty.
  String get formNotEmpty;

  /// Message for a phone number that has a country but no digits yet.
  String get phoneNumberIncomplete;

  /// Invalid value message.
  String get invalidValue;

  /// Invalid email message.
  String get invalidEmail;

  /// Invalid URL message.
  String get invalidURL;

  /// Password must contain digits.
  String get formPasswordDigits;

  /// Password must contain lowercase.
  String get formPasswordLowercase;

  /// Password must contain uppercase.
  String get formPasswordUppercase;

  /// Password must contain special character.
  String get formPasswordSpecial;

  /// Ordered list of date parts for locale.
  List<DatePart> get datePartsOrder;

  /// Year abbreviation.
  String get dateYearAbbreviation;

  /// Month abbreviation.
  String get dateMonthAbbreviation;

  /// Day abbreviation.
  String get dateDayAbbreviation;

  /// Command search placeholder.
  String get commandSearch;

  /// Command empty results.
  String get commandEmpty;

  /// Date picker select year label.
  String get datePickerSelectYear;

  /// Abbreviated Monday.
  String get abbreviatedMonday;

  /// Abbreviated Tuesday.
  String get abbreviatedTuesday;

  /// Abbreviated Wednesday.
  String get abbreviatedWednesday;

  /// Abbreviated Thursday.
  String get abbreviatedThursday;

  /// Abbreviated Friday.
  String get abbreviatedFriday;

  /// Abbreviated Saturday.
  String get abbreviatedSaturday;

  /// Abbreviated Sunday.
  String get abbreviatedSunday;

  /// Full month name: January.
  String get monthJanuary;

  /// Full month name: February.
  String get monthFebruary;

  /// Full month name: March.
  String get monthMarch;

  /// Full month name: April.
  String get monthApril;

  /// Full month name: May.
  String get monthMay;

  /// Full month name: June.
  String get monthJune;

  /// Full month name: July.
  String get monthJuly;

  /// Full month name: August.
  String get monthAugust;

  /// Full month name: September.
  String get monthSeptember;

  /// Full month name: October.
  String get monthOctober;

  /// Full month name: November.
  String get monthNovember;

  /// Full month name: December.
  String get monthDecember;

  /// Abbreviated January.
  String get abbreviatedJanuary;

  /// Abbreviated February.
  String get abbreviatedFebruary;

  /// Abbreviated March.
  String get abbreviatedMarch;

  /// Abbreviated April.
  String get abbreviatedApril;

  /// Abbreviated May.
  String get abbreviatedMay;

  /// Abbreviated June.
  String get abbreviatedJune;

  /// Abbreviated July.
  String get abbreviatedJuly;

  /// Abbreviated August.
  String get abbreviatedAugust;

  /// Abbreviated September.
  String get abbreviatedSeptember;

  /// Abbreviated October.
  String get abbreviatedOctober;

  /// Abbreviated November.
  String get abbreviatedNovember;

  /// Abbreviated December.
  String get abbreviatedDecember;

  /// Cancel button label.
  String get buttonCancel;

  /// Submit button label.
  String get buttonSubmit;

  /// OK button label.
  String get buttonOk;

  /// Close button label.
  String get buttonClose;

  /// Rich editor toolbar group label.
  String get richEditorToolbar;

  /// Rich editor bold button.
  String get richEditorBold;

  /// Rich editor italic button.
  String get richEditorItalic;

  /// Rich editor strikethrough button.
  String get richEditorStrikethrough;

  /// Rich editor inline code button.
  String get richEditorCode;

  /// Rich editor link button and link dialog title.
  String get richEditorLink;

  /// Rich editor bulleted list button.
  String get richEditorBulletedList;

  /// Rich editor numbered list button.
  String get richEditorNumberedList;

  /// Rich editor checklist button.
  String get richEditorTaskList;

  /// Rich editor quote button.
  String get richEditorQuote;

  /// Rich editor link dialog URL field label.
  String get richEditorLinkUrl;

  /// Rich editor link dialog remove action.
  String get richEditorLinkRemove;

  /// Rich editor link dialog error for an unsafe or empty URL.
  String get richEditorLinkInvalid;

  /// Rich editor heading 1 button — the largest heading level.
  String get richEditorHeading1;

  /// Rich editor heading 2 button.
  String get richEditorHeading2;

  /// Rich editor heading 3 button.
  String get richEditorHeading3;

  /// Rich editor block-type menu: a plain paragraph.
  String get richEditorParagraph;

  /// What the rich editor's block-type button picks — the first half of
  /// its accessible name ("Block type: Text").
  String get richEditorBlockType;

  /// Name of the rich editor toolbar that floats over a selection.
  String get richEditorSelectionToolbar;

  /// Rich editor image button.
  String get richEditorImage;

  /// Rich editor notice while a picked image is uploading.
  String get richEditorImageUploading;

  /// Rich editor notice when an image upload fails.
  String get richEditorImageUploadFailed;

  /// Rich editor notice when an image is over the size limit.
  String get richEditorImageTooLarge;

  /// Rich editor notice when an image is not an allowed file type.
  String get richEditorImageNotAllowed;

  /// Rich editor placeholder for an image that cannot be displayed.
  String get richEditorImageUnavailable;

  /// `NumberInput` decrease button name — the accessible name of the minus
  /// button.
  String get numberInputDecrease;

  /// `NumberInput` increase button name — the accessible name of the plus
  /// button.
  String get numberInputIncrease;

  /// Save button label.
  String get buttonSave;

  /// Reset button label.
  String get buttonReset;

  /// Hour label.
  String get timeHour;

  /// Minute label.
  String get timeMinute;

  /// Second label.
  String get timeSecond;

  /// AM label.
  String get timeAM;

  /// PM label.
  String get timePM;

  /// Color red label.
  String get colorRed;

  /// Color green label.
  String get colorGreen;

  /// Color blue label.
  String get colorBlue;

  /// Color alpha label.
  String get colorAlpha;

  /// Color hue label.
  String get colorHue;

  /// Color saturation label.
  String get colorSaturation;

  /// Color value label.
  String get colorValue;

  /// Color lightness label.
  String get colorLightness;

  /// Menu cut label.
  String get menuCut;

  /// Menu copy label.
  String get menuCopy;

  /// Menu paste label.
  String get menuPaste;

  /// Menu select all label.
  String get menuSelectAll;

  /// Menu undo label.
  String get menuUndo;

  /// Menu redo label.
  String get menuRedo;

  /// Menu delete label.
  String get menuDelete;

  /// Menu share label.
  String get menuShare;

  /// Menu search web label.
  String get menuSearchWeb;

  /// Menu live text input label.
  String get menuLiveTextInput;

  /// Date picker placeholder.
  String get placeholderDatePicker;

  /// Time picker placeholder.
  String get placeholderTimePicker;

  /// Color picker placeholder.
  String get placeholderColorPicker;

  /// Previous button label.
  String get buttonPrevious;

  /// Next button label.
  String get buttonNext;

  /// Refresh trigger pull label.
  String get refreshTriggerPull;

  /// Refresh trigger release label.
  String get refreshTriggerRelease;

  /// Refresh trigger refreshing label.
  String get refreshTriggerRefreshing;

  /// Refresh trigger complete label.
  String get refreshTriggerComplete;

  /// Country search placeholder.
  String get searchPlaceholderCountry;

  /// Empty country list message.
  String get emptyCountryList;

  /// Toast snippet copied message.
  String get toastSnippetCopied;

  /// Color picker tab: Recent.
  String get colorPickerTabRecent;

  /// Color picker tab: RGB.
  String get colorPickerTabRGB;

  /// Color picker tab: HSV.
  String get colorPickerTabHSV;

  /// Color picker tab: HSL.
  String get colorPickerTabHSL;

  /// Footer hint after the ↑ ↓ key pair of a command palette.
  String get commandMove;

  /// Command move up label.
  @Deprecated(
    'Use commandMove (since 0.176) — the command footer labels the ↑ ↓ '
    'pair with one word for moving either way; a one-direction label '
    'misnamed the pair.',
  )
  String get commandMoveUp;

  /// Command move down label.
  @Deprecated(
    'Use commandMove (since 0.176) — the command footer labels the ↑ ↓ '
    'pair with one word for moving either way; a one-direction label '
    'misnamed the pair.',
  )
  String get commandMoveDown;

  /// Command activate label.
  String get commandActivate;

  /// Command scope (Arrow Left / Right) hint label.
  String get commandMoveScope;

  /// Command dismiss (Escape) hint label.
  String get commandDismiss;

  /// The automatic "All" scope chip.
  String get commandScopeAll;

  /// Empty-state description naming the two ways out.
  String get commandEmptyHint;

  /// Data table next label.
  String get dataTableNext;

  /// Data table previous label.
  String get dataTablePrevious;

  /// Data table columns label.
  String get dataTableColumns;

  /// Days abbreviation.
  String get timeDaysAbbreviation;

  /// Hours abbreviation.
  String get timeHoursAbbreviation;

  /// Minutes abbreviation.
  String get timeMinutesAbbreviation;

  /// Seconds abbreviation.
  String get timeSecondsAbbreviation;

  /// Duration picker placeholder.
  String get placeholderDurationPicker;

  /// Duration day label.
  String get durationDay;

  /// Duration hour label.
  String get durationHour;

  /// Duration minute label.
  String get durationMinute;

  /// Duration second label.
  String get durationSecond;

  /// File input drop-zone label.
  String get fileInputDropLabel;

  /// File input browse button label.
  String get fileInputBrowseButton;

  /// File input folder button label.
  String get fileInputFolderButton;

  /// Accessible name for the file input save button.
  String get fileInputSaveButton;

  /// Announcement when a drag picks an item up.
  String get dragAnnouncePickedUp;

  /// Announcement when a drag enters a drop target.
  String get dragAnnounceEnteredTarget;

  /// Announcement when a drag is released.
  String get dragAnnounceDropped;

  /// Announcement when a drag ends without a drop.
  String get dragAnnounceCancelled;

  /// Accessible name for a `Sortable` drag handle — which item, of how many.
  String sortableHandleLabel(int position, int count);

  /// How to reorder a `Sortable` item from the keyboard.
  String get sortableHandleHint;

  /// Announcement when a `Sortable` item is picked up from the keyboard.
  String sortableAnnouncePickedUp(int position, int count);

  /// Announcement when a carried `Sortable` item reaches a new position.
  String sortableAnnounceMoved(int position, int count);

  /// Announcement when a carried `Sortable` item is dropped.
  String sortableAnnounceDropped(int position, int count);

  /// Announcement when a `Sortable` keyboard move is abandoned.
  String sortableAnnounceCancelled(int position, int count);

  /// Accessible name for an image in `HoverGallery`.
  String galleryImageLabel(int index);

  /// Accessible name for the `Tracker` region.
  String get trackerLabel;

  /// Accessible name for a `ScrollableClient` region — the only
  /// identity assistive tech gets when the caller's own content carries
  /// none (e.g. a bare canvas), so it can be discovered by Tab/screen
  /// reader navigation instead of being silently skipped.
  String get scrollableRegionLabel;

  /// Accessible name for the `InputOTP` field.
  String get inputOtpLabel;

  /// Accessible name for a recent-colour swatch.
  String colorPickerRecentColor(String value);

  /// Accessible name for a `Stepper` step.
  String stepperStepLabel(String label, int number);

  /// The value a segmented `Progress` reports to assistive technology — the
  /// step reached, of how many. Not shown on screen.
  String progressStepValue(int current, int total);

  /// Accessible name for a pagination jump control.
  String paginationJumpToPage(int page);

  /// Accessible name for a dot-indicator control.
  String dotIndicatorGoToItem(int index);

  /// Read-only indicator position for a non-interactive sequence.
  String dotIndicatorPosition(int current, int total);

  // ── Chrome strings surfaced to the user (visible or via AT) ──

  /// Search field placeholder in `ItemPicker`.
  String get itemPickerSearchPlaceholder;

  /// Empty-state text in `ItemPicker`.
  String get itemPickerEmpty;

  /// Search field placeholder in `Select`.
  String get selectSearchPlaceholder;

  /// Empty-state text in `Select`.
  String get selectEmpty;

  /// Accessible name for the `Alert` region.
  String get alertLabel;

  /// Accessible name for the `Banner` region.
  String get bannerLabel;

  /// Accessible name for a dismiss control.
  String get dismissLabel;

  /// Accessible name for an overflow / more control.
  String get moreLabel;

  /// Accessible name for the `Pagination` navigation.
  /// Accessible name for the page's primary content landmark.
  ///
  /// One per page — it is what a screen-reader user jumps to in order to
  /// skip the header and navigation.
  String get mainLabel;

  /// Accessible name for the `Footer` landmark.
  String get footerLabel;

  /// Accessible name for the `Dock` navigation landmark.
  String get dockLabel;

  /// Accessible name for the `HeroSection` region.
  String get heroSectionLabel;

  /// Accessible name for a `Window` region.
  String get windowLabel;

  String get paginationLabel;

  /// Accessible name for the `Breadcrumb` navigation.
  String get breadcrumbLabel;

  /// Accessible name for a navigation region.
  String get navigationLabel;

  /// Accessible name for the `Menubar` region.
  String get menubarLabel;

  /// Accessible name for the `Carousel` region.
  String get carouselLabel;

  /// Accessible name for the carousel previous control.
  String get carouselPreviousSlide;

  /// Accessible name for the carousel next control.
  String get carouselNextSlide;

  /// Accessible name for the `Calendar` region.
  String get calendarLabel;

  /// Accessible name for navigation to the previous calendar period.
  String get calendarPreviousPeriod;

  /// Accessible name for navigation to the next calendar period.
  String get calendarNextPeriod;

  /// Spoken after a marked `Calendar` date when the marker carries no
  /// label of its own — how many items fall on that date.
  String calendarMarkerCount(int count);

  /// Accessible name for the `Scaffold` region.
  String get scaffoldLabel;

  /// Accessible name for the `ChipInput` field.
  String get chipInputLabel;

  /// Accessible name for a `Chip`'s remove button, naming the chip it
  /// removes. Icon-only buttons carry no text of their own, so without
  /// this a screen reader announces a row of identical unnamed buttons.
  String chipRemoveLabel(String label);

  /// Accessible name for the rating control.
  String get ratingLabel;

  /// Accessible name for the lower-bound thumb of a dual-handle range
  /// slider (`Range`) — distinguishes it from [rangeMaxValueLabel] so
  /// assistive tech can announce which of the two independently
  /// focusable thumbs is active.
  String get rangeMinValueLabel;

  /// Accessible name for the upper-bound thumb of a dual-handle range
  /// slider (`Range`). See [rangeMinValueLabel].
  String get rangeMaxValueLabel;

  /// Accessible name for a loading indicator.

  /// Announced position of a before/after comparison split, as a
  /// percentage.
  ///
  /// `aria-valuenow` alone announces a bare number, which says nothing
  /// about what is being measured — "50" could be anything. This is the
  /// sentence a reader speaks instead.
  String diffPositionLabel(int percent);

  /// Accessible name for a `Resizable` divider — the control that moves
  /// the boundary between two panes.
  ///
  /// A page can hold several splitters, so the name says what it is
  /// rather than which one; the position is announced separately by
  /// [resizableDividerPositionLabel].
  String get resizableDividerLabel;

  /// Announced position of a `Resizable` divider, as the percentage of
  /// the container taken by the pane before it.
  ///
  /// `aria-valuenow` alone announces a bare number, which says nothing
  /// about what is being measured — "30" could be anything. This is the
  /// sentence a reader speaks instead.
  String resizableDividerPositionLabel(int percent);

  String get loadingLabel;

  /// Accessible name for the `DotIndicator` navigation.
  String get dotIndicatorLabel;

  /// Accessible name for the filter reset control.
  String get filterResetLabel;

  /// Accessible name for the code-snippet copy control.
  String get codeSnippetCopyLabel;

  /// Spoken meaning of a `CodeSnippet` line marked
  /// `CoreCodeLineTone.success` — the band behind it is colour, so the tone
  /// is also said in words. [line] is the 1-based number the gutter shows.
  String codeSnippetSuccessLineLabel(int line);

  /// The same for a `CoreCodeLineTone.warning` line. See
  /// [codeSnippetSuccessLineLabel].
  String codeSnippetWarningLineLabel(int line);

  /// The same for a `CoreCodeLineTone.error` line. See
  /// [codeSnippetSuccessLineLabel].
  String codeSnippetErrorLineLabel(int line);

  /// Accessible name for the window minimize control.
  String get windowMinimize;

  /// Accessible name for the window maximize control.
  String get windowMaximize;

  /// Accessible name for the `ColorPicker` region.
  String get colorPickerLabel;

  /// Accessible name for the colour trigger.
  String get colorPickerSelectLabel;

  /// Accessible name for the recent-colours list.
  String get colorPickerRecentLabel;

  /// Accessible name for the saturation/value area.
  String get colorPickerSaturationValue;

  /// Accessible name for the eyedropper preview.
  String get colorPickerPreviewLabel;

  /// Accessible name for the eyedropper trigger button.
  String get colorPickerEyeDropper;

  /// Text the `ColorPicker` trigger shows when no colour is picked.
  String get colorPickerPlaceholder;

  /// Title above the `ColorPicker` panel's recent colours.
  String get colorPickerRecentTitle;

  /// Accessible name for the `TimePicker` popover.
  String get timePickerPopoverLabel;

  /// Accessible name for the country selector.
  String get phoneInputSelectCountry;

  /// Accessible name for a `Divider` used as a meaningful boundary
  /// (`Divider(semantic: true)`) — e.g. between groups of items in a
  /// `Menu`. Applied as `aria-label` alongside `role="separator"`,
  /// mirroring the Flutter `Divider`'s `Semantics(label:)`.
  String get dividerSeparatorLabel;

  /// Accessible name for a `ScrollableClient` viewport that the caller
  /// did not name itself.
  String get scrollableClientLabel;

  /// Localized MIME type display names.
  Map<String, String> get localizedMimeTypes;
}

/// Default English localization implementation for CoUI web components.
///
/// Provides all localized strings in English. This is the fallback
/// localization used when no locale-specific implementation is available.
///
/// Example:
/// ```dart
/// final l10n = DefaultCouiLocalizations.instance;
/// print(l10n.buttonOk); // 'OK'
/// print(l10n.formatNumber(3.14)); // '3.14'
/// ```
class DefaultCouiLocalizations extends CouiLocalizations {
  /// Creates a DefaultCouiLocalizations.
  const DefaultCouiLocalizations();

  /// Singleton instance.
  static const instance = DefaultCouiLocalizations();

  @override
  final localizedMimeTypes = const {
    'application/epub+zip': 'Electronic Publication (EPUB)',
    'application/gzip': 'GZip Compressed Archive',
    'application/java-archive': 'Java Archive (JAR)',
    'application/json': 'JSON Format',
    'application/ld+json': 'JSON-LD Format',
    'application/msword': 'Microsoft Word',
    'application/octet-stream': 'Binary Data',
    'application/ogg': 'Ogg',
    'application/pdf': 'Adobe Portable Document Format (PDF)',
    'application/rtf': 'Rich Text Format (RTF)',
    'application/vnd.amazon.ebook': 'Amazon Kindle eBook Format',
    'application/vnd.apple.installer+xml': 'Apple Installer Package',
    'application/vnd.mozilla.xul+xml': 'XUL',
    'application/vnd.ms-excel': 'Microsoft Excel',
    'application/vnd.ms-fontobject': 'MS Embedded OpenType Fonts',
    'application/vnd.ms-powerpoint': 'Microsoft PowerPoint',
    'application/vnd.oasis.opendocument.presentation':
        'OpenDocument Presentation Document',
    'application/vnd.oasis.opendocument.spreadsheet':
        'OpenDocument Spreadsheet Document',
    'application/vnd.oasis.opendocument.text': 'OpenDocument Text Document',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation':
        'Microsoft PowerPoint (OpenXML)',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet':
        'Microsoft Excel (OpenXML)',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
        'Microsoft Word (OpenXML)',
    'application/vnd.rar': 'RAR Archive',
    'application/vnd.visio': 'Microsoft Visio',
    'application/x-7z-compressed': '7-Zip Archive',
    'application/x-abiword': 'AbiWord Document',
    'application/x-bzip': 'BZip Archive',
    'application/x-bzip2': 'BZip2 Archive',
    'application/x-cdf': 'CD Audio',
    'application/x-csh': 'C-Shell Script',
    'application/x-freearc': 'Archive Document',
    'application/x-httpd-php': 'Hypertext Preprocessor (Personal Home Page)',
    'application/x-sh': 'Bourne Shell Script',
    'application/x-tar': 'Tape Archive (TAR)',
    'application/xhtml+xml': 'XHTML',
    'application/xml': 'XML',
    'application/zip': 'ZIP Archive',
    'audio/3gpp': '3GPP Audio/Video Container',
    'audio/3gpp2': '3GPP2 Audio/Video Container',
    'audio/aac': 'AAC Audio',
    'audio/midi': 'Musical Instrument Digital Interface (MIDI)',
    'audio/mpeg': 'MP3 Audio',
    'audio/ogg': 'Ogg Audio',
    'audio/wav': 'Waveform Audio Format',
    'audio/webm': 'WEBM Audio',
    'audio/x-midi': 'Musical Instrument Digital Interface (MIDI)',
    'font/otf': 'OpenType Font',
    'font/ttf': 'TrueType Font',
    'font/woff': 'Web Open Font Format (WOFF)',
    'font/woff2': 'Web Open Font Format (WOFF)',
    'image/apng': 'Animated Portable Network Graphics',
    'image/avif': 'AVIF Image',
    'image/bmp': 'Windows OS/2 Bitmap Graphics',
    'image/gif': 'Graphics Interchange Format (GIF)',
    'image/jpeg': 'JPEG Images',
    'image/png': 'Portable Network Graphics',
    'image/svg+xml': 'Scalable Vector Graphics (SVG)',
    'image/tiff': 'Tagged Image File Format (TIFF)',
    'image/vnd.microsoft.icon': 'Icon Format',
    'image/webp': 'WEBP Image',
    'text/calendar': 'iCalendar Format',
    'text/css': 'Cascading Style Sheets (CSS)',
    'text/csv': 'Comma-Separated Values (CSV)',
    'text/html': 'HyperText Markup Language (HTML)',
    'text/javascript': 'JavaScript',
    'text/plain': 'Text',
    'video/3gpp': '3GPP Audio/Video Container',
    'video/3gpp2': '3GPP2 Audio/Video Container',
    'video/mp2t': 'MPEG Transport Stream',
    'video/mp4': 'MP4 Video',
    'video/mpeg': 'MPEG Video',
    'video/ogg': 'Ogg Video',
    'video/webm': 'WEBM Video',
    'video/x-msvideo': 'AVI: Audio Video Interleave',
  };

  @override
  String get commandMove => 'Navigate';

  @override
  String get commandMoveUp => 'Move Up';

  @override
  String get commandMoveDown => 'Move Down';

  @override
  String get commandActivate => 'Select';

  @override
  String get commandMoveScope => 'Scope';

  @override
  String get commandDismiss => 'Close';

  @override
  String get commandScopeAll => 'All';

  @override
  String get commandEmptyHint => 'Try another word, or widen the scope to All.';

  @override
  String get timeDaysAbbreviation => 'DD';

  @override
  String get timeHoursAbbreviation => 'HH';

  @override
  String get timeMinutesAbbreviation => 'MM';

  @override
  String get timeSecondsAbbreviation => 'SS';

  @override
  String get commandSearch => 'Type a command or search...';

  @override
  String get commandEmpty => 'No results found.';

  @override
  String get formNotEmpty => 'This field cannot be empty';

  @override
  String get phoneNumberIncomplete => 'Enter a complete phone number';

  @override
  String get invalidValue => 'Invalid value';

  @override
  String get invalidEmail => 'Invalid email';

  @override
  String get invalidURL => 'Invalid URL';

  @override
  String formatNumber(double value) {
    return value == value.toInt() ? value.toInt().toString() : value.toString();
  }

  @override
  String formLessThan(double value) =>
      'Must be less than ${formatNumber(value)}';

  @override
  String formGreaterThan(double value) =>
      'Must be greater than ${formatNumber(value)}';

  @override
  String formLessThanOrEqualTo(double value) =>
      'Must be less than or equal to ${formatNumber(value)}';

  @override
  String formGreaterThanOrEqualTo(double value) =>
      'Must be greater than or equal to ${formatNumber(value)}';

  @override
  String formBetweenInclusively(double max, double min) =>
      'Must be between ${formatNumber(min)} and ${formatNumber(max)} (inclusive)';

  @override
  String formBetweenExclusively(double max, double min) =>
      'Must be between ${formatNumber(min)} and ${formatNumber(max)} (exclusive)';

  @override
  String formLengthLessThan(int value) => 'Must be at least $value characters';

  @override
  String formLengthGreaterThan(int value) =>
      'Must be at most $value characters';

  @override
  String formatDateTime(
    DateTime dateTime, {
    bool showDate = true,
    bool showSeconds = false,
    bool showTime = true,
    bool use24HourFormat = true,
  }) {
    var result = '';
    if (showDate) {
      result += '${getMonth(dateTime.month)} ${dateTime.day}, ${dateTime.year}';
    }
    if (showTime) {
      if (result.isNotEmpty) {
        result += ' ';
      }
      result += _formatClock(
        hour: dateTime.hour,
        minute: dateTime.minute,
        second: dateTime.second,
        showSeconds: showSeconds,
        use24HourFormat: use24HourFormat,
      );
    }

    return result;
  }

  @override
  String formatTimeOfDay(
    TimeOfDay time, {
    bool showSeconds = false,
    bool use24HourFormat = true,
  }) {
    return _formatClock(
      hour: time.hour,
      minute: time.minute,
      second: time.second,
      showSeconds: showSeconds,
      use24HourFormat: use24HourFormat,
    );
  }

  // Digits and the AM/PM split come from `CoreClockFormat` so every
  // locale on both platforms agrees on noon, midnight and padding; this
  // locale only decides where its period word sits.
  String _formatClock({
    required int hour,
    required int minute,
    required int second,
    required bool showSeconds,
    required bool use24HourFormat,
  }) {
    final digits = CoreClockFormat.digits(
      hour: hour,
      minute: minute,
      second: second,
      showSeconds: showSeconds,
      use24HourFormat: use24HourFormat,
    );
    if (use24HourFormat) {
      return digits;
    }
    final period = CoreClockFormat.isPm(hour) ? timePM : timeAM;

    return '$digits $period';
  }

  @override
  String dataTableSelectedRows(int count, int total) {
    return '$count of $total row(s) selected.';
  }

  @override
  String formatDuration(
    Duration duration, {
    bool showDays = true,
    bool showHours = true,
    bool showMinutes = true,
    bool showSeconds = true,
  }) {
    final days = duration.inDays;
    final hours = duration.inHours % Duration.hoursPerDay;
    final minutes = duration.inMinutes % Duration.minutesPerHour;
    final seconds = duration.inSeconds % Duration.secondsPerMinute;
    final parts = <String>[];
    if (showDays && days > 0) {
      parts.add('${days}d');
    }
    if (showHours && hours > 0) {
      parts.add('${hours}h');
    }
    if (showMinutes && minutes > 0) {
      parts.add('${minutes}m');
    }
    if (showSeconds && seconds > 0) {
      parts.add('${seconds}s');
    }

    return parts.join(' ');
  }

  @override
  String get formPasswordDigits => 'Must contain at least one digit';

  @override
  String get formPasswordLowercase =>
      'Must contain at least one lowercase letter';

  @override
  String get formPasswordUppercase =>
      'Must contain at least one uppercase letter';

  @override
  String get formPasswordSpecial =>
      'Must contain at least one special character';

  @override
  String get abbreviatedMonday => 'Mo';

  @override
  String get abbreviatedTuesday => 'Tu';

  @override
  String get abbreviatedWednesday => 'We';

  @override
  String get abbreviatedThursday => 'Th';

  @override
  String get abbreviatedFriday => 'Fr';

  @override
  String get abbreviatedSaturday => 'Sa';

  @override
  String get abbreviatedSunday => 'Su';

  @override
  String get monthJanuary => 'January';

  @override
  String get monthFebruary => 'February';

  @override
  String get monthMarch => 'March';

  @override
  String get monthApril => 'April';

  @override
  String get monthMay => 'May';

  @override
  String get monthJune => 'June';

  @override
  String get monthJuly => 'July';

  @override
  String get monthAugust => 'August';

  @override
  String get monthSeptember => 'September';

  @override
  String get monthOctober => 'October';

  @override
  String get monthNovember => 'November';

  @override
  String get monthDecember => 'December';

  @override
  String get buttonCancel => 'Cancel';

  @override
  String get buttonSubmit => 'Submit';

  @override
  String get buttonOk => 'OK';

  @override
  String get buttonClose => 'Close';

  @override
  String get richEditorToolbar => 'Formatting';

  @override
  String get richEditorBold => 'Bold';

  @override
  String get richEditorItalic => 'Italic';

  @override
  String get richEditorStrikethrough => 'Strikethrough';

  @override
  String get richEditorCode => 'Code';

  @override
  String get richEditorLink => 'Link';

  @override
  String get richEditorBulletedList => 'Bulleted list';

  @override
  String get richEditorNumberedList => 'Numbered list';

  @override
  String get richEditorTaskList => 'Checklist';

  @override
  String get richEditorQuote => 'Quote';

  @override
  String get richEditorLinkUrl => 'Link URL';

  @override
  String get richEditorLinkRemove => 'Remove link';

  @override
  String get richEditorLinkInvalid => 'Enter an http(s) or mailto link.';

  @override
  String get richEditorHeading1 => 'Heading 1';

  @override
  String get richEditorHeading2 => 'Heading 2';

  @override
  String get richEditorHeading3 => 'Heading 3';

  @override
  String get richEditorParagraph => 'Text';

  @override
  String get richEditorBlockType => 'Block type';

  @override
  String get richEditorSelectionToolbar => 'Selection formatting';

  @override
  String get richEditorImage => 'Image';

  @override
  String get richEditorImageUploading => 'Uploading image…';

  @override
  String get richEditorImageUploadFailed => "Couldn't upload the image.";

  @override
  String get richEditorImageTooLarge => 'The image is too large.';

  @override
  String get richEditorImageNotAllowed =>
      'Only PNG, JPEG, GIF and WebP images can be added.';

  @override
  String get richEditorImageUnavailable => 'Image unavailable';

  @override
  String get numberInputDecrease => 'Decrease';

  @override
  String get numberInputIncrease => 'Increase';

  @override
  String get buttonSave => 'Save';

  @override
  String get buttonReset => 'Reset';

  @override
  String get dateYearAbbreviation => 'YYYY';

  @override
  String get dateMonthAbbreviation => 'MM';

  @override
  String get dateDayAbbreviation => 'DD';

  @override
  String get placeholderDatePicker => 'Select a date';

  @override
  String get placeholderColorPicker => 'Select a color';

  @override
  String get buttonNext => 'Next';

  @override
  String get buttonPrevious => 'Previous';

  @override
  String get searchPlaceholderCountry => 'Search country...';

  @override
  String get emptyCountryList => 'No countries found';

  @override
  String get placeholderTimePicker => 'Select a time';

  @override
  String get timeHour => 'Hour';

  @override
  String get timeMinute => 'Minute';

  @override
  String get timeSecond => 'Second';

  @override
  String get timeAM => 'AM';

  @override
  String get timePM => 'PM';

  @override
  String get toastSnippetCopied => 'Copied to clipboard';

  @override
  String get datePickerSelectYear => 'Select a year';

  @override
  String get abbreviatedJanuary => 'Jan';

  @override
  String get abbreviatedFebruary => 'Feb';

  @override
  String get abbreviatedMarch => 'Mar';

  @override
  String get abbreviatedApril => 'Apr';

  @override
  String get abbreviatedMay => 'May';

  @override
  String get abbreviatedJune => 'Jun';

  @override
  String get abbreviatedJuly => 'Jul';

  @override
  String get abbreviatedAugust => 'Aug';

  @override
  String get abbreviatedSeptember => 'Sep';

  @override
  String get abbreviatedOctober => 'Oct';

  @override
  String get abbreviatedNovember => 'Nov';

  @override
  String get abbreviatedDecember => 'Dec';

  @override
  String get colorRed => 'Red';

  @override
  String get colorGreen => 'Green';

  @override
  String get colorBlue => 'Blue';

  @override
  String get colorAlpha => 'Alpha';

  @override
  String get colorHue => 'Hue';

  @override
  String get colorSaturation => 'Sat';

  @override
  String get colorValue => 'Val';

  @override
  String get colorLightness => 'Lum';

  @override
  String get menuCut => 'Cut';

  @override
  String get menuCopy => 'Copy';

  @override
  String get menuPaste => 'Paste';

  @override
  String get menuSelectAll => 'Select All';

  @override
  String get menuUndo => 'Undo';

  @override
  String get menuRedo => 'Redo';

  @override
  String get menuDelete => 'Delete';

  @override
  String get menuShare => 'Share';

  @override
  String get menuSearchWeb => 'Search Web';

  @override
  String get menuLiveTextInput => 'Live Text Input';

  @override
  String get refreshTriggerPull => 'Pull to refresh';

  @override
  String get refreshTriggerRelease => 'Release to refresh';

  @override
  String get refreshTriggerRefreshing => 'Refreshing...';

  @override
  String get refreshTriggerComplete => 'Refresh complete';

  @override
  String get colorPickerTabRecent => 'Recent';

  @override
  String get colorPickerTabRGB => 'RGB';

  @override
  String get colorPickerTabHSV => 'HSV';

  @override
  String get colorPickerTabHSL => 'HSL';

  @override
  String get dataTableColumns => 'Columns';

  @override
  String get dataTableNext => 'Next';

  @override
  String get dataTablePrevious => 'Previous';

  @override
  List<DatePart> get datePartsOrder => const [
    DatePart.month,
    DatePart.day,
    DatePart.year,
  ];

  @override
  String get durationDay => 'Day';

  @override
  String get durationHour => 'Hour';

  @override
  String get durationMinute => 'Minute';

  @override
  String get durationSecond => 'Second';

  @override
  String get placeholderDurationPicker => 'Select a duration';

  @override
  String get fileInputDropLabel => 'Drop files here';

  @override
  String get fileInputBrowseButton => 'Browse files';

  @override
  String get fileInputFolderButton => 'Choose folder';

  @override
  String get fileInputSaveButton => 'Save file';

  @override
  String galleryImageLabel(int index) => 'Gallery image $index';

  @override
  String get dragAnnouncePickedUp => 'Picked up.';

  @override
  String get dragAnnounceEnteredTarget => 'Over a drop target.';

  @override
  String get dragAnnounceDropped => 'Dropped.';

  @override
  String get dragAnnounceCancelled => 'Cancelled.';

  @override
  String sortableHandleLabel(int position, int count) =>
      'Reorder item $position of $count';

  @override
  String get sortableHandleHint =>
      'Press Space or Enter to pick up and drop, the arrow keys to move, '
      'and Escape to cancel.';

  @override
  String sortableAnnouncePickedUp(int position, int count) =>
      'Picked up item $position of $count. Use the arrow keys to move it.';

  @override
  String sortableAnnounceMoved(int position, int count) =>
      'Moved to position $position of $count.';

  @override
  String sortableAnnounceDropped(int position, int count) =>
      'Dropped at position $position of $count.';

  @override
  String sortableAnnounceCancelled(int position, int count) =>
      'Cancelled. Returned to position $position of $count.';

  @override
  String get trackerLabel => 'Tracker';

  @override
  String get scrollableRegionLabel => 'Scrollable content';

  @override
  String get inputOtpLabel => 'One-time password input';

  @override
  String colorPickerRecentColor(String value) => 'Recent color $value';

  @override
  String stepperStepLabel(String label, int number) => 'Step $number: $label';

  @override
  String progressStepValue(int current, int total) => 'Step $current of $total';

  @override
  String paginationJumpToPage(int page) => 'Jump to page $page';

  @override
  String dotIndicatorGoToItem(int index) => 'Go to item $index';

  @override
  String dotIndicatorPosition(int current, int total) =>
      'Item $current of $total';

  @override
  String get itemPickerSearchPlaceholder => 'Search...';

  @override
  String get itemPickerEmpty => 'No items found.';

  @override
  String get selectSearchPlaceholder => 'Search';

  @override
  String get selectEmpty => 'No results';

  @override
  String get alertLabel => 'Alert';

  @override
  String get bannerLabel => 'Banner';

  @override
  String get dismissLabel => 'Dismiss';

  @override
  String get moreLabel => 'More';

  @override
  String get paginationLabel => 'Pagination';

  @override
  String get mainLabel => 'Main content';

  @override
  String get footerLabel => 'Footer';

  @override
  String get dockLabel => 'Dock';

  @override
  String get heroSectionLabel => 'Hero';

  @override
  String get windowLabel => 'Window';

  @override
  String get breadcrumbLabel => 'Breadcrumb';

  @override
  String get navigationLabel => 'Navigation';

  @override
  String get menubarLabel => 'Menubar';

  @override
  String get carouselLabel => 'Carousel';

  @override
  String get carouselPreviousSlide => 'Previous slide';

  @override
  String get carouselNextSlide => 'Next slide';

  @override
  String get calendarLabel => 'Calendar';

  @override
  String get calendarPreviousPeriod => 'Previous period';

  @override
  String get calendarNextPeriod => 'Next period';

  @override
  String calendarMarkerCount(int count) =>
      count == 1 ? '1 item' : '$count items';

  @override
  String get scaffoldLabel => 'Scaffold';

  @override
  String get chipInputLabel => 'Chip input';

  @override
  String chipRemoveLabel(String label) => 'Remove $label';

  @override
  String get ratingLabel => 'Rating';

  @override
  String get rangeMinValueLabel => 'Minimum value';

  @override
  String get rangeMaxValueLabel => 'Maximum value';

  @override
  String get loadingLabel => 'Loading';

  @override
  String diffPositionLabel(int percent) => 'Split at $percent%';

  @override
  String get resizableDividerLabel => 'Resize panels';

  @override
  String resizableDividerPositionLabel(int percent) => 'Divider at $percent%';

  @override
  String get dotIndicatorLabel => 'Page navigation';

  @override
  String get filterResetLabel => 'Reset filter';

  @override
  String get codeSnippetCopyLabel => 'Copy code';

  @override
  String codeSnippetSuccessLineLabel(int line) => 'Line $line: success';

  @override
  String codeSnippetWarningLineLabel(int line) => 'Line $line: warning';

  @override
  String codeSnippetErrorLineLabel(int line) => 'Line $line: error';

  @override
  String get windowMinimize => 'Minimize';

  @override
  String get windowMaximize => 'Maximize';

  @override
  String get colorPickerLabel => 'Color picker';

  @override
  String get colorPickerSelectLabel => 'Select color';

  @override
  String get colorPickerRecentLabel => 'Recent colors';

  @override
  String get colorPickerSaturationValue => 'Saturation and value';

  @override
  String get colorPickerPreviewLabel => 'Color picker capture preview';

  @override
  String get colorPickerEyeDropper => 'Pick colour from screen';

  @override
  String get colorPickerPlaceholder => 'No colour picked';

  @override
  String get colorPickerRecentTitle => 'Recently used';

  @override
  String get timePickerPopoverLabel => 'Time picker popover';

  @override
  String get phoneInputSelectCountry => 'Select country';

  @override
  String get dividerSeparatorLabel => 'Separator';
  String get scrollableClientLabel => 'Scrollable region';
}
