/// Parses `--key=value` / `--flag` style args, shared by every
/// `tool/parity/*.dart` entrypoint so the flag syntax cannot drift between
/// them (NFR-009 — reuse over fork).
Map<String, String> parseFlags(List<String> args) {
  final map = <String, String>{};
  for (final a in args) {
    if (!a.startsWith('--')) continue;
    final eq = a.indexOf('=');
    if (eq < 0) {
      map[a.substring(2)] = 'true';
    } else {
      map[a.substring(2, eq)] = a.substring(eq + 1);
    }
  }
  return map;
}

/// Splits a comma-separated flag value, trimming empty results.
///
/// Returns `null` for an absent flag (caller decides the "no filter"
/// default) and throws for a present-but-empty value (`--components=`) —
/// a flag stated with nothing behind it is a usage error, not "no filter".
List<String>? parseListFlag(Map<String, String> flags, String name) {
  final raw = flags[name];
  if (raw == null) return null;
  final parts = raw
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    throw ArgumentError('--$name 이 비어있다. 생략하거나 값을 채워라.');
  }
  return parts;
}

/// Process exit codes shared across `tool/parity/*.dart` entrypoints.
///
/// Source: `.bmad/architecture-*.md` API Design → "종료 코드 규약". CI must
/// tell "an actual regression" (1) apart from "the runner/tooling itself
/// broke" (2), or NFR-002's false-positive-rate metric conflates the two.
abstract final class ParityExitCode {
  static const int ok = 0;
  static const int validationFailed = 1;
  static const int infraFailed = 2;
}
