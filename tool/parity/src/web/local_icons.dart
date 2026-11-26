// #3605 — offline `<iconify-icon>` support for the capture harness.
//
// `Icon` (packages/coui_web/lib/src/components/icon/icon.dart) renders
// `<iconify-icon icon="lucide:...">`, a custom element whose default
// behaviour is to fetch actual icon path data from Iconify's live API at
// render time — confirmed by hand: loading only the vendored custom-element
// script (see `../../vendor/iconify/README.md`) produces an empty shadow
// root, no `<svg>`. This file vendors the Lucide icon data too and
// registers it locally before the harness body is parsed, the same
// "vendor what the network call would return" fix
// `offline_tailwind_harness.dart` already applies to Tailwind.
import 'dart:io';

import 'package:path/path.dart' as p;

/// Vendored files' repo-root-relative paths — sole provenance record aside
/// from `vendor/iconify/README.md`'s table. Update both together.
const String kVendoredIconifyScriptRelativePath =
    'tool/parity/vendor/iconify/iconify-icon-2.1.0.js';
const String kVendoredLucideCollectionRelativePath =
    'tool/parity/vendor/iconify/lucide-1.2.121.json';

/// Reads [kVendoredIconifyScriptRelativePath] from disk.
String loadVendoredIconifyScript({String? repoRoot}) =>
    _readVendorFile(kVendoredIconifyScriptRelativePath, repoRoot: repoRoot);

/// Reads [kVendoredLucideCollectionRelativePath] from disk — already valid
/// JSON text, passed straight through as the `addCollection(...)` call's
/// argument (see [buildLocalIconifyHeadHtml]), no parse/re-serialize
/// round-trip needed.
String loadVendoredLucideCollectionJson({String? repoRoot}) => _readVendorFile(
  kVendoredLucideCollectionRelativePath,
  repoRoot: repoRoot,
);

/// Neutralizes a literal `</script` inside [json] before it's embedded raw
/// inside an HTML `<script>` block (see [buildLocalIconifyHeadHtml]).
///
/// The HTML tokenizer ends a `<script>` element's raw-text content on the
/// first byte-for-byte `</script` it finds, with no awareness that the
/// bytes came from inside a JSON string value rather than actual markup.
/// Today's vendored collection has zero such occurrences (verified at
/// vendoring time), but a future icon set could legitimately describe
/// itself with e.g. a `"description"` field mentioning a `<script>` tag,
/// and nothing would fail loudly — the page would just silently truncate
/// mid-JSON and every icon after that point would render blank. `\/` is a
/// valid escaped solidus in both JSON (RFC 8259) and a JS string literal,
/// so this changes zero bytes of what `addCollection` actually parses,
/// only whether the HTML tokenizer's exact-match end-tag scan can see it.
String _neutralizeScriptCloseTag(String json) => json.replaceAllMapped(
  RegExp('</script', caseSensitive: false),
  // Preserves whatever case the source actually used — only the inserted
  // backslash matters for breaking the tokenizer's literal match.
  (match) => '<\\/${match.group(0)!.substring(2)}',
);

String _readVendorFile(String relativePath, {String? repoRoot}) {
  final root = repoRoot ?? Directory.current.path;
  final file = File(p.join(root, relativePath));
  if (!file.existsSync()) {
    throw StateError(
      '벤더 파일을 찾지 못함: ${file.path}\n저장소 루트에서 실행 중인지 확인하라.',
    );
  }
  return file.readAsStringSync();
}

/// Builds the `<head>` fragment that makes `<iconify-icon>` render actual
/// SVG content offline: the vendored custom-element script, CoUI's external
/// per-instance normalizer, then registration of the vendored Lucide
/// collection.
///
/// Order matters twice over: this whole fragment must load after nothing
/// (it's self-contained), but the scripts inside it must stay in this
/// order — `customElements.get('iconify-icon')` returns `null` until the
/// first script has run, and the collection must be registered before the
/// harness `<body>` is parsed so every `<iconify-icon>` element resolves it
/// on its first (only, for a static capture page) `connectedCallback`. See
/// `vendor/iconify/README.md`'s "How registration works" for why this is
/// `customElements.get('iconify-icon').addCollection(...)` and not
/// `window.Iconify.addCollection(...)` (the latter silently no-ops — the
/// bundle never defines a global `Iconify`).
String buildLocalIconifyHeadHtml({String? repoRoot}) {
  final script = loadVendoredIconifyScript(repoRoot: repoRoot);
  final normalizer = _readVendorFile(
    'packages/coui_web/lib/iconify_stroke.js',
    repoRoot: repoRoot,
  );
  final collectionJson = _neutralizeScriptCloseTag(
    loadVendoredLucideCollectionJson(repoRoot: repoRoot),
  );

  return '''
<script>$script</script>
<script>$normalizer</script>
<script>
var el = customElements.get('iconify-icon');
if (el && el.addCollection) { el.addCollection($collectionJson); }
</script>''';
}
