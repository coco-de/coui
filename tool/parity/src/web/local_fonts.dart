// #3605 — local, offline `@font-face` embedding for the Web capture
// harness (NFR-006 reproducibility: "폰트를 로컬 파일로 고정 임베드 —
// 시스템 폰트 폴백 제거").
//
// `docs_core/lib/site_head.dart` (the live docs_site head) loads
// `CoreFontFamily.sans` (Pretendard) from a CDN (jsdelivr) and `.mono`
// (Geist Mono) from the site's own build output — both network fetches,
// exactly the dependency the offline harness (#3602/#3605) must not
// inherit. Without a substitute, the browser silently falls back to
// whatever sans-serif/monospace happens to be installed on the machine
// running the capture, and `PropertyDiff`/`PixelDiff` would then be
// measuring font-availability differences between dev machines and CI
// rather than component rendering. `docs_site/fonts/` vendors both
// families as static weight files — Pretendard for the Flutter app's
// `pubspec.yaml` `fonts:` declaration, Geist Mono as byte copies of the
// `GeistMono` masters `coui_flutter` bundles — and this file re-uses those
// same files for the Web harness instead of fetching anything.
import 'dart:convert';
import 'dart:io';

import 'package:coui_core/coui_core.dart' show CoreFontFamily;
import 'package:path/path.dart' as p;

/// Repo-root-relative directory `docs_site/fonts/` already vendors.
const String kLocalFontsRelativeDir = 'docs_site/fonts';

/// `<FileName-weight-segment>` → CSS `font-weight` number, the standard
/// weight-name convention Pretendard uses. `Variable` files are
/// deliberately excluded — a variable font needs a `font-weight` *range*
/// declaration, a different shape from the static per-weight faces this
/// function emits, and every weight it would cover already has a static
/// file here.
const Map<String, int> kFontWeightNames = {
  'Thin': 100,
  'ExtraLight': 200,
  'Light': 300,
  'Regular': 400,
  'Medium': 500,
  'SemiBold': 600,
  'Bold': 700,
  'ExtraBold': 800,
  'Black': 900,
};

/// Geist's own weight names, which [kFontWeightNames] would mis-read: in
/// Geist `Black` is 800 (not 900), and the two extremes are `UltraLight`
/// (200) and `UltraBlack` (900). The numbers are the OS/2 weight classes
/// of the `GeistMono` masters `coui_flutter` bundles. Reading a Geist file
/// through the standard table would declare its 800 master as 900, and a
/// capture asking for 900 would get the wrong outlines with no error.
const Map<String, int> kGeistFontWeightNames = {
  'Thin': 100,
  'UltraLight': 200,
  'Light': 300,
  'Regular': 400,
  'Medium': 500,
  'SemiBold': 600,
  'Bold': 700,
  'Black': 800,
  'UltraBlack': 900,
};

/// File extension → CSS `format()` token + MIME type for the `data:` URI.
const Map<String, (String, String)> kFontFileFormats = {
  '.otf': ('opentype', 'font/otf'),
  '.ttf': ('truetype', 'font/ttf'),
  '.woff': ('woff', 'font/woff'),
  '.woff2': ('woff2', 'font/woff2'),
};

/// One `@font-face` source file, already resolved to a family/weight.
class _FontFile {
  const _FontFile({
    required this.family,
    required this.weight,
    required this.path,
    required this.format,
    required this.mime,
  });

  final String family;
  final int weight;
  final String path;
  final String format;
  final String mime;
}

/// Base filename (no extension, no directory) → (family, weight) parser.
///
/// Recognizes the two vendored families by their filename prefix —
/// `GeistMono-<Weight>` and `Pretendard-<Weight>` — and declares each
/// under the `CoreFontFamily` name the Web CSS stacks ask for, so the
/// harness can never embed a face under a name no stack reads. A file that
/// matches neither prefix, or whose weight segment isn't in its family's
/// weight table (e.g. `-Variable`), is skipped rather than guessed at;
/// silently mis-mapping a font-weight would corrupt every capture that
/// depends on it.
_FontFile? _parseFontFile(File file) {
  final ext = p.extension(file.path).toLowerCase();
  final formatEntry = kFontFileFormats[ext];
  if (formatEntry == null) return null;

  final stem = p.basenameWithoutExtension(file.path);
  final dash = stem.indexOf('-');
  if (dash < 0) return null;
  final prefix = stem.substring(0, dash);
  final weightName = stem.substring(dash + 1);

  final face = switch (prefix) {
    'GeistMono' => (
      family: CoreFontFamily.mono,
      weights: kGeistFontWeightNames,
    ),
    'Pretendard' => (family: CoreFontFamily.sans, weights: kFontWeightNames),
    _ => null,
  };
  if (face == null) return null;

  final weight = face.weights[weightName];
  if (weight == null) return null;

  final (format, mime) = formatEntry;
  return _FontFile(
    family: face.family,
    weight: weight,
    path: file.path,
    format: format,
    mime: mime,
  );
}

/// One process-lifetime cache — the font files are immutable for the
/// duration of a `capture_web.dart` run, and base64-encoding ~15MB of font
/// data per matrix entry (up to 622 entries) would otherwise repeat the
/// same disk read + encode hundreds of times for no different output.
String? _cachedFontFaceCss;
String? _cachedForRepoRoot;

/// Builds a `<style>`-ready `@font-face` block for every recognized,
/// static-weight font file under [kLocalFontsRelativeDir], as base64
/// `data:` URIs — so the harness stays a single self-contained file with
/// zero additional `file://` reads (matching the "단일 정적 HTML 파일"
/// design in `offline_tailwind_harness.dart`).
///
/// [repoRoot] defaults to [Directory.current], matching every other
/// `tool/parity/` script's convention of running from the repository root.
String buildLocalFontFaceCss({String? repoRoot}) {
  final root = repoRoot ?? Directory.current.path;
  if (_cachedFontFaceCss != null && _cachedForRepoRoot == root) {
    return _cachedFontFaceCss!;
  }

  final dir = Directory(p.join(root, kLocalFontsRelativeDir));
  if (!dir.existsSync()) {
    throw StateError(
      '로컬 폰트 디렉터리를 찾지 못함: ${dir.path}\n'
      '저장소 루트에서 실행 중인지 확인하라.',
    );
  }

  final fontFiles = <_FontFile>[
    for (final entity in dir.listSync())
      if (entity is File) ?_parseFontFile(entity),
  ];
  if (fontFiles.isEmpty) {
    throw StateError('${dir.path} 에서 인식 가능한 폰트 파일을 찾지 못함.');
  }

  final buffer = StringBuffer();
  for (final font in fontFiles) {
    final bytes = File(font.path).readAsBytesSync();
    final b64 = base64Encode(bytes);
    buffer.write(
      "@font-face{font-family:'${font.family}';font-weight:${font.weight};"
      'font-style:normal;src:url(data:${font.mime};base64,$b64) '
      "format('${font.format}');}",
    );
  }

  final css = buffer.toString();
  _cachedFontFaceCss = css;
  _cachedForRepoRoot = root;
  return css;
}
