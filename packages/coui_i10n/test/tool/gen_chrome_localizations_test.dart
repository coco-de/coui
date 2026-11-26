// The generator runs while other test files walk the packages it writes
// into — `flutter test` runs files in parallel — so a file it writes, even
// one it deletes again, can be listed by a walker and be gone when the
// walker reads it. Generating the classes must therefore write nothing; the
// classes are formatted in memory.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/gen_chrome_localizations.dart' as gen;

void main() {
  late Map<String, String> generated;
  late _WriteRecorder recorder;

  setUpAll(() async {
    recorder = _WriteRecorder();
    generated = await IOOverrides.runWithIOOverrides(gen.generate, recorder);
  });

  test('generating the locale classes writes no file', () {
    expect(generated, isNotEmpty);
    expect(recorder.written, isEmpty);
  });

  test('the committed locale classes are what the generator makes', () {
    // The generator's own `--check`, run here so a source edit that skipped
    // the generator fails a test instead of shipping stale classes.
    for (final MapEntry(key: path, value: code) in generated.entries) {
      expect(
        File(path).readAsStringSync(),
        code,
        reason:
            '$path is stale — run `dart run tool/gen_chrome_localizations.dart`',
      );
    }
  });
}

/// Hands out the real [File] for every path, wrapped so the paths written or
/// deleted through it are noted in [written].
final class _WriteRecorder extends IOOverrides {
  final written = <String>[];

  @override
  File createFile(String path) =>
      _RecordedFile(super.createFile(path), written);
}

/// Reads through to the real file; records, then performs, each write.
///
/// Only the calls the generator makes are spelled out. Any other call fails
/// the test by name, so a new one is decided here — forwarded if it reads,
/// recorded if it writes — instead of passing the recorder unseen.
final class _RecordedFile implements File {
  _RecordedFile(this._file, this._written);

  final File _file;
  final List<String> _written;

  @override
  String get path => _file.path;

  @override
  Directory get parent => _file.parent;

  @override
  bool existsSync() => _file.existsSync();

  @override
  String readAsStringSync({Encoding encoding = utf8}) =>
      _file.readAsStringSync(encoding: encoding);

  @override
  void writeAsStringSync(
    String contents, {
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) {
    _written.add(path);
    _file.writeAsStringSync(
      contents,
      mode: mode,
      encoding: encoding,
      flush: flush,
    );
  }

  @override
  void deleteSync({bool recursive = false}) {
    _written.add(path);
    _file.deleteSync(recursive: recursive);
  }

  @override
  Never noSuchMethod(Invocation invocation) => throw UnsupportedError(
    '${invocation.memberName} on $path — forward it if it reads, record it '
    'if it writes.',
  );
}
