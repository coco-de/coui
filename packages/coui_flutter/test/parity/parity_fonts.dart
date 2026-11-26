// Loads the real, static per-weight Pretendard / Geist Mono OTF masters
// `docs_site/fonts/` vendors (the same files
// `tool/parity/src/web/local_fonts.dart` embeds into the Web capture
// harness) into the Flutter engine's own font registry under
// `CoreFontFamily.sans`/`.mono`. The Geist Mono files there are byte
// copies of the `GeistMono` masters `coui_flutter` bundles, so both
// platforms measure one face version.
//
// Without this, every Flutter capture under `test/parity/` renders text
// with `flutter_test`'s built-in deterministic test font instead of real
// Pretendard glyph metrics — `packages/coui_flutter/pubspec.yaml` does
// **not** declare Pretendard as a bundled asset (only RadixIcons /
// BootstrapIcons / LucideIcons / GeistSans / GeistMono; Pretendard is
// declared by `docs_site`/`docs_app`, the apps that actually ship it), so
// there is no package-relative asset this package could fall back to —
// loading the file path below is the *only* way to get real metrics here.
// A test-font capture isn't merely lower-fidelity than a real one, it's
// systematically wrong for a *cross-platform* comparison specifically:
// Web has no equivalent "test font" concept, so a Flutter capture that
// never loaded real Pretendard is comparing Web's real glyph metrics
// against Flutter's synthetic 1em-square ones — a divergence that has
// nothing to do with either platform's actual rendering and everything to
// do with which one forgot to load a font file.
//
// Deliberately **not** wired into `test/helpers/golden_test_app.dart` or
// any other shared `setUp` every test file in this package inherits —
// this package's existing golden baselines
// (`test/src/golden/*_golden_test.dart`) were recorded *without*
// Pretendard loaded, and doing so retroactively would regenerate every
// one of them. Every `test/parity/*_test.dart` file that needs real font
// metrics calls this explicitly in its own `setUpAll`.
import 'dart:io';
import 'dart:typed_data';

import 'package:coui_core/coui_core.dart' show CoreFontFamily;
import 'package:flutter/services.dart' show FontLoader;

/// Repo-root-relative directory `docs_site/fonts/` vendors — resolved from
/// this package's own directory the same way `flutter_capture_test.dart`'s
/// `_capturedDir()` does (`flutter test`'s working directory is the
/// package root, `packages/coui_flutter/`, not the repo root).
const String _kLocalFontsRelativeDir = '../../docs_site/fonts';

/// `<FileName-weight-segment>.otf` prefix → the `CoreFontFamily` name to
/// register it under. Only static (non-`Variable`) OTF masters are
/// recognized — mirrors `local_fonts.dart`'s `_parseFontFile`, which
/// documents the same "a variable font needs a weight *range*, a
/// different shape from the static per-weight faces this loads" reasoning.
const Map<String, String> _kFamilyByFilenamePrefix = {
  'Pretendard': CoreFontFamily.sans,
  'GeistMono': CoreFontFamily.mono,
};

/// Loads every recognized static-weight `.otf` file under
/// [_kLocalFontsRelativeDir] into the Flutter engine, grouped by family.
///
/// Call from a `setUpAll` in any `test/parity/*_test.dart` file that
/// captures text — see this file's top comment for why this isn't done
/// globally.
Future<void> loadParityFonts() async {
  final fontsDir = Directory(_kLocalFontsRelativeDir);
  if (!fontsDir.existsSync()) {
    throw StateError(
      '로컬 폰트 디렉터리를 찾지 못함: ${fontsDir.path}\n'
      'packages/coui_flutter 를 작업 디렉터리로 flutter test 를 실행 중인지 '
      '확인하라.',
    );
  }

  final filesByFamily = <String, List<File>>{};
  for (final entity in fontsDir.listSync()) {
    if (entity is! File || !entity.path.toLowerCase().endsWith('.otf')) {
      continue;
    }
    final stem = entity.uri.pathSegments.last;
    final basename = stem.substring(0, stem.length - '.otf'.length);
    final dash = basename.indexOf('-');
    if (dash < 0) continue;
    final family = _kFamilyByFilenamePrefix[basename.substring(0, dash)];
    if (family == null) continue;
    filesByFamily.putIfAbsent(family, () => []).add(entity);
  }
  if (filesByFamily.isEmpty) {
    throw StateError('${fontsDir.path} 에서 인식 가능한 폰트 파일을 찾지 못함.');
  }

  for (final entry in filesByFamily.entries) {
    final loader = FontLoader(entry.key);
    for (final file in entry.value) {
      loader.addFont(_readFontAsset(file));
    }
    await loader.load();
  }
}

Future<ByteData> _readFontAsset(File file) async {
  final bytes = await file.readAsBytes();
  return ByteData.sublistView(bytes);
}
