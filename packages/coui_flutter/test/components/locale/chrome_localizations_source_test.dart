// Every Flutter CoUI locale renders exactly what its slang source says, and
// no non-English locale lets an English default through.
//
// The single source is packages/coui_i10n/chrome/i18n/*.i18n.json. The
// locale classes are generated from it (en is the hand-written Default and is
// held to its JSON here too), and the twin of this test on the other
// platform reads the same files — so the two platforms cannot render a key
// differently without one of them failing.
import 'dart:convert';
import 'dart:io';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

/// A three-second span to format — data for the duration templates, not
/// an animation timing.
const Duration _kThreeSeconds = Duration(seconds: 3);

const String kChromeSourceDir = '../coui_i10n/chrome/i18n';
const String kEnglishIdenticalPath =
    '../coui_i10n/chrome/english_identical.json';

const Map<String, CoUILocalizations> kLocalizationsByLocale = {
  'ar': ArCoUILocalizations.instance,
  'de': DeCoUILocalizations.instance,
  'en': DefaultCoUILocalizations.instance,
  'es': EsCoUILocalizations.instance,
  'fr': FrCoUILocalizations.instance,
  'it': ItCoUILocalizations.instance,
  'ja': JaCoUILocalizations.instance,
  'ko': KoCoUILocalizations.instance,
  'pt': PtCoUILocalizations.instance,
  'ru': RuCoUILocalizations.instance,
  'zh-Hans': ZhHansCoUILocalizations.instance,
};

typedef _Getter = String Function(CoUILocalizations l);

final Map<String, _Getter> _getters = {
  'numberInputDecrease': (l) => l.numberInputDecrease,
  'numberInputIncrease': (l) => l.numberInputIncrease,
  'commandMove': (l) => l.commandMove,
  // The deprecated keys stay in the source JSON until removal, so they still
  // have to render it.
  'commandMoveUp': (l) => l.commandMoveUp,
  'commandMoveDown': (l) => l.commandMoveDown,
  'commandActivate': (l) => l.commandActivate,
  'commandMoveScope': (l) => l.commandMoveScope,
  'commandDismiss': (l) => l.commandDismiss,
  'commandScopeAll': (l) => l.commandScopeAll,
  'commandEmptyHint': (l) => l.commandEmptyHint,
  'timeDaysAbbreviation': (l) => l.timeDaysAbbreviation,
  'timeHoursAbbreviation': (l) => l.timeHoursAbbreviation,
  'timeMinutesAbbreviation': (l) => l.timeMinutesAbbreviation,
  'timeSecondsAbbreviation': (l) => l.timeSecondsAbbreviation,
  'commandSearch': (l) => l.commandSearch,
  'commandEmpty': (l) => l.commandEmpty,
  'formNotEmpty': (l) => l.formNotEmpty,
  'phoneNumberIncomplete': (l) => l.phoneNumberIncomplete,
  'invalidValue': (l) => l.invalidValue,
  'invalidEmail': (l) => l.invalidEmail,
  'invalidURL': (l) => l.invalidURL,
  'formPasswordDigits': (l) => l.formPasswordDigits,
  'formPasswordLowercase': (l) => l.formPasswordLowercase,
  'formPasswordUppercase': (l) => l.formPasswordUppercase,
  'formPasswordSpecial': (l) => l.formPasswordSpecial,
  'abbreviatedMonday': (l) => l.abbreviatedMonday,
  'abbreviatedTuesday': (l) => l.abbreviatedTuesday,
  'abbreviatedWednesday': (l) => l.abbreviatedWednesday,
  'abbreviatedThursday': (l) => l.abbreviatedThursday,
  'abbreviatedFriday': (l) => l.abbreviatedFriday,
  'abbreviatedSaturday': (l) => l.abbreviatedSaturday,
  'abbreviatedSunday': (l) => l.abbreviatedSunday,
  'monthJanuary': (l) => l.monthJanuary,
  'monthFebruary': (l) => l.monthFebruary,
  'monthMarch': (l) => l.monthMarch,
  'monthApril': (l) => l.monthApril,
  'monthMay': (l) => l.monthMay,
  'monthJune': (l) => l.monthJune,
  'monthJuly': (l) => l.monthJuly,
  'monthAugust': (l) => l.monthAugust,
  'monthSeptember': (l) => l.monthSeptember,
  'monthOctober': (l) => l.monthOctober,
  'monthNovember': (l) => l.monthNovember,
  'monthDecember': (l) => l.monthDecember,
  'buttonCancel': (l) => l.buttonCancel,
  'buttonSubmit': (l) => l.buttonSubmit,
  'buttonOk': (l) => l.buttonOk,
  'buttonClose': (l) => l.buttonClose,
  'richEditorToolbar': (l) => l.richEditorToolbar,
  'richEditorBold': (l) => l.richEditorBold,
  'richEditorItalic': (l) => l.richEditorItalic,
  'richEditorStrikethrough': (l) => l.richEditorStrikethrough,
  'richEditorCode': (l) => l.richEditorCode,
  'richEditorLink': (l) => l.richEditorLink,
  'richEditorBulletedList': (l) => l.richEditorBulletedList,
  'richEditorNumberedList': (l) => l.richEditorNumberedList,
  'richEditorTaskList': (l) => l.richEditorTaskList,
  'richEditorQuote': (l) => l.richEditorQuote,
  'richEditorLinkUrl': (l) => l.richEditorLinkUrl,
  'richEditorLinkRemove': (l) => l.richEditorLinkRemove,
  'richEditorLinkInvalid': (l) => l.richEditorLinkInvalid,
  'richEditorHeading1': (l) => l.richEditorHeading1,
  'richEditorHeading2': (l) => l.richEditorHeading2,
  'richEditorHeading3': (l) => l.richEditorHeading3,
  'richEditorParagraph': (l) => l.richEditorParagraph,
  'richEditorBlockType': (l) => l.richEditorBlockType,
  'richEditorSelectionToolbar': (l) => l.richEditorSelectionToolbar,
  'richEditorImage': (l) => l.richEditorImage,
  'richEditorImageUploading': (l) => l.richEditorImageUploading,
  'richEditorImageUploadFailed': (l) => l.richEditorImageUploadFailed,
  'richEditorImageTooLarge': (l) => l.richEditorImageTooLarge,
  'richEditorImageNotAllowed': (l) => l.richEditorImageNotAllowed,
  'richEditorImageUnavailable': (l) => l.richEditorImageUnavailable,
  'buttonSave': (l) => l.buttonSave,
  'buttonReset': (l) => l.buttonReset,
  'dateYearAbbreviation': (l) => l.dateYearAbbreviation,
  'dateMonthAbbreviation': (l) => l.dateMonthAbbreviation,
  'dateDayAbbreviation': (l) => l.dateDayAbbreviation,
  'placeholderDatePicker': (l) => l.placeholderDatePicker,
  'placeholderColorPicker': (l) => l.placeholderColorPicker,
  'buttonNext': (l) => l.buttonNext,
  'buttonPrevious': (l) => l.buttonPrevious,
  'searchPlaceholderCountry': (l) => l.searchPlaceholderCountry,
  'emptyCountryList': (l) => l.emptyCountryList,
  'placeholderTimePicker': (l) => l.placeholderTimePicker,
  'timeHour': (l) => l.timeHour,
  'timeMinute': (l) => l.timeMinute,
  'timeSecond': (l) => l.timeSecond,
  'timeAM': (l) => l.timeAM,
  'timePM': (l) => l.timePM,
  'toastSnippetCopied': (l) => l.toastSnippetCopied,
  'datePickerSelectYear': (l) => l.datePickerSelectYear,
  'abbreviatedJanuary': (l) => l.abbreviatedJanuary,
  'abbreviatedFebruary': (l) => l.abbreviatedFebruary,
  'abbreviatedMarch': (l) => l.abbreviatedMarch,
  'abbreviatedApril': (l) => l.abbreviatedApril,
  'abbreviatedMay': (l) => l.abbreviatedMay,
  'abbreviatedJune': (l) => l.abbreviatedJune,
  'abbreviatedJuly': (l) => l.abbreviatedJuly,
  'abbreviatedAugust': (l) => l.abbreviatedAugust,
  'abbreviatedSeptember': (l) => l.abbreviatedSeptember,
  'abbreviatedOctober': (l) => l.abbreviatedOctober,
  'abbreviatedNovember': (l) => l.abbreviatedNovember,
  'abbreviatedDecember': (l) => l.abbreviatedDecember,
  'colorRed': (l) => l.colorRed,
  'colorGreen': (l) => l.colorGreen,
  'colorBlue': (l) => l.colorBlue,
  'colorAlpha': (l) => l.colorAlpha,
  'menuCut': (l) => l.menuCut,
  'menuCopy': (l) => l.menuCopy,
  'menuPaste': (l) => l.menuPaste,
  'menuSelectAll': (l) => l.menuSelectAll,
  'menuUndo': (l) => l.menuUndo,
  'menuRedo': (l) => l.menuRedo,
  'menuDelete': (l) => l.menuDelete,
  'menuShare': (l) => l.menuShare,
  'menuSearchWeb': (l) => l.menuSearchWeb,
  'menuLiveTextInput': (l) => l.menuLiveTextInput,
  'refreshTriggerPull': (l) => l.refreshTriggerPull,
  'refreshTriggerRelease': (l) => l.refreshTriggerRelease,
  'refreshTriggerRefreshing': (l) => l.refreshTriggerRefreshing,
  'refreshTriggerComplete': (l) => l.refreshTriggerComplete,
  'colorPickerTabRecent': (l) => l.colorPickerTabRecent,
  'colorPickerTabRGB': (l) => l.colorPickerTabRGB,
  'colorPickerTabHSV': (l) => l.colorPickerTabHSV,
  'colorPickerTabHSL': (l) => l.colorPickerTabHSL,
  'colorHue': (l) => l.colorHue,
  'colorSaturation': (l) => l.colorSaturation,
  'colorValue': (l) => l.colorValue,
  'colorLightness': (l) => l.colorLightness,
  'dataTableColumns': (l) => l.dataTableColumns,
  'dataTableNext': (l) => l.dataTableNext,
  'dataTablePrevious': (l) => l.dataTablePrevious,
  'durationDay': (l) => l.durationDay,
  'durationHour': (l) => l.durationHour,
  'durationMinute': (l) => l.durationMinute,
  'durationSecond': (l) => l.durationSecond,
  'placeholderDurationPicker': (l) => l.placeholderDurationPicker,
  'fileInputDropLabel': (l) => l.fileInputDropLabel,
  'fileInputBrowseButton': (l) => l.fileInputBrowseButton,
  'fileInputFolderButton': (l) => l.fileInputFolderButton,
  'fileInputSaveButton': (l) => l.fileInputSaveButton,
  'dragAnnouncePickedUp': (l) => l.dragAnnouncePickedUp,
  'dragAnnounceEnteredTarget': (l) => l.dragAnnounceEnteredTarget,
  'dragAnnounceDropped': (l) => l.dragAnnounceDropped,
  'dragAnnounceCancelled': (l) => l.dragAnnounceCancelled,
  'sortableHandleHint': (l) => l.sortableHandleHint,
  'trackerLabel': (l) => l.trackerLabel,
  'scrollableRegionLabel': (l) => l.scrollableRegionLabel,
  'inputOtpLabel': (l) => l.inputOtpLabel,
  'itemPickerSearchPlaceholder': (l) => l.itemPickerSearchPlaceholder,
  'itemPickerEmpty': (l) => l.itemPickerEmpty,
  'selectSearchPlaceholder': (l) => l.selectSearchPlaceholder,
  'selectEmpty': (l) => l.selectEmpty,
  'alertLabel': (l) => l.alertLabel,
  'bannerLabel': (l) => l.bannerLabel,
  'dismissLabel': (l) => l.dismissLabel,
  'moreLabel': (l) => l.moreLabel,
  'paginationLabel': (l) => l.paginationLabel,
  'mainLabel': (l) => l.mainLabel,
  'footerLabel': (l) => l.footerLabel,
  'dockLabel': (l) => l.dockLabel,
  'heroSectionLabel': (l) => l.heroSectionLabel,
  'windowLabel': (l) => l.windowLabel,
  'breadcrumbLabel': (l) => l.breadcrumbLabel,
  'navigationLabel': (l) => l.navigationLabel,
  'menubarLabel': (l) => l.menubarLabel,
  'carouselLabel': (l) => l.carouselLabel,
  'carouselPreviousSlide': (l) => l.carouselPreviousSlide,
  'carouselNextSlide': (l) => l.carouselNextSlide,
  'calendarLabel': (l) => l.calendarLabel,
  'calendarPreviousPeriod': (l) => l.calendarPreviousPeriod,
  'calendarNextPeriod': (l) => l.calendarNextPeriod,
  'scaffoldLabel': (l) => l.scaffoldLabel,
  'chipInputLabel': (l) => l.chipInputLabel,
  'ratingLabel': (l) => l.ratingLabel,
  'rangeMinValueLabel': (l) => l.rangeMinValueLabel,
  'rangeMaxValueLabel': (l) => l.rangeMaxValueLabel,
  'loadingLabel': (l) => l.loadingLabel,
  'resizableDividerLabel': (l) => l.resizableDividerLabel,
  'dotIndicatorLabel': (l) => l.dotIndicatorLabel,
  'filterResetLabel': (l) => l.filterResetLabel,
  'codeSnippetCopyLabel': (l) => l.codeSnippetCopyLabel,
  'windowMinimize': (l) => l.windowMinimize,
  'windowMaximize': (l) => l.windowMaximize,
  'colorPickerLabel': (l) => l.colorPickerLabel,
  'colorPickerSelectLabel': (l) => l.colorPickerSelectLabel,
  'colorPickerRecentLabel': (l) => l.colorPickerRecentLabel,
  'colorPickerSaturationValue': (l) => l.colorPickerSaturationValue,
  'colorPickerPreviewLabel': (l) => l.colorPickerPreviewLabel,
  'colorPickerEyeDropper': (l) => l.colorPickerEyeDropper,
  'colorPickerPlaceholder': (l) => l.colorPickerPlaceholder,
  'colorPickerRecentTitle': (l) => l.colorPickerRecentTitle,
  'timePickerPopoverLabel': (l) => l.timePickerPopoverLabel,
  'phoneInputSelectCountry': (l) => l.phoneInputSelectCountry,
  'dividerSeparatorLabel': (l) => l.dividerSeparatorLabel,
  'scrollableClientLabel': (l) => l.scrollableClientLabel,
};

/// Parameterised members: the call with fixed sample arguments, and the
/// text each `{placeholder}` of the source template must turn into.
final Map<String, (_Getter, Map<String, String>)> _methods = {
  'formLessThan': ((l) => l.formLessThan(12.25), {'value': '12.25'}),
  'formGreaterThan': ((l) => l.formGreaterThan(12.25), {'value': '12.25'}),
  'formLessThanOrEqualTo': (
    (l) => l.formLessThanOrEqualTo(12.25),
    {'value': '12.25'},
  ),
  'formGreaterThanOrEqualTo': (
    (l) => l.formGreaterThanOrEqualTo(12.25),
    {'value': '12.25'},
  ),
  'formBetweenInclusively': (
    (l) => l.formBetweenInclusively(7.5, 3),
    {'max': '7.5', 'min': '3'},
  ),
  'formBetweenExclusively': (
    (l) => l.formBetweenExclusively(7.5, 3),
    {'max': '7.5', 'min': '3'},
  ),
  'formLengthLessThan': ((l) => l.formLengthLessThan(8), {'value': '8'}),
  'formLengthGreaterThan': ((l) => l.formLengthGreaterThan(8), {'value': '8'}),
  'dataTableSelectedRows': (
    (l) => l.dataTableSelectedRows(7, 9),
    {'count': '7', 'total': '9'},
  ),
  'galleryImageLabel': ((l) => l.galleryImageLabel(2), {'index': '2'}),
  'sortableHandleLabel': (
    (l) => l.sortableHandleLabel(3, 7),
    {'position': '3', 'count': '7'},
  ),
  'sortableAnnouncePickedUp': (
    (l) => l.sortableAnnouncePickedUp(3, 7),
    {'position': '3', 'count': '7'},
  ),
  'sortableAnnounceMoved': (
    (l) => l.sortableAnnounceMoved(3, 7),
    {'position': '3', 'count': '7'},
  ),
  'sortableAnnounceDropped': (
    (l) => l.sortableAnnounceDropped(3, 7),
    {'position': '3', 'count': '7'},
  ),
  'sortableAnnounceCancelled': (
    (l) => l.sortableAnnounceCancelled(3, 7),
    {'position': '3', 'count': '7'},
  ),
  'colorPickerRecentColor': (
    (l) => l.colorPickerRecentColor('#ff0000'),
    {'value': '#ff0000'},
  ),
  'stepperStepLabel': (
    (l) => l.stepperStepLabel('Alpha', 2),
    {'label': 'Alpha', 'number': '2'},
  ),
  'progressStepValue': (
    (l) => l.progressStepValue(1, 2),
    {'current': '1', 'total': '2'},
  ),
  'paginationJumpToPage': ((l) => l.paginationJumpToPage(5), {'page': '5'}),
  'dotIndicatorGoToItem': ((l) => l.dotIndicatorGoToItem(2), {'index': '2'}),
  'dotIndicatorPosition': (
    (l) => l.dotIndicatorPosition(2, 3),
    {'current': '2', 'total': '3'},
  ),
  'chipRemoveLabel': ((l) => l.chipRemoveLabel('Alpha'), {'label': 'Alpha'}),
  'diffPositionLabel': ((l) => l.diffPositionLabel(40), {'percent': '40'}),
  'codeSnippetSuccessLineLabel': (
    (l) => l.codeSnippetSuccessLineLabel(43),
    {'line': '43'},
  ),
  'codeSnippetWarningLineLabel': (
    (l) => l.codeSnippetWarningLineLabel(43),
    {'line': '43'},
  ),
  'codeSnippetErrorLineLabel': (
    (l) => l.codeSnippetErrorLineLabel(43),
    {'line': '43'},
  ),
  'resizableDividerPositionLabel': (
    (l) => l.resizableDividerPositionLabel(40),
    {'percent': '40'},
  ),
};

String _fill(String template, Map<String, String> values) =>
    template.replaceAllMapped(RegExp(r'\{(\w+)\}'), (m) => values[m.group(1)]!);

/// Every key of the source rendered by [l], with fixed sample inputs.
Map<String, String> _render(CoUILocalizations l) => {
  for (final MapEntry(:key, :value) in _getters.entries) key: value(l),
  for (final MapEntry(:key, :value) in _methods.entries) key: value.$1(l),
  'calendarMarkerCount/one': l.calendarMarkerCount(1),
  'calendarMarkerCount/other': l.calendarMarkerCount(4),
  for (final MapEntry(:key, :value) in l.localizedMimeTypes.entries)
    'localizedMimeTypes/$key': value,
};

Map<String, Object?> _source(String locale) =>
    jsonDecode(File('$kChromeSourceDir/$locale.i18n.json').readAsStringSync())
        as Map<String, Object?>;

void main() {
  final locales = Directory(kChromeSourceDir)
      .listSync()
      .map((e) => e.uri.pathSegments.last)
      .where((n) => n.endsWith('.i18n.json'))
      .map((n) => n.substring(0, n.length - '.i18n.json'.length))
      .toSet();

  test('every source locale has a Flutter class, and nothing else does', () {
    expect(locales, kLocalizationsByLocale.keys.toSet());
  });

  test('the member table covers every source key', () {
    final keys = _source('en').keys.where((k) => !k.startsWith('@')).toSet();
    expect(
      {
        ..._getters.keys,
        ..._methods.keys,
        'calendarMarkerCount',
        'localizedMimeTypes',
        'format',
      },
      keys,
    );
  });

  for (final locale in kLocalizationsByLocale.keys) {
    final l = kLocalizationsByLocale[locale]!;
    final source = _source(locale);

    group('$locale renders its source', () {
      for (final key in _getters.keys) {
        test(key, () => expect(_getters[key]!(l), source[key]));
      }
      for (final MapEntry(:key, :value) in _methods.entries) {
        test(key, () {
          expect(value.$1(l), _fill(source[key]! as String, value.$2));
        });
      }
      test('calendarMarkerCount', () {
        final forms = source['calendarMarkerCount']! as Map<String, Object?>;
        expect(
          l.calendarMarkerCount(1),
          _fill(forms['one']! as String, {'count': '1'}),
        );
        expect(
          l.calendarMarkerCount(4),
          _fill(forms['other']! as String, {'count': '4'}),
        );
      });
      test('localizedMimeTypes', () {
        final mime = source['localizedMimeTypes']! as Map<String, Object?>;
        expect(l.localizedMimeTypes, {
          for (final MapEntry(:key, :value) in mime.entries)
            key.replaceAll('_', '.'): value,
        });
      });
      test('format templates', () {
        final format = source['format']! as Map<String, Object?>;
        String template(String key) => format[key]! as String;
        expect(
          l.formatDateTime(DateTime(2026, 3, 7), showTime: false),
          _fill(template('dateTime'), {
            'year': '2026',
            'month': '3',
            'monthPadded': '03',
            'monthName': l.getMonth(3),
            'day': '7',
            'dayPadded': '07',
          }),
        );
        expect(
          l.formatMonthYear(11, 2026),
          _fill(template('monthYear'), {
            'year': '2026',
            'month': '11',
            'monthPadded': '11',
            'monthName': l.getMonth(11),
          }),
        );
        expect(
          l.formatTimeOfDay(
            const TimeOfDay(hour: 13, minute: 5),
            use24HourFormat: false,
          ),
          _fill(template('clockWithPeriod'), {
            'time': '01:05',
            'period': l.timePM,
          }),
        );
        for (final (key, duration) in [
          ('durationDays', const Duration(days: 3)),
          ('durationHours', const Duration(hours: 3)),
          ('durationMinutes', const Duration(minutes: 3)),
          ('durationSeconds', _kThreeSeconds),
        ]) {
          expect(
            l.formatDuration(duration),
            _fill(template(key), {'count': '3'}),
          );
        }
        final order =
            RegExp(r'\{(year|month|monthPadded|monthName|day|dayPadded)\}')
                .allMatches(template('dateTime'))
                .map(
                  (m) => m.group(1)!.startsWith('month')
                      ? 'month'
                      : m.group(1)!.replaceAll('Padded', ''),
                )
                .toList();
        expect(l.datePartsOrder.map((p) => p.name).toList(), order);
      });
    });
  }

  group('no English default leaks into a translated locale', () {
    final english = _render(kLocalizationsByLocale['en']!);
    final allowed =
        jsonDecode(File(kEnglishIdenticalPath).readAsStringSync())
            as Map<String, Object?>;
    for (final locale in kLocalizationsByLocale.keys) {
      if (locale == 'en') continue;
      test(locale, () {
        final rendered = _render(kLocalizationsByLocale[locale]!);
        final identical = {
          for (final MapEntry(:key, :value) in rendered.entries)
            if (value == english[key])
              key.replaceAll(RegExp(r'/(one|other)$'), ''),
        };
        expect(
          identical,
          ((allowed[locale] ?? const <Object?>[]) as List)
              .cast<String>()
              .toSet(),
          reason:
              'A key rendering the English value is either an untranslated '
              'default or must be listed in english_identical.json.',
        );
      });
    }
  });
}
