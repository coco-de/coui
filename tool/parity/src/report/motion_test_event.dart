// #3617 — parses `package:test`'s JSON reporter event stream
// (`dart test --reporter=json` / `flutter test --machine`, both emit the
// same protocol) to find which motion-probe tests failed and why.
//
// Motion probes (#3611 `motion_probe.dart`, #3612
// `transition_contract_probe.dart`, #3613's lifecycle probes) are plain
// `test()`/`expect()`/`fail()` assertions — they don't write a structured
// result artifact the way capture backends write PNG/JSON. Rather than
// retrofitting those already-merged Epic D probes to emit one, this reads
// the JSON test-event log the CI "motion probes" step already produces as
// a side effect of running `dart test`/`flutter test` — one source, no
// new producer.
import 'dart:convert';

/// One failed test's name and captured error text, extracted from a
/// `package:test` JSON event stream.
class MotionTestFailure {
  const MotionTestFailure({required this.testName, required this.errorMessage});

  /// The `test()` description as declared in the probe test file — this is
  /// what a developer searches for to find the assertion that failed.
  final String testName;

  /// The `fail(...)`/`expect(...)` message(s) `package:test` attached to
  /// this test, verbatim — the exact text `motion_failure_classifier.dart`
  /// pattern-matches against.
  final String errorMessage;
}

/// Parses newline-delimited `package:test` JSON events out of [jsonLines]
/// and returns every non-passing test whose name [isMotionProbe] accepts.
///
/// Lines that aren't valid JSON (progress banners `dart test`/`flutter
/// test` print to the same stream in some configurations) are skipped
/// rather than treated as a parse error — this reader only needs the
/// `testStart`/`error`/`testDone` events, and tolerating stray non-JSON
/// lines is cheaper than requiring the caller to pre-filter the log.
List<MotionTestFailure> parseMotionTestFailures(
  String jsonLines, {
  required bool Function(String testName) isMotionProbe,
}) {
  final namesById = <int, String>{};
  final errorsById = <int, StringBuffer>{};
  final resultsById = <int, String>{};

  for (final line in const LineSplitter().convert(jsonLines)) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;

    final Object? decoded;
    try {
      decoded = jsonDecode(trimmed);
    } on FormatException {
      continue;
    }
    if (decoded is! Map<String, Object?>) continue;

    switch (decoded['type']) {
      case 'testStart':
        final test = decoded['test'];
        if (test is Map<String, Object?>) {
          final id = test['id'];
          final name = test['name'];
          if (id is int && name is String) {
            namesById[id] = name;
          }
        }
      case 'error':
        final id = decoded['testID'];
        final message = decoded['error'];
        if (id is int && message is String) {
          (errorsById[id] ??= StringBuffer()).writeln(message);
        }
      case 'testDone':
        final id = decoded['testID'];
        final result = decoded['result'];
        if (id is int && result is String) {
          resultsById[id] = result;
        }
    }
  }

  final failures = <MotionTestFailure>[];
  for (final entry in resultsById.entries) {
    if (entry.value == 'success') continue;
    final name = namesById[entry.key];
    if (name == null || !isMotionProbe(name)) continue;
    final message = errorsById[entry.key]?.toString().trim();
    failures.add(
      MotionTestFailure(
        testName: name,
        errorMessage: message == null || message.isEmpty
            ? '(no error message captured — result: ${entry.value})'
            : message,
      ),
    );
  }
  return failures;
}
