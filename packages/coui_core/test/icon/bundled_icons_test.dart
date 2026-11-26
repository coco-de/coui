// #5149 — every icon a CoUI component draws ships in the package. The
// bundle is generated from the components' own `LucideIcons.*` references;
// a component that starts drawing a new icon fails here until the bundle
// is regenerated, so no component icon can fall back to a network fetch.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

import '../../tool/gen_bundled_icons.dart' as gen;

void main() {
  test(
    'the bundle carries exactly the icons the components reference',
    () async {
      expect(
        await gen.isUpToDate(),
        isTrue,
        reason: 'Run: dart run packages/coui_core/tool/gen_bundled_icons.dart',
      );
    },
  );

  // The check runs while other test files walk this package's sources —
  // `dart test` runs files in parallel — so a file it writes, even one it
  // deletes again, can be listed by a walker and be gone when the walker
  // reads it.
  test('checking the bundle writes no file', () async {
    final recorder = _WriteRecorder();
    await IOOverrides.runWithIOOverrides(gen.isUpToDate, recorder);

    expect(recorder.written, isEmpty);
  });

  test('every bundled icon is drawable data', () {
    expect(CoreBundledIcons.icons, isNotEmpty);
    for (final MapEntry(key: id, value: data)
        in CoreBundledIcons.icons.entries) {
      expect(_kIdShape.hasMatch(id), isTrue, reason: id);
      expect(data.body, contains('<'), reason: id);
      expect(data.width, greaterThan(0), reason: id);
      expect(data.height, greaterThan(0), reason: id);
    }
  });
}

/// `prefix:name`, the id shape `IconName.id` produces.
final _kIdShape = RegExp(r'^[a-z0-9-]+:[a-z0-9-]+$');

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
