/// EPIC-004 (#3597) child #3612 — WebTransitionContractProbe.
///
/// FR-013 (`.bmad/architecture-*.md` Component ⑧): verify Web animation
/// existence/parameters from the **computed style of a live, headless
/// browser** rather than from source text — the exact same "render the
/// real values, don't grep the declaration" discipline `WebCaptureBackend`
/// uses for colour/typography (`web/web-specifics.md`'s single-emit-rule
/// family). A `transition-property`/`transition-duration` pair is a
/// **static CSS declaration** matched against the element's current
/// class/attribute state — reading it does not require the attribute
/// change to actually fire live in the browser, so this probe never needs
/// a compiled (dart2js) client bootstrap to toggle
/// `data-coui-style`/`data-theme` at runtime: the harness bakes the target
/// attribute state directly into the SSR'd static HTML (same technique
/// `offline_tailwind_harness.dart` already uses for `data-theme`), then
/// reads what CSS rule matched. That is also why the dart2js
/// release-vs-debug minification pitfall (`web/web-specifics.md`) does not
/// apply here — there is no compiled event-handler code path in this
/// harness at all to desync.
library;

import 'dart:convert';

import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

/// A parsed `transition-property` / `transition-duration` /
/// `transition-timing-function` triple, as CSS actually resolves it — the
/// three longhands are independent comma-separated lists that **cycle** to
/// the length of the longest one (CSS Transitions §3), so a single
/// `transition-duration: 150ms` paired with
/// `transition-property: background-color, border-color` means *both*
/// properties get 150ms, not just the first.
class ComputedTransitionContract {
  const ComputedTransitionContract({
    required this.properties,
    required this.durationsMs,
    required this.timingFunctions,
  });

  /// Parses the three raw `getComputedStyle(...)` strings into
  /// per-property-aligned lists.
  factory ComputedTransitionContract.parse({
    required String transitionProperty,
    required String transitionDuration,
    required String transitionTimingFunction,
  }) {
    final properties = _splitTopLevelCommas(transitionProperty);
    final rawDurationsMs = _splitTopLevelCommas(
      transitionDuration,
    ).map(_parseCssTimeMs).toList();
    final rawTimingFunctions = _splitTopLevelCommas(transitionTimingFunction);

    return ComputedTransitionContract(
      properties: properties,
      durationsMs: _cycleToLength(rawDurationsMs, properties.length),
      timingFunctions: _cycleToLength(
        rawTimingFunctions,
        properties.length,
      ),
    );
  }

  /// Declared property idents, in order — `['none']` or `['all']` are the
  /// CSS-initial-value forms meaning "nothing was declared here".
  final List<String> properties;

  /// Duration in milliseconds, index-aligned with [properties].
  final List<double> durationsMs;

  /// Timing-function ident/expression, index-aligned with [properties].
  final List<String> timingFunctions;

  /// Whether a **nonzero-duration** transition applies to [property] —
  /// either because [property] is named explicitly, or because the
  /// computed list is `all` with a nonzero duration (CSS's "every
  /// animatable property" form).
  bool declaresTransitionFor(String property) {
    if (properties.contains('none')) return false;
    final index = properties.indexOf(property);
    if (index != -1) return durationsMs[index] > 0;
    final allIndex = properties.indexOf('all');

    return allIndex != -1 && durationsMs[allIndex] > 0;
  }

  /// The duration in milliseconds actually applied to [property], or `null`
  /// if [declaresTransitionFor] would be false for it.
  double? durationMsFor(String property) {
    if (!declaresTransitionFor(property)) return null;
    final index = properties.indexOf(property);
    if (index != -1) return durationsMs[index];

    return durationsMs[properties.indexOf('all')];
  }

  @override
  String toString() =>
      'ComputedTransitionContract(properties: $properties, '
      'durationsMs: $durationsMs, timingFunctions: $timingFunctions)';
}

/// Reads [ComputedTransitionContract] for the element matching [selector]
/// in [page] via `getComputedStyle` — no attribute toggling, no client JS
/// beyond what the vendored Tailwind script already ran to resolve
/// classes into rules (see the library doc comment for why a static read
/// is sufficient for this contract).
Future<ComputedTransitionContract> readComputedTransitionContract(
  pptr.Page page, {
  required String selector,
}) async {
  final json = await page.evaluate<String>(
    '''
(sel) => {
  const el = document.querySelector(sel);
  if (!el) throw new Error('WebTransitionContractProbe: no element matches ' + sel);
  const cs = getComputedStyle(el);
  return JSON.stringify({
    transitionProperty: cs.transitionProperty,
    transitionDuration: cs.transitionDuration,
    transitionTimingFunction: cs.transitionTimingFunction,
  });
}
''',
    args: [selector],
  );
  final map = jsonDecode(json) as Map<String, dynamic>;

  return ComputedTransitionContract.parse(
    transitionProperty: map['transitionProperty'] as String,
    transitionDuration: map['transitionDuration'] as String,
    transitionTimingFunction: map['transitionTimingFunction'] as String,
  );
}

/// Splits a CSS comma-separated value list, respecting parens — several
/// `transition-timing-function` values are `cubic-bezier(a, b, c, d)`
/// expressions whose internal commas must not be treated as list
/// separators.
List<String> _splitTopLevelCommas(String value) {
  final parts = <String>[];
  final buffer = StringBuffer();
  var depth = 0;
  for (final rune in value.runes) {
    final char = String.fromCharCode(rune);
    if (char == '(') depth++;
    if (char == ')') depth--;
    if (char == ',' && depth == 0) {
      parts.add(buffer.toString().trim());
      buffer.clear();
      continue;
    }
    buffer.write(char);
  }
  if (buffer.isNotEmpty) parts.add(buffer.toString().trim());

  return parts.where((p) => p.isNotEmpty).toList();
}

/// Repeats [values] cyclically until it reaches [length] — CSS Transitions
/// §3's rule for when the `transition-duration`/`-timing-function` lists
/// are shorter than `transition-property`.
List<T> _cycleToLength<T>(List<T> values, int length) {
  if (values.isEmpty || length == 0) return const [];

  return List.generate(length, (i) => values[i % values.length]);
}

const int _kMillisecondsPerSecond = 1000;

/// Parses a CSS `<time>` computed-style string (`"0.15s"`, `"150ms"`,
/// `"0s"`) into milliseconds.
double _parseCssTimeMs(String value) {
  final trimmed = value.trim();
  if (trimmed.endsWith('ms')) {
    return double.parse(trimmed.substring(0, trimmed.length - 2));
  }
  if (trimmed.endsWith('s')) {
    return double.parse(trimmed.substring(0, trimmed.length - 1)) *
        _kMillisecondsPerSecond;
  }

  throw FormatException('Unrecognized CSS time value: "$value"');
}

/// Asserts [contract] declares a nonzero-duration transition for
/// [property] — i.e. that switching whatever CSS variable/class/attribute
/// state this element depends on will actually animate that property
/// instead of snapping.
///
/// This is FR-013's "`transition-duration: 0s` 나 `transition-property: none`
/// 이면 실패" check, generalised to any [property] the caller cares about.
void expectTransitionDeclaredForProperty(
  ComputedTransitionContract contract,
  String property, {
  String? reason,
}) {
  if (!contract.declaresTransitionFor(property)) {
    fail(
      '${reason ?? 'Element'}: no transition declared for "$property" — '
      'computed contract is $contract. Expected a nonzero-duration entry '
      'either naming "$property" directly or via "all".',
    );
  }
}

/// Asserts the transition duration [contract] applies to [property] equals
/// [expectedMs] exactly — i.e. that the timing traces back to the same
/// `CoreDuration` token the caller expected, not merely "some nonzero
/// value". Fails if no transition is declared for [property] at all (call
/// [expectTransitionDeclaredForProperty] first for a clearer failure
/// message in that case).
void expectTransitionDurationMatchesToken(
  ComputedTransitionContract contract,
  String property, {
  required int expectedMs,
  String? reason,
}) {
  final actualMs = contract.durationMsFor(property);
  if (actualMs == null) {
    fail(
      '${reason ?? 'Element'}: no transition declared for "$property" at '
      'all — computed contract is $contract.',
    );
  }
  if (actualMs != expectedMs) {
    fail(
      '${reason ?? 'Element'}: transition duration for "$property" is '
      '${actualMs}ms, expected ${expectedMs}ms (a CoreDuration token) — '
      'computed contract is $contract.',
    );
  }
}
