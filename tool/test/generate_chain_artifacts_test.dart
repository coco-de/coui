// The generator's `--check` runs as a CI guard and `--write` from a
// developer's tree, beside test files that walk the trees it writes into —
// a file it writes, even one it deletes again, can be listed by a walker
// and be gone when the walker reads it. Building the artifacts must
// therefore write nothing; every artifact is formatted in memory.
//
// Runs from the repo root (`melos run test:tool`), like the generator.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../generate_chain_artifacts.dart' as gen;

void main() {
  test('building the chain artifacts writes no file', () async {
    final recorder = _WriteRecorder();
    final artifacts = await IOOverrides.runWithIOOverrides(() async {
      final scan = gen.scanRepository();
      final components = scan.components.values.toList()
        ..sort((a, b) => a.slug.compareTo(b.slug));

      return (await gen.buildArtifacts(components, scan.excluded)).artifacts;
    }, recorder);

    expect(artifacts, contains(gen.kAxisTablePath));
    expect(recorder.written, isEmpty);
  });

  group('parseChainExtensions — the colour axis is the main paint field', () {
    // A palette getter means one token whatever it is called on; which
    // field it patches is the component's main paint. A fill-on-track
    // component patches its fill (`color`) because its `backgroundColor` is
    // the track, so a reader that knew only `backgroundColor` would drop
    // that component out of the colour axis.
    const source = '''
extension FooStyleChain on Foo {
  Foo withStyle(CoreFooStyle patch) => this;

  /// `borderRadius: …`.
  Foo get radius4 => withStyle(
    const CoreFooStyle(borderRadius: CoreBorderRadius.all(CoreRadius.radius4)),
  );

  /// `backgroundColor: …`.
  Foo get primary => withStyle(
    const CoreFooStyle(backgroundColor: CoreColor.token(CoreColors.primary)),
  );

  /// `color: …`.
  Foo get success => withStyle(
    const CoreFooStyle(color: CoreColor.token(CoreColors.success)),
  );

  Foo get compact => withStyle(const CoreFooStyle(variant: .compact));
}
''';

    test('`backgroundColor` and `color` both land on the colour axis', () {
      final surface = gen.parseChainExtensions(source).single;

      expect(surface.target, 'Foo');
      expect(surface.hasWithStyle, isTrue);
      expect(surface.radiusGetters, ['radius4']);
      expect(surface.colorGetters, ['primary', 'success']);
    });

    test('any other field stays unclassified, by name', () {
      final surface = gen.parseChainExtensions(source).single;

      expect(surface.otherGetters, ['compact→variant']);
    });
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
