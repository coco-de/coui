import 'dart:io';

import 'package:test/test.dart';

/// Parses `<LivePreview>` tags from all component markdown files.
///
/// Returns map: component → list of variant strings (null for default-only).
Map<String, List<String?>> parseMarkdownVariants() {
  final dir = Directory('content/components');
  final result = <String, List<String?>>{};

  for (final file in dir.listSync().whereType<File>()) {
    if (!file.path.endsWith('.md')) continue;

    final content = file.readAsStringSync();
    final regex = RegExp(
      r'<LivePreview\s+component="([^"]+)"'
      r'(?:\s+variants?="([^"]+)")?',
    );

    for (final match in regex.allMatches(content)) {
      final component = match.group(1)!;
      final variantsAttr = match.group(2);

      if (variantsAttr != null) {
        result[component] = variantsAttr.split(',').map((v) => v.trim()).toList();
      } else {
        result.putIfAbsent(component, () => [null]);
      }
    }
  }

  return result;
}

/// Maps each registry KEY → its builder function name, parsed from the
/// top-level `'key': builder,` map literal.
///
/// Attribution is by registry key (not a name-derived guess) because builder
/// names don't always match keys — e.g. `'text-field': _inputPreview` (web)
/// vs `'text-field': textFieldCode` (code). The value may be public
/// (`buttonCode`) or private (`_buttonPreview`).
Map<String, String> _parseRegistryKeyToFunc(String content) {
  final regex = RegExp(
    r"^\s*'([a-z][a-z0-9-]*)'\s*:\s*(_?\w+)\s*,",
    multiLine: true,
  );
  return {
    for (final m in regex.allMatches(content)) m.group(1)!: m.group(2)!,
  };
}

/// Collects the variant labels a builder body handles, across both switch
/// syntaxes plus the fallback / equality forms. Underscores are allowed so
/// names like `range_dialog` parse.
Set<String> _variantsInBody(String body) {
  final variants = <String>{};
  // switch expression:  'primary' =>
  variants.addAll(
    RegExp(r"'([a-zA-Z][a-zA-Z0-9_-]*)'\s*=>").allMatches(body).map((m) => m.group(1)!),
  );
  // switch statement:  case 'vertical':
  variants.addAll(
    RegExp(r"case\s+'([a-zA-Z][a-zA-Z0-9_-]*)'\s*:").allMatches(body).map((m) => m.group(1)!),
  );
  // default fallback:  variant ?? 'primary'
  variants.addAll(
    RegExp(r"variant\s*\?\?\s*'([a-zA-Z][a-zA-Z0-9_-]*)'").allMatches(body).map((m) => m.group(1)!),
  );
  // equality check:  variant == 'error'
  variants.addAll(
    RegExp(r"variant\s*==\s*'([a-zA-Z][a-zA-Z0-9_-]*)'").allMatches(body).map((m) => m.group(1)!),
  );
  return variants;
}

/// Extracts a top-level function body (brace-matched) by name from [source].
///
/// Brace counting can over-run when a body holds unbalanced braces inside a
/// string literal (common in code snippets); callers only read variant labels
/// — which precede those string bodies — so the over-run is harmless provided
/// each [source] holds a single builder (see [_readCodeFuncBodies]).
String _extractFunctionBodyByName(String source, String funcName) {
  final defRegex = RegExp(
    r'(?:Component|Widget|String)\s+' + RegExp.escape(funcName) + r'\s*\(',
  );
  final match = defRegex.firstMatch(source);
  if (match == null) return '';
  final arrowStart = source.indexOf('=>', match.end);
  final braceStart = source.indexOf('{', match.end);
  // Arrow-body function (`=> const X();`) opens no brace: its body runs to
  // the next `;` and holds no variant labels. Detect it by `=>` preceding
  // any `{` — otherwise a later block function's `{` (e.g. a `switch`-based
  // sibling) would be mis-attributed to this builder.
  if (arrowStart != -1 && (braceStart == -1 || arrowStart < braceStart)) {
    final semicolon = source.indexOf(';', arrowStart);
    if (semicolon == -1) return '';
    return source.substring(arrowStart, semicolon);
  }
  if (braceStart == -1) return '';
  var depth = 1;
  var i = braceStart + 1;
  while (i < source.length && depth > 0) {
    if (source[i] == '{') depth++;
    if (source[i] == '}') depth--;
    i++;
  }
  return source.substring(braceStart, i);
}

/// Parses handled variants from a single-file registry (web / flutter
/// previews), attributing each builder's variants to its registry KEY.
Map<String, Set<String>> parseHandledVariants(String path) {
  final content = File(path).readAsStringSync();
  final keyToFunc = _parseRegistryKeyToFunc(content);
  final result = <String, Set<String>>{};
  for (final entry in keyToFunc.entries) {
    final body = _extractFunctionBodyByName(content, entry.value);
    final variants = _variantsInBody(body);
    if (variants.isNotEmpty) result[entry.key] = variants;
  }
  return result;
}

/// Parses handled variants for the Web code-snippet builders.
///
/// The builders live in per-component example files
/// (`lib/previews/examples/web/**/*_code.dart`), not the registry map, so each
/// file is scanned individually — this bounds the brace-counter over-run (a
/// snippet string can hold unbalanced braces) to a single component.
Map<String, Set<String>> parseCodeHandledVariants(String codeRegistryPath) {
  final keyToFunc = _parseRegistryKeyToFunc(
    File(codeRegistryPath).readAsStringSync(),
  );
  final bodies = _readCodeFuncBodies('lib/previews/examples/web');
  final result = <String, Set<String>>{};
  for (final entry in keyToFunc.entries) {
    final body = bodies[entry.value];
    if (body == null) continue;
    final variants = _variantsInBody(body);
    if (variants.isNotEmpty) result[entry.key] = variants;
  }
  return result;
}

/// Builds `builderName → body` for every `String xxxCode(String? variant)`
/// under [dir], scanning each file independently so a snippet's unbalanced
/// braces can't bleed across files.
Map<String, String> _readCodeFuncBodies(String dir) {
  final result = <String, String>{};
  final nameRegex = RegExp(r'String\s+(\w+Code)\s*\(\s*String\?\s+variant\s*\)');
  for (final entity in Directory(dir).listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('_code.dart')) continue;
    final content = entity.readAsStringSync();
    for (final m in nameRegex.allMatches(content)) {
      result[m.group(1)!] = _extractFunctionBodyByName(content, m.group(1)!);
    }
  }
  return result;
}

/// Known variant differences between web and flutter registries.
///
/// These are intentional platform-specific variants that exist only on one
/// side. When a new mismatch appears that is NOT listed here, the test fails
/// to alert developers.
const kKnownWebOnlyVariants = <String, Set<String>>{
  // Keyed by registry key (`text-field`), not the builder name (`_inputPreview`).
  'text-field': {'error'},
  'slider': {'range', 'disabled'},
  'card': {'hoverable'},
  'link': {'external', 'no-underline'},
};

/// Variants documented (for gallery completeness) that render through the
/// builder's `_ =>` default case — the variant IS the component's default, so
/// it has no explicit switch case in either platform. Not a coverage gap.
const kDefaultRenderedVariants = <String, Set<String>>{
  'mockup': {'phone'},
  'calendar': {'single'},
};

/// Known variant differences between web and code snippet registries.
///
/// Where the web preview enumerates a variant explicitly that the code snippet
/// renders through its `_ =>` default case (or which the snippet expresses via
/// dynamic interpolation the parser can't enumerate). E.g. `button` lists every
/// variant as an explicit web preview case but renders `primary` via the code
/// snippet's `_ =>` default.
const kKnownWebVsCodeDiffs = <String, Set<String>>{
  'button': {'primary'},
  'checkbox': {'disabled'},
  'toggle': {'disabled'},
  'slider': {'range', 'disabled'},
  'card': {'hoverable'},
  'progress': {'empty', 'full'},
  'validation-badge': {'invalid', 'pending'},
  'link': {'external', 'no-underline'},
  'status': {'success', 'warning', 'error'},
  'banner': {'warning', 'error', 'success'},
  'swap': {'rotate', 'flip'},
};

const kKnownCodeVsWebDiffs = <String, Set<String>>{
  'status': {'primary'},
};

void main() {
  late Map<String, List<String?>> markdownVariants;
  late Map<String, Set<String>> webVariants;
  late Map<String, Set<String>> flutterVariants;
  late Map<String, Set<String>> codeVariants;

  setUpAll(() {
    markdownVariants = parseMarkdownVariants();
    webVariants = parseHandledVariants('lib/previews/web_registry.dart');
    flutterVariants = parseHandledVariants(
      'lib/previews/flutter_registry.dart',
    );
    // Code snippet builders live in per-component example files, not the
    // registry map, so resolve them via the code registry's key→builder map.
    codeVariants = parseCodeHandledVariants('lib/previews/code_registry.dart');
  });

  group('Variant parity across platforms', () {
    test('web and flutter have no unexpected variant differences', () {
      final allComponents = {...webVariants.keys, ...flutterVariants.keys};
      final mismatches = <String>[];

      for (final component in allComponents) {
        final web = webVariants[component] ?? {};
        final flutter = flutterVariants[component] ?? {};
        final webOnly = web.difference(flutter).difference(kKnownWebOnlyVariants[component] ?? {});
        final flutterOnly = flutter.difference(web);

        if (webOnly.isNotEmpty || flutterOnly.isNotEmpty) {
          mismatches.add(
            '$component: webOnly=$webOnly, flutterOnly=$flutterOnly',
          );
        }
      }

      expect(
        mismatches,
        isEmpty,
        reason: 'Unexpected variant mismatches:\n${mismatches.join('\n')}',
      );
    });

    test('web and code have no unexpected variant differences', () {
      final allComponents = {...webVariants.keys, ...codeVariants.keys};
      final mismatches = <String>[];

      for (final component in allComponents) {
        final web = webVariants[component] ?? {};
        final code = codeVariants[component] ?? {};
        final webOnly = web.difference(code).difference(kKnownWebVsCodeDiffs[component] ?? {});
        final codeOnly = code.difference(web).difference(kKnownCodeVsWebDiffs[component] ?? {});

        if (webOnly.isNotEmpty || codeOnly.isNotEmpty) {
          mismatches.add(
            '$component: webOnly=$webOnly, codeOnly=$codeOnly',
          );
        }
      }

      expect(
        mismatches,
        isEmpty,
        reason: 'Unexpected variant mismatches:\n${mismatches.join('\n')}',
      );
    });
  });

  group('Markdown variants are handled by builders', () {
    test('every documented variant is handled in web registry', () {
      final unhandled = <String>[];

      for (final entry in markdownVariants.entries) {
        final component = entry.key;
        final documented = entry.value.whereType<String>().toSet();
        if (documented.isEmpty) continue;

        final handled = webVariants[component] ?? {};

        for (final variant in documented) {
          // 'default' is handled by the _ catch-all case.
          if (variant == 'default') continue;
          // Default-equivalent variants render via the _ catch-all (no
          // explicit case) — documented for gallery completeness.
          if (kDefaultRenderedVariants[component]?.contains(variant) ?? false) {
            continue;
          }
          if (!handled.contains(variant)) {
            unhandled.add('$component/$variant');
          }
        }
      }

      expect(
        unhandled,
        isEmpty,
        reason: 'Unhandled web variants:\n${unhandled.join('\n')}',
      );
    });

    test('every documented variant is handled in flutter registry', () {
      final unhandled = <String>[];

      for (final entry in markdownVariants.entries) {
        final component = entry.key;
        final documented = entry.value.whereType<String>().toSet();
        if (documented.isEmpty) continue;

        final handled = flutterVariants[component] ?? {};

        for (final variant in documented) {
          if (variant == 'default') continue;
          if (kDefaultRenderedVariants[component]?.contains(variant) ?? false) {
            continue;
          }
          if (!handled.contains(variant)) {
            unhandled.add('$component/$variant');
          }
        }
      }

      expect(
        unhandled,
        isEmpty,
        reason: 'Unhandled flutter variants:\n${unhandled.join('\n')}',
      );
    });

    test('every documented variant is handled in code registry', () {
      final unhandled = <String>[];
      // Code snippets using `$v` interpolation support all variants dynamically.
      final knownDynamic = {
        ...kKnownWebVsCodeDiffs.keys,
        ...kKnownCodeVsWebDiffs.keys,
      };

      for (final entry in markdownVariants.entries) {
        final component = entry.key;
        if (knownDynamic.contains(component)) continue;

        final documented = entry.value.whereType<String>().toSet();
        if (documented.isEmpty) continue;

        final handled = codeVariants[component] ?? {};

        for (final variant in documented) {
          if (variant == 'default') continue;
          if (kDefaultRenderedVariants[component]?.contains(variant) ?? false) {
            continue;
          }
          if (!handled.contains(variant)) {
            unhandled.add('$component/$variant');
          }
        }
      }

      expect(
        unhandled,
        isEmpty,
        reason: 'Unhandled code variants:\n${unhandled.join('\n')}',
      );
    });
  });

  group('Coverage statistics', () {
    test('reports variant coverage summary', () {
      var totalComponents = 0;
      var componentsWithVariants = 0;
      var totalVariants = 0;

      for (final entry in markdownVariants.entries) {
        totalComponents++;
        final named = entry.value.whereType<String>().length;
        if (named > 0) {
          componentsWithVariants++;
          totalVariants += named;
        }
      }

      // Print summary (visible in verbose test output).
      // ignore: avoid_print
      print(
        'Coverage: $totalComponents components, '
        '$componentsWithVariants with named variants, '
        '$totalVariants total variants',
      );
    });

    test('every component page shows a preview', () {
      // A page shows its component with `<LivePreview>`, or with
      // `<Playground>` once it is on the v2 template. Counting one tag would
      // report every migrated page as lost coverage, and a fixed floor over
      // both would let many pages lose their preview unnoticed.
      final preview = RegExp(r'<(?:LivePreview|Playground)\s+component="[^"]+"');
      final pages = Directory('content/components').listSync().whereType<File>().where((f) => f.path.endsWith('.md'));
      final without = [
        for (final page in pages)
          if (!preview.hasMatch(page.readAsStringSync())) page.uri.pathSegments.last,
      ]..sort();

      expect(pages, isNotEmpty);
      expect(
        without,
        isEmpty,
        reason: 'Component pages without a preview:\n${without.join('\n')}',
      );
    });
  });
}
