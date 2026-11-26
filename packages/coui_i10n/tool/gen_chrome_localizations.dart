// Generates the component-chrome locale classes of BOTH platforms from the
// single slang source in `chrome/i18n/*.i18n.json`:
//
//   coui_flutter  lib/src/components/locale/<lang>_coui_localizations.dart
//   coui_web      lib/src/components/locale/coui_localizations/<lang>_coui_localizations.dart
//
// Every locale except `en` is generated. `en` is the interfaces' own
// `DefaultCoUILocalizations` / `DefaultCouiLocalizations` (the fallback that
// consumers extend), so it stays hand-written; its JSON is the reference the
// generator checks every other locale's key set against, and the platform
// tests check the Default classes render exactly that JSON.
//
// Both platforms receive the same method bodies — only the imports and class
// names differ — so the two can only disagree if this generator is skipped.
// The classes extend the interface directly (never the Default*), keeping
// the compiler-enforced member parity of `cross-platform/localization.md`.
//
// Usage (from packages/coui_i10n):
//   dart run tool/gen_chrome_localizations.dart          # write
//   dart run tool/gen_chrome_localizations.dart --check  # exit 1 if stale
import 'dart:convert';
import 'dart:io';

const _kSourceDir = 'chrome/i18n';
const _kFlutterDir = '../coui_flutter/lib/src/components/locale';
const _kWebDir = '../coui_web/lib/src/components/locale/coui_localizations';

/// Locales whose strings were written by a person. Everything else came
/// from slang_gpt and is marked as awaiting native-speaker review.
const _kHumanAuthored = {'ko', 'en'};

const _kLanguageNames = {
  'ar': 'Arabic',
  'de': 'German',
  'en': 'English',
  'es': 'Spanish',
  'fr': 'French',
  'it': 'Italian',
  'ja': 'Japanese',
  'ko': 'Korean',
  'pt': 'Portuguese',
  'ru': 'Russian',
  'zh-Hans': 'Simplified Chinese',
};

/// Parameterised members: name → (type, parameter) in declaration order.
/// A `{parameter}` in the template becomes the argument; `double`s go
/// through `formatNumber` exactly like the hand-written locales do.
const _kMethods = <String, List<(String, String)>>{
  'formLessThan': [('double', 'value')],
  'formGreaterThan': [('double', 'value')],
  'formLessThanOrEqualTo': [('double', 'value')],
  'formGreaterThanOrEqualTo': [('double', 'value')],
  'formBetweenInclusively': [('double', 'max'), ('double', 'min')],
  'formBetweenExclusively': [('double', 'max'), ('double', 'min')],
  'formLengthLessThan': [('int', 'value')],
  'formLengthGreaterThan': [('int', 'value')],
  'dataTableSelectedRows': [('int', 'count'), ('int', 'total')],
  'galleryImageLabel': [('int', 'index')],
  'sortableHandleLabel': [('int', 'position'), ('int', 'count')],
  'sortableAnnouncePickedUp': [('int', 'position'), ('int', 'count')],
  'sortableAnnounceMoved': [('int', 'position'), ('int', 'count')],
  'sortableAnnounceDropped': [('int', 'position'), ('int', 'count')],
  'sortableAnnounceCancelled': [('int', 'position'), ('int', 'count')],
  'colorPickerRecentColor': [('String', 'value')],
  'stepperStepLabel': [('String', 'label'), ('int', 'number')],
  'progressStepValue': [('int', 'current'), ('int', 'total')],
  'paginationJumpToPage': [('int', 'page')],
  'dotIndicatorGoToItem': [('int', 'index')],
  'dotIndicatorPosition': [('int', 'current'), ('int', 'total')],
  'calendarMarkerCount': [('int', 'count')],
  'chipRemoveLabel': [('String', 'label')],
  'diffPositionLabel': [('int', 'percent')],
  'resizableDividerPositionLabel': [('int', 'percent')],
  'codeSnippetSuccessLineLabel': [('int', 'line')],
  'codeSnippetWarningLineLabel': [('int', 'line')],
  'codeSnippetErrorLineLabel': [('int', 'line')],
};

/// Keys that are not interface members but templates for the formatting
/// methods (`formatDateTime`, `formatTimeOfDay`, `formatDuration`,
/// `formatMonthYear`, `datePartsOrder`).
const _kFormatKeys = {
  'dateTime',
  'monthYear',
  'clockWithPeriod',
  'durationDays',
  'durationHours',
  'durationMinutes',
  'durationSeconds',
};

/// Members that are not plain getters and are emitted specially.
const _kSpecial = {'localizedMimeTypes', 'format'};

Future<void> main(List<String> args) async {
  final check = args.contains('--check');
  final stale = <String>[];

  for (final MapEntry(key: path, value: code) in (await generate()).entries) {
    final file = File(path);
    final current = file.existsSync() ? file.readAsStringSync() : null;
    if (current == code) continue;
    if (check) {
      stale.add(path);
    } else {
      file.writeAsStringSync(code);
      stdout.writeln('wrote $path');
    }
  }

  if (stale.isNotEmpty) {
    stderr.writeln(
      'Stale generated locale classes — run '
      '`dart run tool/gen_chrome_localizations.dart`:\n'
      '${stale.map((p) => '  $p').join('\n')}',
    );
    exitCode = 1;
  }
}

/// Every generated locale class of both platforms, keyed by its path
/// (relative to this package), as its final bytes — what a write puts on
/// disk and `--check` compares against.
///
/// Reads the sources and writes nothing: each class is formatted in memory
/// by [_format]. Every source is checked against the `en` reference before
/// any class is produced.
Future<Map<String, String>> generate() async {
  final sources = _readSources();
  final reference = sources['en']!;
  for (final MapEntry(key: locale, value: json) in sources.entries) {
    _verifyShape(locale, json, reference);
  }

  final generated = <String, String>{};
  for (final MapEntry(key: locale, value: json) in sources.entries) {
    if (locale == 'en') continue;
    for (final platform in _Platform.values) {
      final path =
          '${platform.dir}/${_fileStem(locale)}_coui_localizations.dart';
      generated[path] = await _format(_render(locale, json, platform), path);
    }
  }

  return generated;
}

Map<String, Map<String, Object?>> _readSources() {
  final result = <String, Map<String, Object?>>{};
  final files = Directory(_kSourceDir).listSync().whereType<File>().toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final file in files) {
    final name = file.uri.pathSegments.last;
    if (!name.endsWith('.i18n.json') || name.startsWith('_')) continue;
    final locale = name.substring(0, name.length - '.i18n.json'.length);
    result[locale] =
        jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
  }
  if (!result.containsKey('en') || !result.containsKey('ko')) {
    throw StateError('$_kSourceDir must contain en.i18n.json and ko.i18n.json');
  }

  return result;
}

Iterable<String> _keys(Map<String, Object?> json) =>
    json.keys.where((k) => !k.startsWith('@'));

/// Every locale must carry exactly the reference's members, mime types and
/// templates, with the same placeholders — a translation that drops or
/// renames a `{placeholder}` would otherwise compile into a wrong string.
void _verifyShape(
  String locale,
  Map<String, Object?> json,
  Map<String, Object?> reference,
) {
  void fail(String why) =>
      throw StateError('$_kSourceDir/$locale.i18n.json: $why');

  final missing = _keys(reference).toSet().difference(_keys(json).toSet());
  final extra = _keys(json).toSet().difference(_keys(reference).toSet());
  if (missing.isNotEmpty) fail('missing $missing');
  if (extra.isNotEmpty) fail('unknown $extra');

  final mime = json['localizedMimeTypes']! as Map<String, Object?>;
  final refMime = reference['localizedMimeTypes']! as Map<String, Object?>;
  if (mime.keys.toSet().difference(refMime.keys.toSet()).isNotEmpty ||
      refMime.keys.toSet().difference(mime.keys.toSet()).isNotEmpty) {
    fail('localizedMimeTypes keys differ from en');
  }

  final format = json['format']! as Map<String, Object?>;
  if (format.keys.toSet().difference(_kFormatKeys).isNotEmpty ||
      _kFormatKeys.difference(format.keys.toSet()).isNotEmpty) {
    fail('format must contain exactly $_kFormatKeys');
  }

  for (final key in _keys(reference)) {
    if (_kSpecial.contains(key)) continue;
    final want = _placeholders(reference[key]);
    final got = _placeholders(json[key]);
    if (want.difference(got).isNotEmpty || got.difference(want).isNotEmpty) {
      fail('$key placeholders $got, expected $want');
    }
  }
  final refFormat = reference['format']! as Map<String, Object?>;
  for (final key in _kFormatKeys) {
    final got = _placeholders(format[key]);
    final allowed = switch (key) {
      'dateTime' || 'monthYear' => {
        'year',
        'month',
        'monthPadded',
        'monthName',
        'day',
        'dayPadded',
      },
      'clockWithPeriod' => {'period', 'time'},
      _ => {'count'},
    };
    if (got.difference(allowed).isNotEmpty) {
      fail('format.$key uses $got, allowed $allowed');
    }
    if (key == 'clockWithPeriod' || key.startsWith('duration')) {
      final want = _placeholders(refFormat[key]);
      if (want.difference(got).isNotEmpty) {
        fail('format.$key must keep $want');
      }
    }
  }
  _datePartsOrder(locale, format['dateTime']! as String);
}

Set<String> _placeholders(Object? value) => switch (value) {
  final String s => RegExp(
    r'\{(\w+)\}',
  ).allMatches(s).map((m) => m.group(1)!).toSet(),
  final Map<String, Object?> m => m.values.expand(_placeholders).toSet(),
  _ => const {},
};

String _fileStem(String locale) => locale.toLowerCase().replaceAll('-', '_');

String _classStem(String locale) => locale
    .split('-')
    .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
    .join();

enum _Platform {
  flutter(_kFlutterDir, 'CoUILocalizations'),
  web(_kWebDir, 'CouiLocalizations');

  const _Platform(this.dir, this.interfaceName);

  final String dir;
  final String interfaceName;
}

String _render(String locale, Map<String, Object?> json, _Platform platform) {
  final className = '${_classStem(locale)}${platform.interfaceName}';
  final languageName = _kLanguageNames[locale] ?? locale;
  final origin = _kHumanAuthored.contains(locale)
      ? 'Human-authored source locale.'
      : 'AI-translated (slang_gpt) — awaiting native-speaker review.';
  final b = StringBuffer()
    ..writeln(
      '// GENERATED by packages/coui_i10n/tool/gen_chrome_localizations.dart',
    )
    ..writeln(
      '// from packages/coui_i10n/chrome/i18n/$locale.i18n.json — do not edit;',
    )
    ..writeln('// change the JSON and re-run the generator.');
  switch (platform) {
    case _Platform.flutter:
      b.writeln("import 'package:coui_flutter/coui_flutter.dart';");
    case _Platform.web:
      b
        ..writeln(
          "import 'package:coui_core/coui_core.dart' show CoreClockFormat;",
        )
        ..writeln(
          "import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';",
        );
  }
  b
    ..writeln()
    ..writeln(
      '/// $languageName (`$locale`) implementation of [${platform.interfaceName}].',
    )
    ..writeln('///')
    ..writeln('/// $origin')
    ..writeln('///')
    ..writeln(
      '/// Extends [${platform.interfaceName}] directly (not the Default) so the',
    )
    ..writeln(
      '/// compiler flags any newly-added abstract member instead of silently',
    )
    ..writeln('/// inheriting the English default.')
    ..writeln('class $className extends ${platform.interfaceName} {')
    ..writeln('  /// Creates a $className.')
    ..writeln('  const $className();')
    ..writeln()
    ..writeln(
      '  /// Shared `const` singleton — identity is compared by the locale scope.',
    )
    ..writeln('  static const instance = $className();');

  final format = json['format']! as Map<String, Object?>;
  for (final key in _keys(json)) {
    final comment = json['@$key'];
    final buffer = StringBuffer()..writeln();
    if (comment is String) {
      for (final line in _wrap(comment, 74)) {
        buffer.writeln('  // $line');
      }
    }
    final value = json[key];
    if (key == 'format') {
      b.write(_renderFormat(format));
      continue;
    }
    buffer.writeln('  @override');
    if (key == 'localizedMimeTypes') {
      buffer.writeln(
        '  Map<String, String> get localizedMimeTypes => const {',
      );
      for (final MapEntry(key: k, value: v)
          in (value! as Map<String, Object?>).entries) {
        buffer.writeln("    '${_mimeKey(k)}': ${_quote(v! as String)},");
      }
      buffer.writeln('  };');
    } else if (_kMethods[key] case final params?) {
      final signature = params.map((p) => '${p.$1} ${p.$2}').join(', ');
      if (value is Map<String, Object?>) {
        final one = _interpolate(value['one']! as String, params);
        final other = _interpolate(value['other']! as String, params);
        buffer.writeln(
          one == other
              ? '  String $key($signature) => $other;'
              : '  String $key($signature) =>\n'
                    '      count == 1 ? $one : $other;',
        );
      } else {
        final body = _interpolate(value! as String, params);
        buffer.writeln('  String $key($signature) => $body;');
      }
    } else {
      buffer.writeln('  String get $key => ${_quote(value! as String)};');
    }
    b.write(buffer);
  }
  b.writeln('}');

  return b.toString();
}

/// mime keys are stored with `.` replaced by `_` (slang treats `.` as a key
/// path separator); no real mime type in the table contains `_`.
String _mimeKey(String key) => key.replaceAll('_', '.');

String _renderFormat(Map<String, Object?> format) {
  final dateTime = format['dateTime']! as String;
  final monthYear = format['monthYear']! as String;
  final clock = format['clockWithPeriod']! as String;
  String duration(String key, String variable) => _interpolateNamed(
    format[key]! as String,
    {'count': variable},
  );
  final order = _datePartsOrder('', dateTime);

  return '''

  @override
  String formatNumber(double value) {
    return value == value.toInt() ? value.toInt().toString() : value.toString();
  }

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
      result += ${_interpolateNamed(dateTime, const {'year': 'dateTime.year', 'month': 'dateTime.month', 'monthPadded': "dateTime.month.toString().padLeft(2, '0')", 'day': 'dateTime.day', 'dayPadded': "dateTime.day.toString().padLeft(2, '0')", 'monthName': 'getMonth(dateTime.month)'})};
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
  String formatMonthYear(int month, int year) =>
      ${_interpolateNamed(monthYear, const {'year': 'year', 'month': 'month', 'monthPadded': "month.toString().padLeft(2, '0')", 'monthName': 'getMonth(month)'})};

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

    return ${_interpolateNamed(clock, const {'period': 'period', 'time': 'digits'})};
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
      parts.add(${duration('durationDays', 'days')});
    }
    if (showHours && hours > 0) {
      parts.add(${duration('durationHours', 'hours')});
    }
    if (showMinutes && minutes > 0) {
      parts.add(${duration('durationMinutes', 'minutes')});
    }
    if (showSeconds && seconds > 0) {
      parts.add(${duration('durationSeconds', 'seconds')});
    }

    return parts.join(' ');
  }

  // Derived from the order of the date placeholders in format.dateTime.
  @override
  List<DatePart> get datePartsOrder => const [
${order.map((p) => '    DatePart.$p,').join('\n')}
  ];
''';
}

/// The order of the year, month and day placeholders in [template].
List<String> _datePartsOrder(String locale, String template) {
  final positions = <String, int>{};
  for (final m in RegExp(r'\{(\w+)\}').allMatches(template)) {
    final part = switch (m.group(1)) {
      'year' => 'year',
      'month' || 'monthPadded' || 'monthName' => 'month',
      'day' || 'dayPadded' => 'day',
      _ => null,
    };
    if (part != null) positions.putIfAbsent(part, () => m.start);
  }
  if (positions.length != 3) {
    throw StateError(
      '$locale: format.dateTime must contain {year}, {month} or '
      '{monthName}, and {day} (or their *Padded forms): "$template"',
    );
  }

  return positions.keys.toList()
    ..sort((a, b) => positions[a]!.compareTo(positions[b]!));
}

String _interpolate(String template, List<(String, String)> params) =>
    _interpolateNamed(template, {
      for (final (type, name) in params)
        name: type == 'double' ? 'formatNumber($name)' : name,
    });

/// Renders [template] as a Dart string expression whose `{name}`
/// placeholders become interpolations of [expressions].
///
/// Long values are emitted as adjacent literals split at spaces so the
/// generated files stay within the 80-column lint, and the quote character is
/// chosen so the text needs no escaped inner quotes.
String _interpolateNamed(String template, Map<String, String> expressions) {
  // (text, isExpression) — text is raw for literals, Dart source for
  // interpolations.
  final tokens = <(String, bool)>[];
  void addText(String text) {
    for (final m in RegExp('[^ ]* *').allMatches(text)) {
      if (m.group(0)!.isNotEmpty) tokens.add((m.group(0)!, false));
    }
  }

  var index = 0;
  for (final m in RegExp(r'\{(\w+)\}').allMatches(template)) {
    addText(template.substring(index, m.start));
    final expression = expressions[m.group(1)];
    if (expression == null) {
      throw StateError('Unknown placeholder {${m.group(1)}} in "$template"');
    }
    final next = m.end < template.length ? template[m.end] : '';
    final bare =
        RegExp(r'^[A-Za-z_]\w*$').hasMatch(expression) &&
        !RegExp('[A-Za-z0-9_]').hasMatch(next);
    tokens.add((bare ? '\$$expression' : '\${$expression}', true));
    index = m.end;
  }
  addText(template.substring(index));

  const width = 56;
  final chunks = <List<(String, bool)>>[[]];
  var length = 0;
  for (final token in tokens) {
    if (chunks.last.isNotEmpty && length + token.$1.length > width) {
      chunks.add([]);
      length = 0;
    }
    chunks.last.add(token);
    length += token.$1.length;
  }

  return chunks.map(_literal).join(' ');
}

/// One string literal; the quote is chosen so no inner quote is escaped.
String _literal(List<(String, bool)> tokens) {
  final raw = tokens.where((t) => !t.$2).map((t) => t.$1).join();
  final quote = raw.contains("'") && !raw.contains('"') ? '"' : "'";
  final body = tokens.map((t) => t.$2 ? t.$1 : _escape(t.$1, quote)).join();

  return '$quote$body$quote';
}

String _quote(String value) {
  if (RegExp(r'\{\w+\}').hasMatch(value)) {
    throw StateError('Unexpected placeholder in a plain string: "$value"');
  }

  return _interpolateNamed(value, const {});
}

String _escape(String value, String quote) => value
    .replaceAll(r'\', r'\\')
    .replaceAll(quote, '\\$quote')
    .replaceAll(r'$', r'\$')
    .replaceAll('\n', r'\n');

Iterable<String> _wrap(String text, int width) sync* {
  var line = '';
  for (final word in text.split(' ')) {
    if (line.isNotEmpty && line.length + word.length + 1 > width) {
      yield line;
      line = word;
    } else {
      line = line.isEmpty ? word : '$line $word';
    }
  }
  if (line.isNotEmpty) yield line;
}

/// [code] as `dart format` leaves it at [path].
///
/// The code goes in on stdin and comes back on stdout; `--stdin-name` makes
/// the formatter resolve the target package's `analysis_options.yaml`
/// (`trailing_commas: preserve`, `page_width`) and language version exactly
/// as it would for the file itself. Nothing is written to disk: a scratch
/// file beside the target would sit under that package's `lib/`, where
/// every test that walks its sources lists it — and a walker that listed it
/// before it was deleted fails reading it.
Future<String> _format(String code, String path) async {
  final process = await Process.start('dart', [
    // Stdout is the result here, so no first-run notice may land on it.
    '--suppress-analytics',
    'format',
    '--stdin-name=${Directory.current.path}/$path',
  ]);
  final formatted = process.stdout.transform(utf8.decoder).join();
  final diagnostics = process.stderr.transform(utf8.decoder).join();
  process.stdin.add(utf8.encode(code));
  await process.stdin.close();
  final status = await process.exitCode;
  final output = await formatted;
  // The formatter says nothing on stderr when it formats. A parse error
  // exits non-zero; an `include:` it cannot resolve only warns, exits 0 and
  // formats with the default options — either way the bytes are not what
  // `dart format` makes of the real file.
  final warnings = await diagnostics;
  if (status != 0 || warnings.isNotEmpty) {
    throw StateError('dart format failed for $path:\n$warnings');
  }

  return output;
}
