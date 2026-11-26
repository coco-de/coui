import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:coui_flutter/coui_flutter.dart';

// Locale-implementation registry keyed by bare ISO language code (country
// / script subtags are ignored — Locale('ko','KR') and Locale('ko') both
// resolve to 'ko'). Add a new locale by adding one entry here.
// Every entry except `en` (the Default below) is generated from the single
// slang source in packages/coui_i10n/chrome/ — see
// `cross-platform/localization.md` "번역 파이프라인". `zh` serves the
// Simplified Chinese strings for every Chinese locale.
const _kCoUILocalizationsByLanguageCode = <String, CoUILocalizations>{
  'ar': ArCoUILocalizations(),
  'de': DeCoUILocalizations(),
  'es': EsCoUILocalizations(),
  'fr': FrCoUILocalizations(),
  'it': ItCoUILocalizations(),
  'ja': JaCoUILocalizations(),
  'ko': KoCoUILocalizations(),
  'pt': PtCoUILocalizations(),
  'ru': RuCoUILocalizations(),
  'zh': ZhHansCoUILocalizations(),
};

class CoUILocalizationsDelegate
    extends LocalizationsDelegate<CoUILocalizations> {
  const CoUILocalizationsDelegate();

  static const delegate = CoUILocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CoUILocalizations> load(Locale locale) {
    final localizations =
        _kCoUILocalizationsByLanguageCode[locale.languageCode] ??
        DefaultCoUILocalizations.instance;
    return SynchronousFuture(localizations);
  }

  @override
  bool shouldReload(CoUILocalizationsDelegate old) => false;
}

// ignore: unused_element
const _kFileByteUnits = SizeUnitLocale(1024, [
  'B',
  'KB',
  'MB',
  'GB',
  'TB',
  'PB',
  'EB',
  'ZB',
  'YB',
]);
// ignore: unused_element
const _kFileBitUnits = SizeUnitLocale(
  1024,
  ['Bi', 'KiB', 'MiB', 'GiB', 'TiB', 'PiB', 'EiB', 'ZiB', 'YiB'],
);

class SizeUnitLocale {
  const SizeUnitLocale(this.base, this.units);

  final int base;

  final List<String> units; // separator for digit grouping, e.g. 1,000,000
}

// ignore: unused_element
double _log10(num x) {
  return log(x) / ln10;
}

// ignore: unused_element
int _getYear(DateTime dateTime) => dateTime.year;
// ignore: unused_element
int _getMonth(DateTime dateTime) => dateTime.month;
// ignore: unused_element
int _getDay(DateTime dateTime) => dateTime.day;

// ignore: unused_element
(int?, int?) _computeYearValueRange(Map<DatePart, int> values) {
  return (null, null);
}

// ignore: unused_element
(int?, int?) _computeMonthValueRange(Map<DatePart, int> values) {
  return (1, 12);
}

// ignore: unused_element
(int?, int?) _computeDayValueRange(Map<DatePart, int> values) {
  final year = values[DatePart.year];
  final month = values[DatePart.month];
  if (year == null || month == null) return (1, 31);
  final daysInMonth = DateTime(year, month + 1, 0).day;

  return (1, daysInMonth);
}

enum DatePart {
  day,
  month,
  year;

  const DatePart();
}

abstract class CoUILocalizations {
  const CoUILocalizations();

  static CoUILocalizations of(BuildContext context) {
    return Localizations.of(context, CoUILocalizations) ??
        DefaultCoUILocalizations.instance;
  }

  String formatNumber(double value);

  String formLessThan(double value);

  String formGreaterThan(double value);

  String formLessThanOrEqualTo(double value);

  String formGreaterThanOrEqualTo(double value);

  String formBetweenInclusively(double max, double min);

  String formBetweenExclusively(double max, double min);

  String formLengthLessThan(int value);

  String formLengthGreaterThan(int value);

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

  String formatDateTime(
    DateTime dateTime, {
    bool showDate = true,
    bool showSeconds = false,
    bool showTime = true,
    bool use24HourFormat = true,
  });

  String formatTimeOfDay(
    TimeOfDay time, {
    bool showSeconds = false,
    bool use24HourFormat = true,
  });

  String dataTableSelectedRows(int count, int total);

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

  String formatDuration(
    Duration duration, {
    bool showDays = true,
    bool showHours = true,
    bool showMinutes = true,
    bool showSeconds = true,
  });

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

  String get formNotEmpty;

  /// Message for a phone number that has a country but no digits yet.
  String get phoneNumberIncomplete;
  String get invalidValue;
  String get invalidEmail;
  String get invalidURL;
  String get formPasswordDigits;
  String get formPasswordLowercase;
  String get formPasswordUppercase;
  String get formPasswordSpecial;

  List<DatePart> get datePartsOrder;
  String get dateYearAbbreviation;
  String get dateMonthAbbreviation;
  String get dateDayAbbreviation;

  String get commandSearch;
  String get commandEmpty;
  String get datePickerSelectYear;
  String get abbreviatedMonday;
  String get abbreviatedTuesday;
  String get abbreviatedWednesday;
  String get abbreviatedThursday;
  String get abbreviatedFriday;
  String get abbreviatedSaturday;
  String get abbreviatedSunday;
  String get monthJanuary;
  String get monthFebruary;
  String get monthMarch;
  String get monthApril;
  String get monthMay;
  String get monthJune;
  String get monthJuly;
  String get monthAugust;
  String get monthSeptember;
  String get monthOctober;
  String get monthNovember;
  String get monthDecember;
  String get abbreviatedJanuary;
  String get abbreviatedFebruary;
  String get abbreviatedMarch;
  String get abbreviatedApril;
  String get abbreviatedMay;
  String get abbreviatedJune;
  String get abbreviatedJuly;
  String get abbreviatedAugust;
  String get abbreviatedSeptember;
  String get abbreviatedOctober;
  String get abbreviatedNovember;
  String get abbreviatedDecember;
  String get buttonCancel;

  /// Submit button label — the default `Form.primaryAction` caption.
  String get buttonSubmit;
  String get buttonOk;
  String get buttonClose;
  String get richEditorToolbar;
  String get richEditorBold;
  String get richEditorItalic;
  String get richEditorStrikethrough;
  String get richEditorCode;
  String get richEditorLink;
  String get richEditorBulletedList;
  String get richEditorNumberedList;
  String get richEditorTaskList;
  String get richEditorQuote;
  String get richEditorLinkUrl;
  String get richEditorLinkRemove;
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

  /// Rich editor note in place of an image that cannot be displayed.
  String get richEditorImageUnavailable;

  /// `NumberInput` step button names — the accessible name of the minus and
  /// plus buttons.
  String get numberInputDecrease;
  String get numberInputIncrease;
  String get buttonSave;
  String get buttonReset;
  String get timeHour;
  String get timeMinute;
  String get timeSecond;
  String get timeAM;
  String get timePM;
  String get colorRed;
  String get colorGreen;
  String get colorBlue;
  String get colorAlpha;
  String get colorHue;
  String get colorSaturation;
  String get colorValue;
  String get colorLightness;
  String get menuCut;
  String get menuCopy;
  String get menuPaste;
  String get menuSelectAll;
  String get menuUndo;
  String get menuRedo;
  String get menuDelete;
  String get menuShare;
  String get menuSearchWeb;
  String get menuLiveTextInput;
  String get placeholderDatePicker;
  String get placeholderTimePicker;
  String get placeholderColorPicker;
  String get buttonPrevious;
  String get buttonNext;

  String get refreshTriggerPull;
  String get refreshTriggerRelease;
  String get refreshTriggerRefreshing;
  String get refreshTriggerComplete;

  String get searchPlaceholderCountry;
  String get emptyCountryList;
  String get toastSnippetCopied;

  String get colorPickerTabRecent;
  String get colorPickerTabRGB;
  String get colorPickerTabHSV;
  String get colorPickerTabHSL;

  /// Footer hint after the ↑ ↓ key pair of a command palette.
  String get commandMove;
  @Deprecated(
    'Use commandMove (since 0.178) — the command footer labels the ↑ ↓ '
    'pair with one word for moving either way; a one-direction label '
    'misnamed the pair.',
  )
  String get commandMoveUp;
  @Deprecated(
    'Use commandMove (since 0.178) — the command footer labels the ↑ ↓ '
    'pair with one word for moving either way; a one-direction label '
    'misnamed the pair.',
  )
  String get commandMoveDown;
  String get commandActivate;
  String get commandMoveScope;
  String get commandDismiss;
  String get commandScopeAll;
  String get commandEmptyHint;

  String get dataTableNext;
  String get dataTablePrevious;
  String get dataTableColumns;

  String get timeDaysAbbreviation;
  String get timeHoursAbbreviation;
  String get timeMinutesAbbreviation;
  String get timeSecondsAbbreviation;
  String get placeholderDurationPicker;
  String get durationDay;
  String get durationHour;
  String get durationMinute;
  String get durationSecond;

  String get fileInputDropLabel;
  String get fileInputBrowseButton;

  /// Label for the `FileInput` folder button.
  String get fileInputFolderButton;

  /// Accessible name for the `FileInput` save button.
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
  /// none (e.g. a bare canvas), so it can be discovered by swipe/Tab
  /// navigation instead of being silently skipped.
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

  /// Accessible name for the `Pagination` navigation.
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
  /// `Menu`. The Web twin reads the equivalent `CouiLocalizations`
  /// member and applies it as `aria-label` alongside `role="separator"`.
  ///
  /// Flutter has no flag for this non-focusable use of
  /// `CoreSemanticRole.separator` (only for its focusable "window
  /// splitter" variant, mirrored as `slider:`), so this explicit name is
  /// the only signal Flutter has.
  String get dividerSeparatorLabel;

  /// Accessible name for a `ScrollableClient` viewport that the caller
  /// did not name itself.
  String get scrollableClientLabel;

  Map<String, String> get localizedMimeTypes;
}

class DefaultCoUILocalizations extends CoUILocalizations {
  const DefaultCoUILocalizations();

  static const instance = DefaultCoUILocalizations();

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
  String get colorHue => 'Hue';

  @override
  String get colorSaturation => 'Sat';

  @override
  String get colorValue => 'Val';

  @override
  String get colorLightness => 'Lum';

  @override
  String get dataTableColumns => 'Columns';

  @override
  String get dataTableNext => 'Next';

  @override
  String get dataTablePrevious => 'Previous';

  @override
  List<DatePart> get datePartsOrder => const [
    // MM/DD/YYYY
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
