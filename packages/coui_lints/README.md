# coui_lints

A Dart [analyzer plugin][using-plugins] providing CoUI-specific static
analysis rules — the `jaspr_lints` of this repo. It reports the
mechanically-checkable parts of [`.claude/rules/`][rules] directly in your
editor and in `dart analyze` / `flutter analyze`, instead of only at CI time
via `scripts/guards/`.

[using-plugins]: https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/using_plugins.md
[rules]: ../../.claude/rules/README.md

## Why an analyzer plugin, not `custom_lint`

`jaspr_lints` (the package this one is modeled on) is built on the Dart SDK's
own [`analysis_server_plugin`][asp] framework, not the third-party
`custom_lint` package. That framework ships in the Dart/Flutter SDK itself
(Dart 3.10+ / Flutter 3.38+, both satisfied by this repo's SDK constraints),
needs no separate `dart run custom_lint` step, and surfaces diagnostics the
same way built-in lints do — in your IDE and in plain `dart analyze` output.
`coui_lints` follows the same architecture.

[asp]: https://pub.dev/packages/analysis_server_plugin

## Relationship to `scripts/guards/`

This package **complements**, and does not replace, the existing
`scripts/guards/*.sh` CI gates. The guards remain the CI-blocking source of
truth; `coui_lints` gives the same class of feedback at edit time, before a
commit even happens. Every rule here defaults to `INFO` severity, so enabling
it does not turn pre-existing violations into `--fatal-warnings` CI failures
— it only adds visibility.

## Rules

| Rule | What it catches | `.claude/rules/` source |
|---|---|---|
| `avoid_framework_import` | A file imports a CoUI barrel (`coui_flutter.dart` / `coui_web.dart`) *and* the underlying framework (`material.dart`, `jaspr.dart`, ...) directly. A prefixed (`as m`) or `show`-narrowed framework import is exempt — it injects no bare names, so it cannot make bare CoUI names ambiguous | `cross-platform/api.md` |
| `prefer_stacks_and_position` | Raw Flutter `Stack(...)` / `Positioned(...)` in a file that already imports the CoUI barrel. The file that declares `Stacks` / `Position` itself is exempt (the unified widget renders through the raw one) | `code-style/naming.md` |
| `avoid_material_icon_glyph` | `Icon(Icons.xxx)` — the Material icon font — instead of a CoUI icon catalog | `code-style/naming.md` |
| `prefer_text_chain` | `Component.text(...)` instead of the CoUI `Text(...)` chain API. Documented primitive boundaries (chain base `components/text/`, mono/code blocks, native-input internals) and `<style>`/`<script>` payload text are exempt | `cross-platform/api.md`, `web/web-specifics.md` |
| `avoid_hardcoded_duration` | A raw millisecond/second literal in `Duration(...)` instead of a `CoreDuration` token | `core/design-tokens.md` |
| `avoid_hardcoded_chrome_literal` | A raw numeric literal in `BorderRadius.circular(...)` / `Border.all(width: ...)` / `EdgeInsets.*(...)` instead of a Core token | `core/design-tokens.md` |
| `avoid_dynamic_event_target` | `(dynamic event)` parameters or `(x as dynamic).y` property access in Web event handlers — the dart2js release-minification pitfall | `web/web-specifics.md` |
| `avoid_override_prefixed_resolved_field` | A `Resolved*` class field named `override*` | `code-style/naming.md`, `resolver/resolver-pattern.md` |
| `avoid_local_token_constant` | A private `const _kXxx = CoreSpace.xxx`-style local alias of a Core token | `resolver/resolver-pattern.md` |
| `prefer_k_prefixed_global_constant` | A top-level `const` not named `k…` / `_k…`. An annotation constant — a lower-case alias of its own class, `const immutable = Immutable();` — is exempt | `code-style/naming.md` |
| `prefer_handle_prefixed_callback` | A declared method or function torn off into an `on*` callback whose name lacks the `handle` stem (`_onTap`, `_toggle`). Closures and forwarded callbacks (`onTap: widget.onTap`) name nothing new and are skipped. The message suggests a name that keeps the method's own meaning (`_goToPrev` → `_handleGoToPrev`) | `code-style/naming.md` |
| `avoid_incomplete_copy_with` | A `copyWith` that neither accepts nor reads a field its class declares — the rebuilt constructor resets that field to its default. A field the body carries (`field: field`, a branch on `this.field`) counts; static, private and declaration-initialised fields, and an abstract `copyWith`, are skipped | `core/style-contract.md`, `code-style/lint-stack.md` |
| `pass_theme_geometry` | A call that leaves out an optional named `geometry` argument of type `CoreSurfaceGeometryConstraint?` — the conversion then renders the authored value and ignores the theme's geometry axes (the density). The parameter is optional because the conversion is public API, so this rule is what makes passing it mandatory inside the repo. A `copyWith`'s `geometry` replaces a field and is skipped | `core/theme-axis-composition.md` |

Every rule's exact rationale ("why") lives with the rule it mirrors in
`.claude/rules/` — this package intentionally does not duplicate that prose in
diagnostic messages beyond a short summary; read the linked rule file for the
full context and examples.

## Severity — what CI blocks

A rule enabled with `true` reports at **INFO**: `dart analyze --fatal-warnings`
(CI) does not fail on it, and the lefthook `--fatal-infos` gate catches it on
the files a commit touches. To make a rule a CI gate, give it a severity
instead of `true`:

```yaml
plugins:
  coui_lints:
    diagnostics:
      avoid_incomplete_copy_with: warning
```

`analyzer: errors:` does **not** reach plugin diagnostics — a severity set there
is ignored and the rule stays at INFO without any warning (measured). Raise a
rule only once the repo is at zero for it; otherwise the first unrelated PR
turns red on someone else's debt.

## Suppressing a diagnostic

Rules are suppressed the same way any analyzer diagnostic is, with the
`plugin_name/rule_name` form:

```dart
// ignore: coui_lints/prefer_text_chain
Component.text('raw primitive boundary — see cross-platform/api.md')

// ignore_for_file: coui_lints/avoid_hardcoded_chrome_literal
```

Per this repo's conventions, only use `// ignore:` for a genuine, documented
exception — with a one-line reason — not to silence a real violation.

## Scope and limitations

These rules are a deliberately-scoped first pass at the rules in
`.claude/rules/` that are reliably checkable from the Dart AST alone, without
needing cross-file contract awareness (e.g. "does this Style slot exist on
the sibling `CoreXxxContract`?") or full semantic project graphs. Rules that
need that kind of cross-file reasoning remain the job of
`scripts/guards/resolver/verify_contracts.sh` and friends. Extending this
package with more rules over time is expected — add a new
`lib/src/rules/*_rule.dart`, register it in `lib/src/coui_plugin.dart`, and
enable it under `plugins: coui_lints: diagnostics:` in the root
`analysis_options.yaml`.

No quick fixes (`registerFixForRule`) are implemented yet — this initial
release is diagnostics-only.

## Testing

Rule tests use [`analyzer_testing`][analyzer_testing]'s
`AnalysisRuleTest` + `test_reflective_loader`, per the SDK's own
[testing guide][testing-rules]:

```bash
cd packages/coui_lints
dart test
```

[analyzer_testing]: https://pub.dev/packages/analyzer_testing
[testing-rules]: https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/testing_rules.md
